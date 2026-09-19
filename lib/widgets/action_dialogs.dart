import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/app_state.dart';
import '../models/employee.dart';
import '../models/leave_request.dart';
import '../models/review_item.dart';
import '../models/candidate.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';

class ActionDialogs {
  // -------------------------------------------------------------
  // 1. Add Employee Modal
  // -------------------------------------------------------------
  static void showAddEmployeeDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = appState.isDarkMode;

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final roleController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController(text: 'San Francisco, CA');
    final salaryController = TextEditingController(text: '135000');
    String selectedDept = 'Engineering';
    String selectedStatus = 'Active';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Container(
                width: 540,
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: HrTheme.gradient(context),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person_add_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Onboard New Employee',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Add profile & initialize 360 competency profile',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(context, 'Full Name', nameController, isDark, hint: 'e.g. Liam Vance'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(context, 'Work Email', emailController, isDark, hint: 'name@hr360techx.io'),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(context, 'Job Title', roleController, isDark, hint: 'e.g. Senior Backend Dev'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Department',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkSurface : AppTheme.lightCardHover,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: selectedDept,
                                      dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                                      items: ['Engineering', 'Design', 'Product', 'Human Resources', 'Marketing', 'Data']
                                          .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13))))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => selectedDept = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkSurface : AppTheme.lightCardHover,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: selectedStatus,
                                      dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                                      items: ['Active', 'Remote', 'On Leave']
                                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => selectedStatus = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(context, 'Annual Base Salary (\$)', salaryController, isDark, hint: '135000'),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(context, 'Location', locationController, isDark, hint: 'San Francisco, CA'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HrTheme.brand(context),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              if (nameController.text.trim().isEmpty) return;

                              final newEmp = Employee(
                                id: 'EMP-${1000 + appState.totalWorkforceCount + 1}',
                                name: nameController.text.trim(),
                                email: emailController.text.trim().isEmpty
                                    ? '${nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@hr360techx.io'
                                    : emailController.text.trim(),
                                role: roleController.text.trim().isEmpty ? 'Software Specialist' : roleController.text.trim(),
                                department: selectedDept,
                                avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
                                status: selectedStatus,
                                rating: 4.8,
                                joinDate: 'Sep 2026',
                                phone: phoneController.text.isEmpty ? '+1 (555) 000-1122' : phoneController.text,
                                location: locationController.text.trim(),
                                salary: double.tryParse(salaryController.text.trim()) ?? 120000,
                                competencies: {
                                  'Leadership': 0.85,
                                  'Delivery': 0.90,
                                  'Innovation': 0.88,
                                  'Collaboration': 0.92,
                                  'Problem Solving': 0.94,
                                },
                                recentReview: 'Newly onboarded talent. Initial 360 review cycle initiated.',
                              );

                              appState.addEmployee(newEmp);
                              Navigator.pop(dialogCtx);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Employee ${newEmp.name} onboarded successfully!'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            },
                            child: const Text('Complete Onboarding', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 2. Apply for Leave Modal
  // -------------------------------------------------------------
  static void showApplyLeaveDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = appState.isDarkMode;

    String selectedType = 'Annual Leave';
    final reasonController = TextEditingController();
    int days = 2;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppTheme.successGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.beach_access_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Request Time Off',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Leave Category',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightCardHover,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedType,
                          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                          items: ['Annual Leave', 'Sick Leave', 'Casual Leave', 'Work From Home']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedType = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Number of Days',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded),
                                    onPressed: days > 1 ? () => setModalState(() => days--) : null,
                                  ),
                                  Text(
                                    '$days days',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded),
                                    onPressed: () => setModalState(() => days++),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(context, 'Reason / Notes', reasonController, isDark, maxLines: 3, hint: 'Brief context for HR and manager approval'),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            final newLeave = LeaveRequest(
                              id: 'LR-${300 + appState.leaveRequests.length + 1}',
                              employeeName: 'Dr. Sarah Jenkins',
                              employeeRole: 'VP HR',
                              employeeAvatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
                              type: selectedType,
                              startDate: DateFormat('MMM dd, yyyy').format(DateTime.now().add(const Duration(days: 2))),
                              endDate: DateFormat('MMM dd, yyyy').format(DateTime.now().add(Duration(days: 2 + days))),
                              days: days,
                              reason: reasonController.text.trim().isEmpty ? 'Personal scheduled leave.' : reasonController.text.trim(),
                              status: 'Approved',
                              submittedDate: DateFormat('MMM dd, yyyy').format(DateTime.now()),
                            );

                            appState.addLeaveRequest(newLeave);
                            Navigator.pop(dialogCtx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Leave request for $days days submitted & auto-approved!'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          },
                          child: const Text('Submit Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 3. Submit 360 Feedback Dialog
  // -------------------------------------------------------------
  static void showAddReviewDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = appState.isDarkMode;

    Employee selectedEmp = appState.allEmployeesRaw.first;
    String reviewType = 'Peer Review';
    double score = 4.8;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.warningGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.star_rate_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Submit 360° Review',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Select Colleague',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightCardHover,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Employee>(
                            isExpanded: true,
                            value: selectedEmp,
                            dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                            items: appState.allEmployeesRaw
                                .map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (${e.role})', style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedEmp = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Review Type',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkSurface : AppTheme.lightCardHover,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: reviewType,
                                      dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                                      items: ['Peer Review', 'Manager Review', 'Self Review', '360 Synthesis']
                                          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => reviewType = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overall Rating: ${score.toStringAsFixed(1)} ★',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.warning,
                                  ),
                                ),
                                Slider(
                                  value: score,
                                  min: 1.0,
                                  max: 5.0,
                                  divisions: 40,
                                  activeColor: AppTheme.warning,
                                  onChanged: (v) => setModalState(() => score = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(context, 'Detailed Feedback & Synthesis', feedbackController, isDark, maxLines: 4, hint: 'Highlight accomplishments, collaboration strengths, and growth recommendations.'),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HrTheme.brand(context),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final rev = ReviewItem(
                                id: 'REV-${500 + appState.reviews.length + 1}',
                                employeeId: selectedEmp.id,
                                employeeName: selectedEmp.name,
                                reviewerName: 'Dr. Sarah Jenkins',
                                reviewerRole: 'VP HR',
                                reviewerAvatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
                                reviewType: reviewType,
                                score: score,
                                feedback: feedbackController.text.trim().isEmpty
                                    ? 'High performance contributor demonstrating stellar commitment to team objectives.'
                                    : feedbackController.text.trim(),
                                date: DateFormat('MMM dd, yyyy').format(DateTime.now()),
                                scores: {
                                  'Execution': score,
                                  'Collaboration': (score - 0.1).clamp(1.0, 5.0),
                                  'Innovation': score,
                                  'Problem Solving': (score + 0.1).clamp(1.0, 5.0),
                                  'Communication': score,
                                },
                              );

                              appState.addReview(rev);
                              Navigator.pop(dialogCtx);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('360 Feedback logged for ${selectedEmp.name}!'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            },
                            child: const Text('Submit Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 4. Add Candidate Dialog
  // -------------------------------------------------------------
  static void showAddCandidateDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = appState.isDarkMode;

    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final expController = TextEditingController(text: '5+ Years');
    final skillsController = TextEditingController(text: 'Flutter, Dart, GraphQL, CI/CD');
    String selectedDept = 'Engineering';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.badge_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Add Pipeline Candidate',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(context, 'Candidate Name', nameController, isDark, hint: 'e.g. Jordan Hayes'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(context, 'Role Position', roleController, isDark, hint: 'e.g. Senior Security Architect'),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(context, 'Experience', expController, isDark, hint: '5+ Years'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(context, 'Key Skills (comma separated)', skillsController, isDark, hint: 'Flutter, Go, AWS, Docker'),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HrTheme.brand(context),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (nameController.text.trim().isEmpty) return;

                            final cand = Candidate(
                              id: 'CND-${800 + appState.candidates.length + 1}',
                              name: nameController.text.trim(),
                              role: roleController.text.trim().isEmpty ? 'Software Specialist' : roleController.text.trim(),
                              department: selectedDept,
                              stage: 'Applied',
                              experience: expController.text.trim(),
                              rating: 4.8,
                              appliedDate: DateFormat('MMM dd, yyyy').format(DateTime.now()),
                              skills: skillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                              email: '${nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@talentpool.io',
                              avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
                            );

                            appState.addCandidate(cand);
                            Navigator.pop(dialogCtx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Candidate ${cand.name} added to pipeline!'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          },
                          child: const Text('Add Candidate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 5. Payslip Preview Dialog
  // -------------------------------------------------------------
  static void showPayslipDialog(BuildContext context, Employee employee) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = appState.isDarkMode;

    final gross = employee.salary / 12;
    final tax = gross * 0.22;
    final insurance = 420.0;
    final retirement = gross * 0.05;
    final netPay = gross - tax - insurance - retirement;

    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: HrTheme.gradient(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Official Payslip Statement',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'Period: September 2026 • HR360 TechX Global',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightCardHover,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(employee.avatar),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            Text(
                              '${employee.role} • ${employee.department}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PAID',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildPayslipRow('Monthly Gross Earnings', currency.format(gross), isDark, isBold: true),
                const Divider(),
                _buildPayslipRow('Federal & State Withholdings (22%)', '- ${currency.format(tax)}', isDark, isDeduction: true),
                _buildPayslipRow('Comprehensive Medical & Dental', '- ${currency.format(insurance)}', isDark, isDeduction: true),
                _buildPayslipRow('401(k) Retirement Contribution (5%)', '- ${currency.format(retirement)}', isDark, isDeduction: true),
                const Divider(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: HrTheme.brand(context).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: HrTheme.brand(context).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Disbursed Take-Home',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: HrTheme.brandLight(context),
                        ),
                      ),
                      Text(
                        currency.format(netPay),
                        style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: HrTheme.brandLight(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print PDF'),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payslip statement sent to printer / PDF spooler!')),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HrTheme.brand(context),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                      label: const Text('Download Secure Slip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payslip for ${employee.name} downloaded successfully!'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helpers
  static Widget _buildTextField(BuildContext context, String label, TextEditingController controller, bool isDark, {int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
            filled: true,
            fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightCardHover,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: HrTheme.brand(context), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildPayslipRow(String label, String value, bool isDark, {bool isBold = false, bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isDeduction
                  ? AppTheme.danger
                  : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
