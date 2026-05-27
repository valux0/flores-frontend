import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tweet.dart';
import '../models/tweet_response.dart';
import '../repositories/tweet_repository.dart';
import 'auth_service.dart';

class TweetService implements ITweetRepository {
  static final TweetService _instance = TweetService._internal();

  final String baseUrl = 'https://flores-api.onrender.com/api';
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
        throw Exception('Failed to load tweets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tweets: $e');
    }
  }

  @override
  // CORRECCIÓN AQUÍ: Agregamos {String? imageBase64} en el paréntesis
  Future<Tweet> createTweet(String content, {String? imageBase64}) async {
    try {
      if (content.isEmpty) throw Exception('Tweet content cannot be empty');

      await _authService.init();

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/tweets/create'),
        headers: _getHeaders(),
        body: jsonEncode({
          'tweet': content,
          'image': imageBase64, // Ahora la función ya sabe qué es esto
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseTweetResponse(response.body);
      } else {
        throw Exception('Failed to create tweet: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating tweet: $e');
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
        throw Exception('Failed to delete tweet');
      }
    } catch (e) {
      throw Exception('Error deleting tweet: $e');
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