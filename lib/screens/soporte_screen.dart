import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SoporteScreen extends StatelessWidget {
  const SoporteScreen({super.key});

  // 👉 Número de soporte en WhatsApp + mensaje inicial
  final String _whatsappUrl =
      "https://wa.me/5491160000000?text=Hola%20necesito%20ayuda%20con%20DocYa";

  Future<void> _abrirWhatsApp() async {
    final Uri url = Uri.parse(_whatsappUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Soporte"),
        backgroundColor: const Color(0xFF11B5B0),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Encabezado
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Centro de ayuda",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                "Encuentra respuestas rápidas o comunícate con nuestro equipo.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 📌 FAQ
          _faqItem(
            FontAwesomeIcons.userDoctor,
            "¿Cómo solicito un médico?",
            "En la pantalla principal selecciona tu dirección, responde las preguntas de filtro y confirma la solicitud.",
          ),
          _faqItem(
            FontAwesomeIcons.creditCard,
            "¿Cómo pago la consulta?",
            "Podés pagar con tarjeta, transferencia o Mercado Pago directamente desde la app.",
          ),
          _faqItem(
            FontAwesomeIcons.triangleExclamation,
            "¿Qué pasa si el médico no llega?",
            "Si el médico no llega, podés cancelar y se te reembolsará el dinero automáticamente.",
          ),
          _faqItem(
            FontAwesomeIcons.userNurse,
            "¿Puedo pedir un enfermero?",
            "Sí, el médico puede solicitar un enfermero desde la misma app si lo considera necesario.",
          ),

          const SizedBox(height: 30),

          // 📲 Botón WhatsApp soporte
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // verde WhatsApp
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _abrirWhatsApp,
              icon: const Icon(FontAwesomeIcons.whatsapp, size: 22),
              label: const Text(
                "Contactar por WhatsApp",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(IconData icono, String pregunta, String respuesta) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(icono, color: const Color(0xFF11B5B0), size: 26),
        title: Text(
          pregunta,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              respuesta,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
