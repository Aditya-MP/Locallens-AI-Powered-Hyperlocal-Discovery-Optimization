import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  static const String osrmUrl = 'http://router.project-osrm.org/route/v1/driving';
  
  static Future<List<LatLng>> getRoutePolyline(double fromLat, double fromLng, double toLat, double toLng) async {
    final url = '$osrmUrl/$fromLng,$fromLat;$toLng,$toLat?overview=full&geometries=geojson';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
      return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
    }
    return [];
  }
}