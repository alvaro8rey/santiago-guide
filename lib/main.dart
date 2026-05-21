import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:santiago_guide/config/supabase_config.dart';
import 'package:santiago_guide/screens/camera_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Santiago Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      home: const PermissionScreen(),
      routes: {
        '/camera': (context) => const CameraScreen(),
        '/permissions': (context) => const PermissionScreen(),
      },
    );
  }
}

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _cameraGranted = false;
  bool _locationGranted = false;
  bool _checkingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _checkingPermissions = true);

    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;

    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _locationGranted = locationStatus.isGranted;
      _checkingPermissions = false;
    });

    if (_cameraGranted && _locationGranted) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/camera');
      }
    }
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final locationStatus = await Permission.location.request();

    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _locationGranted = locationStatus.isGranted;
    });

    if (_cameraGranted && _locationGranted) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/camera');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermissions) {
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
                'Verificando permisos...',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                size: 64,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              const Text(
                'Santiago Guide',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Descubre Santiago con realidad aumentada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              if (!_cameraGranted)
                _PermissionCard(
                  icon: Icons.videocam,
                  title: 'Cámara',
                  description: 'Necesitamos acceso a tu cámara para AR',
                  granted: _cameraGranted,
                )
              else
                _PermissionCard(
                  icon: Icons.videocam,
                  title: 'Cámara',
                  description: 'Permiso concedido ✓',
                  granted: true,
                ),
              const SizedBox(height: 16),
              if (!_locationGranted)
                _PermissionCard(
                  icon: Icons.gps_fixed,
                  title: 'Ubicación',
                  description: 'Necesitamos tu ubicación para los POIs',
                  granted: _locationGranted,
                )
              else
                _PermissionCard(
                  icon: Icons.gps_fixed,
                  title: 'Ubicación',
                  description: 'Permiso concedido ✓',
                  granted: true,
                ),
              const SizedBox(height: 40),
              if (!_cameraGranted || !_locationGranted)
                ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Conceder Permisos',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed('/camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Comenzar',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool granted;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: granted ? Colors.green.withValues(alpha: 0.1) : Colors.grey[800],
        border: Border.all(
          color: granted ? Colors.green : Colors.grey[700]!,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: granted ? Colors.green : Colors.grey[500],
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (granted)
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }
}