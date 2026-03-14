import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../auth/auth_service.dart';
import '../config/app_config.dart';
import '../providers/branch_provider.dart';
import '../providers/locale_provider.dart';
import '../../features/cart/models/cart_item.dart';
import '../../features/menu/models/menu_item.dart';
import '../../features/menu/services/menu_service.dart';
import '../../features/orders/services/order_service.dart';
import '../../features/rooms/models/room.dart';
import '../../features/rooms/services/room_service.dart';

const _channel = MethodChannel('com.chillax.client/session_notification');

class _DrinkInfo {
  final int id;
  final String name;
  final MenuItem item;
  _DrinkInfo({required this.id, required this.name, required this.item});
}

/// Manages the persistent native notification shown during active sessions.
///
/// Architecture:
/// - Owns the full lifecycle: listens for session changes, shows/dismisses.
/// - Resolves favorite drinks directly from the API (no provider dependency).
/// - Action handler registered in constructor (no timing issues).
/// - Waiter/Controller actions handled natively via HTTP (no Flutter dependency).
/// - Drink actions forwarded to Dart via method channel.
class SessionNotificationService {
  final Ref _ref;
  Timer? _updateTimer;
  RoomSession? _activeSession;
  ProviderSubscription? _sessionSub;

  MenuItem? _drink1Item;
  MenuItem? _drink2Item;

  /// Cached drinks so we don't re-fetch on every periodic update
  List<_DrinkInfo>? _cachedDrinks;
  int? _cachedSessionId;

