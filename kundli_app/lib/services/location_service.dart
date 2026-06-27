import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class LocationService {
  Future<List<LocationModel>> search(String query) async {
    query = query.trim();

    if (query.length < 2) return [];

    try {
      final url = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': query,
          'format': 'jsonv2',
          'limit': '8',
          'addressdetails': '1',
          'featuretype': 'city,town,village,state',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'kundli-app/1.0',
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List;
      return data.map((e) => LocationModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}