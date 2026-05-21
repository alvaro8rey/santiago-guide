import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:santiago_guide/models/poi.dart';
import 'package:santiago_guide/services/audio_service.dart';

class PoiDetailScreen extends StatefulWidget {
  final Poi poi;

  const PoiDetailScreen({Key? key, required this.poi}) : super(key: key);

  @override
  State<PoiDetailScreen> createState() => _PoiDetailScreenState();
}

class _PoiDetailScreenState extends State<PoiDetailScreen> {
  final AudioService _audioService = AudioService();
  bool _showDescription = true;

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra superior
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Encabezado
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.poi.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Botones de navegación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _NavigationButton(
                    label: 'Audio',
                    isActive: !_showDescription,
                    onTap: () => setState(() => _showDescription = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NavigationButton(
                    label: 'Descripción',
                    isActive: _showDescription,
                    onTap: () => setState(() => _showDescription = true),
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Expanded(
            child: _showDescription
                ? _DescriptionView(poi: widget.poi)
                : _AudioView(audioService: _audioService, poi: widget.poi),
          ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.amber : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.amber : Colors.grey[400],
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DescriptionView extends StatelessWidget {
  final Poi poi;

  const _DescriptionView({required this.poi});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          if (poi.imagenUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: poi.imagenUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Descripción
          Text(
            poi.descripcion,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AudioView extends StatefulWidget {
  final AudioService audioService;
  final Poi poi;

  const _AudioView({
    required this.audioService,
    required this.poi,
  });

  @override
  State<_AudioView> createState() => _AudioViewState();
}

class _AudioViewState extends State<_AudioView> {
  @override
  void initState() {
    super.initState();
    if (widget.poi.audioUrl.isNotEmpty) {
      widget.audioService.play(widget.poi.audioUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.poi.audioUrl.isEmpty) {
      return Center(
        child: Text(
          'No hay audio disponible',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono de audio
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.volume_up,
              size: 50,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 32),
          // Barra de progreso
          StreamBuilder<Duration>(
            stream: widget.audioService.positionStream,
            initialData: Duration.zero,
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration>(
                stream: widget.audioService.durationStream,
                initialData: Duration.zero,
                builder: (context, durationSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = durationSnapshot.data ?? Duration.zero;
                  final progress = duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0;

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: (value) {
                            widget.audioService.seek(
                              Duration(
                                milliseconds:
                                    (duration.inMilliseconds * value).toInt(),
                              ),
                            );
                          },
                          activeColor: Colors.amber,
                          inactiveColor: Colors.grey[700],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
          // Botones de control
          StreamBuilder<AudioState>(
            stream: widget.audioService.stateStream,
            initialData: AudioState.stopped,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data == AudioState.playing;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.amber),
                    onPressed: () => widget.audioService.stop(),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.grey[900],
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          widget.audioService.pause();
                        } else {
                          widget.audioService
                              .play(widget.poi.audioUrl);
                        }
                      },
                      iconSize: 32,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
