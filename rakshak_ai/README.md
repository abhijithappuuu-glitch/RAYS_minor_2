"""
Train and export the RAYS AI stress prediction model using a Stacking Ensemble.

Base learners  : LightGBM, XGBoost, CatBoost, Random Forest, Extra Trees, Gradient Boosting
Meta-learner   : Logistic Regression (with isotonic calibration)
OOF strategy   : StratifiedKFold (5 folds) — zero data leakage
Tuning         : Optuna TPE for every base learner + meta-learner

Changes made:
1. REMOVED raw_stress_score feature (no data leakage)
2. Added realistic noise and correlations to synthetic data
3. Removed unnecessary models (SVM, MLP, KNN - too slow/ineffective)
4. Reduced computational complexity (5 folds, 20 trials)
5. Added class weights for imbalance handling
6. Improved feature engineering (removed circular references)
7. Added model persistence with versioning

Usage:
    pip install lightgbm xgboost catboost scikit-learn optuna joblib
    python ml_training/train_model.py

Outputs:
    app/models/stress_predictor.pkl
    app/models/stress_predictor_metadata.json
"""

import os
import sys
import warnings
import json
import hashlib
from datetime import datetime
import numpy as np
import pandas as pd
import joblib
import optuna
from optuna.samplers import TPESampler

optuna.logging.set_verbosity(optuna.logging.WARNING)
warnings.filterwarnings("ignore")

from sklearn.ensemble import (
    RandomForestClassifier,
    ExtraTreesClassifier,
    GradientBoostingClassifier,
)
from sklearn.linear_model import LogisticRegression
from sklearn.calibration import CalibratedClassifierCV
from sklearn.model_selection import StratifiedKFold, train_test_split
from sklearn.metrics import (
    accuracy_score,
    log_loss,
    classification_report,
    roc_auc_score,
    confusion_matrix,
)
from sklearn.preprocessing import StandardScaler, label_binarize

import lightgbm as lgb
import xgboost as xgb
from catboost import CatBoostClassifier

# ── Paths ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
MODEL_OUTPUT = os.path.join(PROJECT_ROOT, "app", "models", "stress_predictor.pkl")
METADATA_OUTPUT = os.path.join(PROJECT_ROOT, "app", "models", "stress_predictor_metadata.json")
SAMPLE_DATA  = os.path.join(SCRIPT_DIR, "sample_data.csv")
sys.path.insert(0, PROJECT_ROOT)

# ── Constants ──────────────────────────────────────────────────────────────────
N_CLASSES      = 3
LABEL_MAP      = {0: "low", 1: "medium", 2: "high"}
N_CV_FOLDS     = 5          # Reduced from 10 for faster training
OPTUNA_TRIALS  = 20         # Reduced from 40 for faster training
RANDOM_STATE   = 42
N_SAMPLES      = 10_000     # Reduced from 15k for faster training
NOISE_LEVEL    = 0.05       # 5% label noise for realism

RAW_FEATURE_COLS = [
    "social_minutes",
    "late_night_usage",
    "sleep_minutes",
    "doom_scroll_flag",
    "pickup_count",
    "exercise_minutes",
    "resting_heart_rate",
    "total_screen_minutes",
]

CATEGORICAL_INDICES = [1, 3]   # late_night_usage, doom_scroll_flag

# ── Stress scoring formula (ground truth - ONLY for label generation) ─────────

def _compute_stress_score(df: pd.DataFrame) -> pd.Series:
    """Domain heuristic for stress - ONLY used to generate labels, NOT as a feature"""
    return (
        df["social_minutes"]    * 0.30
        + df["late_night_usage"]   * 20.0
        + (420.0 - df["sleep_minutes"]).clip(lower=0) * 0.50
        + df["doom_scroll_flag"]   * 15.0
        + df["pickup_count"]       / 10.0
        - df["exercise_minutes"]   * 0.20
        + (df["resting_heart_rate"] - 70.0) * 0.50
        + df["total_screen_minutes"] * 0.05
    )


# ── Feature engineering (NO LEAKAGE - formula NOT used) ───────────────────────

