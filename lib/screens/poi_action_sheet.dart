import 'package:flutter/material.dart';
import 'package:santiago_guide/models/poi.dart';
import 'package:santiago_guide/services/audio_service.dart';

class PoiActionSheet extends StatefulWidget {
  final Poi poi;

  const PoiActionSheet({Key? key, required this.poi}) : super(key: key);

  @override
  State<PoiActionSheet> createState() => _PoiActionSheetState();
}

class _PoiActionSheetState extends State<PoiActionSheet> {
  final AudioService _audioService = AudioService();
  bool _showingAudio = true;
  AudioState _audioState = AudioState.stopped;

  @override
  void initState() {
    super.initState();
    if (widget.poi.audioUrl.isNotEmpty) {
      _audioService.play(widget.poi.audioUrl);
    }

    _audioService.stateStream.listen((state) {
      if (mounted) {
        setState(() => _audioState = state);
      }
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.poi.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (widget.poi.audioUrl.isNotEmpty)
                            Text(
                              '🎵 Audio disponible',
                              style: TextStyle(
                                color: Colors.amber[400],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.volume_up,
                        label: 'Audio',
                        isActive: _showingAudio &&
                            widget.poi.audioUrl.isNotEmpty,
                        enabled: widget.poi.audioUrl.isNotEmpty,
                        onTap: widget.poi.audioUrl.isNotEmpty
                            ? () =>
                                setState(() => _showingAudio = true)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.info_outline,
                        label: 'Info',
                        isActive: !_showingAudio,
                        onTap: () =>
                            setState(() => _showingAudio = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Content
              Expanded(
                child: _showingAudio && widget.poi.audioUrl.isNotEmpty
                    ? _AudioPlayer(
                        poi: widget.poi,
                        audioService: _audioService,
                        audioState: _audioState,
                      )
                    : _InfoPanel(poi: widget.poi),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? Colors.amber
                  : (enabled ? Colors.grey[400] : Colors.grey[600]),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.amber
                    : (enabled ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioPlayer extends StatefulWidget {
  final Poi poi;
  final AudioService audioService;
  final AudioState audioState;

  const _AudioPlayer({
    required this.poi,
    required this.audioService,
    required this.audioState,
  });

  @override
  State<_AudioPlayer> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<_AudioPlayer> {
  late Stream<Duration> positionStream;
  late Stream<Duration> durationStream;

  @override
  void initState() {
    super.initState();
    positionStream = widget.audioService.positionStream;
    durationStream = widget.audioService.durationStream;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Icono de audio grande
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withValues(alpha: 0.2),
              border: Border.all(color: Colors.amber, width: 2),
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
            stream: positionStream,
            initialData: Duration.zero,
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration>(
                stream: durationStream,
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
                                    (duration.inMilliseconds * value)
                                        .toInt(),
                              ),
                            );
                          },
                          activeColor: Colors.amber,
                          inactiveColor: Colors.grey[700],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.amber),
                onPressed: () => widget.audioService.stop(),
                iconSize: 28,
              ),
              const SizedBox(width: 24),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber,
                ),
                child: IconButton(
                  icon: Icon(
                    widget.audioState == AudioState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.grey[900],
                  ),
                  onPressed: () {
                    if (widget.audioState == AudioState.playing) {
                      widget.audioService.pause();
                    } else {
                      widget.audioService
                          .play(widget.poi.audioUrl);
                    }
                  },
                  iconSize: 28,
                ),
              ),
            ],
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

class _InfoPanel extends StatelessWidget {
  final Poi poi;

  const _InfoPanel({required this.poi});

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
              child: Image.network(
                poi.imagenUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[800],
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey),
                  );
                },
              ),
            ),
          if (poi.imagenUrl.isNotEmpty) const SizedBox(height: 16),
          // Descripción / Transcripción
          Text(
            'Información',
            style: TextStyle(
              color: Colors.amber[400],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
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
