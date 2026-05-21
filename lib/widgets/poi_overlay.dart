import 'package:flutter/material.dart';
import 'package:santiago_guide/models/poi.dart';

class PoiOverlay extends StatelessWidget {
  final List<MapEntry<Poi, Offset>> visiblePois;
  final Function(Poi) onPoiTap;

  const PoiOverlay({
    Key? key,
    required this.visiblePois,
    required this.onPoiTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final entry in visiblePois)
          Positioned(
            left: (entry.value.dx - 20).clamp(0, double.infinity),
            top: (entry.value.dy - 20).clamp(0, double.infinity),
            child: GestureDetector(
              onTap: () => onPoiTap(entry.key),
              child: _PoiMarker(poi: entry.key),
            ),
          ),
      ],
    );
  }
}

class _PoiMarker extends StatefulWidget {
  final Poi poi;

  const _PoiMarker({required this.poi});

  @override
  State<_PoiMarker> createState() => _PoiMarkerState();
}

class _PoiMarkerState extends State<_PoiMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Anillo pulsante (efecto de onda)
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.3).animate(
            CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
          ),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.amber.withValues(
                  alpha: 1.0 - (_pulseController.value),
                ),
                width: 2,
              ),
            ),
          ),
        ),
        // Marcador principal
        Transform.translate(
          offset: const Offset(0, -45),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber[300]!,
                  Colors.amber[700]!,
                ],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.6),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.grey[900],
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Nombre del POI con mejor estilo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.amber,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.poi.nombre,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
