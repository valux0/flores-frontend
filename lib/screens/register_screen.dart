import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      await _authService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Flor cultivada con éxito! Ya puedes entrar.")),
        );
        Navigator.pop(context); // Regresa al Login
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.filter_vintage, size: 80, color: Color(0xFFCE93D8)),
              const SizedBox(height: 16),
              const Text("Únete al Jardín", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(hintText: "Nombre de usuario", prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(hintText: "Correo electrónico", prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(hintText: "Contraseña", prefixIcon: Icon(Icons.lock)),
              ),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCE93D8).withOpacity(0.2),
                    foregroundColor: const Color(0xFFCE93D8),
                    side: const BorderSide(color: Color(0xFFCE93D8)),
                  ),
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Crear mi cuenta"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}