class Tweet {
  final int id;
  final String tweet;
  final String? image;
  final String? username; // Almacena el nombre del autor

  Tweet({required this.id, required this.tweet, this.image, this.username});

  factory Tweet.fromJson(Map<String, dynamic> json) {
    // Extraemos el username del objeto postedBy que viene del Backend
    String? name;
    if (json['postedBy'] != null) {
      name = json['postedBy']['username'];
    }

    return Tweet(
      id: json['id'] ?? 0,
      tweet: json['tweet'] ?? '',
      image: json['image'],
      username: name,
    );
  }

  // Esta función es necesaria para enviar datos al servidor
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tweet': tweet,
      'image': image,
      // No enviamos username aquí porque el servidor lo sabe por el Token
    };
  }
}