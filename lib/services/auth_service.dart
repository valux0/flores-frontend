import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Servicio Singleton para autenticación
class AuthService {
  static final AuthService _instance = AuthService._internal();

  // URL base sin barra al final para evitar errores de //
  final String baseUrl = 'https://flores-api.onrender.com/api';
  //final String baseUrl = 'http://localhost:8080/api';
  late http.Client _httpClient;
  SharedPreferences? _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  AuthService._internal() {
    _httpClient = http.Client();
  }

  factory AuthService() {
    return _instance;
  }

  static AuthService getInstance() {
    return _instance;
  }

  Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> init() async {
    await _ensureInit();
  }

  Future<User> login(String username, String password) async {
    try {
      await _ensureInit();
      
      // La ruta final es http://localhost:8080/api/auth/signin
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('DEBUG LOGIN: Status code = ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final token = jsonData['accessToken']?.toString() ?? '';
        
        if (token.isEmpty) {
          throw Exception('No se recibió el token del servidor');
        }
        
        // Guardar token y datos del usuario
        await _prefs!.setString(_tokenKey, token);
        
        final userData = {
          'id': jsonData['id'],
          'username': jsonData['username'],
          'email': jsonData['email'],
        };
        
        final user = User.fromJson(userData);
        await _prefs!.setString(_userKey, jsonEncode(user.toJson()));
        
        print('✅ LOGIN EXITOSO: Bienvenido ${user.username}');
        return user;
      } else {
        throw Exception('Error: Usuario o contraseña incorrectos');
      }
    } catch (e) {
      print('❌ ERROR EN LOGIN: $e');
      throw Exception('Falla en la conexión con el servidor');
    }
  }

  String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  User? getUser() {
    final userJson = _prefs?.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  bool isAuthenticated() {
    return getToken() != null && getToken()!.isNotEmpty;
  }

  Future<void> logout() async {
    await _ensureInit();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_userKey);
  }

  // Función para registrar un nuevo usuario
  Future<void> register(String username, String email, String password) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'role': ['user'] // Por defecto creamos usuarios normales
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error al registrarse');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}