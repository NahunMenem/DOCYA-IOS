import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'buscando_medico_screen.dart';
import 'solicitud_medico_screen.dart';
import '../globals.dart';

Future<String?> getPacienteUuid() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("paciente_uuid");
}


class SolicitudEnfermeroScreen extends StatefulWidget {
  final String direccion;
  final LatLng ubicacion;

  const SolicitudEnfermeroScreen({
    super.key,
    required this.direccion,
    required this.ubicacion,
  });

  @override
  State<SolicitudEnfermeroScreen> createState() =>
      _SolicitudEnfermeroScreenState();
}

class _SolicitudEnfermeroScreenState extends State<SolicitudEnfermeroScreen> {
  bool aceptaConsentimiento = false;
  final TextEditingController motivoCtrl = TextEditingController();
  late GoogleMapController _mapController;

  // 🔹 Estilo Uber Dark para mapa
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

  Future<void> _solicitarEnfermero() async {
    final body = {
      "paciente_uuid": pacienteUuidGlobal,
      "motivo": motivoCtrl.text.trim(),
      "direccion": widget.direccion,
      "lat": widget.ubicacion.latitude,
      "lng": widget.ubicacion.longitude,
      "tipo": "enfermero", // 👈 clave!
    };

    try {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "⚠️ ${data['detail'] ?? 'No hay enfermeros disponibles'}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al solicitar enfermero")),
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
              // Header con logo
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
                      // Mapa
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

                      // Dirección
                      glassCard(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFF11B5B0), size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(widget.direccion,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Alcance del enfermero
                      Text(
                        "👩‍⚕️ Alcance del enfermero",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const SizedBox(height: 12),
                      glassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("✅ Control de signos vitales"),
                            SizedBox(height: 6),
                            Text("✅ Aplicación de inyectables y vacunas"),
                            SizedBox(height: 6),
                            Text("✅ Curaciones simples"),
                            SizedBox(height: 6),
                            Text("✅ Colocación de vías y sueros"),
                            SizedBox(height: 6),
                            Text("✅ Extracciones de sangre"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Motivo
                      Text("Motivo de la consulta",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      const SizedBox(height: 10),
                      glassCard(
                        child: TextField(
                          controller: motivoCtrl,
                          maxLines: 3,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "Ej: curación, inyección...",
                            hintStyle: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black45),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

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
                      const SizedBox(height: 60),

                      // Botón solicitar médico como opción
                      Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF11B5B0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                          icon: const Icon(Icons.local_hospital,
                              color: Color(0xFF11B5B0)),
                          label: const Text("Solicitar médico"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SolicitudMedicoScreen(
                                  direccion: widget.direccion,
                                  ubicacion: widget.ubicacion,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer con costo y botón
              SafeArea(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Text("💰 Este servicio tiene un costo de:",
                          style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDark ? Colors.white70 : Colors.black54)),
                      const SizedBox(height: 4),
                      const Text("\$15.000 ARS",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF11B5B0))),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF11B5B0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed:
                            aceptaConsentimiento ? _solicitarEnfermero : null,
                        child: const Text("Solicitar enfermero",
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
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
