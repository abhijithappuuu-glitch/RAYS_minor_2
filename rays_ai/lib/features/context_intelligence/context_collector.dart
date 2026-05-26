import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';

/// Context Intelligence Collector
///
/// Passively gathers ambient context signals that contribute to the
/// ML stress model:
/// - Ambient light level (lux) — detects late-night phone usage in dark rooms
/// - Charging state — correlates with bedtime/wake patterns
/// - Device pickup/unlock frequency — via platform channel
///
/// All data is collected locally and never transmitted without encryption.
class ContextIntelligenceCollector {
  static const _usageChannel = MethodChannel('rakshak.ai/usage_stats');

  final Battery _battery = Battery();

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double _lastLux = -1;
  bool _isCharging = false;
  int _pickupCount = 0;

  // Motion thresholds for pickup detection
  static const double _pickupThreshold = 12.0; // m/s² — significant motion

  /// Initialize all passive collectors
  Future<void> initialize() async {
    await _initChargingState();
    _startAccelerometerListener();
  }

  /// Stop all collectors and release resources
  void dispose() {
    _accelSubscription?.cancel();
  }

  // ── Charging State ─────────────────────────────────────
  Future<void> _initChargingState() async {
    try {
      final state = await _battery.batteryState;
      _isCharging = state == BatteryState.charging ||
          state == BatteryState.full;

      _battery.onBatteryStateChanged.listen((state) {
        _isCharging = state == BatteryState.charging ||
            state == BatteryState.full;
      });
    } catch (_) {
      _isCharging = false;
    }
  }

  // ── Accelerometer (Pickup Detection) ──────────────────
  void _startAccelerometerListener() {
    _accelSubscription = accelerometerEventStream().listen((event) {
      final magnitude = _vectorMagnitude(event.x, event.y, event.z);
      // Detect significant motion (phone picked up from resting)
      if (magnitude > _pickupThreshold) {
        _pickupCount++;
      }
    });
  }

  double _vectorMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  // ── Ambient Light (via platform channel) ──────────────
  Future<double> getAmbientLux() async {
    try {
      final result = await _usageChannel.invokeMethod<double>('getAmbientLux');
      _lastLux = result ?? -1;
      return _lastLux;
    } catch (_) {
      return -1;
    }
  }

  // ── Combined Context Snapshot ─────────────────────────
  /// Returns a map of all context signals for the ML engine
  Future<Map<String, dynamic>> getContextSnapshot() async {
    final lux = await getAmbientLux();
    final hour = DateTime.now().hour;
    final isNightTime = hour >= 23 || hour < 6;

    return {
      'ambient_lux': lux,
      'is_charging': _isCharging,
      'pickup_count': _pickupCount,
      'is_night_time': isNightTime,
      'hour': hour,
      'is_dark_room': lux >= 0 && lux < 10,
      'battery_state': _isCharging ? 'charging' : 'discharging',
    };
  }

  /// Reset counters (call after each analysis cycle)
  void resetCounters() {
    _pickupCount = 0;
  }

  /// Get current charging state
  bool get isCharging => _isCharging;

  /// Get accumulated pickup count since last reset
  int get pickupCount => _pickupCount;
}
