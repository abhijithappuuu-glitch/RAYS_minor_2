# ═══════════════════════════════════════════════════════
# Rakshak AI — ProGuard / R8 Rules
# Production-grade code shrinking & obfuscation
# ═══════════════════════════════════════════════════════

# ─── Flutter ────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ─── Kotlin ─────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Metadata { public <methods>; }

# ─── AndroidX ───────────────────────────────────────────
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# ─── WorkManager ────────────────────────────────────────
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker { 
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# ─── Isar Database ──────────────────────────────────────
-keep class dev.isar.** { *; }
-keep class **.IsarCollection { *; }

# ─── Security (PointyCastle / Encrypt) ──────────────────
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**
-keep class pointycastle.** { *; }

# ─── Health Connect ─────────────────────────────────────
-keep class androidx.health.connect.** { *; }
-keep class androidx.health.platform.** { *; }

# ─── Dio / OkHttp ──────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# ─── JSON Serialization ────────────────────────────────
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ─── Rakshak AI Native Plugin ──────────────────────────
-keep class com.rakshak.ai.** { *; }

# ─── General Optimization ──────────────────────────────
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int d(...);
    public static int v(...);
    public static int i(...);
}
