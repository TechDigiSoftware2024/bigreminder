import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../theme/super_admin_colors.dart';

class LocationPickerScreen extends StatefulWidget {
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultCenter = LatLng(20.5937, 78.9629);

  final _mapController = MapController();
  final _searchController = TextEditingController();

  LatLng? _selected;
  String? _address;
  bool _locating = false;
  bool _resolving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAddress?.trim();
    if (initial != null && initial.isNotEmpty) {
      _searchController.text = initial;
      _address = initial;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Turn on location services to use your current position.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to find you on the map.');
      }

      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      _moveTo(point);
      await _resolveAddress(point);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _resolving = true;
      _error = null;
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '1',
      });
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Could not search that address.');
      }

      final data = jsonDecode(response.body);
      if (data is! List || data.isEmpty) {
        throw Exception('No matching place found.');
      }

      final first = Map<String, dynamic>.from(data.first as Map);
      final lat = double.tryParse('${first['lat']}');
      final lon = double.tryParse('${first['lon']}');
      if (lat == null || lon == null) {
        throw Exception('No matching place found.');
      }

      final point = LatLng(lat, lon);
      _moveTo(point);
      final label = (first['display_name'] ?? query).toString();
      if (!mounted) return;
      setState(() => _address = label);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _resolveAddress(LatLng point) async {
    setState(() => _resolving = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'format': 'jsonv2',
      });
      final response = await http.get(uri, headers: _headers());
      String label =
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map && data['display_name'] != null) {
          label = data['display_name'].toString();
        }
      }
      if (!mounted) return;
      setState(() => _address = label);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _address =
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      });
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _moveTo(LatLng point) {
    setState(() => _selected = point);
    _mapController.move(point, 16);
  }

  Map<String, String> _headers() {
    return const {
      'User-Agent': 'techdigi.software.bigreminder',
      'Accept': 'application/json',
    };
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Scaffold(
      backgroundColor: SuperAdminColors.background,
      appBar: AppBar(
        backgroundColor: SuperAdminColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text('Pick address'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchAddress(),
                    decoration: InputDecoration(
                      hintText: 'Search address',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: SuperAdminColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: SuperAdminColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: SuperAdminColors.primaryDark,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _resolving ? null : _searchAddress,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: selected ?? _defaultCenter,
                initialZoom: selected == null ? 4.5 : 16,
                onTap: (_, point) {
                  setState(() => _selected = point);
                  _resolveAddress(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'techdigi.software.bigreminder',
                ),
                if (selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selected,
                        width: 42,
                        height: 42,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: SuperAdminColors.error,
                          size: 42,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: SuperAdminColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Text(
                    _address ?? 'Tap the map or search to choose an address.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SuperAdminColors.textPrimary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _locating ? null : _useCurrentLocation,
                        icon: _locating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded),
                        label: const Text('My location'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selected == null || _resolving
                              ? null
                              : () {
                                  final address = (_address ??
                                          _searchController.text)
                                      .trim();
                                  if (address.isEmpty) return;
                                  Navigator.pop(context, address);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SuperAdminColors.primaryDark,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: SuperAdminColors.grey100,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(_resolving ? 'Finding address...' : 'Use this address'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
