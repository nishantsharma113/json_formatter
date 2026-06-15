import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/json_formatter_provider.dart';

class StatisticsPanel extends ConsumerWidget {
  const StatisticsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatterState = ref.watch(jsonFormatterProvider);
    final stats = formatterState.stats;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBorder = BorderSide(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'JSON Statistics',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildStatCard(
                  context,
                  title: 'File Size',
                  value: '${stats.fileSizeKb.toStringAsFixed(2)} KB',
                  icon: Icons.data_usage,
                  color: AppColors.info,
                  borderSide: cardBorder,
                ),
                _buildStatCard(
                  context,
                  title: 'Total Lines',
                  value: '${stats.linesCount}',
                  icon: Icons.format_list_numbered,
                  color: isDark
                      ? AppColors.darkSecondary
                      : AppColors.lightSecondary,
                  borderSide: cardBorder,
                ),
                _buildStatCard(
                  context,
                  title: 'Characters',
                  value: '${stats.charactersCount}',
                  icon: Icons.text_fields,
                  color: Colors.blueGrey,
                  borderSide: cardBorder,
                ),
                _buildStatCard(
                  context,
                  title: 'Objects Count',
                  value: '${stats.objectsCount}',
                  icon: Icons.data_object,
                  color: AppColors.success,
                  borderSide: cardBorder,
                ),
                _buildStatCard(
                  context,
                  title: 'Arrays Count',
                  value: '${stats.arraysCount}',
                  icon: Icons.view_headline,
                  color: AppColors.warning,
                  borderSide: cardBorder,
                ),
                _buildStatCard(
                  context,
                  title: 'Keys Count',
                  value: '${stats.keysCount}',
                  icon: Icons.vpn_key,
                  color: Colors.pink,
                  borderSide: cardBorder,
                ),
                _buildStatCard(
                  context,
                  title: 'Max Nesting Depth',
                  value: '${stats.maxDepth}',
                  icon: Icons.unfold_more,
                  color: Colors.deepPurple,
                  borderSide: cardBorder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BorderSide borderSide,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.4)
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderSide.color),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
