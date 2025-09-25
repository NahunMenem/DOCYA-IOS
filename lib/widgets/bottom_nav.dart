import 'dart:ui';
import 'package:flutter/material.dart';

Widget bottomNav(int selectedIndex, Function(int) onTap) {
  return ClipRRect(
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    ),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F2027).withOpacity(0.9), // azul oscuro
              const Color(0xFF203A43).withOpacity(0.9), // intermedio
              const Color(0xFF2C5364).withOpacity(0.9), // teal oscuro
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, // 👈 transparente para mostrar gradiente
          elevation: 0,
          currentIndex: selectedIndex,
          onTap: onTap,
          selectedItemColor: const Color(0xFF14B8A6), // Verde DocYa
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Recetas"),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Historia"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          ],
        ),
      ),
    ),
  );
}
