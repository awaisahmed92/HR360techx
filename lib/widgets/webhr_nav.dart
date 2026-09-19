import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/util/person_name.dart';
import '../navigation/module_catalog.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';

/// WebHR dual-rail: icon strip + module submenu.
class WebHrNavRail extends StatelessWidget {
  const WebHrNavRail({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final brand = HrTheme.brand(context);
    final onBrand = HrTheme.onBrand(context);
    final isDark = app.isDarkMode;
    final railBg = isDark ? const Color(0xFF2A241F) : brand;
    final subBg = isDark ? AppTheme.darkSurface : const Color(0xFFF3F1EE);
    final module = app.activeModule;

    return Row(
      children: [
        // Primary icon rail
        Container(
          width: 78,
          color: railBg,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '360',
                    style: TextStyle(
                      color: onBrand,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    for (final m in ModuleCatalog.modules)
                      _RailItem(
                        label: m.label,
                        icon: m.icon,
                        selected: app.moduleId == m.id,
                        onBrand: onBrand,
                        onTap: () => app.selectModule(m.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Secondary submenu
        if (module.children.isNotEmpty)
          Container(
            width: 210,
            decoration: BoxDecoration(
              color: subBg,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE5DFD6),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Text(
                    module.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF3D342C),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (final s in module.children)
                        _SubItem(
                          label: s.label,
                          icon: s.icon,
                          selected: app.subId == s.id,
                          brand: brand,
                          onBrand: onBrand,
                          onTap: () => app.selectSub(s.id),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onBrand,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color onBrand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: onBrand.withOpacity(selected ? 1 : 0.75)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: onBrand.withOpacity(selected ? 1 : 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubItem extends StatelessWidget {
  const _SubItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.brand,
    required this.onBrand,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color brand;
  final Color onBrand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? brand : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? onBrand
                      : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF6B5E52)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? onBrand
                          : (isDark ? AppTheme.darkTextPrimary : const Color(0xFF3D342C)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact top bar for WebHR shell.
class WebHrTopBar extends StatelessWidget {
  const WebHrTopBar({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final auth = context.watch<AuthState>();
    final isDark = app.isDarkMode;
    final brand = HrTheme.brand(context);
    final onBrand = HrTheme.onBrand(context);
    final title = app.activeSub.label;
    final displayName = cleanDisplayName(auth.user?.name);
    final role = auth.user?.designationName ?? '';

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : const Color(0xFFE8E2DA),
          ),
        ),
      ),
      child: Row(
        children: [
          if (onMenu != null)
            IconButton(onPressed: onMenu, icon: const Icon(Icons.menu)),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF2C241C),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: brand.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              auth.user?.isAdmin == true ? 'Admin' : 'Employee',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: brand,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Employees, Module, Help',
                hintStyle: TextStyle(fontSize: 12, color: HrTheme.textMuted(context)),
                filled: true,
                fillColor: isDark ? AppTheme.darkCard : const Color(0xFFF5F3F0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                suffixIcon: Icon(Icons.search, size: 18, color: HrTheme.textMuted(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Quick Action',
            offset: const Offset(0, 42),
            onSelected: (value) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                if (value == 'employee') {
                  context.read<AppState>().requestOpenEmployeeForm();
                }
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'employee',
                child: Row(
                  children: [
                    Icon(Icons.person_add_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Add Employee'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: onBrand),
                  const SizedBox(width: 6),
                  Text(
                    'Quick Action',
                    style: TextStyle(
                      color: onBrand,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Theme',
            onPressed: () => app.openScreen(moduleId: 'dashboard', subId: 'account_settings'),
            icon: Icon(Icons.palette_outlined, color: brand),
          ),
          IconButton(
            tooltip: 'Dark / Light',
            onPressed: app.toggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: brand,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            offset: const Offset(0, 42),
            onSelected: (value) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted) return;
                if (value == 'profile') {
                  context.read<AppState>().openScreen(moduleId: 'dashboard', subId: 'my_info');
                } else if (value == 'settings') {
                  context.read<AppState>().openScreen(moduleId: 'dashboard', subId: 'account_settings');
                } else if (value == 'logout') {
                  await context.read<AuthState>().logout();
                }
              });
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: brand.withOpacity(0.15),
                      child: Icon(Icons.person, color: brand, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.isEmpty ? 'Signed in' : displayName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          if (role.isNotEmpty)
                            Text(role, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 10),
                    Text('My Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Account Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 16,
              backgroundColor: brand.withOpacity(0.15),
              child: Icon(Icons.person_outline, size: 18, color: brand),
            ),
          ),
        ],
      ),
    );
  }
}

