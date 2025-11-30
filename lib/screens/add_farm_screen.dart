
// lib/screens/add_farm_screen.dart

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/farm_model.dart';
import '../services/farm_service.dart';

// Assuming you have a way to get the current access token
const String mockAccessToken = "MOCK_JWT_TOKEN"; 

class AddFarmScreen extends StatefulWidget {
  // Pass the user's access token to the screen
  final String accessToken;
  // Optional callback to be executed when the process is complete (saved or skipped)
  final VoidCallback? onComplete; 
  
  const AddFarmScreen({super.key, this.accessToken = mockAccessToken, this.onComplete});

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final List<LatLng> _polygonPoints = [];
  final MapController _mapController = MapController();

  bool _isLoading = false;
  LatLng _initialCenter = const LatLng(20.5937, 78.9629); // Default to India center

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Request location permission and get current location for map center
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, continue with default center
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, continue with default center
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _initialCenter = LatLng(position.latitude, position.longitude);
        _mapController.move(_initialCenter, 15.0); // Zoom in on current location
      });
    } catch (e) {
      log("Could not get location: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latLng) {
    if (_polygonPoints.length < 10) { // Limit points for simplicity/performance
      setState(() {
        _polygonPoints.add(latLng);
      });
    } else {
      _showSnackbar("Maximum 10 points reached for the boundary.");
    }
  }

  void _clearBoundary() {
    setState(() {
      _polygonPoints.clear();
    });
  }
  
  void _onSkip() {
    // Optionally log this skip action
    log("User skipped adding farm during onboarding.");
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
       if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _submitFarm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_polygonPoints.length < 3) {
      _showSnackbar("Farm boundary must have at least 3 points (a triangle).");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final boundary = FarmBoundary.fromLatLng(_polygonPoints);
      final request = CreateFarmRequest(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        boundary: boundary,
      );

      final farmService = FarmService(widget.accessToken);
      await farmService.createFarm(request);

      _showSnackbar("Farm '${request.name}' created successfully!");
      
      // Call the completion callback to signal moving to the next onboarding step or main screen
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
         if (mounted) {
          Navigator.of(context).pop();
        }
      }

    } catch (e) {
      _showSnackbar("Error submitting farm: ${e.toString()}", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the color of the polygon line (blue for open, green for closed/ready)
    final color = _polygonPoints.length >= 3 ? Colors.green : Colors.blue;
    
    // The polygon for flutter_map requires the list of LatLngs directly.
    final List<LatLng> polygonToDraw = _polygonPoints.length >= 3 
        ? [..._polygonPoints, _polygonPoints.first] // Close the polygon visually
        : _polygonPoints;

    // Check if the form is ready to be submitted
    final isSubmitReady = _polygonPoints.length >= 3 && _nameController.text.isNotEmpty && _addressController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Farm"),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        // Adding a skip button for better onboarding flow control
        actions: [
          TextButton(
            onPressed: _onSkip,
            child: const Text(
              'Skip',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Farm Details Form
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Farm Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a name.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address/Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an address or description.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Map Instructions
              Text(
                'Draw Farm Boundary: Tap on the map to mark the corners (vertices) of your farm.',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              
              // Map View
              SizedBox(
                height: 400, // Fixed height for the map
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _initialCenter,
                        initialZoom: 15.0,
                        onTap: _handleMapTap,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          // Using a standard OpenStreetMap tile layer. 
                          // If you have a true satellite tile URL (e.g., from Mapbox, etc.), replace it here.
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', 
                          userAgentPackageName: 'com.example.myapp',
                          // Add other options here if using a satellite provider (e.g., attribution, API key parameter)
                        ),
                        
                        // Polygon Layer to show the farm boundary
                        if (polygonToDraw.isNotEmpty)
                          PolygonLayer(
                            polygons: [
                              Polygon(
                                points: polygonToDraw,
                                color: color.withAlpha(128),
                                borderColor: color,
                                borderStrokeWidth: 2,
                                isFilled: true,
                              ),
                            ],
                          ),

                        // Marker Layer to show the individual tap points
                        if (_polygonPoints.isNotEmpty)
                          MarkerLayer(
                            markers: _polygonPoints.map((point) {
                              return Marker(
                                width: 30.0,
                                height: 30.0,
                                point: point,
                                child: Icon(
                                  Icons.circle,
                                  color: Colors.red.shade700,
                                  size: 10,
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _clearBoundary,
                    icon: const Icon(Icons.clear, color: Colors.red),
                    label: const Text('Clear Boundary', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isLoading || !isSubmitReady ? null : _submitFarm,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Farm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
