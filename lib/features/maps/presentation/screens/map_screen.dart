import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../widgets/map_widget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double _bpm = 120;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isTracking = false;
  Timer? _metronomeTimer;
  Timer? _trackingTimer;
  int _totalSeconds = 0;
  double _totalDistance = 0;
  bool _showResetButton = false; // Novo estado para controlar a visibilidade do botão reset

  @override
  void dispose() {
    _metronomeTimer?.cancel();
    _trackingTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startMetronome() {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
    });

    final interval = (60 / _bpm * 1000).round();
    _metronomeTimer = Timer.periodic(Duration(milliseconds: interval), (
      timer,
    ) async {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/metronome.mp3'));
    });
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _startTracking() {
    if (_isTracking) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isTracking = true;
        _showResetButton = false; // Esconde o botão reset quando começa novo tracking
        _totalSeconds = 0;
        _totalDistance = 0;
      });

      _trackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _totalSeconds++;
        });
      });
    });
  }

  void _stopTracking() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackingTimer?.cancel();
      setState(() {
        _isTracking = false;
        _showResetButton = true; // Mostra o botão reset quando para o tracking
      });
    });
  }

  void _resetTracking() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Resetar Valores"),
          content: const Text("Deseja resetar os valores da sua corrida?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _totalSeconds = 0;
                  _totalDistance = 0;
                  _showResetButton = false;
                });
                Navigator.of(context).pop();
              },
              child: const Text("Resetar"),
            ),
          ],
        );
      },
    );
  }

  void _updateDistance(double newDistance) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _totalDistance = newDistance;
        });
      });
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 400,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MapWidget(
                    isTracking: _isTracking,
                    onDistanceUpdated: _updateDistance,
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Text(
                      _isTracking ? 'Tracking...' : 'Map Area',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Route Stats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('Total Time'),
                              const SizedBox(height: 5),
                              Text(
                                _formatTime(_totalSeconds),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Total Distance'),
                              const SizedBox(height: 5),
                              Text(
                                '${_totalDistance.toStringAsFixed(0)} m',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isTracking
                                ? () => WidgetsBinding.instance
                                      .addPostFrameCallback((_) => _stopTracking())
                                : () =>
                                      WidgetsBinding.instance.addPostFrameCallback(
                                        (_) => _startTracking(),
                                      ),
                            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                            label: Text(_isTracking ? 'Stop' : 'Play'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                          if (_showResetButton) // Mostra o botão reset apenas quando _showResetButton for true
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: ElevatedButton.icon(
                                onPressed: _resetTracking,
                                icon: const Icon(Icons.restart_alt),
                                label: const Text('Reset'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audio Pacer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_isPlaying) {
                                _stopMetronome();
                              } else {
                                _startMetronome();
                              }
                            },
                            icon: Icon(_isPlaying ? Icons.stop : Icons.hearing),
                            label: Text(_isPlaying ? 'Stop' : 'Start'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text("Pace: ${_bpm.toInt()} BPM"),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Slider(
                        value: _bpm,
                        min: 60,
                        max: 200,
                        divisions: 28,
                        label: '${_bpm.toInt()} BPM',
                        onChanged: (value) {
                          setState(() {
                            _bpm = value;
                          });

                          if (_isPlaying) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _stopMetronome();
                              _startMetronome();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}