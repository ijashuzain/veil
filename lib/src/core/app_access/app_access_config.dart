import 'package:flutter/foundation.dart';

enum AppAccessStatus { allowed, maintenance, updateRequired }

class AppAccessConfig {
  const AppAccessConfig({
    this.maintenance = false,
    this.message = 'Veil is undergoing maintenance. Please try again shortly.',
    this.androidMinBuild = 0,
    this.iosMinBuild = 0,
    this.androidStoreUrl = '',
    this.iosStoreUrl = '',
  });

  final bool maintenance;
  final String message;
  final int androidMinBuild;
  final int iosMinBuild;
  final String androidStoreUrl;
  final String iosStoreUrl;

  factory AppAccessConfig.fromJson(Map<String, dynamic> json) {
    final android = json['android_min_build'];
    final ios = json['ios_min_build'];
    if (json['maintenance_enabled'] is! bool ||
        android is! int ||
        android < 0 ||
        ios is! int ||
        ios < 0) {
      throw const FormatException('Invalid app configuration');
    }
    return AppAccessConfig(
      maintenance: json['maintenance_enabled'] as bool,
      message:
          json['maintenance_message'] as String? ??
          const AppAccessConfig().message,
      androidMinBuild: android,
      iosMinBuild: ios,
      androidStoreUrl: json['android_store_url'] as String? ?? '',
      iosStoreUrl: json['ios_store_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'maintenance_enabled': maintenance,
    'maintenance_message': message,
    'android_min_build': androidMinBuild,
    'ios_min_build': iosMinBuild,
    'android_store_url': androidStoreUrl,
    'ios_store_url': iosStoreUrl,
  };

  Uri? storeUrl(TargetPlatform platform) {
    final url = Uri.tryParse(
      platform == TargetPlatform.android ? androidStoreUrl : iosStoreUrl,
    );
    if (url == null ||
        url.scheme != 'https' ||
        url.userInfo.isNotEmpty ||
        url.hasPort) {
      return null;
    }
    if (platform == TargetPlatform.android &&
        url.host == 'play.google.com' &&
        url.path == '/store/apps/details' &&
        (url.queryParameters['id'] ?? '').isNotEmpty) {
      return url;
    }
    if (platform == TargetPlatform.iOS &&
        url.host == 'apps.apple.com' &&
        url.path.contains('/app/')) {
      return url;
    }
    return null;
  }

  AppAccessStatus status({
    required TargetPlatform platform,
    required String build,
    bool web = false,
  }) {
    if (maintenance) return AppAccessStatus.maintenance;
    if (web) return AppAccessStatus.allowed;
    final minimum = switch (platform) {
      TargetPlatform.android => androidMinBuild,
      TargetPlatform.iOS => iosMinBuild,
      _ => 0,
    };
    final installed = int.tryParse(build);
    // Never strand users behind an invalid store link or unreadable build.
    return installed != null &&
            installed < minimum &&
            storeUrl(platform) != null
        ? AppAccessStatus.updateRequired
        : AppAccessStatus.allowed;
  }
}
