import 'package:flutter/material.dart';

class RecetasScreen extends StatelessWidget {
  const RecetasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚡ Datos simulados de recetas médicas (mock)
    final List<Map<String, dynamic>> recetas = [
      {
        "fecha": "2025-08-22",
        "especialidad": "Clínica Médica",
        "medico": "Dra. Ana Pérez",
        "medicamentos": ["Paracetamol 500mg cada 8h", "Ibuprofeno 400mg c/12h"],
        "estado": "Activa",
      },
      {
        "fecha": "2025-08-18",
        "especialidad": "Pediatría",
        "medico": "Dr. Juan López",
        "medicamentos": ["Amoxicilina 250mg cada 8h"],
        "estado": "Vencida",
      },
      {
        "fecha": "2025-08-12",
        "especialidad": "Cardiología",
        "medico": "Dr. Martín González",
        "medicamentos": ["Enalapril 10mg diario", "Atorvastatina 20mg nocturna"],
        "estado": "Activa",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Recetas"),
        backgroundColor: const Color(0xFF11B5B0),
        foregroundColor: Colors.white,
      ),
      body: recetas.isEmpty
          ? const Center(
              child: Text(
                "Todavía no tenés recetas médicas",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recetas.length,
              itemBuilder: (context, index) {
                final receta = recetas[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF11B5B0),
                      child: const Icon(Icons.receipt_long,
                          color: Colors.white),
                    ),
                    title: Text(
                      "${receta['especialidad']} - ${receta['medico']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📅 ${receta['fecha']}"),
                        Text(
                            "💊 Medicamentos: ${(receta['medicamentos'] as List).join(', ')}"),
                      ],
                    ),
                    trailing: Text(
                      receta['estado'] ?? "",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: receta['estado'] == "Activa"
                            ? Colors.green
                            : Colors.redAccent,
                      ),
                    ),
                    onTap: () {
                      // 👇 Detalle completo de la receta
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text("Receta - ${receta['especialidad']}"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("👨‍⚕️ Médico: ${receta['medico']}"),
                              Text("📅 Fecha: ${receta['fecha']}"),
                              const SizedBox(height: 10),
                              const Text("💊 Medicamentos:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              ...List.generate(
                                (receta['medicamentos'] as List).length,
                                (i) => Text("- ${receta['medicamentos'][i]}"),
                              ),
                              const SizedBox(height: 10),
                              Text("📌 Estado: ${receta['estado']}"),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cerrar"),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
