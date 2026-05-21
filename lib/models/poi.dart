class Poi {
  final String id;
  final String nombre;
  final String descripcion;
  final double lat;
  final double lng;
  final int radioActivacion;
  final String imagenUrl;
  final String audioUrl;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Poi({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.lat,
    required this.lng,
    required this.radioActivacion,
    required this.imagenUrl,
    required this.audioUrl,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    return Poi(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      radioActivacion: json['radio_activacion'] as int? ?? 30,
      imagenUrl: json['imagen_url'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'lat': lat,
      'lng': lng,
      'radio_activacion': radioActivacion,
      'imagen_url': imagenUrl,
      'audio_url': audioUrl,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
