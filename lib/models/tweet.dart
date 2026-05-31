class Tweet {
  final int id;
  final String tweet;
  final String? image;
  final String? username;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool hasLiked;
  // --- NUEVO: Lista de comentarios ---
  final List<FlorComment> comments; 

  Tweet({
    required this.id, 
    required this.tweet, 
    this.image, 
    this.username,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.hasLiked = false,
    this.comments = const [],
  });

  factory Tweet.fromJson(Map<String, dynamic> json) {
    // Procesamos la lista de comentarios que manda Java
    var list = json['comments'] as List? ?? [];
    List<FlorComment> commentObjs = list.map((c) => FlorComment.fromJson(c)).toList();

    return Tweet(
      id: json['id'] ?? 0,
      tweet: json['tweet'] ?? '',
      image: json['image'],
      username: json['postedBy'] != null ? json['postedBy']['username'] : "Anónimo",
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      hasLiked: json['hasLiked'] ?? false,
      comments: commentObjs,
    );
  }
}

// Nueva clase pequeña para los comentarios
class FlorComment {
  final String text;
  final String username;

  FlorComment({required this.text, required this.username});

  factory FlorComment.fromJson(Map<String, dynamic> json) {
    return FlorComment(
      text: json['text'] ?? '',
      username: json['username'] ?? 'Anónimo',
    );
  }
}