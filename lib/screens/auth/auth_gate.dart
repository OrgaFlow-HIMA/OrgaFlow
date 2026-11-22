import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../dashboard/dashboard_page.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';

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
  bool _showWelcome = true;
  bool _showRegister = false;
  bool _isJustRegistered = false;
  bool _ignoreAuthChanges = false; // FLAG UNTUK MENCEGAH GLITCH SAAT REGISTER
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
        debugPrint(
          '[OrgaFlow AuthGate] Akun nonaktif/pending: ${profile.statusAkun}',
        );
        final isPending = profile.isPending;
        final errorMsg = isPending
            ? 'Akun Anda (${profile.email}) sedang menunggu persetujuan dari Sekretaris. Anda akan dapat masuk setelah akun diverifikasi.'
            : profile.isRejected
            ? 'Pendaftaran akun Anda ditolak oleh Sekretaris${profile.catatanPersetujuan != null ? ': ${profile.catatanPersetujuan}' : '.'}'
            : 'Akun Anda sedang tidak aktif (${profile.statusAkun}). Silakan hubungi pengurus.';
        await _authService.signOut();
        if (mounted) {
          setState(() {
            _cachedProfile = null;
            _isJustRegistered = false;
            _sessionErrorMessage = errorMsg;
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
          _isJustRegistered = false;
          _showWelcome = false;
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
        // Jika sedang mendaftar dan user tiba-tiba login (karena proses register),
        // abaikan perubahan auth agar SnackBar sukses bisa tampil tanpa glitch.
        if (_ignoreAuthChanges && _showRegister) {
          return RegisterScreen(
            key: const ValueKey('register_screen_ignored'),
            authService: _authService,
            onBackToLogin: () {
              setState(() {
                _showRegister = false;
                _ignoreAuthChanges = false;
              });
            },
            onRegisterSuccess: () {}, // Do nothing
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedProfile == null &&
            _showWelcome) {
          return _buildLoadingScreen();
        }

        final user = snapshot.data;

        if (user == null) {
          _cachedProfile = null;

          if (_showWelcome) {
            return WelcomeScreen(
              key: const ValueKey('welcome_screen'),
              onContinue: () => setState(() => _showWelcome = false),
            );
          }

          if (_showRegister) {
            return RegisterScreen(
              key: const ValueKey('register_screen'),
              authService: _authService,
              onBackToLogin: () {
                setState(() {
                  _showRegister = false;
                  _ignoreAuthChanges = false;
                });
              },
              onRegisterSuccess: () {
                // Set flag agar AuthGate mengabaikan perubahan auth sementara
                setState(() => _ignoreAuthChanges = true);
              },
            );
          }

          return LoginScreen(
            key: const ValueKey('login_screen'),
            authService: _authService,
            initialErrorMessage: _sessionErrorMessage,
            onBack: () {
              setState(() {
                _showWelcome = true;
                _sessionErrorMessage = null;
                _isJustRegistered = false;
              });
            },
            onNavigateToRegister: () {
              setState(() {
                _showRegister = true;
                _sessionErrorMessage = null;
                _isJustRegistered = false;
              });
            },
            onLoginSuccess: (profile) {
              setState(() {
                _cachedProfile = profile;
                _sessionErrorMessage = null;
                _isJustRegistered = false;
              });
            },
          );
        }

        // Pengguna login (dari proses register atau login biasa), tapi profil belum dimuat
        if (_cachedProfile == null || _cachedProfile!.uid != user.uid) {
          if (!_isLoadingProfile) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadProfileForUser(user);
            });
          }

          // Jika baru selesai register, jangan tampilkan loading screen
          if (_isJustRegistered) {
            return LoginScreen(
              key: const ValueKey('login_screen_after_register'),
              authService: _authService,
              initialErrorMessage: _sessionErrorMessage,
              onBack: () {
                setState(() {
                  _showWelcome = true;
                  _sessionErrorMessage = null;
                  _isJustRegistered = false;
                });
              },
              onNavigateToRegister: () {
                setState(() {
                  _showRegister = true;
                  _sessionErrorMessage = null;
                  _isJustRegistered = false;
                });
              },
              onLoginSuccess: (profile) {
                setState(() {
                  _cachedProfile = profile;
                  _sessionErrorMessage = null;
                  _isJustRegistered = false;
                });
              },
            );
          }

          return _buildLoadingScreen(key: const ValueKey('loading_screen'));
        }

        final profile = _cachedProfile!;

        return DashboardPage(
          key: const ValueKey('dashboard_page'),
          profile: profile,
          authService: _authService,
        );
      },
    );
  }

  Widget _buildLoadingScreen({Key? key}) {
    return Scaffold(
      key: key,
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
