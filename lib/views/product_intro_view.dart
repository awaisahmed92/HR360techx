import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Public product page. Try now opens the existing login screen.
class ProductIntroView extends StatelessWidget {
  const ProductIntroView({
    super.key,
    required this.onTryNow,
    this.onSignUp,
  });

  final VoidCallback onTryNow;
  final VoidCallback? onSignUp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1120), Color(0xFF163A6E)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 800;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 48 : 20,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bar(onTryNow: onTryNow),
                        const SizedBox(height: 56),
                        const Text(
                          'WORKFORCE CLOUD',
                          style: TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'People, time, and pay\non one desk.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: wide ? 52 : 36,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(
                          width: 560,
                          child: Text(
                            'Run the workforce from hire to payroll: employees, leave, attendance, performance, and Pakistan statutory pay in the same company workspace.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 17,
                              height: 1.55,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _Cta(label: 'Try now', filled: true, onPressed: onTryNow),
                            if (onSignUp != null)
                              _Cta(label: 'Create an account', filled: false, onPressed: onSignUp!),
                          ],
                        ),
                        const SizedBox(height: 40),
                        const Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _Feature(
                              title: 'Workforce',
                              body: 'Employee records, roles, contracts, and the organization your managers already use.',
                            ),
                            _Feature(
                              title: 'Time',
                              body: 'Leave, attendance, shifts, and timesheets with the approval path you set.',
                            ),
                            _Feature(
                              title: 'Pay and talent',
                              body: 'Salary runs with tax, EOBI, and SESSI, plus hiring and performance beside them.',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.onTryNow});

  final VoidCallback onTryNow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E4B8C), Color(0xFF3B6FB0)],
            ),
          ),
          child: const Text(
            '360',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HR360 TechX', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              Text('Talent Cloud', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
          ),
        ),
        _Cta(label: 'Try now', filled: true, onPressed: onTryNow),
      ],
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.label, required this.filled, required this.onPressed});

  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: filled ? const Color(0xFF2A72B5) : Colors.transparent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: filled ? BorderSide.none : const BorderSide(color: Color(0xFF334155)),
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              Text(body, style: const TextStyle(color: Color(0xFF94A3B8), height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
