import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:santiago_guide/models/poi.dart';
import 'package:santiago_guide/screens/poi_action_sheet.dart';
import 'package:santiago_guide/services/camera_service.dart';
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
  final CameraService _cameraService = CameraService();

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
      // Inicializar cámara
      await _cameraService.initialize();

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
      builder: (context) => PoiActionSheet(poi: poi),
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
    _cameraService.dispose();
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
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo: cámara (fullscreen)
            if (_cameraService.isInitialized)
              CameraPreview(_cameraService.controller)
            else
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
                        'Inicializando cámara...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
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
          // Información superior (simplificada)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Santiago Guide',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentPosition != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.green,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'GPS OK',
                              style: TextStyle(
                                color: Colors.green[300],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange[300]!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Información inferior (minimalista)
          if (_visiblePois.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_visiblePois.length} punto${_visiblePois.length == 1 ? '' : 's'} disponible${_visiblePois.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
