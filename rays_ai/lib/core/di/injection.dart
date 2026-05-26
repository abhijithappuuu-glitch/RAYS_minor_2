import 'package:get_it/get_it.dart';
import 'package:rakshak_ai/core/security/encryption_service.dart';
import 'package:rakshak_ai/core/security/secure_storage_service.dart';
import 'package:rakshak_ai/core/network/dio_client.dart';
import 'package:rakshak_ai/core/network/network_service.dart';
import 'package:rakshak_ai/core/services/data_export_service.dart';
import 'package:rakshak_ai/data/datasources/local/isar_database.dart';
import 'package:rakshak_ai/data/datasources/remote/stress_api_service.dart';
import 'package:rakshak_ai/data/repositories/stress_repository_impl.dart';
import 'package:rakshak_ai/data/repositories/usage_repository_impl.dart';
import 'package:rakshak_ai/data/repositories/health_repository_impl.dart';
import 'package:rakshak_ai/domain/repositories/stress_repository.dart';
import 'package:rakshak_ai/domain/repositories/usage_repository.dart';
import 'package:rakshak_ai/domain/repositories/health_repository.dart';
import 'package:rakshak_ai/domain/usecases/calculate_stress_score.dart';
import 'package:rakshak_ai/domain/usecases/fetch_usage_stats.dart';
import 'package:rakshak_ai/domain/usecases/predict_stress_ml.dart';
import 'package:rakshak_ai/features/background_monitoring/adaptive_scheduler.dart';
import 'package:rakshak_ai/features/smart_notifications/intervention_engine.dart';
import 'package:rakshak_ai/features/context_intelligence/context_collector.dart';

final getIt = GetIt.instance;

/// Initialize all dependency injection bindings
Future<void> configureDependencies() async {
  // ── Security ──────────────────────────────────────────
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );
  getIt.registerLazySingleton<EncryptionService>(
    () => EncryptionService(getIt<SecureStorageService>().storage),
  );

  // ── Network ───────────────────────────────────────────
  getIt.registerLazySingleton<DioClient>(() => DioClient());
  getIt.registerLazySingleton<NetworkService>(
    () => NetworkService(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<StressApiService>(
    () => StressApiService(getIt<NetworkService>()),
  );

  // ── Database ──────────────────────────────────────────
  final database = IsarDatabase();
  await database.initialize();
  getIt.registerLazySingleton<IsarDatabase>(() => database);

  // ── Repositories ──────────────────────────────────────
  getIt.registerLazySingleton<StressRepository>(
    () => StressRepositoryImpl(
      database: getIt<IsarDatabase>(),
      networkService: getIt<NetworkService>(),
      encryptionService: getIt<EncryptionService>(),
    ),
  );
  getIt.registerLazySingleton<UsageRepository>(
    () => UsageRepositoryImpl(),
  );
  getIt.registerLazySingleton<HealthRepository>(
    () => HealthRepositoryImpl(),
  );

  // ── Use Cases ─────────────────────────────────────────
  getIt.registerFactory<CalculateStressScore>(
    () => CalculateStressScore(getIt<StressRepository>()),
  );
  getIt.registerFactory<FetchUsageStats>(
    () => FetchUsageStats(getIt<UsageRepository>()),
  );
  getIt.registerFactory<PredictStressML>(() => PredictStressML());

  // ── Services ──────────────────────────────────────────
  getIt.registerLazySingleton<DataExportService>(
    () => DataExportService(
      database: getIt<IsarDatabase>(),
      encryption: getIt<EncryptionService>(),
    ),
  );

  // ── Features ──────────────────────────────────────────
  getIt.registerLazySingleton<AdaptiveScheduler>(() => AdaptiveScheduler());
  getIt.registerLazySingleton<InterventionEngine>(() => InterventionEngine());
  getIt.registerLazySingleton<ContextIntelligenceCollector>(
    () => ContextIntelligenceCollector(),
  );
}
