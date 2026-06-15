import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../features/formatter/presentation/providers/json_formatter_provider.dart';
import '../../features/formatter/presentation/widgets/json_editor_widget.dart';
import '../../features/formatter/presentation/widgets/statistics_panel.dart';
import '../../features/tree_view/presentation/widgets/json_tree_viewer_widget.dart';
import '../../features/compare/presentation/widgets/json_compare_screen.dart';
import '../../features/converter/presentation/widgets/converters_screen.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import '../../features/settings/presentation/widgets/settings_dialog.dart';

class MainDashboardScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const MainDashboardScreen({super.key, required this.initialTab});

  @override
  ConsumerState<MainDashboardScreen> createState() =>
      _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _desktopRightTabController;
  late TabController _mobileTabController;
  int _activeDashboardView = 0; // 0 = Editor, 1 = Compare, 2 = Converters

  @override
  void initState() {
    super.initState();
    _desktopRightTabController = TabController(length: 2, vsync: this);
    _mobileTabController = TabController(length: 4, vsync: this);
    _activeDashboardView = widget.initialTab;
  }

  @override
  void dispose() {
    _desktopRightTabController.dispose();
    _mobileTabController.dispose();
    super.dispose();
  }

  void _showSettings() {
    showDialog(context: context, builder: (context) => const SettingsDialog());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    // Responsive design decision
    final bool isTablet = size.width >= 768 && size.width <= 1200;
    final bool isMobile = size.width < 768;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: _buildHeader(isDark, isMobile),
      body: SafeArea(
        child: Column(
          children: [
            // Responsive content body
            Expanded(
              child: isMobile
                  ? _buildMobileLayout(isDark)
                  : _buildDesktopLayout(isDark, isTablet, borderColor),
            ),

            // Status Bar at the bottom
            _buildStatusBar(isDark, borderColor),
          ],
        ),
      ),
    );
  }

  // --- HEADER WIDGET ---
  PreferredSizeWidget _buildHeader(bool isDark, bool isMobile) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/logo.png',
            width: 28,
            height: 28,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'JSON Formatter Pro',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.lightPrimaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'PRO',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Mode Switches (only for Desktop & Tablet)
        if (!isMobile) ...[
          _buildViewButton(0, 'Editor', Icons.edit_note),
          _buildViewButton(1, 'Compare', Icons.difference),
          _buildViewButton(2, 'Converters', Icons.transform),
          const SizedBox(width: 12),
          VerticalDivider(
            width: 1,
            indent: 12,
            endIndent: 12,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(width: 12),
        ],
        IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          tooltip: 'Toggle Theme',
          onPressed: () {
            final settingsNotifier = ref.read(settingsProvider.notifier);
            final currentTheme = ref.read(settingsProvider).themeMode;
            settingsNotifier.setThemeMode(
              currentTheme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: _showSettings,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
    );
  }

  Widget _buildViewButton(int index, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _activeDashboardView == index;

    final activeColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        icon: Icon(
          icon,
          size: 16,
          color: isActive
              ? activeColor
              : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
        ),
        label: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive
                ? activeColor
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
          ),
        ),
        onPressed: () {
          setState(() {
            _activeDashboardView = index;
          });
        },
        style: TextButton.styleFrom(
          backgroundColor: isActive
              ? activeColor.withValues(alpha: 0.08)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  // --- DESKTOP LAYOUT ---
  Widget _buildDesktopLayout(bool isDark, bool isTablet, Color borderColor) {
    switch (_activeDashboardView) {
      case 1:
        return const JsonCompareScreen();
      case 2:
        return const ConvertersScreen();
      case 0:
      default:
        return Row(
          children: [
            // Left Pane: Raw Editor Input
            const Expanded(
              child: JsonEditorWidget(title: 'Input JSON', isReadOnly: false),
            ),
            VerticalDivider(width: 1, color: borderColor),
            // Right Pane: Output switcher (Formatted / Tree)
            Expanded(
              child: Container(
                color: isDark ? AppColors.darkSurface : Colors.white,
                child: Column(
                  children: [
                    // Tab controller row
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightPrimaryContainer.withValues(
                                alpha: 0.5,
                              ),
                        border: Border(bottom: BorderSide(color: borderColor)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TabBar(
                              controller: _desktopRightTabController,
                              indicatorColor: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                              labelColor: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                              unselectedLabelColor: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              labelStyle: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              tabs: const [
                                Tab(text: 'Formatted Output'),
                                Tab(text: 'JSON Tree Viewer'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            tooltip: 'Format Pretty JSON',
                            onPressed: () => ref
                                .read(jsonFormatterProvider.notifier)
                                .format(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.compress, size: 18),
                            tooltip: 'Minify JSON',
                            onPressed: () => ref
                                .read(jsonFormatterProvider.notifier)
                                .minify(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_all, size: 18),
                            tooltip: 'Load Sample JSON',
                            onPressed: () => ref
                                .read(jsonFormatterProvider.notifier)
                                .loadDemo(),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _desktopRightTabController,
                        physics:
                            const NeverScrollableScrollPhysics(), // Prevent swipe inside editor
                        children: const [
                          JsonEditorWidget(
                            title: 'Formatted JSON',
                            isReadOnly: true,
                          ),
                          JsonTreeViewerWidget(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sidebar: Statistics panel (Hidden on small tablets for responsiveness)
            if (!isTablet) ...[
              VerticalDivider(width: 1, color: borderColor),
              const StatisticsPanel(),
            ],
          ],
        );
    }
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        // Tab header
        TabBar(
          controller: _mobileTabController,
          indicatorColor: isDark
              ? AppColors.darkPrimary
              : AppColors.lightPrimary,
          labelColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          labelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          tabs: const [
            Tab(text: 'Input'),
            Tab(text: 'Output'),
            Tab(text: 'Tree'),
            Tab(text: 'Compare'),
          ],
        ),
        // Tab views
        Expanded(
          child: TabBarView(
            controller: _mobileTabController,
            children: const [
              JsonEditorWidget(title: 'Input JSON', isReadOnly: false),
              JsonEditorWidget(title: 'Formatted Output', isReadOnly: true),
              JsonTreeViewerWidget(),
              JsonCompareScreen(),
            ],
          ),
        ),
      ],
    );
  }

  // --- STATUS BAR ---
  Widget _buildStatusBar(bool isDark, Color borderColor) {
    final formatterState = ref.watch(jsonFormatterProvider);
    final settings = ref.watch(settingsProvider);

    final isValid = formatterState.validationResult.isValid;
    final msg = formatterState.validationResult.errorMessage;
    final line = formatterState.validationResult.line;
    final col = formatterState.validationResult.column;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF070B14) : const Color(0xFFF1F5F9),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Validation Status Badge
          if (formatterState.rawInput.trim().isEmpty)
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Waiting for JSON input',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            )
          else if (isValid)
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Valid JSON',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Invalid JSON: $msg (Line $line, Col $col)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Spacing index Info
          Text(
            settings.indentSize == 1
                ? 'Spaces: Tab'
                : 'Spaces: ${settings.indentSize}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 16),
          // Character count
          Text(
            'Chars: ${formatterState.rawInput.length}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
