import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import 'dart:async';

class MapWidget extends StatefulWidget {
  final bool isTracking;
  final Function(double) onDistanceUpdated;

  const MapWidget({
    super.key,
    required this.isTracking,
    required this.onDistanceUpdated,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();
  LatLng? currentLocation;
  bool isLoading = true;
  String? errorMessage;
  double? heading;
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<Position>? _positionSubscription;
  List<LatLng> _trackingPoints = [];
  Position? _lastPosition;
  double _totalDistance = 0;
  Polyline? _trackingPolyline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
    _initCompass();
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isTracking && !oldWidget.isTracking) {
        _startPositionUpdates();
      } else if (!widget.isTracking && oldWidget.isTracking) {
        _stopPositionUpdates();
      }
    });
  }

  void _initCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      setState(() {
        heading = event.heading;
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        throw Exception('Permissão de localização negada');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });

      _mapController.move(currentLocation!, 16);
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao obter localização: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _startPositionUpdates() {
    _trackingPoints.clear();
    _totalDistance = 0;
    widget.onDistanceUpdated(0);

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      if (!widget.isTracking || !mounted) return;

      if (position.accuracy > 25) return;

      final newPoint = LatLng(position.latitude, position.longitude);
      final smoothedPoint = _smoothLocation(newPoint);

      currentLocation = smoothedPoint;
      _trackingPoints.add(smoothedPoint);

      if (_lastPosition != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distanceInMeters < 100) {
          _totalDistance += distanceInMeters;
          widget.onDistanceUpdated(_totalDistance);
        }
      }

      _lastPosition = position;

      if (mounted) {
        setState(() {
          _trackingPolyline = Polyline(
            points: _trackingPoints,
            color: AppColors.primary,
            strokeWidth: 4,
          );
        });
      }

      _mapController.move(smoothedPoint, _mapController.camera.zoom);
    });
  }

  void _stopPositionUpdates() {
    _positionSubscription?.cancel();
    _lastPosition = null;
  }

  /// Suavização da localização para evitar zigue-zague
  LatLng _smoothLocation(LatLng newPoint) {
    if (_trackingPoints.length < 2) return newPoint;

    final last = _trackingPoints[_trackingPoints.length - 1];
    final secondLast = _trackingPoints[_trackingPoints.length - 2];

    double smoothedLat = (newPoint.latitude + last.latitude + secondLast.latitude) / 3;
    double smoothedLng = (newPoint.longitude + last.longitude + secondLast.longitude) / 3;

    return LatLng(smoothedLat, smoothedLng);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: currentLocation ?? const LatLng(-15.7975, -47.8919),
            initialZoom: 16,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png?api_key=37d1c875-cf2c-4c5e-9e4d-47e4beae8aac',
              userAgentPackageName: 'com.example.mapa_stadia',
              subdomains: ['a', 'b', 'c'],
            ),
            if (_trackingPolyline != null)
              PolylineLayer(polylines: [_trackingPolyline!]),
            if (currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    width: 50,
                    height: 50,
                    point: currentLocation!,
                    child: Transform.rotate(
                      angle: (heading ?? 0) * (math.pi / 180) * -1,
                      child: Icon(
                        Icons.circle,
                        color: AppColors.mapMarker,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _getCurrentLocation,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),

        if (isLoading) const Center(child: CircularProgressIndicator()),

        if (errorMessage != null)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(child: Text(errorMessage!)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => errorMessage = null),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
