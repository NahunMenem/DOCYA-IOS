import 'dart:convert';
import 'dart:ui'; // para blur
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final int consultaId;
  final String remitenteTipo; // "paciente" o "profesional"
  final String remitenteId;   // user_id o medico_id

  const ChatScreen({
    super.key,
    required this.consultaId,
    required this.remitenteTipo,
    required this.remitenteId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  WebSocketChannel? _channel;
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _loadHistory();
  }

  void _connectWebSocket() {
    final url =
        "wss://docya-railway-production.up.railway.app/ws/chat/${widget.consultaId}/${widget.remitenteTipo}/${widget.remitenteId}";
    print("🔌 Conectando WS a: $url");

    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen(
      (event) {
        print("📩 WS recibido: $event");
        try {
          final data = jsonDecode(event);
          if (data is Map<String, dynamic>) {
            setState(() => _messages.add(data));
          }
        } catch (e) {
          print("⚠️ Error parseando WS: $e");
        }
      },
      onDone: () {
        print("🔌 WS cerrado, reintentando en 2s...");
        Future.delayed(const Duration(seconds: 2), _connectWebSocket);
      },
      onError: (err) {
        print("❌ Error WS: $err");
      },
    );
  }

  Future<void> _loadHistory() async {
    final url =
        "https://docya-railway-production.up.railway.app/consultas/${widget.consultaId}/chat";
    print("🌐 GET historial: $url");

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      print("📥 Historial recibido: $decoded");

      final List history = (decoded is List) ? decoded : [];
      setState(() {
        _messages.addAll(history.cast<Map<String, dynamic>>());
      });
    } else {
      print("⚠️ Error cargando historial: ${response.statusCode}");
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty || _channel == null) return;

    final msg = {"mensaje": _controller.text.trim()};
    print("📤 Enviando mensaje: $msg");
    _channel!.sink.add(jsonEncode(msg));

    _controller.clear();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Chat de Consulta",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMine =
                      msg["remitente_id"].toString() == widget.remitenteId;

                  return Align(
                    alignment:
                        isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isMine
                                ? const Color(0xFF14B8A6).withOpacity(0.8)
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            msg["mensaje"] ?? "",
                            style: TextStyle(
                              color: isMine ? Colors.white : Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.white.withOpacity(0.15),
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Escribe un mensaje...",
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF14B8A6)),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
