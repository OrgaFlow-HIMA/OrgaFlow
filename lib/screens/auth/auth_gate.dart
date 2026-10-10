import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../dashboard/management_dashboard.dart';
import '../dashboard/member_dashboard.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  final AuthService? authService;
  final UserService? userService;

  const AuthGate({super.key, this.authService, this.userService});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService;
  late final UserService _userService;

  UserProfile? _cachedProfile;
  bool _isLoadingProfile = false;
  String? _sessionErrorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _userService = widget.userService ?? UserService();
  }

  Future<void> _loadProfileForUser(User user) async {
    setState(() {
      _isLoadingProfile = true;
      _sessionErrorMessage = null;
    });

    try {
      debugPrint(
        '[OrgaFlow AuthGate] Memeriksa profil untuk UID: ${user.uid} (${user.email})',
      );
      final profile = await _userService.getUserProfile(
        user.uid,
        email: user.email,
      );

      if (!mounted) return;

      if (profile == null) {
        debugPrint('[OrgaFlow AuthGate] Profil tidak ditemukan di Firestore!');
        final errorMsg =
            'Akun ${user.email} berhasil login ke Auth, namun data profil belum dibuat di Firestore '
            '(collection: "users", Document ID: "${user.uid}"). Pastikan Document ID sama dengan User UID ini.';
        await _authService.signOut();
        if (mounted) {
          setState(() {
            _cachedProfile = null;
            _sessionErrorMessage = errorMsg;
          });
        }
        return;
      }

      if (!profile.isActive) {
        debugPrint('[OrgaFlow AuthGate] Akun nonaktif: ${profile.statusAkun}');
        await _authService.signOut();
        if (mounted) {
          setState(() {
            _cachedProfile = null;
            _sessionErrorMessage =
                'Akun Anda sedang tidak aktif (${profile.statusAkun}). Silakan hubungi pengurus.';
          });
        }
        return;
      }

      debugPrint(
        '[OrgaFlow AuthGate] Profil valid! Role: ${profile.role.label}',
      );
      if (mounted) {
        setState(() {
          _cachedProfile = profile;
        });
      }
    } on InvalidRoleException catch (e) {
      debugPrint('[OrgaFlow AuthGate] InvalidRoleException: $e');
      await _authService.signOut();
      if (mounted) {
        setState(() {
          _cachedProfile = null;
          _sessionErrorMessage =
              'Role akun tidak valid. Hubungi pengurus HIMA TI.';
        });
      }
    } catch (e) {
      debugPrint('[OrgaFlow AuthGate] Error saat load profile: $e');
      final errorClean = e.toString().replaceFirst('Exception: ', '');
      await _authService.signOut();
      if (mounted) {
        setState(() {
          _cachedProfile = null;
          _sessionErrorMessage = errorClean;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Menunggu koneksi stream awal
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedProfile == null) {
          return _buildLoadingScreen();
        }

        final user = snapshot.data;

        // Pengguna belum login
        if (user == null) {
          _cachedProfile = null;
          return LoginScreen(
            authService: _authService,
            initialErrorMessage: _sessionErrorMessage,
            onLoginSuccess: (profile) {
              setState(() {
                _cachedProfile = profile;
                _sessionErrorMessage = null;
              });
            },
          );
        }

        // Pengguna login, tetapi profil belum dimuat atau berbeda sesi
        if (_cachedProfile == null || _cachedProfile!.uid != user.uid) {
          if (!_isLoadingProfile) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadProfileForUser(user);
            });
          }
          return _buildLoadingScreen();
        }

        final profile = _cachedProfile!;

        // Skenario 1: Wajib Ganti Password pada login pertama
        if (profile.wajibGantiPassword) {
          return ChangePasswordScreen(
            profile: profile,
            authService: _authService,
            onSuccess: () {
              // Muat ulang profil dari database untuk memastikan wajib_ganti_password sudah false
              _loadProfileForUser(user);
            },
          );
        }

        // Skenario 2: Role Pengurus (Ketua, Wakil Ketua, Sekretaris, Bendahara, Kepala Divisi)
        if (profile.role.isPengurus) {
          return ManagementDashboard(
            profile: profile,
            authService: _authService,
          );
        }

        // Skenario 3: Role Anggota
        if (profile.role.isAnggota) {
          return MemberDashboard(profile: profile, authService: _authService);
        }

        // Fallback keamanan jika role di luar ketentuan
        return LoginScreen(
          authService: _authService,
          initialErrorMessage: _sessionErrorMessage,
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Memeriksa status sesi organisasi...',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
              ),
            ),
            if (_sessionErrorMessage != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _sessionErrorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
