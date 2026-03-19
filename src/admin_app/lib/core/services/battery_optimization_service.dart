import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to check and prompt the admin to disable battery optimization
/// and grant full-screen intent permission.
///
/// On Android, aggressive battery optimization (Doze mode, OEM app killers)
/// can block FCM notifications even when they are high priority. The only
/// reliable fix is to have the user whitelist the app.
///
/// On Android 14+, full-screen intent permission must be manually granted
/// for the urgent order reminder to show over the lock screen.
class BatteryOptimizationService {
  static const _channel = MethodChannel('com.chillax.admin/permissions');
  static const _batteryDismissedKey = 'battery_optimization_prompt_dismissed';
  static const _fullScreenDismissedKey = 'full_screen_intent_prompt_dismissed';

  // --- Battery Optimization ---

  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;

    try {
      final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
      return true;
    }
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint('Error requesting battery optimization exemption: $e');
    }
  }

  static Future<bool> shouldShowBatteryPrompt() async {
    if (!Platform.isAndroid) return false;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_batteryDismissedKey) ?? false) return false;

    final isIgnoring = await isIgnoringBatteryOptimizations();
    return !isIgnoring;
  }

  static Future<void> dismissBatteryPromptPermanently() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_batteryDismissedKey, true);
  }

  // --- Full-Screen Intent (Android 14+) ---

  static Future<bool> canUseFullScreenIntent() async {
    if (!Platform.isAndroid) return true;

    try {
      final result = await _channel.invokeMethod<bool>('canUseFullScreenIntent');
      return result ?? true;
    } catch (e) {
      debugPrint('Error checking full-screen intent permission: $e');
      return true;
    }
  }

  static Future<void> requestFullScreenIntentPermission() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('requestFullScreenIntentPermission');
    } catch (e) {
      debugPrint('Error requesting full-screen intent permission: $e');
    }
  }

  static Future<bool> shouldShowFullScreenPrompt() async {
    if (!Platform.isAndroid) return false;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_fullScreenDismissedKey) ?? false) return false;

    final canUse = await canUseFullScreenIntent();
    return !canUse;
  }

  static Future<void> dismissFullScreenPromptPermanently() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fullScreenDismissedKey, true);
  }

  /// Convenience: check if any prompt needs to be shown.
  static Future<bool> shouldShowPrompt() async {
    return await shouldShowBatteryPrompt() || await shouldShowFullScreenPrompt();
  }
}
