import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConsultasScreen extends StatefulWidget {
  final String pacienteUuid;

  const ConsultasScreen({super.key, required this.pacienteUuid});

  @override
  State<ConsultasScreen> createState() => _ConsultasScreenState();
}

class _ConsultasScreenState extends State<ConsultasScreen> {
  List<dynamic> consultas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistoriaClinica();
  }

  Future<void> _fetchHistoriaClinica() async {
    final url =
        "https://docya-railway-production.up.railway.app/pacientes/${widget.pacienteUuid}/historia_clinica";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          consultas = jsonDecode(response.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Error ${response.statusCode}: no se pudo cargar la historia clínica")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando historia clínica: $e")),
      );
    }
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case "finalizada":
        return Colors.greenAccent;
      case "cancelada":
        return Colors.redAccent;
      case "aceptada":
        return Colors.blueAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
        title: const Text("Mi Historia Clínica"),
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : consultas.isEmpty
                ? const Center(
                    child: Text(
                      "Todavía no tenés consultas registradas",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: consultas.length,
                    itemBuilder: (context, index) {
                      final consulta = consultas[index];

                      // Parseamos historia_clinica si existe
                      Map<String, dynamic>? historia;
                      if (consulta['historia_clinica'] != null) {
                        try {
                          historia = jsonDecode(consulta['historia_clinica']);
                        } catch (_) {
                          historia = null;
                        }
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline marker
                          Column(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _estadoColor(
                                      consulta['estado'] ?? ""),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (index != consultas.length - 1)
                                Container(
                                  width: 2,
                                  height: 140,
                                  color: Colors.white24,
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Card glass
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: Colors.white24, width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Encabezado
                                      Text(
                                        "Consulta #${consulta['consulta_id']}",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Médico: ${consulta['medico'] ?? 'No asignado'}",
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "📅 ${consulta['fecha_consulta']}",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white54),
                                      ),
                                      const Divider(
                                          height: 20, color: Colors.white24),

                                      // Motivo
                                      Text(
                                        "Motivo: ${consulta['motivo'] ?? '-'}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(height: 10),

                                      // Historia clínica si existe
                                      if (historia != null) ...[
                                        const Text("Historia clínica:",
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF14B8A6))),
                                        const SizedBox(height: 6),
                                        if (historia['signos_vitales'] != null) ...[
                                          Text("🫀 TA: ${historia['signos_vitales']['ta']}",
                                              style: const TextStyle(color: Colors.white70)),
                                          Text("💓 FC: ${historia['signos_vitales']['fc']}",
                                              style: const TextStyle(color: Colors.white70)),
                                          Text("🌡️ Temp: ${historia['signos_vitales']['temp']}°C",
                                              style: const TextStyle(color: Colors.white70)),
                                          Text("🫁 SatO2: ${historia['signos_vitales']['sat']}%",
                                              style: const TextStyle(color: Colors.white70)),
                                        ],
                                        if (historia['respiratorio'] != null)
                                          Text("Respiratorio: ${historia['respiratorio']}",
                                              style: const TextStyle(color: Colors.white70)),
                                        if (historia['cardio'] != null)
                                          Text("Cardio: ${historia['cardio']}",
                                              style: const TextStyle(color: Colors.white70)),
                                        if (historia['abdomen'] != null)
                                          Text("Abdomen: ${historia['abdomen']}",
                                              style: const TextStyle(color: Colors.white70)),
                                        if (historia['snc'] != null)
                                          Text("SNC: ${historia['snc']}",
                                              style: const TextStyle(color: Colors.white70)),
                                        if (historia['diagnostico'] != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                              "📋 Diagnóstico: ${historia['diagnostico']}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white)),
                                        ],
                                        if (historia['observacion'] != null &&
                                            historia['observacion']
                                                .toString()
                                                .isNotEmpty)
                                          Text("📝 Observaciones: ${historia['observacion']}",
                                              style: const TextStyle(color: Colors.white70)),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}
