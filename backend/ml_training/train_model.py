import os
import json
import joblib
import numpy as np
import pandas as pd
from datetime import datetime
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, roc_auc_score
from sklearn.preprocessing import StandardScaler
import lightgbm as lgb

RANDOM_STATE = 42

RAW_FEATURES = [
    "sleep_minutes",
    "total_screen_minutes",
    "social_minutes",
    "exercise_minutes",
    "pickup_count",
    "resting_heart_rate",
    "hrv_score",  # Added HRV Feature
    "doom_scroll_flag",
    "late_night_usage",
]

def add_personalized_features(df: pd.DataFrame) -> pd.DataFrame:
    d = df.copy()

    # Simulated personal baselines (in inference this comes from DB)
    d["baseline_sleep"] = 420
    d["baseline_screen"] = 300
    d["baseline_hr"] = 72
    d["baseline_pickups"] = 80
    d["baseline_hrv"] = 50.0

    d["sleep_delta"] = d["sleep_minutes"] - d["baseline_sleep"]
    d["screen_delta"] = d["total_screen_minutes"] - d["baseline_screen"]
    d["hr_delta"] = d["resting_heart_rate"] - d["baseline_hr"]
    d["pickup_delta"] = d["pickup_count"] - d["baseline_pickups"]
    d["hrv_delta"] = d["hrv_score"] - d["baseline_hrv"]

    d["screen_sleep_ratio"] = d["total_screen_minutes"] / (d["sleep_minutes"] + 1e-6)
    d["social_screen_ratio"] = d["social_minutes"] / (d["total_screen_minutes"] + 1e-6)

    d["low_sleep_flag"] = (d["sleep_minutes"] < 360).astype(int)
    d["high_screen_flag"] = (d["total_screen_minutes"] > 420).astype(int)
    d["high_hr_flag"] = (d["resting_heart_rate"] > 85).astype(int)

    d["recovery_score"] = (
        d["exercise_minutes"]
        + d["sleep_minutes"] / 10
        - d["total_screen_minutes"] / 20
        + d["hrv_score"] / 10
    )

    return d

def create_labels(df: pd.DataFrame) -> np.ndarray:
    stress_score = (
        (420 - df["sleep_minutes"]).clip(lower=0) * 0.04
        + df["total_screen_minutes"] * 0.01
        + df["doom_scroll_flag"] * 5.0
        + (df["resting_heart_rate"] - 70).clip(lower=0) * 0.5
        - df["exercise_minutes"] * 0.05
        - (df["hrv_score"] - 50) * 0.2
    )

    labels = np.zeros(len(df), dtype=int)
    labels[stress_score >= 15] = 1
    labels[stress_score >= 30] = 2

    return labels

def generate_data(n_samples=5000):
    np.random.seed(RANDOM_STATE)
    df = pd.DataFrame()

    df["sleep_minutes"] = np.random.normal(420, 70, n_samples).clip(240, 600)
    df["total_screen_minutes"] = np.random.normal(320, 120, n_samples).clip(60, 720)
    df["social_minutes"] = (df["total_screen_minutes"] * np.random.uniform(0.2, 0.7, n_samples)).astype(int)
    df["exercise_minutes"] = np.random.normal(40, 25, n_samples).clip(0, 120)
    df["pickup_count"] = np.random.normal(90, 40, n_samples).clip(10, 250)
    df["resting_heart_rate"] = np.random.normal(74, 10, n_samples).clip(50, 110)
    df["hrv_score"] = np.random.normal(50, 15, n_samples).clip(10, 100) # Added HRV
    df["doom_scroll_flag"] = np.random.binomial(1, 0.2, n_samples)
    df["late_night_usage"] = np.random.binomial(1, 0.35, n_samples)

    df["stress_label"] = create_labels(df)
    return df

def train_model():
    print("Generating dataset with HRV...")
    df = generate_data(6000)
    df = add_personalized_features(df)

    feature_cols = [col for col in df.columns if col != "stress_label"]
    X, y = df[feature_cols], df["stress_label"]

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, stratify=y, random_state=RANDOM_STATE)

    scaler = StandardScaler()
    X_train_scaled, X_test_scaled = scaler.fit_transform(X_train), scaler.transform(X_test)

    print("Training LightGBM...")
    model = lgb.LGBMClassifier(
        objective="multiclass", num_class=3, learning_rate=0.03, n_estimators=300,
        max_depth=8, num_leaves=31, subsample=0.8, colsample_bytree=0.8,
        random_state=RANDOM_STATE, class_weight="balanced", verbose=-1,
    )
    model.fit(X_train_scaled, y_train)

    print("Evaluating...")
    y_pred, y_prob = model.predict(X_test_scaled), model.predict_proba(X_test_scaled)
    acc = accuracy_score(y_test, y_pred)
    try:
        from sklearn.preprocessing import label_binarize
        y_test_bin = label_binarize(y_test, classes=[0, 1, 2])
        auc = roc_auc_score(y_test_bin, y_prob, multi_class="ovr")
        print(f"Accuracy: {acc:.4f}\nROC-AUC : {auc:.4f}")
    except Exception:
        print(f"Accuracy: {acc:.4f}\nROC-AUC : (skipped — class distribution issue)")
    
    bundle = {"model": model, "scaler": scaler, "feature_cols": feature_cols, "version": "3.0.0", "trained_at": datetime.now().isoformat()}

    script_dir = os.path.dirname(os.path.abspath(__file__))
    model_output_dir = os.path.join(os.path.dirname(script_dir), "app", "models")
    os.makedirs(model_output_dir, exist_ok=True)
    joblib.dump(bundle, os.path.join(model_output_dir, "stress_predictor.pkl"))

if __name__ == "__main__":
    train_model()