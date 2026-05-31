import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tweet.dart';
import '../models/tweet_response.dart';
import '../repositories/tweet_repository.dart';
import 'auth_service.dart';

class TweetService implements ITweetRepository {
  static final TweetService _instance = TweetService._internal();

  // URL de tu Backend en Render
  final String baseUrl = 'https://flores-api.onrender.com/api';
  //final String baseUrl = 'http://localhost:8080/api';
  late http.Client _httpClient;
  late AuthService _authService;

  TweetService._internal() {
    _httpClient = http.Client();
    _authService = AuthService();
  }

  factory TweetService() => _instance;

  static TweetService getInstance() => _instance;

  Map<String, String> _getHeaders() {
    final token = _authService.getToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  Future<List<Tweet>> fetchTweets() async {
    try {
      await _authService.init();
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/tweets/all'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return _parseGetTweetsResponse(response.body);
      } else {
        throw Exception('Error al cargar Flores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  @override
  Future<Tweet> createTweet(String content, {String? imageBase64}) async {
    try {
      if (content.isEmpty) throw Exception('El contenido no puede estar vacío');

      await _authService.init();

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/tweets/create'),
        headers: _getHeaders(),
        body: jsonEncode({
          'tweet': content,
          'image': imageBase64,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseTweetResponse(response.body);
      } else {
        throw Exception('Error al crear Flor: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en la creación: $e');
    }
  }

  @override
  Future<void> deleteTweet(int id) async {
    try {
      await _authService.init();
      final response = await _httpClient.delete(
        Uri.parse('$baseUrl/tweets/$id'),
        headers: _getHeaders(),
      );
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('No se pudo borrar la Flor');
      }
    } catch (e) {
      throw Exception('Error al eliminar: $e');
    }
  }

  // --- NUEVA LÓGICA DE REACCIÓN (LIKE / SHARE) ---
  // Esta función hace el "Toggle" (dar/quitar) automáticamente
  Future<void> reactToFlor(int id, String type) async {
    try {
      await _authService.init();
      // Ejemplo: /api/tweets/10/react?type=LIKE
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/tweets/$id/react?type=$type'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al procesar reaccion: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falla de red al reaccionar: $e');
    }
  }

  // --- NUEVA LÓGICA DE COMENTARIOS ---
  Future<void> addComment(int id, String text) async {
    try {
      await _authService.init();
      // Ruta: /api/comments/tweet/10
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/comments/tweet/$id'),
        headers: _getHeaders(),
        body: text, // Enviamos el texto directamente como String
      );

      if (response.statusCode != 200) {
        throw Exception('Error al publicar comentario');
      }
    } catch (e) {
      throw Exception('Error de conexión al comentar: $e');
    }
  }

  List<Tweet> _parseGetTweetsResponse(String responseBody) {
    final jsonData = jsonDecode(responseBody);
    final tweetResponse = TweetResponse.fromJson(Map<String, dynamic>.from(jsonData));
    return tweetResponse.content;
  }

  Tweet _parseTweetResponse(String responseBody) {
    final jsonData = jsonDecode(responseBody);
    return Tweet.fromJson(Map<String, dynamic>.from(jsonData));
  }

  @override
  void dispose() => _httpClient.close();
}