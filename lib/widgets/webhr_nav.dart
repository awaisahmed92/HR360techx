import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/util/person_name.dart';
import '../navigation/module_catalog.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';
import 'company_logo.dart';

enum HrNavLayout { full, icons, drawer }

/// Dual rail on wide screens, icon rail on tablet, single list in the phone drawer.
class WebHrNavRail extends StatelessWidget {
  const WebHrNavRail({
    super.key,
    this.layout = HrNavLayout.full,
    this.onModuleSelected,
  });

  final HrNavLayout layout;
  final VoidCallback? onModuleSelected;

  @override
  Widget build(BuildContext context) {
    if (layout == HrNavLayout.drawer) return const _DrawerNav();
    final showSubs = layout == HrNavLayout.full;
    return Row(
      children: [
        _IconRail(onModuleSelected: onModuleSelected),
        if (showSubs) const WebHrSubmenuPanel(),
      ],
    );
  }
}

class WebHrSubmenuPanel extends StatelessWidget {
  const WebHrSubmenuPanel({super.key, this.onPicked});

  final VoidCallback? onPicked;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final brand = HrTheme.brand(context);
    final isDark = app.isDarkMode;
    final module = app.activeModule;
    final bg = isDark ? AppTheme.sidebarDark : Colors.white;
    final line = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final muted = isDark ? AppTheme.darkTextMuted : const Color(0xFF6B7280);

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    module.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      color: muted,
                    ),
                  ),
                ),
                if (onPicked != null)
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onPicked,
                    icon: Icon(Icons.close, size: 18, color: muted),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              children: [
                for (final s in module.children)
                  _SubItem(
                    label: s.label,
                    icon: s.icon,
                    selected: app.subId == s.id,
                    brand: brand,
                    onTap: () {
                      app.selectSub(s.id);
                      onPicked?.call();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconRail extends StatelessWidget {
  const _IconRail({this.onModuleSelected});

  final VoidCallback? onModuleSelected;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final brand = HrTheme.brand(context);
    final isDark = app.isDarkMode;
    final bg = isDark ? AppTheme.sidebarDark : Colors.white;
    final line = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: line)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : const Color(0xFFF3F5F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: line),
            ),
            child: const CompanyLogo(size: 32),
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
                    brand: brand,
                    isDark: isDark,
                    onTap: () {
                      app.selectModule(m.id);
                      onModuleSelected?.call();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.brand,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color brand;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final idle = isDark ? AppTheme.darkTextSecondary : const Color(0xFF6B7280);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? brand.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: selected ? brand : Colors.transparent, width: 3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? brand : idle),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? brand : idle,
                ),
              ),
            ],
          ),
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
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    final idle = isDark ? AppTheme.darkTextSecondary : const Color(0xFF6B7280);
    final text = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? brand.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: selected ? brand : Colors.transparent, width: 3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(icon, size: 18, color: selected ? brand : idle),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? brand : text,
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

class _DrawerNav extends StatelessWidget {
  const _DrawerNav();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final brand = HrTheme.brand(context);
    final isDark = app.isDarkMode;
    final bg = isDark ? AppTheme.sidebarDark : Colors.white;
    final muted = isDark ? AppTheme.darkTextMuted : const Color(0xFF6B7280);

    return ColoredBox(
      color: bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Row(
              children: [
                CompanyLogo(size: 28),
                SizedBox(width: 10),
                Text(
                  'HR360',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          for (final module in ModuleCatalog.modules) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                module.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: muted,
                ),
              ),
            ),
            for (final sub in module.children)
              _SubItem(
                label: sub.label,
                icon: sub.icon,
                selected: app.moduleId == module.id && app.subId == sub.id,
                brand: brand,
                onTap: () {
                  app.openScreen(moduleId: module.id, subId: sub.id);
                  final scaffold = Scaffold.maybeOf(context);
                  if (scaffold?.isDrawerOpen ?? false) Navigator.of(context).pop();
                },
              ),
          ],
        ],
      ),
    );
  }
}

/// Ink top bar: product mark, search, and the existing account controls.
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
    final displayName = cleanDisplayName(auth.user?.name);
    final role = auth.user?.designationName ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showSearch = width >= 860;
        final showTitle = width >= 640;
        final showQuickLabel = width >= 520;
        final bar = isDark ? AppTheme.ink : Colors.white;
        final fg = isDark ? Colors.white : const Color(0xFF1A1D26);
        final muted = isDark ? const Color(0xFFC5CAD3) : const Color(0xFF6B7280);
        final field = isDark ? const Color(0xFF1E242E) : const Color(0xFFF3F5F8);
        final fieldLine = isDark ? const Color(0xFF2A3140) : const Color(0xFFE6E8EE);
        return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bar,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF2A3140) : const Color(0xFFE6E8EE))),
      ),
      child: Row(
        children: [
          if (onMenu != null)
            IconButton(
              onPressed: onMenu,
              icon: Icon(Icons.menu, color: fg),
            ),
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? Colors.white : brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const CompanyLogo(size: 26),
          ),
          const SizedBox(width: 10),
          Text(
            'HR360',
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (showTitle) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                app.activeSub.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),
          if (showSearch)
            SizedBox(
              width: 240,
              height: 36,
              child: TextField(
                style: TextStyle(color: fg, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search Employees, Module, Help',
                  hintStyle: TextStyle(fontSize: 12, color: muted),
                  filled: true,
                  fillColor: field,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  suffixIcon: Icon(Icons.search, size: 18, color: muted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: fieldLine),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: fieldLine),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: brand),
                  ),
                ),
              ),
            ),
          const Spacer(),
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
              padding: EdgeInsets.symmetric(horizontal: showQuickLabel ? 12 : 8, vertical: 8),
              decoration: BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: onBrand),
                  if (showQuickLabel) ...[
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
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Theme',
            onPressed: () => app.openScreen(moduleId: 'dashboard', subId: 'account_settings'),
            icon: Icon(Icons.palette_outlined, color: fg),
          ),
          IconButton(
            tooltip: 'Dark / Light',
            onPressed: app.toggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: fg,
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
                      backgroundColor: brand.withValues(alpha: 0.15),
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
              backgroundColor: brand.withValues(alpha: 0.12),
              child: Icon(Icons.person_outline, size: 18, color: brand),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
