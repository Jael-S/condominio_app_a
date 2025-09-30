import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class IAService {
  static Future<Map<String, dynamic>?> analyzeImage(File imageFile, String token) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/ia/analyze/');
      final request = http.MultipartRequest('POST', url);
      
      request.headers['Authorization'] = 'Token $token';
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
