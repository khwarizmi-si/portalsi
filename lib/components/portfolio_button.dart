// lib/components/portfolio_button.dart

import 'package:flutter/material.dart';

class PortfolioButton extends StatelessWidget {
  final VoidCallback onTap;

  const PortfolioButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFF9E7), // Kuning sangat muda (mirip background)
              Color(0xFFFFE6B5), // Kuning lebih gelap
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo Sekolah Impian
            Image.asset(
              'assets/logo_sekolah.png', // <-- GANTI DENGAN PATH LOGO ANDA
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Portfolio Santri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Lihat portfolio santri Sekolah Impian',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.black87,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}