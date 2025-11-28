import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';

// Define the core green color used in the design
final Color _primaryGreen = Colors.green.shade700;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _startClaimFlow(BuildContext context) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No camera found.')));
        }
        return;
      }

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CameraScreen(camera: cameras.first),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error accessing camera: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Light background for contrast
      appBar: AppBar(
        automaticallyImplyLeading: false, // Hide back button on the main screen
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            // Profile Picture Placeholder (Mimicking image_7b6d4e.jpg)
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(
                'assets/profile_placeholder.png',
              ), // Add an image asset here
              backgroundColor: Colors.grey,
            ),
            const SizedBox(width: 12),
            // Greeting Text
            Text(
              'Good Morning, Alex',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Weather Card (Featured Green Style) ---
            _buildWeatherCard(),

            // --- 2. Your Fields Section ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                "Your Fields",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildFieldCard(
                    'Field A - Wheat',
                    'Status: Healthy',
                    'assets/wheat1.jpg',
                    Colors.green,
                  ),
                  _buildFieldCard(
                    'Field B - Corn',
                    'Needs Attention',
                    'assets/corn.jpg',
                    Colors.orange,
                  ),
                  // Add more field cards here
                ],
              ),
            ),

            // --- 3. Recent Activity Section ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            // Activity List items (Styled to look like the image)
            _buildActivityTile(
              icon: Icons.qr_code_scanner,
              color: _primaryGreen,
              title: 'Scan completed for Field A',
              subtitle: 'Today, 9:41 AM',
              trailingWidget: const Icon(
                Icons.keyboard_arrow_right,
                color: Colors.grey,
              ),
            ),
            _buildActivityTile(
              icon: Icons.check_circle_outline,
              color: _primaryGreen,
              title: 'New claim filed',
              subtitle: 'Yesterday, 3:20 PM',
              trailingWidget: const Icon(
                Icons.keyboard_arrow_right,
                color: Colors.grey,
              ),
            ),
            _buildActivityTile(
              icon: Icons.pest_control,
              color: Colors.red.shade700,
              title: 'Pest alert issued for Field B',
              subtitle: 'June 20, 11:00 AM',
              trailingWidget: Container(
                // Mimicking the circular camera button in the list
                decoration: BoxDecoration(
                  color: _primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _startClaimFlow(context),
                ),
              ),
            ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      // Floating button to start the claim/capture flow
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startClaimFlow(context),
        backgroundColor: _primaryGreen,
        child: const Icon(Icons.camera_alt, size: 28),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Essential for >3 items
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.spa), label: 'Fields'),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Claims',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 0,
        selectedItemColor: _primaryGreen,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25), // Updated from withOpacity
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather in Greenfield',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '28°C Sunny',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Humidity: 65% | Wind: 12 km/h',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              Icon(Icons.wb_sunny, size: 48, color: Colors.orange.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(
    String title,
    String status,
    String imagePath,
    Color statusColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder (Use AssetImage if you add images, otherwise use a placeholder)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: 100,
                color: Colors.grey.shade200, // Placeholder color
                child: Center(
                  child: Image.asset(
                    'assets/field_placeholder.png', // Placeholder image asset
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget trailingWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(25), // Updated from withOpacity
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(title),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
          trailing: trailingWidget,
        ),
      ),
    );
  }
}
