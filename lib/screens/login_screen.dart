import '../globals.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

/// 🔹 Tipos de snackbar
enum SnackType { success, error, info, warning }

/// 🔹 Widget reutilizable DocYaSnackbar
class DocYaSnackbar {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    SnackType type = SnackType.success,
  }) {
    Color startColor;
    Color endColor;
    IconData icon;

    switch (type) {
      case SnackType.success:
        startColor = const Color(0xFF14B8A6);
        endColor = const Color(0xFF0F2027);
        icon = Icons.check_circle_rounded;
        break;
      case SnackType.error:
        startColor = Colors.redAccent;
        endColor = const Color(0xFF2C5364);
        icon = Icons.error_rounded;
        break;
      case SnackType.info:
        startColor = Colors.blueAccent;
        endColor = const Color(0xFF2C5364);
        icon = Icons.info_rounded;
        break;
      case SnackType.warning:
        startColor = Colors.amber;
        endColor = const Color(0xFF2C5364);
        icon = Icons.warning_amber_rounded;
        break;
    }

    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _auth = AuthService();

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
  }

  Future<void> _saveUser(String nombre, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("nombreUsuario", nombre);
    await prefs.setString("userId", id);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final loginData = await _auth.login(
      _email.text.trim(),
      _password.text.trim(),
    );

    setState(() => _loading = false);

    if (loginData != null) {
      await _saveToken(loginData["access_token"]);
      await _saveUser(loginData["full_name"], loginData["user_id"]);
      pacienteUuidGlobal = loginData["user_id"];

      DocYaSnackbar.show(
        context,
        title: "✅ Bienvenido",
        message: "Hola ${loginData["full_name"]}, ingresaste con éxito.",
        type: SnackType.success,
      );

      _goHome();
    } else {
      DocYaSnackbar.show(
        context,
        title: "⚠️ Error",
        message: "Email o contraseña inválidos.",
        type: SnackType.error,
      );
    }
  }

  void _google() async {
    setState(() => _loading = true);

    final loginData = await _auth.loginWithGoogle();

    setState(() => _loading = false);

    if (loginData != null) {
      await _saveToken(loginData["access_token"]);
      await _saveUser(loginData["full_name"], loginData["user_id"]);

      DocYaSnackbar.show(
        context,
        title: "✅ Bienvenido",
        message: "Ingresaste con Google.",
        type: SnackType.success,
      );

      _goHome();
    } else {
      DocYaSnackbar.show(
        context,
        title: "⚠️ Error",
        message: "No se pudo iniciar sesión con Google.",
        type: SnackType.error,
      );
    }
  }

  void _goHome() {
    Navigator.pushReplacementNamed(context, "/home");
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF14B8A6);
    const dark = Color(0xFF111827);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/logoblanco.png', height: 80),
                  const SizedBox(height: 24),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  prefixIcon: Icon(Icons.email_outlined,
                                      color: Colors.white70),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Ingresá tu email';
                                  }
                                  if (!v.contains('@')) return 'Email inválido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Contraseña',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  prefixIcon: Icon(Icons.lock_outline,
                                      color: Colors.white70),
                                ),
                                validator: (v) =>
                                    (v == null || v.length < 6)
                                        ? 'Mínimo 6 caracteres'
                                        : null,
                              ),
                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Text('Ingresar',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('¿No tenés cuenta?',
                                      style: TextStyle(color: Colors.white70)),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const RegisterScreen()));
                                    },
                                    child: const Text('Registrate',
                                        style: TextStyle(color: primary)),
                                  )
                                ],
                              ),
                              const Divider(height: 30, color: Colors.white24),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: Image.asset("assets/google_logo.png",
                                      height: 22),
                                  onPressed: _loading ? null : _google,
                                  label: const Text('Ingresar con Google',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: dark,
                                    side: const BorderSide(
                                        color: primary, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Al continuar aceptás nuestros Términos y Política de Privacidad.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
