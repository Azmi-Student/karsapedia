import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/bento_fetch_builder.dart';
import '../widgets/menu_bento_grid.dart';
import '../widgets/recommendation_hero_card.dart';

class BerandaTab extends StatelessWidget {
  final UserModel initialUser;
  final dynamic refreshTrigger;
  final ValueChanged<int> onNavigateToTab;

  const BerandaTab({
    super.key,
    required this.initialUser,
    required this.refreshTrigger,
    required this.onNavigateToTab,
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
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hi, Nama & Subtitle Deskripsi
              _buildHeader(user),

              const SizedBox(height: 24),

              // 2. Card Berupa Rekomendasi (Frosted Glass Card)
              RecommendationHeroCard(
                onAction: () => onNavigateToTab(2),
              ),

              const SizedBox(height: 24),

              // 3. Card Menu Pembelajaran: Simulasi, Tryout, Minigames
              MenuBentoGrid(
                onSelectMenu: onNavigateToTab,
              ),

              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, ${user.name}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Selamat datang di platform belajar interaktif Karsapedia.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

