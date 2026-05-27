import '../models/tweet.dart';

/// Abstract interface for Twitter repository operations
/// Follows the Dependency Inversion Principle (DIP)
abstract class ITweetRepository {
  /// Fetch all tweets
  Future<List<Tweet>> fetchTweets();

  /// Create a new tweet - MODIFICADO para aceptar imagen opcional
  Future<Tweet> createTweet(String content, {String? imageBase64});

  /// Delete a tweet by ID
  Future<void> deleteTweet(int id);

  /// Cleanup resources
  void dispose();
}