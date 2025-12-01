import 'package:flutter/material.dart';

class TeammyLogo extends StatelessWidget {
  const TeammyLogo({super.key, this.size = 68, this.textColor});

  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4E6FFB),
                Color(0xFF4BD2B0),
              ],
            ),
          ),
          child: const Center(
            child: Text(
              'T',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Teammy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor ?? const Color(0xFF1C2954),
          ),
        ),
      ],
    );
  }
}
