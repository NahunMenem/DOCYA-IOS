import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'buscando_medico_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart';

Future<String?> getPacienteUuid() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("paciente_uuid");
}


class SolicitudMedicoScreen extends StatefulWidget {
  final String direccion;
  final LatLng ubicacion;

  const SolicitudMedicoScreen({
    super.key,
    required this.direccion,
    required this.ubicacion,
  });

  @override
  State<SolicitudMedicoScreen> createState() => _SolicitudMedicoScreenState();
}

class _SolicitudMedicoScreenState extends State<SolicitudMedicoScreen> {
  bool aceptaConsentimiento = false;
  final TextEditingController motivoCtrl = TextEditingController();
  late GoogleMapController _mapController;

  // 🔹 Estilo Uber para mapa dark
  final String uberMapStyle = '''
  [
    {"elementType": "geometry","stylers":[{"color":"#212121"}]},
    {"elementType": "labels.icon","stylers":[{"visibility":"off"}]},
    {"elementType": "labels.text.fill","stylers":[{"color":"#757575"}]},
    {"elementType": "labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType": "poi","stylers":[{"visibility":"off"}]},
    {"featureType": "road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType": "road","elementType":"geometry.stroke","stylers":[{"color":"#3c3c3c"}]},
    {"featureType": "water","elementType":"geometry","stylers":[{"color":"#000000"}]}
  ]
  ''';

  final String apiUrl =
      "https://docya-railway-production.up.railway.app/consultas/solicitar";

  Future<void> _solicitarConsulta() async {
    final body = {
      "paciente_uuid": pacienteUuidGlobal,
      "motivo": motivoCtrl.text.trim(),
      "direccion": widget.direccion,
      "lat": widget.ubicacion.latitude,
      "lng": widget.ubicacion.longitude,
    };

    try {
      // 👀 Debug prints
      print("👉 URL: $apiUrl");
      print("👉 Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("👉 StatusCode: ${response.statusCode}");
      print("👉 Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // 🔎 Si devuelve consulta_id => paso a la siguiente pantalla
        if (data is Map && data.containsKey("consulta_id")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BuscandoMedicoScreen(
                direccion: widget.direccion,
                ubicacion: widget.ubicacion,
                motivo: motivoCtrl.text.trim(),
                consultaId: data["consulta_id"],
                pacienteUuid: pacienteUuidGlobal,
              ),
            ),
          );
        } else {
          // Si viene {"detail": "..."}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ ${data['detail'] ?? 'No hay médicos disponibles'}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al solicitar médico: ${response.body}")),
        );
      }
    } catch (e) {
      print("❌ Error de conexión: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.setMapStyle(uberMapStyle);
  }

  // 🔹 Glass card adaptada al tema
  Widget glassCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.15))
                : Border.all(color: Colors.black12),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      body: Container(
        decoration: isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 Header con logo
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Image.asset(
                    isDark ? "assets/logoblanco.png" : "assets/logo.png",
                    height: 36,
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🗺️ Mapa
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 200,
                          child: GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: CameraPosition(
                              target: widget.ubicacion,
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId("ubicacion"),
                                position: widget.ubicacion,
                              )
                            },
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 📍 Dirección
                      glassCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFF11B5B0), size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.direccion,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 📝 Motivo
                      Text(
                        "Motivo de la consulta",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const SizedBox(height: 10),
                      glassCard(
                        child: TextField(
                          controller: motivoCtrl,
                          maxLines: 3,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "Ej: fiebre, dolor de garganta...",
                            hintStyle: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black45),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 📜 Declaración jurada
                      Text(
                        "Declaración Jurada",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const SizedBox(height: 10),
                      glassCard(
                        child: Text(
                          "Declaro bajo juramento que he respondido con honestidad las preguntas previas de triage.",
                          style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 12),

                      CheckboxListTile(
                        value: aceptaConsentimiento,
                        onChanged: (val) =>
                            setState(() => aceptaConsentimiento = val ?? false),
                        activeColor: const Color(0xFF11B5B0),
                        checkColor: Colors.white,
                        title: Text(
                          "Acepto la declaración jurada",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // 💰 Footer
              SafeArea(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "💰 Este servicio tiene un costo de:",
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "\$30.000 ARS",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF11B5B0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF11B5B0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed:
                            aceptaConsentimiento ? _solicitarConsulta : null,
                        child: const Text(
                          "Pagar con MercadoPago",
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
