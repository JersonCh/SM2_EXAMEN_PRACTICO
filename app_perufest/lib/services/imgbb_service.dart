import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ImgBBService {
  // Tu API Key de ImgBB (debes registrarte en https://api.imgbb.com/)
  static const String _apiKey = '79fefe21668969aa8a446cab366bc81a'; // Cambia esto por tu API key real
  static const String _baseUrl = 'https://api.imgbb.com/1/upload';

  // Método para subir imagen de perfil de usuario
  static Future<String?> subirImagenPerfil(File imagen, String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('Iniciando subida de imagen de perfil para usuario: $userId');
      }

      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      
      // Agregar archivo
      request.files.add(await http.MultipartFile.fromPath('image', imagen.path));
      request.fields['key'] = _apiKey;
      request.fields['name'] = 'perfil_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final imageUrl = jsonResponse['data']['url'] as String;
          
          if (kDebugMode) {
            debugPrint('Imagen de perfil subida exitosamente: $imageUrl');
          }
          
          return imageUrl;
        } else {
          throw Exception('Error del servidor: ${jsonResponse['error']['message']}');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al subir imagen de perfil: $e');
      }
      rethrow;
    }
  }

  // Método alternativo usando FormData (más eficiente para archivos grandes)
  static Future<String?> subirImagenFormData(File imagen) async {
    try {
      if (kDebugMode) {
        debugPrint('Iniciando subida de imagen con FormData...');
      }

      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      
      // Agregar archivo
      request.files.add(await http.MultipartFile.fromPath('image', imagen.path));
      request.fields['key'] = _apiKey;
      request.fields['name'] = 'evento_${DateTime.now().millisecondsSinceEpoch}';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final imageUrl = jsonResponse['data']['url'] as String;
          
          if (kDebugMode) {
            debugPrint('Imagen subida exitosamente: $imageUrl');
          }
          
          return imageUrl;
        } else {
          throw Exception('Error del servidor: ${jsonResponse['error']['message']}');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al subir imagen: $e');
      }
      rethrow;
    }
  }
}