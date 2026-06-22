import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class LocationService {
  Future<List<LocationModel>> search(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$query'
      '&countrycodes=in'
      '&format=jsonv2'
      '&limit=10',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'kundli-app'},
    );

    final data = jsonDecode(response.body);

    return (data as List)
        .map((e) => LocationModel.fromJson(e))
        .toList();
  }
}