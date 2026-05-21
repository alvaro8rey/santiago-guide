import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:santiago_guide/models/poi.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  late StreamController<Position> _positionController;
  late StreamController<double> _bearingController;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _positionController = StreamController<Position>.broadcast();
    _bearingController = StreamController<double>.broadcast();

    // Solicitar permisos de ubicación
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado');
    }

    // Stream de GPS
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen(_positionController.add);

    // Stream de brújula
    _compassSubscription = FlutterCompass.events?.listen(
      (CompassEvent event) {
        if (event.heading != null) {
          _bearingController.add(event.heading!);
        }
      },
    );

    _isInitialized = true;
  }

  Stream<Position> get positionStream => _positionController.stream;
  Stream<double> get bearingStream => _bearingController.stream;

  /// Distancia entre dos puntos GPS en metros
  static double haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371000; // radio terrestre en metros
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Bearing (ángulo) entre dos puntos GPS en grados (0-360)
  static double calculateBearing(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLng = _toRad(lng2 - lng1);
    final y = sin(dLng) * cos(_toRad(lat2));
    final x = cos(_toRad(lat1)) * sin(_toRad(lat2)) -
        sin(_toRad(lat1)) * cos(_toRad(lat2)) * cos(dLng);
    final bearing = atan2(y, x);
    return (_toDeg(bearing) + 360) % 360;
  }

  /// Determina si el POI está dentro del campo visual de la cámara
  bool isPoisInView({
    required double userLat,
    required double userLng,
    required double bearing,
    required Poi poi,
  }) {
    final distance = haversineDistance(userLat, userLng, poi.lat, poi.lng);

    // Fuera del radio de activación
    if (distance > poi.radioActivacion) {
      return false;
    }

    // Calcular ángulo al POI
    final poiBearing = calculateBearing(userLat, userLng, poi.lat, poi.lng);

    // Campo visual aproximado: 65 grados (±32.5 grados desde el centro)
    const fov = 65.0;
    final halfFov = fov / 2;

    // Ángulo relativo al bearing actual
    var angleDiff = (poiBearing - bearing).abs();
    if (angleDiff > 180) {
      angleDiff = 360 - angleDiff;
    }

    return angleDiff <= halfFov;
  }

  /// Calcula la posición 2D en pantalla del POI
  Offset calculateScreenPosition({
    required double userLat,
    required double userLng,
    required double bearing,
    required Poi poi,
    required double screenWidth,
    required double screenHeight,
  }) {
    const fov = 65.0;
    const fovRad = fov * pi / 180;

    final poiBearing = calculateBearing(userLat, userLng, poi.lat, poi.lng);
    var angleDiff = poiBearing - bearing;

    // Normalizar ángulo a -180 a 180
    while (angleDiff > 180) angleDiff -= 360;
    while (angleDiff < -180) angleDiff += 360;

    // Convertir ángulo a radianes
    final angleRad = angleDiff * pi / 180;

    // Proyectar a coordenada X en pantalla (-1 a 1, luego a píxeles)
    final normalizedX = tan(angleRad) / tan(fovRad / 2);
    final screenX = (screenWidth / 2) * (1 + normalizedX);

    // Y siempre en el centro verticalmente (simplificado)
    const screenY = 0.5; // Centro vertical

    return Offset(screenX, screenHeight * screenY);
  }

  static double _toRad(double deg) => deg * pi / 180;
  static double _toDeg(double rad) => rad * 180 / pi;

  void dispose() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _positionController.close();
    _bearingController.close();
  }
}
