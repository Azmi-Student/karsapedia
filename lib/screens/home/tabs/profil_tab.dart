import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/bento_fetch_builder.dart';
import '../widgets/sheets/change_password_sheet.dart';
import '../widgets/sheets/edit_profile_sheet.dart';
import '../widgets/sheets/edit_school_sheet.dart';

class ProfilTab extends StatelessWidget {
  final UserModel initialUser;
  final dynamic refreshTrigger;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const ProfilTab({
    super.key,
    required this.initialUser,
    required this.refreshTrigger,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return BentoFetchBuilder<UserModel>(
      cacheKey: 'current_user_profile',
      autoRefreshInterval: const Duration(seconds: 6),
      refreshTrigger: refreshTrigger,
      fetcher: () async {
        final fresh = await AuthService.getMe();
        return fresh ?? initialUser;
      },
      fromJson: (json) => UserModel.fromJson(Map<String, dynamic>.from(json as Map)),
      toJson: (user) => user.toJson(),
      builder: (context, user, isRefreshing) {
        final schoolName = user.school?.name ?? 'Belum ditentukan';

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Profil Pengguna',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kelola biodata, institusi pendidikan, dan keamanan akun Anda.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // Bento Card 1: Avatar & Identitas
              _buildProfileSummaryCard(user),

              const SizedBox(height: 24),

              // Kelompok 1: AKUN DAN BIODATA
              _buildSectionTitle('AKUN DAN BIODATA'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProfileMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Biodata Diri',
                      subtitle: user.name,
                      caption: user.phoneNumber?.isNotEmpty == true
                          ? user.phoneNumber!
                          : 'Nomor WhatsApp belum diisi',
                      onTap: () {
                        EditProfileSheet.show(
                          context,
                          user: user,
                          onSaved: onRefresh,
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                    _buildProfileMenuItem(
                      icon: Icons.school_outlined,
                      title: 'Asal Sekolah / Institusi',
                      subtitle: schoolName,
                      caption: 'Ketuk untuk mengganti sekolah terdaftar',
                      onTap: () {
                        EditSchoolSheet.show(
                          context,
                          user: user,
                          onSaved: onRefresh,
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                    _buildProfileMenuItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Kata Sandi & Keamanan',
                      subtitle: 'Perbarui kata sandi akun Karsapedia',
                      onTap: () {
                        ChangePasswordSheet.show(context);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Kelompok 2: INFORMASI LAINNYA
              _buildSectionTitle('INFORMASI LAINNYA'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProfileMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Pusat Bantuan & Panduan',
                      subtitle: 'Pertanyaan umum dan kontak dukungan resmi',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pusat Bantuan: Hubungi admin@karsapedia.com untuk bantuan.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                    _buildProfileMenuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Versi Aplikasi',
                      subtitle: 'Karsapedia Mobile v1.0.0 (Build 2026)',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Terbaru',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      onTap: null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tombol Keluar Akun
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: AppTheme.error),
                          SizedBox(width: 8),
                          Text(
                            'Keluar dari Akun',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.username != null && user.username!.isNotEmpty
                      ? '@${user.username} (${user.email})'
                      : user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.success,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? caption,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                ),
                child: Icon(icon, size: 18, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (caption != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  (onTap != null
                      ? const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppTheme.textSecondary,
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

