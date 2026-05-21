import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:santiago_guide/models/poi.dart';
import 'package:santiago_guide/screens/poi_detail_screen.dart';
import 'package:santiago_guide/services/location_service.dart';
import 'package:santiago_guide/services/poi_service.dart';
import 'package:santiago_guide/widgets/poi_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  final PoiService _poiService = PoiService();

  List<Poi> _allPois = [];
  List<MapEntry<Poi, Offset>> _visiblePois = [];
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  double _currentBearing = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Inicializar servicio de ubicación
      await _locationService.initialize();

      // Cargar POIs
      _allPois = await _poiService.fetchPois();

      // Suscribirse a cambios de posición
      _locationService.positionStream.listen((position) {
        setState(() {
          _currentPosition = position;
        });
        _updateVisiblePois();
      });

      // Suscribirse a cambios de brújula
      _locationService.bearingStream.listen((bearing) {
        setState(() {
          _currentBearing = bearing;
        });
        _updateVisiblePois();
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _updateVisiblePois() {
    if (_currentPosition == null) return;

    final visiblePois = <MapEntry<Poi, Offset>>[];

    for (final poi in _allPois) {
      if (_locationService.isPoisInView(
        userLat: _currentPosition!.latitude,
        userLng: _currentPosition!.longitude,
        bearing: _currentBearing,
        poi: poi,
      )) {
        final screenSize = MediaQuery.of(context).size;
        final screenPosition = _locationService.calculateScreenPosition(
          userLat: _currentPosition!.latitude,
          userLng: _currentPosition!.longitude,
          bearing: _currentBearing,
          poi: poi,
          screenWidth: screenSize.width,
          screenHeight: screenSize.height * 0.7, // Parte de la pantalla ocupada por cámara
        );

        visiblePois.add(MapEntry(poi, screenPosition));
      }
    }

    setState(() {
      _visiblePois = visiblePois;
    });
  }

  void _showPoiDetail(Poi poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PoiDetailScreen(poi: poi),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _locationService.dispose();
        break;
      case AppLifecycleState.resumed:
        _initializeApp();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              const SizedBox(height: 16),
              Text(
                'Inicializando Santiago Guide',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _initializeApp();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  child: Text(
                    'Reintentar',
                    style: TextStyle(color: Colors.grey[900]),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo: cámara
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 2),
                      color: Colors.grey[900],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 60,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cámara en tiempo real',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Apunta hacia un punto de interés',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Overlay con marcadores
          PoiOverlay(
            visiblePois: _visiblePois,
            onPoiTap: _showPoiDetail,
          ),
          // Información superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Santiago Guide',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentPosition != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            'Brújula: ${_currentBearing.toStringAsFixed(1)}°',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Obteniendo ubicación...',
                        style: TextStyle(
                          color: Colors.orange[300],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Información inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puntos de interés visibles: ${_visiblePois.length}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total cargados: ${_allPois.length}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
