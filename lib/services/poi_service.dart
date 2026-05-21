import 'package:santiago_guide/config/supabase_config.dart';
import 'package:santiago_guide/models/poi.dart';

class PoiService {
  static final PoiService _instance = PoiService._internal();

  factory PoiService() {
    return _instance;
  }

  PoiService._internal();

  List<Poi>? _cachedPois;
  DateTime? _lastFetch;
  final Duration _cacheDuration = const Duration(minutes: 30);

  Future<List<Poi>> fetchPois() async {
    // Devuelve cache si es reciente
    if (_cachedPois != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!).inMinutes <
          _cacheDuration.inMinutes) {
        return _cachedPois!;
      }
    }

    try {
      final response = await SupabaseConfig.client
          .from('pois')
          .select()
          .eq('activo', true);

      _cachedPois =
          (response as List).map((p) => Poi.fromJson(p)).toList();
      _lastFetch = DateTime.now();
      return _cachedPois!;
    } catch (e) {
      // Si falla la petición y hay cache anterior, devolverlo
      if (_cachedPois != null) {
        return _cachedPois!;
      }
      rethrow;
    }
  }

  void clearCache() {
    _cachedPois = null;
    _lastFetch = null;
  }
}
