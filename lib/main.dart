import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// 📌 Screens existentes
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// 📌 Nuevas screens
import 'screens/solicitud_medico_screen.dart';
import 'screens/MedicoEnCaminoScreen.dart'; // 👈 asegúrate de importar tu screen

// 🔔 Notificaciones
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/chat_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data["tipo"] == "nuevo_mensaje") {
    print("📩 Mensaje en background (paciente): ${message.data}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const DocYaApp());
}

class DocYaApp extends StatefulWidget {
  const DocYaApp({super.key});

  @override
  State<DocYaApp> createState() => _DocYaAppState();
}

class _DocYaAppState extends State<DocYaApp> {
  bool darkMode = true; // 👈 Arranca en oscuro, podés poner false para claro

  // 🔔 setup handlers
  @override
  void initState() {
    super.initState();
    _setupPushHandlersPaciente();
  }

  void _setupPushHandlersPaciente() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data["tipo"] == "nuevo_mensaje") {
        final consultaId = int.tryParse(message.data["consulta_id"] ?? "0");
        if (consultaId != null && consultaId > 0) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(content: Text("💬 Nuevo mensaje en la consulta $consultaId")),
          );
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data["tipo"] == "nuevo_mensaje") {
        final consultaId = int.tryParse(message.data["consulta_id"] ?? "0");
        final remitenteId = message.data["remitente_id"] ?? "";
        if (consultaId != null && consultaId > 0) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                consultaId: consultaId,
                remitenteTipo: "paciente",
                remitenteId: remitenteId, // ⚠️ reemplazar por el UUID del login
              ),
            ),
          );
        }
      }
    });
  }

  // 🔹 Tema claro (blanco clínico)
  final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF14B8A6),
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF14B8A6)),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
  );

  // 🔹 Tema oscuro (gradiente + glass)
  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF14B8A6),
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 🔔 necesario para abrir ChatScreen
      title: 'DocYa',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,

      // 🌍 Localización en español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // 🇪🇸 Español
        Locale('en', ''), // 🇬🇧 Inglés (opcional)
      ],

      // 📌 Ruta inicial
      initialRoute: "/login",

      // 📌 Rutas nombradas
      routes: {
        "/login": (context) => const LoginScreen(),

        // ✅ ahora no pasamos nombreUsuario ni userId hardcodeados
        "/home": (context) => HomeScreen(
              nombreUsuario: null,
              userId: null,
              onToggleTheme: () {
                setState(() {
                  darkMode = !darkMode;
                });
              },
            ),

        // 🔹 Pantallas de flujo de consultas
        "/solicitud": (context) => const SolicitudMedicoScreen(
              direccion: "Av. Santa Fe 1234, Palermo",
              ubicacion: LatLng(-34.6037, -58.3816),
            ),

        "/medico_en_camino": (context) => MedicoEnCaminoScreen(
              direccion: "Av. Rivadavia 1234",
              ubicacionPaciente: const LatLng(-34.6037, -58.3816),
              motivo: "Dolor de cabeza",
              medicoId: 1,
              nombreMedico: "Dr. Juan Pérez",
              matricula: "MP12345",
              consultaId: 10,
              pacienteUuid: "1", // ⚠️ después reemplazar por dinámico desde login
            ),
      },
    );
  }
}
