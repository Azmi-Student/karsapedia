import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/minigames_tab.dart';
import 'tabs/profil_tab.dart';
import 'tabs/simulasi_tab.dart';
import 'tabs/tryout_tab.dart';
import 'widgets/floating_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _refreshCounter = 0;

  void _onSelectTab(int index) {
    setState(() {
      _currentIndex = index;
      _refreshCounter++;
    });
  }

  void _onNavigateWithFeedback(int targetIndex, [String? title]) {
    _onSelectTab(targetIndex);
    if (title != null && title.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Membuka menu: $title'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Karsapedia pada perangkat ini?',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final refreshKey = '$_currentIndex-$_refreshCounter';

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Ambient Mesh Glow 1 (Periwinkle di kanan atas)
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE0E7FF).withOpacity(0.55),
                    const Color(0xFFF4F5F6).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Ambient Mesh Glow 2 (Slate halus di kiri tengah)
          Positioned(
            top: 240,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE2E8F0).withOpacity(0.50),
                    const Color(0xFFF4F5F6).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Konten Layar Berdasarkan Tab Aktif
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    // Tab 0: Beranda
                    BerandaTab(
                      initialUser: widget.user,
                      refreshTrigger: refreshKey,
                      onNavigateToTab: (idx) => _onNavigateWithFeedback(idx),
                    ),

                    // Tab 1: Simulasi
                    SimulasiTab(
                      onBackToHome: () => _onSelectTab(0),
                    ),

                    // Tab 2: Tryout
                    TryoutTab(
                      onBackToHome: () => _onSelectTab(0),
                    ),

                    // Tab 3: Minigames
                    MinigamesTab(
                      onBackToHome: () => _onSelectTab(0),
                    ),

                    // Tab 4: Profil
                    ProfilTab(
                      initialUser: widget.user,
                      refreshTrigger: refreshKey,
                      onRefresh: () => _onSelectTab(_currentIndex),
                      onLogout: _handleLogout,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Floating Frosted Glass Bottom Navigation Bar
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _currentIndex,
        onSelectTab: _onSelectTab,
      ),
    );
  }
}
