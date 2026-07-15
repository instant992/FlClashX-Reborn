import 'dart:convert';
import 'dart:io';

import 'package:flclashx/l10n/l10n.dart';
import 'package:flclashx/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionNotificationService {
  static const String _prefsKeyPrefix = 'subscription_notified_';
  static const List<int> notificationDays = [3, 2, 1, 0, -1];

  static Future<void> checkAndNotify(
    Profile profile,
    AppLocalizations l,
  ) async {
    if (!Platform.isAndroid) return;
    final subscriptionInfo = profile.subscriptionInfo;
    if (subscriptionInfo == null) return;
    final expire = subscriptionInfo.expire;
    if (expire == 0) return;

    final expireDate = DateTime.fromMillisecondsSinceEpoch(expire * 1000);
    final now = DateTime.now();
    final isExpired = expireDate.isBefore(now);
    final daysUntilExpire = expireDate.difference(now).inDays;

    final int notificationThreshold;
    if (isExpired) {
      notificationThreshold = -1;
    } else if (daysUntilExpire == 0) {
      notificationThreshold = 0;
    } else {
      notificationThreshold = daysUntilExpire;
    }

    if (notificationDays.contains(notificationThreshold)) {
      await _showNotificationIfNeeded(profile, notificationThreshold, l);
    }
  }

  static Future<void> _showNotificationIfNeeded(
    Profile profile,
    int notificationThreshold,
    AppLocalizations l,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getPrefsKey(profile.id, notificationThreshold);
    final lastNotifiedExpire = prefs.getInt(key);
    final currentExpire = profile.subscriptionInfo?.expire ?? 0;
    if (lastNotifiedExpire == currentExpire) return;

    final supportUrl = profile.providerHeaders['support-url'] ?? '';
    String title = profile.label;
    final svc = profile.providerHeaders['flclashx-servicename'];
    if (svc != null && svc.isNotEmpty) {
      try {
        final normalized = base64.normalize(svc);
        title = utf8.decode(base64.decode(normalized)).trim();
      } catch (_) {
        title = svc.trim();
      }
    }

    final String message;
    if (notificationThreshold < 0) {
      message = l.subscriptionExpired;
    } else if (notificationThreshold == 0) {
      message = l.subscriptionExpiresToday;
    } else {
      message = l.subscriptionExpiresInDays(notificationThreshold.toString());
    }

    await _sendNotification(
      title: title,
      message: message,
      actionLabel: supportUrl.isNotEmpty ? l.renew : '',
      actionUrl: supportUrl,
    );
    await prefs.setInt(key, currentExpire);
  }

  static Future<void> _sendNotification({
    required String title,
    required String message,
    required String actionLabel,
    required String actionUrl,
  }) async {
    // TODO(Phase 6): wire to Android native notification channel via the
    // AIDL service plugin once the Android native side is ported.
  }

  static String _getPrefsKey(int profileId, int days) =>
      '$_prefsKeyPrefix${profileId}_${days}d';

  static Future<void> resetNotifications(int profileId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final days in notificationDays) {
      await prefs.remove(_getPrefsKey(profileId, days));
    }
  }
}
