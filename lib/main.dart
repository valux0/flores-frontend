import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'services/tweet_service.dart';
import 'services/auth_service.dart';
import 'models/tweet.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart'; 

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
        scaffoldBackgroundColor: const Color(0xFF15202B),
        // --- FIX LOGIN: Cuadros blancos con letras negras ---
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          prefixIconColor: Colors.black,
          suffixIconColor: Colors.black,
          hintStyle: const TextStyle(color: Colors.grey),
          labelStyle: const TextStyle(color: Colors.black),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
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
  '/register': (context) => const RegisterScreen(), // <--- AGREGA ESTA LÍNEA
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

  Future<String?> _uploadToCloudinary(XFile file) async {
    // RECUERDA: Usa tus credenciales reales aquí
    const String cloudName = "dgsjf1njc"; 
    const String uploadPreset = "twweter_preset";

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
    } catch (e) { 
      _showErrorDialog('Error: $e'); 
    } finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  // --- NUEVO: Lógica de Like real (Toggle) ---
  void _toggleLike(int id) async {
    try {
      await _tweetService.reactToFlor(id, "LIKE");
      _loadTweets(); // Recarga para ver el número cambiar
    } catch (e) {
      print(e);
    }
  }

  // --- NUEVO: Lógica de Compartir real ---
  void _toggleShare(int id) async {
    try {
      await _tweetService.reactToFlor(id, "SHARE");
      _loadTweets();
    } catch (e) {
      print(e);
    }
  }

  // --- NUEVO: Diálogo de Comentarios ---
  void _showCommentDialog(int id) {
    final TextEditingController _commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Escribir comentario"),
        content: TextField(
          controller: _commentCtrl, 
          style: const TextStyle(color: Colors.black), 
          autofocus: true,
          decoration: const InputDecoration(hintText: "Tu mensaje...")
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              if (_commentCtrl.text.isNotEmpty) {
                await _tweetService.addComment(id, _commentCtrl.text);
                Navigator.pop(context);
                _loadTweets();
              }
            },
            child: const Text("Publicar"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTweet(int id) async {
    try {
      await _tweetService.deleteTweet(id);
      _loadTweets();
    } catch (e) { _showErrorDialog("Error al borrar"); }
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar mensaje?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(onPressed: () { Navigator.pop(context); _deleteTweet(id); }, child: const Text('Sí', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Aviso'), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getUser();
    return Scaffold(
      appBar: AppBar(
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
                if (snapshot.hasError) return const Center(child: Text('Error al cargar datos'));
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
          const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _tweetController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "¿Qué flor quieres publicar?", filled: false, border: InputBorder.none),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.image_outlined, color: Colors.blue), onPressed: _pickImage),
                    if (_imageFile != null) const Text("📸 Lista", style: TextStyle(fontSize: 10, color: Colors.green)),
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
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.1))),
    child: Column( // Cambiamos a Column para poder poner los comentarios abajo
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(tweet.username ?? "Usuario",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white)),
                      const SizedBox(width: 5),
                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.grey),
                          onPressed: () => _showDeleteConfirmation(tweet.id))
                    ],
                  ),
                  Text(tweet.tweet,
                      style: const TextStyle(fontSize: 15, color: Colors.white70)),
                  if (tweet.image != null && tweet.image!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(tweet.image!)),
                    ),
                  const SizedBox(height: 12),
                  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // 1. BOTÓN DE LIKE (Ahora a la izquierda)
    GestureDetector(
      onTap: () => _toggleLike(tweet.id),
      child: Row(children: [
        Icon(
            tweet.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: tweet.hasLiked ? Colors.pink : Colors.grey,
            size: 18),
        const SizedBox(width: 4),
        Text("${tweet.likeCount}",
            style: TextStyle(
                color: tweet.hasLiked ? Colors.pink : Colors.grey)),
      ]),
    ),

    // 2. BOTÓN DE COMPARTIR (Se mantiene al centro)
    GestureDetector(
        onTap: () => _toggleShare(tweet.id),
        child: _iconBtn(Icons.autorenew, "${tweet.shareCount}")),

    // 3. BOTÓN DE COMENTARIOS (Ahora a la derecha y con margen)
    Padding(
      padding: const EdgeInsets.only(right: 15.0), // Margen para que no pegue al borde
      child: GestureDetector(
          onTap: () => _showCommentDialog(tweet.id),
          child: _iconBtn(Icons.chat_bubble_outline, "${tweet.commentCount}")),
    ),
  ],
),
                ],
              ),
            ),
          ],
        ),

        // --- NUEVA SECCIÓN DE COMENTARIOS ---
        if (tweet.comments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 50, top: 10), // Indentación
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03), // Fondo sutil
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: Colors.pinkAccent, width: 2), // Línea lateral identificadora
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Comentarios", 
                    style: TextStyle(fontSize: 11, color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Listamos cada comentario
                  ...tweet.comments.map((comment) => _buildCommentItem(comment)).toList(),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

// --- WIDGET AUXILIAR PARA CADA COMENTARIO (VERSIÓN LIMPIA) ---
Widget _buildCommentItem(FlorComment comment) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Nombre del usuario que comentó en azul
            Text(comment.username, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
            const SizedBox(width: 5),
            const Icon(Icons.verified, color: Colors.blue, size: 12),
          ],
        ),
        const SizedBox(height: 2),
        // Texto del comentario
        Text(comment.text, 
          style: const TextStyle(fontSize: 13, color: Colors.white70)),
        
        // Se eliminó la fila de iconos (Like, Share, etc.) de aquí
      ],
    ),
  );
}

  Widget _iconBtn(IconData icon, String text) {
    return Row(children: [Icon(icon, color: Colors.grey, size: 18), const SizedBox(width: 4), Text(text, style: const TextStyle(color: Colors.grey))]);
  }

  @override
  void dispose() {
    _tweetController.dispose();
    super.dispose();
  }
}