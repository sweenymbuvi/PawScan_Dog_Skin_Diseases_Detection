import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FindVetsScreen extends StatefulWidget {
  const FindVetsScreen({super.key});

  @override
  State<FindVetsScreen> createState() => _FindVetsScreenState();
}

class _FindVetsScreenState extends State<FindVetsScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  Set<Marker> _markers = {};
  List<VetClinic> _vetClinics = [];
  VetClinic? _selectedVet;

  // Replace with your actual Google Maps API key
  final String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Request location permission
      final permission = await Permission.location.request();

      if (permission.isGranted) {
        // Get current position
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Search for nearby vets
        await _searchNearbyVets();

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showPermissionDialog();
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Could not get your location. Please try again.');
    }
  }

  Future<void> _searchNearbyVets() async {
    if (_currentPosition == null) return;

    try {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;

      print('Searching for vets near: $lat, $lng');

      // New Places API (Text Search)
      final url = 'https://places.googleapis.com/v1/places:searchText';

      final requestBody = json.encode({
        "textQuery": "veterinary clinic",
        "locationBias": {
          "circle": {
            "center": {"latitude": lat, "longitude": lng},
            "radius": 10000.0, // 10km
          },
        },
        "maxResultCount": 20,
        "rankPreference": "DISTANCE",
      });

      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.displayName,places.formattedAddress,places.location,places.rating,places.currentOpeningHours,places.id',
        },
        body: requestBody,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['places'] == null || (data['places'] as List).isEmpty) {
          print('No vets found nearby');
          _showErrorDialog(
            'No veterinary clinics found within 10km. Try expanding your search area.',
          );
          return;
        }

        final results = data['places'] as List;
        print('Found ${results.length} vet clinics');

        _vetClinics = results.map((place) {
          final location = place['location'];
          return VetClinic(
            name: place['displayName']?['text'] ?? 'Veterinary Clinic',
            address: place['formattedAddress'] ?? 'Address not available',
            lat: location['latitude'],
            lng: location['longitude'],
            rating: place['rating']?.toDouble() ?? 0.0,
            placeId: place['id'] ?? '',
            isOpen: place['currentOpeningHours']?['openNow'] ?? false,
          );
        }).toList();

        print('Processed ${_vetClinics.length} vet clinics');
        _createMarkers();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Found ${_vetClinics.length} veterinary clinics nearby',
              ),
              backgroundColor: const Color(0xFF5CD15A),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        print('API Error 400: ${data['error']?['message']}');
        _showErrorDialog(
          'API Error: ${data['error']?['message'] ?? "Bad request"}',
        );
      } else if (response.statusCode == 403) {
        print('API Error 403: Check if Places API (New) is enabled');
        _showErrorDialog(
          'API Error: Please enable Places API (New) in Google Cloud Console',
        );
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response: ${response.body}');
        _showErrorDialog(
          'Failed to search for vets. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error searching vets: $e');
      _showErrorDialog('Error searching for veterinary clinics: $e');
    }
  }

  void _createMarkers() {
    final markers = <Marker>{};

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add vet clinic markers
    for (var i = 0; i < _vetClinics.length; i++) {
      final vet = _vetClinics[i];
      markers.add(
        Marker(
          markerId: MarkerId('vet_$i'),
          position: LatLng(vet.lat, vet.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: vet.name, snippet: vet.address),
          onTap: () {
            setState(() {
              _selectedVet = vet;
            });
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to find nearby veterinary clinics. Please enable location access in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(VetClinic vet) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${vet.lat},${vet.lng}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: Colors.white,
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const Text(
                'Find Veterinary Clinics',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const Spacer(),
              if (!_isLoading && _currentPosition != null)
                IconButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    await _searchNearbyVets();
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  color: const Color(0xFF5CD15A),
                  tooltip: 'Refresh search',
                ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF5CD15A)),
                  SizedBox(height: 16),
                  Text(
                    'Finding nearby vets...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            )
          : _currentPosition == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 64,
                    color: Color(0xFF999999),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Location access denied',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please enable location to find nearby vets',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5CD15A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

                // Vet list at bottom
                if (_vetClinics.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Nearby Vets (${_vetClinics.length})',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D2D2D),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF5CD15A,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Within 5km',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF5CD15A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _vetClinics.length,
                              itemBuilder: (context, index) {
                                final vet = _vetClinics[index];
                                return _buildVetCard(vet);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Selected vet details
                if (_selectedVet != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 220,
                    child: _buildSelectedVetCard(_selectedVet!),
                  ),
              ],
            ),
    );
  }

  Widget _buildVetCard(VetClinic vet) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedVet = vet;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(vet.lat, vet.lng)),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vet.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D2D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vet.isOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5CD15A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Open',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (vet.rating > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFF0BB22),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vet.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  vet.address,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedVetCard(VetClinic vet) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    vet.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedVet = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (vet.rating > 0)
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Color(0xFFF0BB22)),
                  const SizedBox(width: 4),
                  Text(
                    vet.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (vet.isOpen)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5CD15A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Open Now',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF5CD15A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              vet.address,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openDirections(vet),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5CD15A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class VetClinic {
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double rating;
  final String placeId;
  final bool isOpen;

  VetClinic({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.placeId,
    required this.isOpen,
  });
}
