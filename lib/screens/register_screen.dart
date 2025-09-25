import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'terminos_screen.dart';

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
    // Colores e íconos por tipo
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _dni = TextEditingController();
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _pais;
  String? _provincia;
  String? _localidad;
  DateTime? _fechaNacimiento;
  bool _aceptaCondiciones = false;

  bool _loading = false;
  String? _error;
  final _auth = AuthService();

  final List<String> _paises = ["Argentina"];

  final Map<String, List<String>> _provincias = {
    "Argentina": [
      "CABA", "Buenos Aires", "Catamarca", "Chaco", "Chubut", "Córdoba",
      "Corrientes", "Entre Ríos", "Formosa", "Jujuy", "La Pampa",
      "La Rioja", "Mendoza", "Misiones", "Neuquén", "Río Negro",
      "Salta", "San Juan", "San Luis", "Santa Cruz", "Santa Fe",
      "Santiago del Estero", "Tierra del Fuego", "Tucumán"
    ]
  };

  final Map<String, List<String>> _localidades = {
    "CABA": ["Almagro", "Belgrano", "Boedo", "Palermo", "Recoleta", "San Telmo"],
    "Buenos Aires": ["La Plata", "Mar del Plata"],
    "Córdoba": ["Córdoba Capital", "Villa Carlos Paz"],
    "Santa Fe": ["Rosario", "Santa Fe Capital"],
    "Mendoza": ["Mendoza Capital", "San Rafael"],
    "La Rioja": ["La Rioja Capital", "Chilecito"],
    "Salta": ["Salta Capital", "Orán"],
  };

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pais == null ||
        _provincia == null ||
        _localidad == null ||
        _fechaNacimiento == null ||
        !_aceptaCondiciones) {
      setState(() => _error = "Completa todos los campos y acepta los términos");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final fechaIso = _fechaNacimiento!.toIso8601String().split("T").first;

    final result = await _auth.register(
      _name.text.trim(),
      _email.text.trim(),
      _password.text.trim(),
      dni: _dni.text.trim(),
      telefono: _phone.text.trim(),
      pais: _pais!,
      provincia: _provincia!,
      localidad: _localidad!,
      fechaNacimiento: fechaIso,
      aceptoCondiciones: _aceptaCondiciones,
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (result["ok"] == true) {
      Navigator.pop(context);
      DocYaSnackbar.show(
        context,
        title: "🎉 Registro exitoso",
        message: result["mensaje"] ??
            "Tu cuenta fue creada. Revisa tu correo para activarla.",
        type: SnackType.success,
      );
    } else {
      DocYaSnackbar.show(
        context,
        title: "⚠️ Error",
        message: result["detail"] ?? "No se pudo registrar.",
        type: SnackType.error,
      );
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: const Color(0xFF14B8A6)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Image.asset("assets/logoblanco.png", height: 80),
                          const SizedBox(height: 16),
                          const Text(
                            "Regístrate en DocYa",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 24),

                          TextFormField(
                            controller: _name,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle("Nombre y apellido", Icons.person),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _dni,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle("DNI / Pasaporte", Icons.badge),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _phone,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle("Teléfono", Icons.phone_android),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            value: _pais,
                            dropdownColor: const Color(0xFF203A43),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle("País", Icons.public),
                            items: _paises
                                .map((p) =>
                                    DropdownMenuItem(value: p, child: Text(p)))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _pais = val;
                                _provincia = null;
                                _localidad = null;
                              });
                            },
                            validator: (v) =>
                                v == null ? "Selecciona un país" : null,
                          ),
                          const SizedBox(height: 16),

                          if (_pais != null)
                            DropdownButtonFormField<String>(
                              value: _provincia,
                              dropdownColor: const Color(0xFF203A43),
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputStyle("Provincia", Icons.map),
                              items: (_provincias[_pais] ?? [])
                                  .map((prov) => DropdownMenuItem(
                                      value: prov, child: Text(prov)))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _provincia = val;
                                  _localidad = null;
                                });
                              },
                              validator: (v) =>
                                  v == null ? "Selecciona una provincia" : null,
                            ),
                          if (_pais != null) const SizedBox(height: 16),

                          if (_provincia != null)
                            DropdownButtonFormField<String>(
                              value: _localidad,
                              dropdownColor: const Color(0xFF203A43),
                              style: const TextStyle(color: Colors.white),
                              decoration:
                                  _inputStyle("Localidad", Icons.location_city),
                              items: (_localidades[_provincia] ?? [])
                                  .map((loc) => DropdownMenuItem(
                                      value: loc, child: Text(loc)))
                                  .toList(),
                              onChanged: (val) => setState(() => _localidad = val),
                              validator: (v) =>
                                  v == null ? "Selecciona una localidad" : null,
                            ),
                          if (_provincia != null) const SizedBox(height: 16),

                          TextFormField(
                            readOnly: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle(
                                "Fecha de nacimiento", Icons.calendar_today),
                            controller: TextEditingController(
                              text: _fechaNacimiento == null
                                  ? ""
                                  : "${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}",
                            ),
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                locale: const Locale("es", "ES"),
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _fechaNacimiento = picked);
                              }
                            },
                            validator: (_) => _fechaNacimiento == null
                                ? "Selecciona tu fecha de nacimiento"
                                : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _email,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle("Email", Icons.email),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requerido';
                              if (!v.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _password,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle("Contraseña", Icons.lock),
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _confirm,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle(
                                "Confirmar contraseña", Icons.check_circle),
                            obscureText: true,
                            validator: (v) =>
                                v != _password.text ? 'No coincide' : null,
                          ),
                          const SizedBox(height: 16),

                          CheckboxListTile(
                            value: _aceptaCondiciones,
                            activeColor: const Color(0xFF14B8A6),
                            onChanged: (val) =>
                                setState(() => _aceptaCondiciones = val ?? false),
                            title: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    "Acepto los Términos y Condiciones",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.white70),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const TerminosScreen()),
                                    );
                                  },
                                  child: const Text(
                                    "Ver",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF14B8A6),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                          ],

                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF14B8A6),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Crear cuenta",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "¿Ya tienes cuenta? Inicia sesión",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
