import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:exif/exif.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/capture_data.dart';
import 'verification_result_screen.dart'; // Next screen

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  Position? _currentPosition;
  bool _isLocating = false;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _startHighAccuracyLocation();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraPermissionStatus = status;
    });
    if (status.isGranted) {
      _initializeCamera();
    }
  }

  void _initializeCamera() {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    // Force a rebuild now that we have a future
    setState(() {});
  }


  // --- LOCATION & PERMISSIONS ---
  Future<void> _startHighAccuracyLocation() async {
    setState(() => _isLocating = true);

    // 1. Check permissions and services
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Handle denied state for user guidance
        setState(() => _isLocating = false);
        return;
      }
    }

    // 2. Define location settings for high accuracy
    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      forceLocationManager: true, // Use GPS provider
    );

    // 3. Get high-accuracy position with a timeout
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 10));
    } catch (e, s) {
      if (!mounted) return;

      if (kDebugMode) {
        // --- FALLBACK TO FAKE LOCATION IN DEBUG MODE ---
        developer.log(
          'Failed to get real location. Using fake location.',
          name: 'cropic.camera',
          level: 900, // WARNING
          error: e,
          stackTrace: s,
        );
        _currentPosition = Position(
            latitude: 37.422, // Googleplex latitude
            longitude: -122.084, // Googleplex longitude
            timestamp: DateTime.now(),
            accuracy: 0.0, // Using 0.0 accuracy as a marker for a fake location
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 1.0,
            headingAccuracy: 1.0);

        _showErrorDialog(
          "Debug Location Active",
          "Could not get a real GPS signal. A fake location has been set for testing.",
        );
      } else {
        // Handle location fetch errors in production
        _showErrorDialog(
          "Location Error",
          "Could not get device GPS. Ensure location services are on.",
        );
      }
    } finally {
       if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  // --- CAPTURE & VERIFICATION ---
  Future<void> _onCapture() async {
    if (_isLocating || _currentPosition == null) {
      _showErrorDialog(
        "Location Required",
        "Acquiring high-accuracy GPS. Please wait a moment.",
      );
      return;
    }

    if (_initializeControllerFuture == null) {
       _showErrorDialog("Camera Not Ready", "Please grant camera permission.");
       return;
    }

    try {
      await _initializeControllerFuture;
      final XFile photo = await _controller.takePicture();
      final File imageFile = File(photo.path);

      // 1. Extract EXIF data
      final Map<String, IfdTag> tags = await readExifFromBytes(
        await imageFile.readAsBytes(),
      );
      GpsInfo? exifGps = tags.containsKey('GPS GPSLatitude')
          ? extractGpsInfo(tags)
          : null;
      final DateTime? exifDT = tags.containsKey('Image DateTime')
          ? DateTime.tryParse(
              tags['Image DateTime']!.values
                  .toString()
                  .replaceFirst(':', '')
                  .replaceAll(':', '-')
                  .trim(),
            )
          : null;

      // --- DEBUG DATA INJECTION FOR EMULATOR ---
      if (exifGps == null && kDebugMode) {
        developer.log(
          'Photo is missing EXIF GPS data. Faking it with device location.',
          name: 'cropic.camera',
          level: 900, // WARNING
        );
        exifGps = GpsInfo(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude
        );
      }

      // 2. Create Capture Data Object
      final CaptureData data = CaptureData(
        photoFile: photo,
        captureLat: _currentPosition!.latitude,
        captureLon: _currentPosition!.longitude,
        exifLat: exifGps?.latitude,
        exifLon: exifGps?.longitude,
        exifTimestamp: exifDT,
      );

      // 3. Client-Side EXIF check (BYPASSED IN DEBUG MODE)
      if (!kDebugMode && !data.isExifDataPresent) {
          _showErrorDialog(
            "Location Missing in Photo",
            "The photo file is missing location data. Please enable 'Geotagging' or 'Camera Location' in your device camera settings and retry.",
          );
          await imageFile.delete(); // Clean up local file
          return;
      }

      if (mounted) {
        // 4. Navigate to the next screen for upload
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VerificationResultScreen(captureData: data),
          ),
        );
      }
    } catch (e, s) {
       if (!mounted) return;
        developer.log(
          'An error occurred during capture',
          name: 'cropic.camera',
          level: 1000, // SEVERE
          error: e,
          stackTrace: s,
        );
      _showErrorDialog(
        "Capture Failed",
        "An error occurred during capture. Check the debug console for details.",
      );
    }
  }

  // --- UI & Helpers ---
  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Minimal GPS extraction helper (needs more robust date/time handling for production)
  GpsInfo? extractGpsInfo(Map<String, IfdTag> tags) {
    // Simplified logic: production code needs robust conversion of Rational values
    // This is often complex; relying on server-side exifr is safer, but we need the client check
    // For now, we only check for the presence of the tags.
    // A fully robust implementation is verbose. We assume tags[key].values are present for the check.
    if (tags.containsKey('GPS GPSLatitude') &&
        tags.containsKey('GPS GPSLongitude')) {
      // Mock data extraction for demo purposes, assume location is present if tags are.
      return GpsInfo(latitude: 0.0, longitude: 0.0);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Farm Photo')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
  if (_cameraPermissionStatus.isGranted) {
    if (_initializeControllerFuture == null) {
      // This case should ideally not be hit if logic is correct, but as a fallback:
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: [
              CameraPreview(_controller),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isLocating
                          ? '🛰️ Getting high-accuracy GPS...'
                          : _currentPosition != null
                              ? _currentPosition!.accuracy == 0.0 // Check for fake location
                                  ? '✅ DEBUG GPS Locked (Fake Location)'
                                  : '✅ GPS Locked. Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m'
                              : '❌ Location Unavailable. Check settings.',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: FloatingActionButton(
                    onPressed: _onCapture,
                    child: const Icon(Icons.camera_alt, size: 36),
                  ),
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  } else {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Camera permission is required to continue."),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _requestCameraPermission,
            child: const Text("Grant Permission"),
          ),
        ],
      ),
    );
  }
}


  @override
  void dispose() {
    // Only dispose if the controller was initialized
    if (_initializeControllerFuture != null) {
       _controller.dispose();
    }
    super.dispose();
  }
}

class GpsInfo {
  final double latitude;
  final double longitude;
  GpsInfo({required this.latitude, required this.longitude});
}
