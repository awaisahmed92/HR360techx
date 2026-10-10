import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/company_logo.dart';

/// Public product page shown before authentication.
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
          gradient: RadialGradient(
            center: Alignment(0.75, -0.85),
            radius: 1.35,
            colors: [Color(0xFF173B67), Color(0xFF0B1528), Color(0xFF07101F)],
            stops: [0, 0.48, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 40 : 20,
                  vertical: 18,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bar(onTryNow: onTryNow, onSignUp: onSignUp),
                        SizedBox(height: wide ? 68 : 42),
                        _Hero(
                          wide: wide,
                          onTryNow: onTryNow,
                          onSignUp: onSignUp,
                        ),
                        SizedBox(height: wide ? 84 : 58),
                        const _SectionHeading(),
                        const SizedBox(height: 26),
                        const _Features(),
                        const SizedBox(height: 56),
                        _BottomCta(
                          onPressed: onSignUp ?? onTryNow,
                        ),
                        const SizedBox(height: 28),
                        const Center(
                          child: Text(
                            'HR360 TechX  •  One connected experience for every team',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 12),
                          ),
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.wide,
    required this.onTryNow,
    required this.onSignUp,
  });

  final bool wide;
  final VoidCallback onTryNow;
  final VoidCallback? onSignUp;

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.28)),
          ),
          child: const Text(
            'GLOBAL WORKFORCE PLATFORM',
            style: TextStyle(
              color: Color(0xFF7DD3FC),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'One platform.\nEvery person.\nAnywhere.',
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 54 : 39,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Bring your people, time, leave, payroll, hiring, and performance together in one secure workspace—built for modern teams across the world.',
          style: TextStyle(
            color: Color(0xFFB4C2D4),
            fontSize: 17,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Cta(
              label:
                  onSignUp == null ? 'Explore HR360' : 'Create your workspace',
              filled: true,
              onPressed: onSignUp ?? onTryNow,
            ),
            _Cta(label: 'Sign in', filled: false, onPressed: onTryNow),
          ],
        ),
        const SizedBox(height: 25),
        const Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            _CheckLabel('Fast onboarding'),
            _CheckLabel('Global-ready'),
            _CheckLabel('One source of truth'),
          ],
        ),
      ],
    );

    const visual = _HeroVisual();
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [visual, const SizedBox(height: 36), copy],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 9, child: copy),
        const SizedBox(width: 48),
        const Expanded(flex: 11, child: visual),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(
            'assets/hr-banner.jpg',
            fit: BoxFit.contain,
            semanticLabel: 'Wherever your team is, we connect everyone',
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.onTryNow, required this.onSignUp});

  final VoidCallback onTryNow;
  final VoidCallback? onSignUp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CompanyLogo(size: 40),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HR360 TechX',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              Text(
                'Global Talent Cloud',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
        _Cta(label: 'Sign in', filled: false, onPressed: onTryNow),
        if (onSignUp != null) ...[
          const SizedBox(width: 10),
          _Cta(label: 'Get started', filled: true, onPressed: onSignUp!),
        ],
      ],
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta(
      {required this.label, required this.filled, required this.onPressed});

  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: filled ? const Color(0xFF1677C8) : Colors.transparent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: filled
              ? BorderSide.none
              : const BorderSide(color: Color(0xFF3B4B61)),
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _CheckLabel extends StatelessWidget {
  const _CheckLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            color: Color(0xFF38BDF8), size: 17),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          Text(
            'Everything your people need to do their best work',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Replace scattered tools with a clear, connected employee experience.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features();

  static const items = [
    (
      Icons.groups_rounded,
      'People operations',
      'Employee records, onboarding, documents, roles, and organization structure in one place.',
    ),
    (
      Icons.schedule_rounded,
      'Time and attendance',
      'Simplify attendance, shifts, timesheets, leave requests, and manager approvals.',
    ),
    (
      Icons.auto_graph_rounded,
      'Pay and performance',
      'Connect compensation, payroll workflows, goals, reviews, and employee growth.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 850
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 560
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final item in items)
              _Feature(
                width: cardWidth,
                icon: item.$1,
                title: item.$2,
                body: item.$3,
              ),
          ],
        );
      },
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.width,
    required this.icon,
    required this.title,
    required this.body,
  });

  final double width;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111E31).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF24364E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1677C8).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFF5CC8FF), size: 22),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: Color(0xFF94A3B8), height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF104C7C), Color(0xFF176FAE)],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF3BA3E6).withValues(alpha: 0.35)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 18,
        spacing: 24,
        children: [
          const SizedBox(
            width: 610,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to bring your workforce together?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Create your HR360 TechX workspace and give every employee one place to connect.',
                  style: TextStyle(color: Color(0xFFD6EAF8), height: 1.5),
                ),
              ],
            ),
          ),
          _Cta(label: 'Get started', filled: true, onPressed: onPressed),
        ],
      ),
    );
  }
}