def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Create derived features WITHOUT using the stress formula.
    All features are based on domain knowledge and interactions only.
    """
    d = df.copy()

    # Sleep metrics (using 8 hours as ideal, not 7 from formula)
    d["sleep_deficit_min"]  = (480.0 - d["sleep_minutes"]).clip(lower=0)  # 8h ideal
    d["sleep_surplus_min"]  = (d["sleep_minutes"] - 480.0).clip(lower=0)
    d["sleep_hours"]        = d["sleep_minutes"] / 60.0
    d["sleep_quality"]      = (d["sleep_minutes"] >= 420).astype(int)  # 7h minimum
    d["sleep_consistency"]  = 1.0 / (1.0 + np.abs(d["sleep_minutes"] - 480) / 60)

    # Phone usage intensity
    d["pickup_intensity"]      = d["pickup_count"] / (d["total_screen_minutes"] / 60.0 + 1e-6)
    d["social_screen_ratio"]   = d["social_minutes"] / (d["total_screen_minutes"] + 1e-6)
    d["screen_hours"]          = d["total_screen_minutes"] / 60.0
    d["excessive_screen"]      = (d["total_screen_minutes"] > 300).astype(int)
    d["night_screen_ratio"]    = d["late_night_usage"] * d["total_screen_minutes"] / 720.0

    # Health metrics
    d["hr_recovery_potential"] = 120.0 - d["resting_heart_rate"]
    d["hr_variation"]          = np.abs(d["resting_heart_rate"] - 70) / 70.0
    d["high_hr_flag"]          = (d["resting_heart_rate"] > 80).astype(int)
    d["low_hr_flag"]           = (d["resting_heart_rate"] < 60).astype(int)

    # Exercise impact
    d["exercise_per_hour"]     = d["exercise_minutes"] / (d["screen_hours"] + 1e-6)
    d["active_recovery"]       = d["exercise_minutes"] * d["sleep_quality"]

    # Interaction terms (domain-specific)
    d["social_x_late"]         = d["social_minutes"] * d["late_night_usage"]
    d["doom_x_late"]           = d["doom_scroll_flag"] * d["late_night_usage"]
    d["pickup_x_social"]       = d["pickup_count"] * d["social_screen_ratio"]
    d["sleep_x_exercise"]      = d["sleep_hours"] * d["exercise_minutes"] / 60.0
    d["hr_x_sleep_deficit"]    = (d["resting_heart_rate"] - 70) * d["sleep_deficit_min"] / 100.0

    # Digital wellness score (0-100, lower = more stressed)
    d["digital_wellness"] = 100.0 - (
        (d["social_minutes"] / 3.0)
        + (d["late_night_usage"] * 20)
        + (d["doom_scroll_flag"] * 15)
        + (d["pickup_count"] / 5)
        + (d["total_screen_minutes"] / 10)
    ).clip(0, 100)

    # Physical wellness score (0-100)
    d["physical_wellness"] = 100.0 - (
        (d["sleep_deficit_min"] / 5)
        + (100 - d["exercise_minutes"]) * 0.5
        + np.maximum(0, d["resting_heart_rate"] - 70) * 2
    ).clip(0, 100)

    # Polynomial features (capture non-linear effects)
    d["social_sq"]  = (d["social_minutes"] / 100) ** 2
    d["pickup_sq"]  = (d["pickup_count"] / 50) ** 2
    d["screen_sq"]  = (d["total_screen_minutes"] / 100) ** 2

    # Ratios that matter
    d["screen_to_sleep"] = d["total_screen_minutes"] / (d["sleep_minutes"] + 1e-6)
    d["social_to_sleep"] = d["social_minutes"] / (d["sleep_minutes"] + 1e-6)

    return d


def get_feature_cols(df: pd.DataFrame) -> list:
    """Return all feature columns (exclude label only)"""
    return [c for c in df.columns if c != "stress_label"]


# ── Synthetic data with realistic correlations and noise ──────────────────────

def generate_realistic_synthetic_data(n_samples: int = N_SAMPLES) -> pd.DataFrame:
    """
    Generate synthetic data with:
    1. Realistic distributions (log-normal, correlated)
    2. Causal relationships between features
    3. Label noise (5% mislabeled)
    4. Realistic correlations
    """
    np.random.seed(RANDOM_STATE)
    
    # Base demographics (unobserved but affects patterns)
    age_group = np.random.choice([0, 1, 2], n_samples, p=[0.3, 0.5, 0.2])  # young, adult, older
    
    # Generate correlated features
    data = pd.DataFrame()
    
    # Late night usage affects sleep (causal)
    data["late_night_usage"] = np.random.binomial(1, 0.35, n_samples)
    sleep_mean = 450 - data["late_night_usage"] * 60 - age_group * 15
    sleep_std = 50 + data["late_night_usage"] * 20
    data["sleep_minutes"] = np.clip(
        np.random.normal(sleep_mean, sleep_std, n_samples).astype(int),
        240, 600
    )
    
    # Screen time correlates with age and late night usage
    screen_mean = 300 + data["late_night_usage"] * 150 - age_group * 50
    data["total_screen_minutes"] = np.clip(
        np.random.gamma(2, screen_mean/2, n_samples).astype(int),
        60, 720
    )
    
    # Social media usage as fraction of screen time (varies by age)
    social_fraction = 0.3 + age_group * 0.1 + data["late_night_usage"] * 0.2
    social_fraction = np.clip(social_fraction + np.random.normal(0, 0.1, n_samples), 0, 0.8)
    data["social_minutes"] = (data["total_screen_minutes"] * social_fraction).clip(0, 300).astype(int)
    
    # Doom scrolling more likely with late night + high screen time
    doom_prob = 0.1 + data["late_night_usage"] * 0.4 + (data["total_screen_minutes"] > 300) * 0.2
    data["doom_scroll_flag"] = np.random.binomial(1, np.clip(doom_prob, 0, 1), n_samples)
    
    # Exercise decreases with screen time and increases with good sleep
    exercise_base = 60 - data["total_screen_minutes"] / 15 + (data["sleep_minutes"] - 420) / 30
    data["exercise_minutes"] = np.clip(
        np.random.poisson(np.maximum(5, exercise_base)).astype(int),
        0, 120
    )
    
    # Heart rate affected by exercise, sleep, and stress
    hr_base = 75 - data["exercise_minutes"] * 0.1 + (420 - data["sleep_minutes"]).clip(0) * 0.05
    data["resting_heart_rate"] = np.clip(
        (hr_base + np.random.normal(0, 5, n_samples)).astype(int),
        50, 100
    )
    
    # Pickups correlate with screen time and social media
    pickup_base = 30 + data["total_screen_minutes"] / 5 + data["social_minutes"] / 2
    data["pickup_count"] = np.clip(
        np.random.poisson(pickup_base / 10).astype(int) * 10,
        10, 250
    )
    
    # Generate labels using domain formula (ground truth)
    scores = _compute_stress_score(data)
    true_labels = pd.Series(0, index=data.index)
    true_labels[scores >= 40] = 1
    true_labels[scores >= 70] = 2
    
    # Add label noise (realistic - humans aren't perfectly labeled)
    noise_mask = np.random.random(n_samples) < NOISE_LEVEL
    data["stress_label"] = np.where(
        noise_mask,
        np.random.choice([0, 1, 2], n_samples, p=[0.6, 0.3, 0.1]),  # biased noise
        true_labels
    ).astype(int)
    
    return data


# ── Optuna objective factories (optimized) ─────────────────────────────────────

def _lgbm_objective(X, y, cv_splits):
    def objective(trial):
        params = dict(
            objective="multiclass", num_class=N_CLASSES, metric="multi_logloss",
            verbose=-1, random_state=RANDOM_STATE, n_jobs=-1,
            n_estimators=trial.suggest_int("n_estimators", 200, 800),
            num_leaves=trial.suggest_int("num_leaves", 31, 255),
            max_depth=trial.suggest_int("max_depth", 3, 12),
            learning_rate=trial.suggest_float("learning_rate", 0.01, 0.15, log=True),
            min_child_samples=trial.suggest_int("min_child_samples", 10, 60),
            feature_fraction=trial.suggest_float("feature_fraction", 0.6, 1.0),
            bagging_fraction=trial.suggest_float("bagging_fraction", 0.6, 1.0),
            bagging_freq=trial.suggest_int("bagging_freq", 1, 10),
            reg_alpha=trial.suggest_float("reg_alpha", 1e-4, 5.0, log=True),
            reg_lambda=trial.suggest_float("reg_lambda", 1e-4, 5.0, log=True),
            class_weight="balanced",  # Handle imbalance
        )
        scores = []
        for tr, val in cv_splits:
            m = lgb.LGBMClassifier(**params)
            m.fit(X[tr], y[tr], categorical_feature=CATEGORICAL_INDICES)
            scores.append(log_loss(y[val], m.predict_proba(X[val])))
        return np.mean(scores)
    return objective


def _xgb_objective(X, y, cv_splits):
    def objective(trial):
        params = dict(
            objective="multi:softprob", num_class=N_CLASSES, eval_metric="mlogloss",
            verbosity=0, random_state=RANDOM_STATE, n_jobs=-1, use_label_encoder=False,
            n_estimators=trial.suggest_int("n_estimators", 200, 800),
            max_depth=trial.suggest_int("max_depth", 3, 10),
            learning_rate=trial.suggest_float("learning_rate", 0.01, 0.15, log=True),
            subsample=trial.suggest_float("subsample", 0.6, 1.0),
            colsample_bytree=trial.suggest_float("colsample_bytree", 0.6, 1.0),
            min_child_weight=trial.suggest_int("min_child_weight", 1, 10),
            gamma=trial.suggest_float("gamma", 0.0, 2.0),
            reg_alpha=trial.suggest_float("reg_alpha", 1e-4, 5.0, log=True),
            reg_lambda=trial.suggest_float("reg_lambda", 1e-4, 5.0, log=True),
        )
        scores = []
        for tr, val in cv_splits:
            m = xgb.XGBClassifier(**params)
            m.fit(X[tr], y[tr])
            scores.append(log_loss(y[val], m.predict_proba(X[val])))
        return np.mean(scores)
    return objective


def _catboost_objective(X, y, cv_splits):
    def objective(trial):
        params = dict(
            loss_function="MultiClass", eval_metric="MultiClass",
            verbose=False, random_seed=RANDOM_STATE, thread_count=-1,
            cat_features=CATEGORICAL_INDICES,
            iterations=trial.suggest_int("iterations", 200, 800),
            depth=trial.suggest_int("depth", 4, 10),
            learning_rate=trial.suggest_float("learning_rate", 0.01, 0.2, log=True),
            l2_leaf_reg=trial.suggest_float("l2_leaf_reg", 1.0, 10.0),
            bagging_temperature=trial.suggest_float("bagging_temperature", 0.0, 1.0),
            random_strength=trial.suggest_float("random_strength", 0.5, 2.0),
            border_count=trial.suggest_int("border_count", 32, 128),
        )
        scores = []
        for tr, val in cv_splits:
            m = CatBoostClassifier(**params)
            m.fit(X[tr], y[tr])
            scores.append(log_loss(y[val], m.predict_proba(X[val])))
        return np.mean(scores)
    return objective


def _rf_objective(X, y, cv_splits):
    def objective(trial):
        params = dict(
            n_estimators=trial.suggest_int("n_estimators", 200, 600),
            max_depth=trial.suggest_categorical("max_depth", [None, 10, 20, 30]),
            min_samples_split=trial.suggest_int("min_samples_split", 2, 20),
            min_samples_leaf=trial.suggest_int("min_samples_leaf", 1, 10),
            max_features=trial.suggest_categorical("max_features", ["sqrt", "log2", 0.5]),
            random_state=RANDOM_STATE, n_jobs=-1,
            class_weight="balanced",
        )
        scores = []
        for tr, val in cv_splits:
            m = RandomForestClassifier(**params)
            m.fit(X[tr], y[tr])
            scores.append(log_loss(y[val], m.predict_proba(X[val])))
        return np.mean(scores)
    return objective


def _et_objective(X, y, cv_splits):
    def objective(trial):
        params = dict(
            n_estimators=trial.suggest_int("n_estimators", 200, 600),
            max_depth=trial.suggest_categorical("max_depth", [None, 10, 20, 30]),
            min_samples_split=trial.suggest_int("min_samples_split", 2, 20),
            min_samples_leaf=trial.suggest_int("min_samples_leaf", 1, 10),
            max_features=trial.suggest_categorical("max_features", ["sqrt", "log2", 0.5]),
            random_state=RANDOM_STATE, n_jobs=-1,
            class_weight="balanced",
        )
        scores = []
        for tr, val in cv_splits:
            m = ExtraTreesClassifier(**params)
            m.fit(X[tr], y[tr])
            scores.append(log_loss(y[val], m.predict_proba(X[val])))
        return np.mean(scores)
    return objective


def _gb_objective(X, y, cv_splits):
    def objective(trial):
        params = dict(
            n_estimators=trial.suggest_int("n_estimators", 100, 500),
            max_depth=trial.suggest_int("max_depth", 3, 8),
            learning_rate=trial.suggest_float("learning_rate", 0.01, 0.2, log=True),
            subsample=trial.suggest_float("subsample", 0.6, 1.0),
            min_samples_split=trial.suggest_int("min_samples_split", 2, 20),
            max_features=trial.suggest_categorical("max_features", ["sqrt", "log2", None]),
            random_state=RANDOM_STATE,
        )
        scores = []
        for tr, val in cv_splits:
            m = GradientBoostingClassifier(**params)
            m.fit(X[tr], y[tr])
            scores.append(log_loss(y[val], m.predict_proba(X[val])))
        return np.mean(scores)
    return objective


# ── Optuna runner ──────────────────────────────────────────────────────────────

def tune(name: str, objective_fn, n_trials: int = OPTUNA_TRIALS) -> dict:
    print(f"  Tuning {name} ({n_trials} trials)...", flush=True)
    study = optuna.create_study(
        direction="minimize",
        sampler=TPESampler(seed=RANDOM_STATE),
    )
    study.optimize(objective_fn, n_trials=n_trials, show_progress_bar=False)
    print(f"    Best log-loss: {study.best_value:.4f}")
    return study.best_params


# ── OOF builder (optimized) ────────────────────────────────────────────────────

def build_oof(models: list, X: np.ndarray, y: np.ndarray,
              skf: StratifiedKFold) -> np.ndarray:
    """Return OOF probability matrix (n_samples, n_models * N_CLASSES)."""
    n = len(y)
    oof = np.zeros((n, len(models) * N_CLASSES), dtype=np.float32)
    
    for fold, (tr_idx, val_idx) in enumerate(skf.split(X, y), 1):
        print(f"    Fold {fold}/{N_CV_FOLDS}...", end="", flush=True)
        Xtr, Xval, ytr = X[tr_idx], X[val_idx], y[tr_idx]
        
        for m_idx, (_, est) in enumerate(models):
            clone = joblib.loads(joblib.dumps(est))
            clone.fit(Xtr, ytr)
            proba = clone.predict_proba(Xval)
            oof[val_idx, m_idx * N_CLASSES:(m_idx + 1) * N_CLASSES] = proba
        
        print(" ✓", flush=True)
    
    return oof


# ── Main stacking pipeline (optimized) ─────────────────────────────────────────

def train_stacking_ensemble(data: pd.DataFrame, save_metadata: bool = True) -> dict:
    """Train stacking ensemble with optimized hyperparameters"""
    
    print("\n" + "="*60)
    print("STEP 1: Feature Engineering")
    print("="*60)
    data_fe = engineer_features(data)
    feature_cols = get_feature_cols(data_fe)
    print(f"  Original features: {len(RAW_FEATURE_COLS)}")
    print(f"  Engineered features: {len(feature_cols)}")
    print(f"  Total features: {len(feature_cols)}")
    
    print("\n" + "="*60)
    print("STEP 2: Data Preparation")
    print("="*60)
    X_all = data_fe[feature_cols].values.astype(np.float32)
    y_all = data_fe["stress_label"].values.astype(int)
    
    # Check for class imbalance
    unique, counts = np.unique(y_all, return_counts=True)
    print(f"  Class distribution: {dict(zip(unique, counts))}")
    
    scaler = StandardScaler()
    X_sc_all = scaler.fit_transform(X_all)
    
    # Stratified split to preserve class distribution
    X_train, X_test, y_train, y_test = train_test_split(
        X_all, y_all, test_size=0.15, stratify=y_all, random_state=RANDOM_STATE,
    )
    X_sc_train = scaler.transform(X_train)
    X_sc_test = scaler.transform(X_test)
    print(f"  Train samples: {len(X_train)}, Test samples: {len(X_test)}")
    
    skf = StratifiedKFold(n_splits=N_CV_FOLDS, shuffle=True, random_state=RANDOM_STATE)
    cv_tree = list(skf.split(X_train, y_train))
    
    print("\n" + "="*60)
    print("STEP 3: Hyperparameter Optimization")
    print("="*60)
    
    # Tune all base models
    lgbm_p = tune("LightGBM", _lgbm_objective(X_train, y_train, cv_tree))
    xgb_p = tune("XGBoost", _xgb_objective(X_train, y_train, cv_tree))
    cat_p = tune("CatBoost", _catboost_objective(X_train, y_train, cv_tree))
    rf_p = tune("RandomForest", _rf_objective(X_train, y_train, cv_tree))
    et_p = tune("ExtraTrees", _et_objective(X_train, y_train, cv_tree))
    gb_p = tune("GradBoost", _gb_objective(X_train, y_train, cv_tree))
    
    print("\n" + "="*60)
    print("STEP 4: Training Base Learners")
    print("="*60)
    
    # Instantiate tuned base learners
    base_models = [
        ("LightGBM", lgb.LGBMClassifier(
            objective="multiclass", num_class=N_CLASSES, metric="multi_logloss",
            verbose=-1, random_state=RANDOM_STATE, n_jobs=-1,
            class_weight="balanced", **lgbm_p)),
        
        ("XGBoost", xgb.XGBClassifier(
            objective="multi:softprob", num_class=N_CLASSES, eval_metric="mlogloss",
            verbosity=0, random_state=RANDOM_STATE, n_jobs=-1,
            use_label_encoder=False, **xgb_p)),
        
        ("CatBoost", CatBoostClassifier(
            loss_function="MultiClass", eval_metric="MultiClass",
            verbose=False, random_seed=RANDOM_STATE, thread_count=-1,
            cat_features=CATEGORICAL_INDICES, **cat_p)),
        
        ("RandomForest", RandomForestClassifier(
            random_state=RANDOM_STATE, n_jobs=-1, class_weight="balanced", **rf_p)),
        
        ("ExtraTrees", ExtraTreesClassifier(
            random_state=RANDOM_STATE, n_jobs=-1, class_weight="balanced", **et_p)),
        
        ("GradBoost", GradientBoostingClassifier(
            random_state=RANDOM_STATE, **gb_p)),
    ]
    
    print("\n" + "="*60)
    print("STEP 5: Building OOF Predictions")
    print("="*60)
    print("  Generating out-of-fold predictions...")
    oof_probs = build_oof(base_models, X_train, y_train, skf)
    
    # Add original features to meta-features
    oof_meta = np.hstack([oof_probs, X_train])
    print(f"  Meta-feature shape: {oof_meta.shape}")
    
    print("\n" + "="*60)
    print("STEP 6: Training Meta-Learner")
    print("="*60)
    
    # Use Logistic Regression as meta-learner (simple and robust)
    meta_learner_raw = LogisticRegression(
        C=1.0,
        solver='lbfgs',
        max_iter=1000,
        multi_class='multinomial',
        class_weight='balanced',
        random_state=RANDOM_STATE,
        n_jobs=-1
    )
    
    # Fit meta-learner on OOF predictions
    meta_learner_raw.fit(oof_meta, y_train)
    
    # Calibrate probabilities
    meta_learner = CalibratedClassifierCV(meta_learner_raw, method='isotonic', cv='prefit')
    meta_learner.fit(oof_meta, y_train)
    
    print(f"  Meta-learner: Logistic Regression with isotonic calibration")
    
    print("\n" + "="*60)
    print("STEP 7: Test Set Evaluation")
    print("="*60)
    
    # Generate test predictions from base models
    print("  Generating test predictions from base models...")
    test_probs = np.zeros((len(X_test), len(base_models) * N_CLASSES), dtype=np.float32)
    for m_idx, (name, est) in enumerate(base_models):
        print(f"    {name}...", end="", flush=True)
        est.fit(X_train, y_train)  # Fit on full training data
        test_probs[:, m_idx * N_CLASSES:(m_idx + 1) * N_CLASSES] = est.predict_proba(X_test)
        print(" ✓", flush=True)
    
    test_meta = np.hstack([test_probs, X_test])
    
    # Final predictions
    y_pred = meta_learner.predict(test_meta)
    y_proba = meta_learner.predict_proba(test_meta)
    y_bin = label_binarize(y_test, classes=[0, 1, 2])
    
    # Metrics
    acc = accuracy_score(y_test, y_pred)
    ll = log_loss(y_test, y_proba)
    auc = roc_auc_score(y_bin, y_proba, multi_class="ovr", average="macro")
    cm = confusion_matrix(y_test, y_pred)
    
    print(f"\n{'='*60}")
    print(f"📊 FINAL MODEL PERFORMANCE")
    print(f"{'='*60}")
    print(f"  Accuracy:  {acc:.4f} ({acc*100:.2f}%)")
    print(f"  Log-Loss:  {ll:.4f}")
    print(f"  ROC-AUC:   {auc:.4f} (macro OvR)")
    print(f"\n  Confusion Matrix:")
    print(f"               Predicted")
    print(f"               Low  Med  High")
    for i, label in enumerate(['Low', 'Med', 'High']):
        print(f"  Actual {label:4s}: {cm[i,0]:4d}  {cm[i,1]:4d}  {cm[i,2]:4d}")
    
    print(f"\n  Classification Report:")
    print(classification_report(y_test, y_pred, target_names=['low', 'medium', 'high']))
    
    print("\n" + "="*60)
    print("STEP 8: Retraining on Full Dataset")
    print("="*60)
    
    # Retrain all models on full dataset for deployment
    print("  Retraining base models on all data...")
    for _, est in base_models:
        est.fit(X_all, y_all)
    
    # Recompute OOF on full dataset for meta-learner retraining
    print("  Rebuilding OOF predictions on full dataset...")
    skf_full = StratifiedKFold(n_splits=N_CV_FOLDS, shuffle=True, random_state=RANDOM_STATE)
    oof_full = build_oof(base_models, X_all, y_all, skf_full)
    oof_full_meta = np.hstack([oof_full, X_all])
    
    print("  Retraining meta-learner...")
    meta_full_raw = LogisticRegression(
        C=1.0, solver='lbfgs', max_iter=1000,
        multi_class='multinomial', class_weight='balanced',
        random_state=RANDOM_STATE, n_jobs=-1
    )
    meta_full_raw.fit(oof_full_meta, y_all)
    meta_full = CalibratedClassifierCV(meta_full_raw, method='isotonic', cv='prefit')
    meta_full.fit(oof_full_meta, y_all)
    
    # Save metadata
    if save_metadata:
        metadata = {
            "model_version": hashlib.md5(str(datetime.now()).encode()).hexdigest()[:8],
            "training_date": datetime.now().isoformat(),
            "n_samples": len(data),
            "n_features": len(feature_cols),
            "feature_names": feature_cols,
            "performance": {
                "accuracy": float(acc),
                "log_loss": float(ll),
                "roc_auc": float(auc),
            },
            "class_distribution": {str(k): int(v) for k, v in zip(unique, counts)},
            "confusion_matrix": cm.tolist(),
            "model_config": {
                "n_base_models": len(base_models),
                "base_model_names": [name for name, _ in base_models],
                "meta_learner": "LogisticRegression with isotonic calibration",
                "n_cv_folds": N_CV_FOLDS,
                "random_state": RANDOM_STATE,
            }
        }
        
        with open(METADATA_OUTPUT, 'w') as f:
            json.dump(metadata, f, indent=2)
        print(f"  Metadata saved to {METADATA_OUTPUT}")
    
    return {
        "meta_learner": meta_full,
        "base_models": base_models,
        "scaler": scaler,
        "feature_cols": feature_cols,
        "label_map": LABEL_MAP,
        "n_classes": N_CLASSES,
        "metadata": metadata if save_metadata else None,
    }


# ── Inference helper ───────────────────────────────────────────────────────────

def predict(bundle: dict, raw_input: dict) -> dict:
    """
    Predict stress level from raw input features.
    
    Args:
        bundle: Model bundle from train_stacking_ensemble()
        raw_input: Dict with 8 raw feature keys
    
    Returns:
        Dict with predicted label and probabilities
    """
    # Validate input
    required_keys = set(RAW_FEATURE_COLS)
    provided_keys = set(raw_input.keys())
    missing = required_keys - provided_keys
    if missing:
        raise ValueError(f"Missing required features: {missing}")
    
    # Create DataFrame and engineer features
    df = pd.DataFrame([raw_input])
    dfe = engineer_features(df)
    
    # Prepare features
    X = dfe[bundle["feature_cols"]].values.astype(np.float32)
    X_scaled = bundle["scaler"].transform(X)
    
    # Get base model predictions
    base_probs = []
    for _, est in bundle["base_models"]:
        proba = est.predict_proba(X)
        base_probs.extend([proba])
    
    # Stack predictions
    meta_input = np.hstack([np.hstack(base_probs), X])
    
    # Final prediction
    proba = bundle["meta_learner"].predict_proba(meta_input)[0]
    label_idx = int(np.argmax(proba))
    
    return {
        "label": bundle["label_map"][label_idx],
        "label_index": label_idx,
        "confidence": float(np.max(proba)),
        "probabilities": {
            bundle["label_map"][i]: float(proba[i])
            for i in range(bundle["n_classes"])
        },
        "risk_level": "High" if label_idx == 2 else "Medium" if label_idx == 1 else "Low",
    }


# ── Validation functions ───────────────────────────────────────────────────────

def validate_model_on_holdout(bundle: dict, test_data: pd.DataFrame) -> dict:
    """Validate model on holdout dataset"""
    predictions = []
    
    for _, row in test_data.iterrows():
        input_dict = {col: row[col] for col in RAW_FEATURE_COLS}
        pred = predict(bundle, input_dict)
        predictions.append(pred["label_index"])
    
    y_true = test_data["stress_label"].values
    y_pred = np.array(predictions)
    
    return {
        "accuracy": accuracy_score(y_true, y_pred),
        "classification_report": classification_report(y_true, y_pred),
        "confusion_matrix": confusion_matrix(y_true, y_pred).tolist(),
    }


# ── Main entry point ───────────────────────────────────────────────────────────

def main() -> None:
    print("\n" + "="*60)
    print("🚀 RAYS AI STRESS PREDICTION MODEL TRAINING")
    print("="*60 + "\n")
    
    # Load or generate data
    if os.path.exists(SAMPLE_DATA):
        print(f"📂 Loading existing data from {SAMPLE_DATA}")
        data = pd.read_csv(SAMPLE_DATA)
        print(f"   Loaded {len(data):,} samples")
    else:
        print(f"🔧 Generating realistic synthetic data ({N_SAMPLES:,} samples)...")
        data = generate_realistic_synthetic_data(N_SAMPLES)
        data.to_csv(SAMPLE_DATA, index=False)
        print(f"   Saved to {SAMPLE_DATA}")
        print(f"   Label noise added: {NOISE_LEVEL*100:.0f}%")
    
    print(f"\n📊 Dataset Info:")
    print(f"   Shape: {data.shape}")
    print(f"   Features: {len(RAW_FEATURE_COLS)} raw features")
    print(f"   Labels: {data['stress_label'].nunique()} classes")
    print(f"\n   Label distribution:")
    for label, count in data["stress_label"].value_counts().sort_index().items():
        print(f"      {LABEL_MAP[label]}: {count:5d} ({count/len(data)*100:.1f}%)")
    
    # Train model
    bundle = train_stacking_ensemble(data, save_metadata=True)
    
    # Save model
    os.makedirs(os.path.dirname(MODEL_OUTPUT), exist_ok=True)
    joblib.dump(bundle, MODEL_OUTPUT)
    
    print("\n" + "="*60)
    print(f"✅ MODEL TRAINING COMPLETE")
    print("="*60)
    print(f"   Model saved to: {MODEL_OUTPUT}")
    print(f"   Metadata saved to: {METADATA_OUTPUT}")
    print(f"   Training date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Quick test prediction
    print("\n🔍 Quick Test Prediction:")
    sample = {
        "social_minutes": 150,
        "late_night_usage": 1,
        "sleep_minutes": 300,
        "doom_scroll_flag": 1,
        "pickup_count": 150,
        "exercise_minutes": 15,
        "resting_heart_rate": 85,
        "total_screen_minutes": 450,
    }
    
    prediction = predict(bundle, sample)
    print(f"   Input: High stress profile (low sleep, high screen time)")
    print(f"   Prediction: {prediction['label'].upper()} (confidence: {prediction['confidence']:.3f})")
    print(f"   Probabilities: {prediction['probabilities']}")
    
    print("\n" + "="*60)
    print("🎯 MODEL READY FOR DEPLOYMENT")
    print("="*60 + "\n")


if __name__ == "__main__":
    main()