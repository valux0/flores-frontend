import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- CAMBIO: Título y Flor ---
            const Icon(Icons.filter_vintage, size: 80, color: Color(0xFFCE93D8)),
            const SizedBox(height: 16),
            const Text(
              "Flores",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              "Iniciar sesión",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Cuadro de Usuario
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.black), // Texto negro al escribir
              decoration: const InputDecoration(
                hintText: "Usuario",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Cuadro de Contraseña
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.black), // Texto negro al escribir
              decoration: const InputDecoration(
                hintText: "Contraseña",
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
              ),
            
            const SizedBox(height: 24),

            // Botón de Entrar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCE93D8).withOpacity(0.2),
                  foregroundColor: const Color(0xFFCE93D8),
                  side: const BorderSide(color: Color(0xFFCE93D8)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(strokeWidth: 2) 
                    : const Text("Entrar a mi jardín"),
            ),
            ),
            
            // ELIMINADO: Ya no existe el recuadro de credenciales de prueba
          ],
        ),
      ),
    );
  }
}