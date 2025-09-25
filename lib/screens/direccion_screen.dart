import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 📍 API Key Google
const kGoogleApiKey = "AIzaSyClH5_b6XATyG2o9cFj8CKGS1E-bzrFFhU";

class DireccionScreen extends StatefulWidget {
  final String userId;
  final String nombreUsuario;

  const DireccionScreen({
    super.key,
    required this.userId,
    required this.nombreUsuario,
  });

  @override
  State<DireccionScreen> createState() => _DireccionScreenState();
}

class _DireccionScreenState extends State<DireccionScreen> {
  LatLng? selectedLocation;
  late GoogleMapController mapController;

  TextEditingController direccionCtrl = TextEditingController();
  TextEditingController pisoCtrl = TextEditingController();
  TextEditingController deptoCtrl = TextEditingController();
  TextEditingController indicacionesCtrl = TextEditingController();
  TextEditingController telefonoCtrl = TextEditingController();

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> guardarDireccion() async {
    if (selectedLocation == null) return;

    final url = Uri.parse(
        "https://docya-railway-production.up.railway.app/direccion/guardar");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.userId,
        "lat": selectedLocation!.latitude,
        "lng": selectedLocation!.longitude,
        "direccion": direccionCtrl.text,
        "piso": pisoCtrl.text,
        "depto": deptoCtrl.text,
        "indicaciones": indicacionesCtrl.text,
        "telefono_contacto": telefonoCtrl.text,
      }),
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Dirección guardada con éxito")),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error al guardar dirección")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 🌍 Google Map de fondo
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: selectedLocation ?? const LatLng(-34.6037, -58.3816),
              zoom: selectedLocation != null ? 16 : 14,
            ),
            onTap: (LatLng pos) {
              setState(() => selectedLocation = pos);
            },
            markers: selectedLocation != null
                ? {Marker(markerId: const MarkerId("sel"), position: selectedLocation!)}
                : {},
          ),

          // 🔍 Barra de búsqueda arriba
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: direccionCtrl,
                googleAPIKey: kGoogleApiKey,
                debounceTime: 800,
                countries: ["ar"],
                isLatLngRequired: true,
                inputDecoration: InputDecoration(
                  hintText: "Buscar dirección...",
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF11B5B0)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  if (prediction.lat != null && prediction.lng != null) {
                    setState(() {
                      selectedLocation = LatLng(
                        double.parse(prediction.lat!),
                        double.parse(prediction.lng!),
                      );
                    });
                    mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(selectedLocation!, 16),
                    );
                  }
                },
                itemClick: (Prediction prediction) {
                  direccionCtrl.text = prediction.description ?? "";
                  direccionCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: direccionCtrl.text.length),
                  );
                },
              ),
            ),
          ),

          // 📝 Panel flotante abajo
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  )
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hola ${widget.nombreUsuario}, confirmá tu dirección",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 12),
                    TextField(
                        controller: pisoCtrl,
                        decoration: const InputDecoration(
                          labelText: "Piso",
                          prefixIcon: Icon(Icons.apartment_outlined),
                        )),
                    const SizedBox(height: 8),
                    TextField(
                        controller: deptoCtrl,
                        decoration: const InputDecoration(
                          labelText: "Depto",
                          prefixIcon: Icon(Icons.meeting_room_outlined),
                        )),
                    const SizedBox(height: 8),
                    TextField(
                        controller: indicacionesCtrl,
                        decoration: const InputDecoration(
                          labelText: "Indicaciones",
                          prefixIcon: Icon(Icons.info_outline),
                        )),
                    const SizedBox(height: 8),
                    TextField(
                        controller: telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Teléfono de contacto",
                          prefixIcon: Icon(Icons.phone),
                        )),
                    const SizedBox(height: 16),

                    // Botón grande estilo Uber
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF11B5B0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: guardarDireccion,
                        child: const Text("Confirmar dirección"),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
