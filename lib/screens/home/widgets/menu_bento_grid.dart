import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MenuBentoGrid extends StatelessWidget {
  final ValueChanged<int> onSelectMenu;

  const MenuBentoGrid({
    super.key,
    required this.onSelectMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Pembelajaran',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14),

        // Menu Simulasi (Index 1)
        _buildMenuItemCard(
          icon: Icons.science_outlined,
          title: 'Simulasi',
          description: 'Eksperimen interaktif dan simulasi terarah konsep sains dan materi.',
          onTap: () => onSelectMenu(1),
        ),

        const SizedBox(height: 12),

        // Menu Tryout (Index 2)
        _buildMenuItemCard(
          icon: Icons.assignment_outlined,
          title: 'Tryout',
          description: 'Latihan bank soal berkala, simulasi ujian, dan evaluasi berkala.',
          onTap: () => onSelectMenu(2),
        ),

        const SizedBox(height: 12),

        // Menu Minigames (Index 3)
        _buildMenuItemCard(
          icon: Icons.sports_esports_outlined,
          title: 'Minigames',
          description: 'Kuis edukasi gamifikasi santai, tantangan literasi, dan asah logika.',
          onTap: () => onSelectMenu(3),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

