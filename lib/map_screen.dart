import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_geolocator/common/geolocation_denied_dialog.dart';
import 'package:maps_geolocator/determine_position_geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.onPressed});
  final void Function()? onPressed;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _sub;
  LatLng? _me;
  bool _followMe = true;
  final List<LatLng> _path = [];
  bool _openedSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTracking();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openedSettings) {
      _openedSettings = false;
      _startTracking();
    }
  }

  // диалог на подключение локации еще раз, вызов GeolocationDeniedDialog
  Future<void> showLocationDialog() async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (_) => const GeolocationDeniedDialog(),
    );

    if (openSettings == true) {
      _openedSettings = true;
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _startTracking() async {
    try {
      await _sub?.cancel();
      _sub = null;
      final pos = await determinePosition();
      final position = LatLng(pos.latitude, pos.longitude);
      setState(() => _me = position);
    } catch (e) {
      if (!mounted) return;
      // покажем диалог и дадим открыть настройки
      await showLocationDialog();
      return; // не запускаем stream
    }

    _sub = Geolocator.getPositionStream().listen(
      (pos) {
        final position = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _me = position;
          _path.add(position);
          if (_path.length > 2000) _path.removeAt(0);
        });

        if (_followMe) {
          _mapController.move(position, _mapController.camera.zoom);
        }
      },

      onError: (e, st) async {
        debugPrint('Position stream error: $e');
        await _sub?.cancel();
        _sub = null;
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _me ?? const LatLng(55.751244, 37.618423);
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialZoom: 16,
              initialCenter: center,

              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _followMe) {
                  setState(
                    () => _followMe = false,
                  ); // пользователь подвигал карту
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                // + many other options
              ),
              if (_path.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      strokeWidth: 4,
                      points: _path,
                      color: Colors.black45,
                    ),
                  ],
                ),
              if (_me != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _me!,
                      child: Icon(CupertinoIcons.location_solid, size: 34),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 200,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _followMe = true;
                  if (_me != null) {
                    _mapController.move(_me!, 16);
                  } else {
                    showLocationDialog();
                  }
                });
              },
              backgroundColor: Colors.white.withAlpha(230),
              elevation: 4,
              shape: CircleBorder(),
              child: Icon(CupertinoIcons.location_fill, color: Colors.black),
            ),
          ),
          DraggableScrollableSheet(
            snap: true,
            //стартовая высота 20%
            //стартово как будет выглядеть плашка
            initialChildSize: 0.08,
            minChildSize: 0.08,
            maxChildSize: 0.20,
            snapSizes: const [0.08, 0.20],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(10),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Мое местоположение:',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Широта: ${_me?.latitude ?? ''}'),
                          Text('Долгота: ${_me?.longitude ?? ''}'),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