  SessionNotificationService(this._ref) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        _handleAction(call.arguments as String?);
      }
    });
  }

  /// Start listening for session changes. Call once after auth is ready.
  void startListening() {
    // Avoid duplicate subscriptions
    _sessionSub?.close();

    _sessionSub = _ref.listen<AsyncValue<List<RoomSession>>>(
      mySessionsProvider,
      (previous, next) => _onSessionsChanged(next),
      fireImmediately: true,
    );

    // Ensure fresh data — the provider's initial load may have failed
    // (e.g., 401 before auth was ready). This triggers a silent refresh
    // that updates the state and fires the listener above.
    _ref.read(mySessionsProvider.notifier).refresh();
  }

  /// Stop listening (e.g., on logout).
  void stopListening() {
    _sessionSub?.close();
    _sessionSub = null;
    dismissNotification();
  }

  void _onSessionsChanged(AsyncValue<List<RoomSession>> state) {
    state.whenData((sessions) {
      final active = sessions
          .where((s) => s.status == SessionStatus.active)
          .firstOrNull;

      if (active != null) {
        final lang = _ref.read(localeProvider).languageCode;
        _showForSession(active, lang);
      } else {
        dismissNotification();
      }
    });
  }

  /// Show or update the notification for an active session.
  Future<void> _showForSession(RoomSession session, String locale) async {
    _activeSession = session;

    // Save session info in parallel, don't block notification display
    _saveSessionInfo(session);

    final isArabic = locale == 'ar';
    final roomName = isArabic
        ? (session.roomName.ar ?? session.roomName.en)
        : session.roomName.en;

    // Session context for iOS Live Activity intents (background actions)
    final accessToken = await _ref.read(authServiceProvider.notifier).getAccessToken();
    final branchId = _ref.read(selectedBranchIdProvider);
    final sessionContext = <String, dynamic>{
      if (accessToken != null) 'accessToken': accessToken,
      'apiBaseUrl': AppConfig.notificationsApiUrl,
      'sessionId': session.id,
      'roomId': session.roomId,
      if (branchId != null) 'branchId': branchId,
      'roomNameEn': session.roomName.en,
      if (session.roomName.ar != null) 'roomNameAr': session.roomName.ar,
    };

    // Show notification immediately with just room name + timer
    final needsDrinks = _cachedSessionId != session.id ||
        (_cachedDrinks?.isEmpty ?? true);
    final drinks = _cachedDrinks ?? [];

    try {
      await _channel.invokeMethod('show', {
        'roomName': roomName,
        'duration': session.formattedDuration,
        'startTimeMs': session.actualStartTime?.millisecondsSinceEpoch,
        'locale': locale,
        if (drinks.isNotEmpty) 'drink1Id': drinks[0].id,
        if (drinks.isNotEmpty) 'drink1Name': drinks[0].name,
        if (drinks.length > 1) 'drink2Id': drinks[1].id,
        if (drinks.length > 1) 'drink2Name': drinks[1].name,
        ...sessionContext,
      });
    } catch (e) {
      debugPrint('Failed to show session notification: $e');
    }

    _startPeriodicUpdate(locale);

    // Resolve drinks in the background, then update notification with them
    if (needsDrinks) {
      _cachedDrinks = await _resolveFavoriteDrinks(locale);
      if (_cachedDrinks!.isNotEmpty) {
        _cachedSessionId = session.id;
      }
      final resolved = _cachedDrinks ?? [];
      _drink1Item = resolved.isNotEmpty ? resolved[0].item : null;
      _drink2Item = resolved.length > 1 ? resolved[1].item : null;

      // Pre-compute order payloads for iOS Live Activity intents
      final drink1Payload = resolved.isNotEmpty
          ? await _buildDrinkOrderPayload(resolved[0].item, session)
          : null;
      final drink2Payload = resolved.length > 1
          ? await _buildDrinkOrderPayload(resolved[1].item, session)
          : null;

      // Update notification with drink buttons
      if (resolved.isNotEmpty && _activeSession != null) {
        try {
          await _channel.invokeMethod('show', {
            'roomName': roomName,
            'duration': session.formattedDuration,
            'startTimeMs': session.actualStartTime?.millisecondsSinceEpoch,
            'locale': locale,
            'drink1Id': resolved[0].id,
            'drink1Name': resolved[0].name,
            if (resolved.length > 1) 'drink2Id': resolved[1].id,
            if (resolved.length > 1) 'drink2Name': resolved[1].name,
            ...sessionContext,
            'ordersApiUrl': AppConfig.ordersApiUrl,
            if (drink1Payload != null) 'drink1OrderPayload': drink1Payload,
            if (drink2Payload != null) 'drink2OrderPayload': drink2Payload,
          });
        } catch (_) {}
      }
    } else {
      _drink1Item = drinks.isNotEmpty ? drinks[0].item : null;
      _drink2Item = drinks.length > 1 ? drinks[1].item : null;
    }
  }

  Future<void> dismissNotification() async {
    _updateTimer?.cancel();
    _updateTimer = null;
    _activeSession = null;
    _drink1Item = null;
    _drink2Item = null;
    _cachedDrinks = null;
    _cachedSessionId = null;

    try {
      await _channel.invokeMethod('dismiss');
    } catch (e) {
      debugPrint('Failed to dismiss session notification: $e');
    }

    await _clearSessionInfo();
  }

  /// Resolve up to 2 drinks: favorites first, then popular items as fallback.
  Future<List<_DrinkInfo>> _resolveFavoriteDrinks(String locale) async {
    try {
      final menuRepo = _ref.read(menuRepositoryProvider);
      final isArabic = locale == 'ar';

      final items = await menuRepo.getMenuItems();
      if (items.isEmpty) return [];

      // Try favorites first
      final favoriteIds = await menuRepo.getFavorites();
      final drinks = <_DrinkInfo>[];

      for (final itemId in favoriteIds) {
        if (drinks.length >= 2) break;
        final item =
            items.where((i) => i.id == itemId && i.isAvailable).firstOrNull;
        if (item == null) continue;
        final name = isArabic ? (item.name.ar ?? item.name.en) : item.name.en;
        drinks.add(_DrinkInfo(id: item.id, name: name, item: item));
      }

      // Fall back to popular items if not enough favorites
      if (drinks.length < 2) {
        final popularItems = items
            .where((i) => i.isPopular && i.isAvailable &&
                !drinks.any((d) => d.id == i.id))
            .toList();
        for (final item in popularItems) {
          if (drinks.length >= 2) break;
          final name =
              isArabic ? (item.name.ar ?? item.name.en) : item.name.en;
          drinks.add(_DrinkInfo(id: item.id, name: name, item: item));
        }
      }

      return drinks;
    } catch (e) {
      debugPrint('Failed to resolve favorite drinks: $e');
      return [];
    }
  }

  void _startPeriodicUpdate(String locale) {
    _updateTimer?.cancel();
    // On iOS, periodic re-posts cause a banner flash (appear/disappear)
    // since iOS doesn't support persistent ongoing notifications.
    // Only Android needs periodic updates for the live timer.
    if (!kIsWeb && Platform.isIOS) return;
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_activeSession != null) {
        _showForSession(_activeSession!, locale);
      }
    });
  }

  // ── Action handling ──────────────────────────────────────────────────

  void _handleAction(String? actionId) async {
    if (actionId == null || _activeSession == null) return;

    if (actionId == 'order_drink_1' || actionId == 'order_drink_2') {
      await _handleDrinkOrder(actionId);
      return;
    }

    // Handle service requests (waiter, controller)
    final requestType = switch (actionId) {
      'call_waiter' => 1,
      'controller' => 2,
      _ => null,
    };
    if (requestType == null) return;

    try {
      final authService = _ref.read(authServiceProvider.notifier);
      final accessToken = await authService.getAccessToken();
      if (accessToken == null) return;

      final branchId = _ref.read(selectedBranchIdProvider);
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.notificationsApiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          if (branchId != null) 'X-Branch-Id': '$branchId',
        },
        queryParameters: {'api-version': '1.0'},
      ));

      await dio.post('service-requests', data: {
        'sessionId': _activeSession!.id,
        'roomId': _activeSession!.roomId,
        'roomName': _activeSession!.roomName.toJson(),
        'requestType': requestType,
      });
    } catch (e) {
      debugPrint('Failed to send service request: $e');
    }
  }

  Future<void> _handleDrinkOrder(String actionId) async {
    final item = actionId == 'order_drink_1' ? _drink1Item : _drink2Item;
    if (item == null) return;

    try {
      final authState = _ref.read(authServiceProvider);
      if (!authState.isAuthenticated) return;

      final menuRepo = _ref.read(menuRepositoryProvider);
      final preference = await menuRepo.getUserPreference(item.id);

      final orderRepo = _ref.read(orderRepositoryProvider);
      await orderRepo.submitFastOrder(
        item: item,
        userId: authState.userId ?? '',
        userName: authState.name ?? '',
        roomName: _activeSession!.roomName.toJson(),
        preference: preference,
      );

      _ref.read(ordersProvider.notifier).refresh();
    } catch (e) {
      debugPrint('Failed to submit drink order from notification: $e');
    }
  }

  /// Build a JSON string for the order API payload so iOS intents can send it directly.
  Future<String?> _buildDrinkOrderPayload(MenuItem item, RoomSession session) async {
    try {
      final authState = _ref.read(authServiceProvider);
      if (!authState.isAuthenticated) return null;

      final menuRepo = _ref.read(menuRepositoryProvider);
      final preference = await menuRepo.getUserPreference(item.id);

      // Replicate submitFastOrder logic to build the cart item
      final selectedOptions = <int, List<int>>{};

      for (final customization in item.customizations) {
        final defaults = customization.options
            .where((o) => o.isDefault)
            .map((o) => o.id)
            .toList();
        if (defaults.isNotEmpty) {
          selectedOptions[customization.id] = defaults;
        } else if (customization.isRequired && customization.options.isNotEmpty) {
          selectedOptions[customization.id] = [customization.options.first.id];
        }
      }

      if (preference != null) {
        final savedByCustomization = <int, List<int>>{};
        for (final option in preference.selectedOptions) {
          savedByCustomization
              .putIfAbsent(option.customizationId, () => [])
              .add(option.optionId);
        }
        for (final customization in item.customizations) {
          final savedOpts = savedByCustomization[customization.id];
          if (savedOpts != null && savedOpts.isNotEmpty) {
            final validOptions = savedOpts
                .where((optionId) =>
                    customization.options.any((o) => o.id == optionId))
                .toList();
            if (validOptions.isNotEmpty) {
              selectedOptions[customization.id] = validOptions;
            }
          }
        }
        for (final customization in item.customizations) {
          if (customization.isRequired) {
            final selected = selectedOptions[customization.id] ?? [];
            if (selected.isEmpty && customization.options.isNotEmpty) {
              selectedOptions[customization.id] = [customization.options.first.id];
            }
          }
        }
      }

      final selectedCustomizations = <SelectedCustomization>[];
      for (final customization in item.customizations) {
        final optionIds = selectedOptions[customization.id] ?? [];
        for (final optionId in optionIds) {
          final option = customization.options.firstWhere((o) => o.id == optionId);
          selectedCustomizations.add(SelectedCustomization(
            customizationId: customization.id,
            customizationName: customization.name,
            optionId: option.id,
            optionName: option.name,
            priceAdjustment: option.priceAdjustment,
          ));
        }
      }

      final cartItem = CartItem.fromMenuItem(item, customizations: selectedCustomizations);

      return jsonEncode({
        'userId': authState.userId ?? '',
        'userName': authState.name ?? '',
        'roomName': session.roomName.toJson(),
        'pointsToRedeem': 0,
        'loyaltyDiscount': 0,
        'items': [cartItem.toJson()],
      });
    } catch (e) {
      debugPrint('Failed to build drink order payload: $e');
      return null;
    }
  }

  // ── SharedPreferences for native fallback ────────────────────────────

  Future<void> _saveSessionInfo(RoomSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken =
        await _ref.read(authServiceProvider.notifier).getAccessToken();
    final branchId = _ref.read(selectedBranchIdProvider);

    await prefs.setInt('active_session_id', session.id);
    await prefs.setInt('active_session_room_id', session.roomId);
    await prefs.setString('active_session_room_name_en', session.roomName.en);
    if (session.roomName.ar != null) {
      await prefs.setString('active_session_room_name_ar', session.roomName.ar!);
    }
    if (accessToken != null) {
      await prefs.setString('active_session_access_token', accessToken);
    }
    if (branchId != null) {
      await prefs.setInt('active_session_branch_id', branchId);
    }
  }

  Future<void> _clearSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_session_id');
    await prefs.remove('active_session_room_id');
    await prefs.remove('active_session_room_name_en');
    await prefs.remove('active_session_room_name_ar');
    await prefs.remove('active_session_access_token');
    await prefs.remove('active_session_branch_id');
  }

  void dispose() {
    _sessionSub?.close();
    _updateTimer?.cancel();
    _updateTimer = null;
  }
}

final sessionNotificationServiceProvider =
    Provider<SessionNotificationService>((ref) {
  final service = SessionNotificationService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
