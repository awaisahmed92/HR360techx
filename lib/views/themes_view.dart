import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/brand_themes.dart';
import '../theme/hr_theme.dart';

/// Account Settings → Themes (WebHR-style color circles).
class ThemesView extends StatelessWidget {
  const ThemesView({super.key});

  static const _settingsLinks = [
    'Personal Information',
    'eSignature',
    'Change Password',
    'Notifications',
    'Themes',
    'Additional Information',
    'Bank Accounts',
    'Dependents',
    'Work Experience',
    'Qualifications',
    'Membership and Certifications',
    'Privacy',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = app.isDarkMode;
    final brand = app.brandColor;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final card = isDark ? AppTheme.darkCard : Colors.white;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final pageBg = isDark ? AppTheme.darkBg : const Color(0xFFF7F7F5);

    return ColoredBox(
      color: pageBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        children: [
          Text(
            'Account Settings',
            style: GoogleFonts.libreBaskerville(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color.lerp(brand, isDark ? Colors.white : Colors.black, 0.2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 720;
                final menu = _SettingsMenu(
                  links: _settingsLinks,
                  selected: 'Themes',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  brand: brand,
                  onSelect: (label) {
                    if (label == 'Personal Information') {
                      app.setTab(app.profileTabIndex);
                    }
                  },
                );
                final themes = Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                  child: ThemesPanel(
                    brandId: app.brandThemeId,
                    onPick: app.setBrandTheme,
                  ),
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 240, child: menu),
                      Container(width: 1, color: border),
                      Expanded(child: themes),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    menu,
                    Divider(height: 1, color: border),
                    themes,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu({
    required this.links,
    required this.selected,
    required this.textPrimary,
    required this.textSecondary,
    required this.brand,
    required this.onSelect,
  });

  final List<String> links;
  final String selected;
  final Color textPrimary;
  final Color textSecondary;
  final Color brand;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final link in links)
            InkWell(
              onTap: () => onSelect(link),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  link,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight:
                        link == selected ? FontWeight.w700 : FontWeight.w500,
                    color: link == selected ? brand : textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ThemesPanel extends StatelessWidget {
  const ThemesPanel({
    super.key,
    required this.brandId,
    required this.onPick,
  });

  final String brandId;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final textSecondary = HrTheme.textSecondary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Themes',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 28,
          runSpacing: 28,
          children: [
            for (final theme in BrandThemes.all)
              _ThemeSwatch(
                option: theme,
                selected: theme.id == brandId,
                onTap: () => onPick(theme.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final BrandThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    final labelColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 110,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: option.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: selected ? 3 : 0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: option.color.withOpacity(selected ? 0.45 : 0.22),
                    blurRadius: selected ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                  if (selected)
                    BoxShadow(
                      color: option.color.withOpacity(0.5),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                ],
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      color: BrandThemes.byId(option.id).color.computeLuminance() >
                              0.55
                          ? Colors.black87
                          : Colors.white,
                      size: 32,
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              option.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
