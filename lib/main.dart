import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // We start here

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Note: Camera initialization (availableCameras()) is moved to the HomeScreen's flow.
  runApp(const CameraApp());
}

class CameraApp extends StatelessWidget {
  const CameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Claim App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        // Define a consistent look for input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2.0),
          ),
        ),
      ),
      home: const HomeScreen(), // Start at the dashboard
    );
  }
}
