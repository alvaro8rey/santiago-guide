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

class _PoiMarker extends StatelessWidget {
  final Poi poi;

  const _PoiMarker({required this.poi});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsación exterior
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Marcador principal
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(top: -44),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
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
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        // Nombre del POI
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.amber, width: 1),
          ),
          child: Text(
            poi.nombre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
