import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_state.dart';
import '../../theme/app_theme.dart';

/// Hides [child] when the signed-in user lacks module/screen access.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.module,
    this.screen,
    required this.child,
    this.fallback,
  });

  final String module;
  final String? screen;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final allowed = screen == null
        ? auth.canViewModule(module)
        : auth.canView(module, screen!);

    if (allowed) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

/// Full-page denied state for routed tabs.
class AccessDeniedView extends StatelessWidget {
  const AccessDeniedView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Access denied',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'Your designation does not include this module. Contact your HR admin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
