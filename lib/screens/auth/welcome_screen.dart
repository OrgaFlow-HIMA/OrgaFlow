import 'package:flutter/material.dart';
import 'package:flutter_orgaflow/core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    // Sesuaikan dengan warna background gambar ilustrasi
    final Color topBackgroundColor = const Color(0xFFE5E5FA);

    return Scaffold(
      backgroundColor: topBackgroundColor,
      body: Stack(
        children: [
          // 1. GAMBAR ILUSTRASI (Sebagai Background Utama)
          Positioned.fill(
            bottom:
                MediaQuery.of(context).size.height *
                0.4, // Sisakan ruang di bawah
            child: Image.asset(
              'assets/images/illustration-welcome.webp',
              fit: BoxFit.cover,
              alignment: const Alignment(0.0, -0.2), // Sedikit diturunkan
            ),
          ),

          // 3. CONTAINER PUTIH (Overlap menimpa gambar)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height:
                  MediaQuery.of(context).size.height *
                  0.50, // Ambil 45% layar bagian bawah
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                // --- SHADOW HALUS ---
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.08,
                    ), // Warna hitam transparan
                    blurRadius: 20, // Tingkat kehalusan bayangan
                    spreadRadius: 2, // Sedikit melebar
                    offset: const Offset(0, -5), // Bayangan mengarah ke atas
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        SizedBox(height: 36),
                        // --- JUDUL ---
                        const Text(
                          'Kelola Organisasi\nJadi Lebih Mudah',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- DESKRIPSI ---
                        const Text(
                          'Bangun kolaborasi, kelola anggota, dan koordinasikan kegiatan organisasi dalam satu aplikasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 90),

                    // --- TOMBOL MULAI SEKARANG ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Mulai Sekarang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
