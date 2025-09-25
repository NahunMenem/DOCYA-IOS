import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'solicitud_enfermero_screen.dart';

import 'filtro_medico_screen.dart';
import '../widgets/bottom_nav.dart';
import 'perfil_screen.dart';
import 'consultas_screen.dart';
import 'recetas_screen.dart';

// 📍 API Key Google
const kGoogleApiKey = "AIzaSyClH5_b6XATyG2o9cFj8CKGS1E-bzrFFhU"; // reemplazá con la tuya

class HomeScreen extends StatefulWidget {
  final String? nombreUsuario;
  final String? userId;
  final VoidCallback onToggleTheme; // 👈 Nuevo: alternar tema

  const HomeScreen({
    super.key,
    this.nombreUsuario,
    this.userId,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _nombreUsuario;
  String? _userId;

  LatLng? selectedLocation;
  late GoogleMapController mapController;
  bool cargando = true;
  bool tieneDireccion = false;
  int _selectedIndex = 0;

  final TextEditingController direccionCtrl = TextEditingController();
  final TextEditingController pisoCtrl = TextEditingController();
  final TextEditingController deptoCtrl = TextEditingController();
  final TextEditingController indicacionesCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();

  // 🔹 Estilo Uber Dark (mapa negro)
  final String uberMapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType":"poi","stylers":[{"visibility":"off"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#3c3c3c"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _cargarSesion();
  }

  Future<void> _cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreUsuario = widget.nombreUsuario ?? prefs.getString("nombreUsuario");
      _userId = widget.userId ?? prefs.getString("userId");
    });

    if (_userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, "/login");
      });
    } else {
      _cargarDireccionGuardada();
    }
  }

  Future<void> _guardarSesion(String nombre, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("nombreUsuario", nombre);
    await prefs.setString("userId", id);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.setMapStyle(uberMapStyle);
  }

  Future<void> _cargarDireccionGuardada() async {
    final url = Uri.parse(
      "https://docya-railway-production.up.railway.app/direccion/mia/${_userId}",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        selectedLocation = LatLng(data["lat"], data["lng"]);
        direccionCtrl.text = data["direccion"] ?? "";
        pisoCtrl.text = data["piso"] ?? "";
        deptoCtrl.text = data["depto"] ?? "";
        indicacionesCtrl.text = data["indicaciones"] ?? "";
        telefonoCtrl.text = data["telefono_contacto"] ?? "";
        tieneDireccion = true;
        cargando = false;
      });
    } else {
      setState(() {
        tieneDireccion = false;
        cargando = false;
      });
    }
  }

  Future<void> guardarDireccion() async {
    if (selectedLocation == null) return;

    final url = Uri.parse(
      "https://docya-railway-production.up.railway.app/direccion/guardar",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": _userId,
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
      setState(() => tieneDireccion = true);
      _mostrarSnackBar(context, "Dirección guardada con éxito", exito: true);
    } else {
      _mostrarSnackBar(context, "❌ Error al guardar dirección", exito: false);
    }
  }

  /// 🔹 SnackBar flotante y moderno estilo DocYa
  void _mostrarSnackBar(BuildContext context, String mensaje, {bool exito = true}) {
    final color = exito ? const Color(0xFF14B8A6) : Colors.redAccent;
    final icono = exito ? Icons.check_circle : Icons.error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icono, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }


  // 🔹 Card estilo glass
  Widget glassCard({
    required Widget child,
    EdgeInsets? padding,
    double? minHeight,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints:
              minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: isDark
                ? Border.all(color: Colors.white24, width: 1)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }

  // ------------------ VISTA REGISTRAR DIRECCIÓN ------------------
  Widget _vistaRegistrarDireccion() {
    return _fondoGradiente(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hola, ${_nombreUsuario ?? "Usuario"}",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                "Necesitamos tu dirección para enviarte un profesional",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              glassCard(
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: direccionCtrl,
                  googleAPIKey: kGoogleApiKey,
                  debounceTime: 800,
                  countries: ["ar"],
                  isLatLngRequired: true,
                  inputDecoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Buscar dirección...",
                    hintStyle: Theme.of(context).textTheme.bodyMedium,
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF14B8A6)),
                  ),
                  getPlaceDetailWithLatLng: (Prediction p) {
                    if (p.lat != null && p.lng != null) {
                      setState(() {
                        selectedLocation = LatLng(
                          double.parse(p.lat!),
                          double.parse(p.lng!),
                        );
                      });
                      mapController.animateCamera(
                        CameraUpdate.newLatLngZoom(selectedLocation!, 16),
                      );
                    }
                  },
                  itemClick: (Prediction p) {
                    direccionCtrl.text = p.description ?? "";
                    direccionCtrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: direccionCtrl.text.length),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 150,
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: selectedLocation ??
                          const LatLng(-34.6037, -58.3816),
                      zoom: selectedLocation != null ? 16 : 14,
                    ),
                    markers: selectedLocation != null
                        ? {
                            Marker(
                                markerId: const MarkerId("sel"),
                                position: selectedLocation!)
                          }
                        : {},
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _campo("Piso", pisoCtrl),
              _campo("Depto", deptoCtrl),
              _campo("Indicaciones (ej: timbre, referencia)", indicacionesCtrl),
              _campo("Teléfono de contacto", telefonoCtrl),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: guardarDireccion,
                  child: const Text(
                    "Confirmar dirección",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: glassCard(
        child: TextField(
          controller: controller,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: Theme.of(context).textTheme.bodyMedium,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // ------------------ VISTA HOME PRINCIPAL ------------------
  Widget _vistaHomePrincipal() {
    return _fondoGradiente(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hola, ${_nombreUsuario ?? "Usuario"}, ¿qué necesitás hoy?",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Botón principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () {
                    if (selectedLocation != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FiltroMedicoScreen(
                            direccion: direccionCtrl.text,
                            ubicacion: selectedLocation!,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("❌ Seleccioná una ubicación primero"),
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.local_hospital,
                          color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        "Solicitar médico ahora",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Dirección guardada
              glassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF14B8A6),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.location_on, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(direccionCtrl.text,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text("Piso: ${pisoCtrl.text} - Depto: ${deptoCtrl.text}",
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => tieneDireccion = false),
                      child: const Text("Cambiar",
                          style: TextStyle(
                              color: Color(0xFF14B8A6),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 150,
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: selectedLocation ??
                          const LatLng(-34.6037, -58.3816),
                      zoom: selectedLocation != null ? 16 : 14,
                    ),
                    markers: selectedLocation != null
                        ? {
                            Marker(
                                markerId: const MarkerId("sel"),
                                position: selectedLocation!)
                          }
                        : {},
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Atajos
              Row(
                children: [
                  Expanded(
                    child: _serviceTile(
                      Icons.vaccines,
                      "Enfermero",
                      onTap: () {
                        if (selectedLocation != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SolicitudEnfermeroScreen(
                                direccion: direccionCtrl.text,
                                ubicacion: selectedLocation!,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("❌ Seleccioná una ubicación primero"),
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: _serviceTile(Icons.emergency, "Emergencia",
                        color: Colors.redAccent, onTap: () async {
                      final Uri callUri = Uri(scheme: 'tel', path: '911');
                      if (await canLaunchUrl(callUri)) {
                        await launchUrl(callUri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("❌ No se pudo iniciar la llamada")),
                        );
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Beneficios
              Row(
                children: [
                  Expanded(child: _benefitTile(Icons.flash_on, "Atención rápida")),
                  const SizedBox(width: 12),
                  Expanded(child: _benefitTile(Icons.verified_user, "Pago seguro")),
                  const SizedBox(width: 12),
                  Expanded(child: _benefitTile(Icons.star, "Médicos calificados")),
                ],
              ),
              const SizedBox(height: 24),

              Text("Noticias de salud",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),

              glassCard(
                minHeight: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("💉 Campaña contra el dengue",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      "Ya comenzó la vacunación contra el dengue. Consultá a tu médico.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              glassCard(
                minHeight: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🩺 Chequeos anuales",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      "No olvides hacerte un control clínico una vez al año.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ Tiles ------------------
  Widget _serviceTile(IconData icon, String title,
      {VoidCallback? onTap, Color color = const Color(0xFF14B8A6)}) {
    return glassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _benefitTile(IconData icon, String title) {
    final color = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return glassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  // 🔹 Fondo gradiente global
  Widget _fondoGradiente({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) {
      return Container(color: const Color(0xFFF5F5F5), child: child);
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }

  // ------------------ BUILD ------------------
  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        title: Image.asset("assets/logoblanco.png", height: 36),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            onPressed: widget.onToggleTheme, // 👈 alterna el tema
          ),
        ],
      ),
      body: () {
        if (!tieneDireccion) return _vistaRegistrarDireccion();

        switch (_selectedIndex) {
          case 0:
            return _vistaHomePrincipal();
          case 1:
            return const RecetasScreen();
          case 2:
            return ConsultasScreen(pacienteUuid: _userId ?? "");
          case 3:
            return PerfilScreen(userId: _userId ?? "");
          default:
            return _vistaHomePrincipal();
        }
      }(),
      bottomNavigationBar: bottomNav(_selectedIndex, (i) {
        setState(() => _selectedIndex = i);
      }),
    );
  }
}
