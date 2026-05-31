import '../models/tweet.dart';

/// Abstract interface for Twitter repository operations
/// Follows the Dependency Inversion Principle (DIP)
abstract class ITweetRepository {
  /// Obtener todas las flores
  Future<List<Tweet>> fetchTweets();

  /// Crear una nueva flor con imagen opcional
  Future<Tweet> createTweet(String content, {String? imageBase64});

  /// Eliminar una flor por ID
  Future<void> deleteTweet(int id);

  /// --- NUEVAS FUNCIONES DE INTERACCIÓN ---

  /// Reaccionar (LIKE o SHARE) a una flor
  Future<void> reactToFlor(int id, String type);

  /// Agregar un comentario a una flor
  Future<void> addComment(int id, String text);

  /// Cleanup resources
  void dispose();
}