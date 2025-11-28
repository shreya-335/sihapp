import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import '../data/capture_data.dart';

// IMPORTANT: Use 10.0.2.2 for Android emulator to reach localhost on host machine
const String _baseUrl = 'http://10.0.2.2:3000/api';
const String _authToken = 'mock-user-jwt-token';

class ApiClient {
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_authToken',
  };

  // --- 1. /api/uploads/presign (STEP 1) ---
  Future<Map<String, dynamic>> presignUpload(CaptureData data) async {
    final file = File(data.photoFile.path);
    final response = await http.post(
      Uri.parse('$_baseUrl/uploads/presign'),
      headers: _headers,
      body: jsonEncode({
        "localUploadId": data.localUploadId,
        "filename": data.photoFile.name,
        "filesize": await file.length(),
        "captureTimestamp": data.captureTimestamp.toIso8601String(),
        "hasCaptureCoords": data
            .isExifDataPresent, // Should always be true here, or capture wouldn't happen
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get presigned URL: ${response.body}');
    }
  }

  // --- 2. Direct Upload to Cloudinary (STEP 2) ---
  Future<Map<String, dynamic>> uploadToCloudinary(
    XFile file,
    Map<String, dynamic> signedParams,
  ) async {
    final uploadUrl = signedParams['uploadUrl'] as String;
    final Map<String, dynamic> uploadFields = signedParams['uploadParams'];

    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

    // Add signed upload parameters
    uploadFields.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // Add file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Field name for file in Cloudinary direct upload
        file.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      // Cloudinary returns the public_id and URL on success
      return jsonDecode(response.body);
    } else {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }
  }

  // --- 3. /api/uploads/complete (STEP 3) ---
  Future<Map<String, dynamic>> completeUpload(
    CaptureData data,
    String publicId,
    String storageUrl,
  ) async {
    // Mocking upload location (audit data) - in production, you'd get a fresh GPS fix here.
    final uploadLat = data.captureLat + 0.0001;
    final uploadLon = data.captureLon + 0.0001;

    final response = await http.post(
      Uri.parse('$_baseUrl/uploads/complete'),
      headers: _headers,
      body: jsonEncode({
        "uploadId": data.uploadId,
        "publicId": publicId,
        "localUploadId": data.localUploadId,
        "captureLat": data.captureLat,
        "captureLon": data.captureLon,
        "captureTimestamp": data.captureTimestamp.toIso8601String(),
        "uploadLat": uploadLat,
        "uploadLon": uploadLon,
        "uploadTimestamp": DateTime.now().toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Handle server rejection (e.g., failed EXIF parsing)
      final body = jsonDecode(response.body);
      throw Exception(
        'Failed to complete upload: ${body['reason'] ?? response.statusCode}',
      );
    }
  }
}
