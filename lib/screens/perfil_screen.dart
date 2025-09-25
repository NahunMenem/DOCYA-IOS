import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'soporte_screen.dart';
import 'consultas_screen.dart';
import 'configuracion_screen.dart';

class PerfilScreen extends StatefulWidget {
  final String userId;

  const PerfilScreen({super.key, required this.userId});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool cargando = true;
  String nombreUsuario = "";
  String email = "";
  String telefono = "";

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final url = Uri.parse(
          "https://docya-railway-production.up.railway.app/usuarios/${widget.userId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          nombreUsuario = data['full_name'] ?? "";
          email = data['email'] ?? "";
          telefono = data['telefono'] ?? "Sin teléfono";
          cargando = false;
        });
      } else {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error al obtener perfil: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error de conexión: $e")),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: const Color(0xFF11B5B0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + nombre
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundColor: Color(0xFF11B5B0),
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(nombreUsuario,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.grey)),
                Text(telefono, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Opciones
          _opcionPerfil(Icons.history, "Historial de consultas", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ConsultasScreen(pacienteUuid: widget.userId),
              ),
            );
          }),

          _opcionPerfil(Icons.payment, "Métodos de pago", () {}),

          _opcionPerfil(Icons.settings, "Configuración", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConfiguracionScreen(),
              ),
            );

          }),

          _opcionPerfil(Icons.help_outline, "Soporte", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SoporteScreen()),
            );
          }),

          const SizedBox(height: 20),

          // Botón logout real
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout),
            label: const Text("Cerrar sesión",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _opcionPerfil(IconData icono, String titulo, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icono, color: const Color(0xFF11B5B0)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
