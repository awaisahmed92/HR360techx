import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/self_service/self_service_state.dart';

/// Small dashboard icon: Sign in when today is open, Sign out when punched in.
class DashboardPunchButton extends StatefulWidget {
  const DashboardPunchButton({super.key});

  @override
  State<DashboardPunchButton> createState() => _DashboardPunchButtonState();
}

class _DashboardPunchButtonState extends State<DashboardPunchButton> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SelfServiceState>().loadAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SelfServiceState>();
    final today = ss.attendanceToday;
    final canIn = today?['can_punch_in'] == true;
    final canOut = today?['can_punch_out'] == true;
    final done = today != null && !canIn && !canOut;

    final icon = canOut ? Icons.logout : Icons.login;
    final color = canOut
        ? const Color(0xFFEA580C)
        : done
            ? const Color(0xFF16A34A)
            : const Color(0xFF2563EB);
    final tip = canOut
        ? 'Sign out'
        : done
            ? 'Attendance marked'
            : 'Sign in';

    return IconButton(
      tooltip: tip,
      onPressed: _busy || ss.loading || (!canIn && !canOut)
          ? null
          : () async {
              setState(() => _busy = true);
              final messenger = ScaffoldMessenger.of(context);
              final err = await ss.punch(canOut ? 'out' : 'in');
              if (!mounted) return;
              setState(() => _busy = false);
              if (err == null) return;
              messenger.showSnackBar(SnackBar(content: Text(err)));
            },
      icon: Icon(icon, color: color, size: 22),
    );
  }
}

/// Banner control: status line, work-from-home switch, and Sign In / Sign Out.
class DashboardSignBar extends StatefulWidget {
  const DashboardSignBar({super.key});

  @override
  State<DashboardSignBar> createState() => _DashboardSignBarState();
}

class _DashboardSignBarState extends State<DashboardSignBar> {
  bool _busy = false;
  bool _fromHome = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ss = context.read<SelfServiceState>();
      final app = context.read<AppState>();
      await ss.loadAttendance();
      if (!mounted) return;
      app.setClockedIn(ss.attendanceToday?['can_punch_out'] == true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SelfServiceState>();
    final today = ss.attendanceToday;
    final canIn = today?['can_punch_in'] != false;
    final canOut = today?['can_punch_out'] == true;
    final done = today != null && !canIn && !canOut;
    final message = canOut
        ? 'You are signed in.'
        : done
            ? 'You have signed out today.'
            : 'You have not clocked in today!';
    final label = canOut ? 'Sign Out' : 'Sign In';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Work From Home', style: TextStyle(color: Colors.white, fontSize: 13)),
              Switch(
                value: _fromHome,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF9A3412),
                onChanged: canIn && !canOut ? (v) => setState(() => _fromHome = v) : null,
              ),
              const SizedBox(width: 4),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9A3412),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF9A3412).withValues(alpha: 0.45),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: _busy || done
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        final messenger = ScaffoldMessenger.of(context);
                        final app = context.read<AppState>();
                        final err = await ss.punch(canOut ? 'out' : 'in', workFromHome: _fromHome && !canOut);
                        if (!mounted) return;
                        setState(() => _busy = false);
                        final today = ss.attendanceToday;
                        app.setClockedIn(today?['can_punch_out'] == true);
                        if (err == null) return;
                        messenger.showSnackBar(SnackBar(content: Text(err)));
                      },
                child: Text(_busy ? 'Please wait…' : label, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
