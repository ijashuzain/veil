import 'package:flutter/services.dart';

class PlayerPlatform {
  static const channel = MethodChannel('veil/player');
  static Future<double> brightness() async {
    try {
      return await channel.invokeMethod<double>('getBrightness') ?? .5;
    } on MissingPluginException {
      return .5;
    }
  }

  static Future<void> setBrightness(double value) async {
    try {
      await channel.invokeMethod<void>('setBrightness', value.clamp(.02, 1.0));
    } on MissingPluginException {
      /* Unsupported platforms retain current brightness. */
    }
  }

  static Future<void> restoreBrightness() async {
    try {
      await channel.invokeMethod<void>('restoreBrightness');
    } on MissingPluginException {
      /* No platform override to restore. */
    }
  }

  static Future<Map<String, dynamic>?> fullscreen({
    required String url,
    required Map<String, String> headers,
    required int position,
    required bool playing,
    required double volume,
    String format = 'hls',
  }) async {
    final result = await channel
        .invokeMapMethod<String, dynamic>('fullscreen', {
          'url': url,
          'headers': headers,
          'position': position,
          'playing': playing,
          'volume': volume,
          'format': format,
        });
    return result;
  }
}
