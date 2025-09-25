import 'package:flutter/material.dart';

class TerminosScreen extends StatelessWidget {
  const TerminosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Términos y Condiciones"),
        backgroundColor: const Color(0xFF14B8A6),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Text(
          """
Consentimiento informado y Términos de uso

Declaro bajo juramento que:

1. He leído y acepto los Términos y Condiciones y la Política de Privacidad de DocYa.  
2. Entiendo que DocYa es una plataforma tecnológica que conecta pacientes con médicos y enfermeros, y que no se responsabiliza por los actos médicos que se realicen durante la atención.  
3. Comprendo que DocYa no brinda servicios de urgencias ni emergencias médicas. En caso de emergencia debo comunicarme al 911 o dirigirme al centro de salud más cercano.  
4. Autorizo a que mis datos personales y de salud sean tratados conforme a la Ley 25.326 de Protección de Datos Personales en Argentina.  
5. Manifiesto haber brindado información cierta y completa en el registro y en los formularios de triage previos a cada consulta.
""",
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
      ),
    );
  }
}
