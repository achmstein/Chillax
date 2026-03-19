import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to check and prompt the admin to disable battery optimization.
///
/// On Android, aggressive battery optimization (Doze mode, OEM app killers)
/// can block FCM notifications even when they are high priority. The only
/// reliable fix is to have the user whitelist the app.
class BatteryOptimizationService {
  static const _channel = MethodChannel('com.chillax.admin/battery');
  static const _dismissedKey = 'battery_optimization_prompt_dismissed';

  /// Check if battery optimization is already disabled for this app.
  /// Returns true on iOS or if already whitelisted.
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;

    try {
      final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
      return true; // Assume OK if we can't check
    }
  }

  /// Open the system dialog to request battery optimization exemption.
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint('Error requesting battery optimization exemption: $e');
    }
  }

  /// Check if the user has permanently dismissed the prompt.
  static Future<bool> isPromptDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dismissedKey) ?? false;
  }

  /// Mark the prompt as permanently dismissed.
  static Future<void> dismissPromptPermanently() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }

  /// Returns true if we should show the prompt:
  /// - Android only
  /// - Battery optimization is NOT disabled
  /// - User hasn't permanently dismissed
  static Future<bool> shouldShowPrompt() async {
    if (!Platform.isAndroid) return false;

    final isDismissed = await isPromptDismissed();
    if (isDismissed) return false;

    final isIgnoring = await isIgnoringBatteryOptimizations();
    return !isIgnoring;
  }
}
