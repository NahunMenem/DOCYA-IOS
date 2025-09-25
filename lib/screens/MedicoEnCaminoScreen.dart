import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart'; // 👈 importamos la pantalla de chat
import 'consulta_en_curso_screen.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

Future<BitmapDescriptor> getScaledIcon(String path, int width) async {
  final ByteData data = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: width, // 👈 fuerza el ancho final
  );
  final fi = await codec.getNextFrame();
  final bytes = await fi.image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

class MedicoEnCaminoScreen extends StatefulWidget {
  final String direccion;
  final LatLng ubicacionPaciente;
  final String motivo;
  final int medicoId;
  final String nombreMedico;
  final String matricula;
  final int consultaId;
  final String pacienteUuid;

  const MedicoEnCaminoScreen({
    super.key,
    required this.direccion,
    required this.ubicacionPaciente,
    required this.motivo,
    required this.medicoId,
    required this.nombreMedico,
    required this.matricula,
    required this.consultaId,
    required this.pacienteUuid,
  });

  @override
  State<MedicoEnCaminoScreen> createState() => _MedicoEnCaminoScreenState();
}

class _MedicoEnCaminoScreenState extends State<MedicoEnCaminoScreen> {
  late GoogleMapController _mapController;
  Timer? _timer;
  LatLng? medicoLocation;
  double? tiempoEstimado;
  BitmapDescriptor? medicoIcon;
  Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  final String uberMapStyle = '''
  [
    {"elementType": "geometry","stylers": [{"color": "#212121"}]},
    {"elementType": "labels.icon","stylers": [{"visibility": "off"}]},
    {"elementType": "labels.text.fill","stylers": [{"color": "#757575"}]},
    {"elementType": "labels.text.stroke","stylers": [{"color": "#212121"}]},
    {"featureType": "poi","stylers": [{"visibility": "off"}]},
    {"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2c2c2c"}]},
    {"featureType": "road","elementType": "geometry.stroke","stylers": [{"color": "#3c3c3c"}]},
    {"featureType": "water","elementType": "geometry","stylers": [{"color": "#000000"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _cargarIconoMedico();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      _getUbicacionMedico();
      _checkEstadoConsulta();
    });
  }

  Future<void> _cargarIconoMedico() async {
    final icon = await getScaledIcon("assets/ambulancia.png", 128); // 👈 tamaño tipo Uber
    setState(() => medicoIcon = icon);
  }





  Future<void> _getUbicacionMedico() async {
    final url =
        "https://docya-railway-production.up.railway.app/consultas/${widget.consultaId}/ubicacion_medico";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nuevaUbicacion = LatLng(data["lat"], data["lng"]);

        setState(() {
          medicoLocation = nuevaUbicacion;
        });

        await _dibujarRuta();
        _calcularTiempo();
      }
    } catch (e) {
      debugPrint("Error obteniendo ubicación médico: $e");
    }
  }

  Future<void> _checkEstadoConsulta() async {
    final url =
        "https://docya-railway-production.up.railway.app/consultas/${widget.consultaId}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["estado"] == "en_domicilio" && mounted) {
          final horaInicio = DateFormat("HH:mm").format(DateTime.now());

          await http.patch(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"hora_inicio": horaInicio}),
          );

          _timer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ConsultaEnCursoScreen(
                consultaId: widget.consultaId,
                profesionalId: widget.medicoId,
                pacienteUuid: widget.pacienteUuid,
                nombreProfesional: widget.nombreMedico,
                especialidad: data["especialidad"] ?? "Clínica médica",
                matricula: widget.matricula,
                motivo: widget.motivo,
                direccion: widget.direccion,
                horaInicio: horaInicio,
                tipo: "medico",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error revisando estado consulta: $e");
    }
  }

  Future<void> _dibujarRuta() async {
    if (medicoLocation == null) return;

    const String apiKey = "AIzaSyClH5_b6XATyG2o9cFj8CKGS1E-bzrFFhU"; // ⚠️ tu API Key
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${medicoLocation!.latitude},${medicoLocation!.longitude}"
        "&destination=${widget.ubicacionPaciente.latitude},${widget.ubicacionPaciente.longitude}"
        "&mode=driving&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data["routes"].isNotEmpty) {
      final puntos = data["routes"][0]["overview_polyline"]["points"];
      final decodedPoints = PolylinePoints().decodePolyline(puntos);

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId("ruta"),
            color: const Color(0xFF11B5B0),
            width: 6,
            points: decodedPoints
                .map((e) => LatLng(e.latitude, e.longitude))
                .toList(),
          ),
        };

        _markers.clear();
        _markers.add(Marker(
          markerId: const MarkerId("paciente"),
          position: widget.ubicacionPaciente,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: "Tu domicilio"),
        ));
        if (medicoIcon != null && medicoLocation != null) {
          _markers.add(Marker(
            markerId: const MarkerId("medico"),
            position: medicoLocation!,
            icon: medicoIcon!,
            infoWindow: const InfoWindow(title: "Médico en camino"),
          ));
        }
      });
    }
  }

  void _calcularTiempo() {
    if (medicoLocation == null) return;
    double distanciaKm = _haversine(
      medicoLocation!.latitude,
      medicoLocation!.longitude,
      widget.ubicacionPaciente.latitude,
      widget.ubicacionPaciente.longitude,
    );
    setState(() {
      tiempoEstimado = distanciaKm / 0.5; // ~30km/h
    });
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  void dispose() {
    _mapController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _llamarMedico() async {
    final Uri tel = Uri(scheme: "tel", path: "123456789"); // ⚠️ reemplazar con número real
    if (await canLaunchUrl(tel)) {
      await launchUrl(tel);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo iniciar la llamada 📞")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int minutos = (tiempoEstimado ?? 0).ceil();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF11B5B0),
        title: const Text("Médico en camino"),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController.setMapStyle(uberMapStyle);
            },
            initialCameraPosition: CameraPosition(
              target: widget.ubicacionPaciente,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF14B8A6),
                        backgroundImage: NetworkImage(
                          "https://docya-railway-production.up.railway.app/profiles/${widget.medicoId}.jpg",
                        ),
                        onBackgroundImageError: (_, __) {
                          // fallback si 404
                        },
                        child: const Icon(Icons.person, size: 30, color: Colors.white),
                      ),


                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nombreMedico,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text("Matrícula: ${widget.matricula}",
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black54)),
                            Text("⏳ Llegada estimada: $minutos min",
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (i) {
                                return const Icon(Icons.star,
                                    size: 16, color: Colors.amber);
                              }),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: _llamarMedico,
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF11B5B0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              consultaId: widget.consultaId,
                              remitenteTipo: "paciente", // 👈 o "profesional" según el rol
                              remitenteId: widget.pacienteUuid,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text(
                        "Enviar mensaje",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
