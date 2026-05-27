import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'services/tweet_service.dart';
import 'services/auth_service.dart';
import 'models/tweet.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flores',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF15202B), // Fondo oscuro estilo Twitter
        
        // --- CAMBIO PARA EL LOGIN: Cuadros blancos con letras negras ---
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, 
          prefixIconColor: Colors.black,
          suffixIconColor: Colors.black,
          hintStyle: const TextStyle(color: Colors.grey),
          labelStyle: const TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        // Color del texto al escribir en los campos del Login
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black), // Texto en inputs
          bodyLarge: TextStyle(color: Colors.white),  // Texto general
        ),
        useMaterial3: true,
      ),
      home: _buildHome(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MyHomePage(title: 'Flores'),
      },
    );
  }

  Widget _buildHome() {
    final authService = AuthService();
    return authService.isAuthenticated() 
        ? const MyHomePage(title: 'Flores') 
        : const LoginScreen();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TweetService _tweetService;
  late AuthService _authService;
  late Future<List<Tweet>> _tweetsFuture;
  final TextEditingController _tweetController = TextEditingController();
  bool _isLoading = false;
  XFile? _imageFile;
  final Set<int> _likedTweets = {}; // Para el estado de los likes

  @override
  void initState() {
    super.initState();
    _tweetService = TweetService();
    _authService = AuthService();
    _loadTweets();
  }

  void _loadTweets() {
    setState(() {
      _tweetsFuture = _tweetService.fetchTweets();
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? selected = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (selected != null) setState(() => _imageFile = selected);
  }

  void _toggleLike(int id) {
    setState(() {
      if (_likedTweets.contains(id)) {
        _likedTweets.remove(id);
      } else {
        _likedTweets.add(id);
      }
    });
  }

  Future<String?> _uploadToCloudinary(XFile file) async {
    const String cloudName = "dgsjf1njc"; // CAMBIA ESTO
    const String uploadPreset = "twweter_preset";   // CAMBIA ESTO
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final bytes = await file.readAsBytes();
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name, contentType: MediaType('image', 'jpeg')));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final res = jsonDecode(await response.stream.bytesToString());
        return res['secure_url'];
      }
    } catch (e) { print(e); }
    return null;
  }

  Future<void> _createFlor() async {
    final content = _tweetController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_imageFile != null) imageUrl = await _uploadToCloudinary(_imageFile!);
      await _tweetService.createTweet(content, imageBase64: imageUrl);
      _tweetController.clear();
      setState(() => _imageFile = null);
      _loadTweets();
    } catch (e) { print(e); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getUser();
    return Scaffold(
      appBar: AppBar(
        // --- CAMBIO: Flor en la esquina izquierda ---
        leading: const Icon(Icons.filter_vintage, color: Colors.pinkAccent, size: 28),
        title: const Text("Flores", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF15202B),
        actions: [
          Center(child: Text('Hola, ${user?.username ?? "Admin"} ')),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      body: Column(
        children: [
          _buildInputSection(),
          const Divider(color: Colors.grey, thickness: 0.1),
          Expanded(
            child: FutureBuilder<List<Tweet>>(
              future: _tweetsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final tweets = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: tweets.length,
                  itemBuilder: (context, index) => _buildFlorCard(tweets[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.filter_vintage, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _tweetController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white), // Texto blanco en el home
                  decoration: const InputDecoration(
                    hintText: "¿Qué flor quieres publicar?",
                    filled: false, 
                    border: InputBorder.none,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.image_outlined, color: Colors.blue), onPressed: _pickImage),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createFlor,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: const Text("Publicar Flor"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlorCard(Tweet tweet) {
    bool isLiked = _likedTweets.contains(tweet.id);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 0.1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // --- CAMBIO: Mostrar nombre real del usuario ---
                    Text(tweet.username ?? "Usuario", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    const SizedBox(width: 5),
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey), onPressed: () => _deleteTweet(tweet.id))
                  ],
                ),
                Text(tweet.tweet, style: const TextStyle(fontSize: 15, color: Colors.white70)),
                if (tweet.image != null && tweet.image!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(tweet.image!)),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _iconButton(Icons.chat_bubble_outline, "0"),
                    _iconButton(Icons.autorenew, "0"),
                    GestureDetector(
                      onTap: () => _toggleLike(tweet.id),
                      child: Row(children: [
                        Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.pink : Colors.grey, size: 18),
                        const SizedBox(width: 4),
                        Text(isLiked ? "1" : "0", style: TextStyle(color: isLiked ? Colors.pink : Colors.grey)),
                      ]),
                    ),
                    const Icon(Icons.ios_share, color: Colors.grey, size: 18),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String text) {
    return Row(children: [Icon(icon, color: Colors.grey, size: 18), const SizedBox(width: 4), Text(text, style: const TextStyle(color: Colors.grey))]);
  }

  void _deleteTweet(int id) async {
    await _tweetService.deleteTweet(id);
    _loadTweets();
  }
}