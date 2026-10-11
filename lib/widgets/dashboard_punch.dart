import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/self_service/self_service_state.dart';

/// Small dashboard icon: Sign in when today is open, Sign out when punched in.
class DashboardPunchButton extends StatefulWidget {
  const DashboardPunchButton({super.key});

  @override
  State<DashboardPunchButton> createState() => _DashboardPunchButtonState();
}

class _DashboardPunchButtonState extends State<DashboardPunchButton> {
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
      onPressed: ss.busy || (!canIn && !canOut)
          ? null
          : () async {
              final err = await ss.punch(canOut ? 'out' : 'in');
              if (!context.mounted || err == null) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
            },
      icon: Icon(icon, color: color, size: 22),
    );
  }
}
