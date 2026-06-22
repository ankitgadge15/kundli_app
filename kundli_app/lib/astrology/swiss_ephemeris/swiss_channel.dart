import 'package:flutter/services.dart';

class SwissChannel {
  static const MethodChannel _channel =
      MethodChannel('kundli/swiss_ephemeris');

  static Future<Map<dynamic, dynamic>> calculate({
    required String date,
    required String time,
    required double latitude,
    required double longitude,
  }) async {
    final result = await _channel.invokeMethod(
      'calculateKundli',
      {
        'date': date,
        'time': time,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return result;
  }
}