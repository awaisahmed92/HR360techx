import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';
import '../models/leave_request.dart';
import '../models/review_item.dart';
import '../models/candidate.dart';
import '../navigation/module_catalog.dart';
import '../theme/brand_themes.dart';
import '../core/config/clock_faces.dart';
import '../core/config/countries.dart';
import '../core/settings/org_settings_repository.dart';
import '../core/feed/status_feed_repository.dart';
import '../core/auth/auth_state.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _loadPrefs();
  }

  static const _prefDark = 'hr360_dark_mode';
  static const _prefBrand = 'hr360_brand_theme';

  // Organization / System settings
  OrgSettingsState orgSettings = OrgSettingsState();
  OrgSettingsRepository? _orgRepo;
  StatusFeedRepository? _feedRepo;

  void bindAuth(AuthState auth) {
    _orgRepo = OrgSettingsRepository(getSession: () => auth.session);
    _feedRepo = StatusFeedRepository(getSession: () => auth.session);
    loadOrgSettings();
    loadStatusFeed();
  }

  Future<void> loadOrgSettings() async {
    final repo = _orgRepo ?? OrgSettingsRepository(getSession: () => null);
    orgSettings = await repo.load();
    notifyListeners();
  }

  Future<String?> saveOrgSettings() async {
    try {
      final repo = _orgRepo ?? OrgSettingsRepository(getSession: () => null);
      await repo.save(orgSettings);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void patchOrgSettings(void Function(OrgSettingsState s) fn) {
    fn(orgSettings);
    notifyListeners();
  }

  Future<void> setClockFace(String id) async {
    orgSettings.clockFaceId = id;
    notifyListeners();
    await saveOrgSettings();
  }

  Future<String?> uploadOrgLogo(List<int> bytes, String filename) async {
    final repo = _orgRepo;
    if (repo == null) return 'Not signed in';
    final url = await repo.uploadLogo(bytes, filename);
    if (url == null) return 'Upload failed';
    orgSettings.logoUrl = url;
    await saveOrgSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hr360_login_logo', url);
    notifyListeners();
    return null;
  }

  ClockFaceOption get selectedClockFace =>
      ClockFaces.byId(orgSettings.clockFaceId);

  CountryOption get selectedClockCountry =>
      Countries.byCode(orgSettings.clockCountry.isNotEmpty
          ? orgSettings.clockCountry
          : orgSettings.contactCountry);

  Future<void> setClockCountry(String code) async {
    final country = Countries.byCode(code);
    orgSettings.clockCountry = country.code;
    orgSettings.timeZone = country.timeZoneLabel;
    notifyListeners();
    await saveOrgSettings();
  }

  // ── WebHR module navigation ──
  String _moduleId = 'dashboard';
  String _subId = 'home';
  String get moduleId => _moduleId;
  String get subId => _subId;
  HrModuleNav get activeModule => ModuleCatalog.byId(_moduleId);
  HrSubNav get activeSub => ModuleCatalog.subById(activeModule, _subId);
  String get activeScreen => activeSub.screen;

  void selectModule(String id) {
    if (_moduleId == id) return;
    _moduleId = id;
    _subId = ModuleCatalog.byId(id).children.first.id;
    notifyListeners();
  }

  void selectSub(String id) {
    if (_subId == id) return;
    _subId = id;
    notifyListeners();
  }

  void openScreen({required String moduleId, required String subId}) {
    _moduleId = moduleId;
    _subId = subId;
    notifyListeners();
  }

  // Legacy tab index (kept for older widgets that still call setTab)
  int get currentTab {
    // Best-effort map for AppHeader titles
    switch (activeScreen) {
      case 'my_dashboard':
      case 'hr_dashboard':
        return 0;
      case 'employees':
      case 'employees_dashboard':
        return 1;
      case 'performance':
        return 2;
      case 'leave':
        return 3;
      case 'recruitment':
        return 4;
      case 'payroll':
      case 'payroll_setup':
        return 5;
      case 'attendance':
        return 6;
      case 'travel':
        return 7;
      case 'timesheet':
      case 'timesheet_dashboard':
        return 8;
      case 'approvals':
        return 9;
      case 'profile':
        return 10;
      case 'settings':
        return 11;
      default:
        return 0;
    }
  }

  void setTab(int index) {
    // Map old indices → new module/sub for compatibility
    const map = <int, (String, String)>{
      0: ('dashboard', 'home'),
      1: ('employees', 'employees'),
      2: ('employees', 'performance'),
      3: ('timesheet', 'leaves'),
      4: ('employees', 'recruitment'),
      5: ('payroll', 'pay_dashboard'),
      6: ('timesheet', 'attendance'),
      7: ('employees', 'travels'),
      8: ('timesheet', 'worksheet'),
      9: ('dashboard', 'approvals'),
      10: ('dashboard', 'my_info'),
      11: ('dashboard', 'account_settings'),
    };
    final t = map[index];
    if (t == null) return;
    openScreen(moduleId: t.$1, subId: t.$2);
  }

  // Dark Mode Toggle
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Brand accent (WebHR-style theme colors)
  String _brandThemeId = BrandThemes.defaultId;
  String get brandThemeId => _brandThemeId;
  BrandThemeOption get brandTheme => BrandThemes.byId(_brandThemeId);
  Color get brandColor => brandTheme.color;

  /// Open Employees → Add form after navigation (Quick Action / deep link).
  bool pendingOpenEmployeeForm = false;

  void requestOpenEmployeeForm() {
    pendingOpenEmployeeForm = true;
    openScreen(moduleId: 'employees', subId: 'employees');
  }

  bool consumeOpenEmployeeForm() {
    if (!pendingOpenEmployeeForm) return false;
    pendingOpenEmployeeForm = false;
    return true;
  }

  Future<void> Function(Map<String, dynamic> prefs)? uiPrefsSaver;
  Future<Map<String, dynamic>?> Function()? uiPrefsLoader;

  void setBrandTheme(String id) {
    if (_brandThemeId == id) return;
    _brandThemeId = id;
    notifyListeners();
    _persist();
    _syncPrefsToServer();
  }

  /// Apply prefs from login /me or GET /settings/ui-prefs (DB wins over local).
  void applyUiPrefs(Map<String, dynamic>? prefs, {bool persistLocal = true}) {
    if (prefs == null) return;
    final id = (prefs['brand_theme_id'] ?? '').toString();
    final dark = prefs['dark_mode'];
    var changed = false;
    if (id.isNotEmpty && id != _brandThemeId) {
      _brandThemeId = id;
      changed = true;
    }
    if (dark is bool && dark != _isDarkMode) {
      _isDarkMode = dark;
      changed = true;
    }
    if (changed) {
      notifyListeners();
      if (persistLocal) _persist();
    }
  }

  Future<void> loadUiPrefsFromServer() async {
    final loader = uiPrefsLoader;
    if (loader == null) return;
    try {
      final prefs = await loader();
      applyUiPrefs(prefs);
    } catch (_) {}
  }

  void _syncPrefsToServer() {
    final saver = uiPrefsSaver;
    if (saver == null) return;
    saver({
      'brand_theme_id': _brandThemeId,
      'dark_mode': _isDarkMode,
    });
  }

  /// Set by MainShell so Themes / Profile can navigate correctly.
  bool adminShell = true;
  int get profileTabIndex => 10;
  int get themesTabIndex => 11;

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_prefDark) ?? false;
    _brandThemeId = prefs.getString(_prefBrand) ?? BrandThemes.defaultId;
    await _loadStatusFeed(prefs);
    await loadOrgSettings();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDark, _isDarkMode);
    await prefs.setString(_prefBrand, _brandThemeId);
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _persist();
    _syncPrefsToServer();
  }

  // Clock In / Out Simulation
  bool _isClockedIn = false;
  DateTime _clockInTime = DateTime.now().subtract(const Duration(hours: 3, minutes: 42));
  bool get isClockedIn => _isClockedIn;
  DateTime get clockInTime => _clockInTime;

  void toggleClock() {
    _isClockedIn = !_isClockedIn;
    if (_isClockedIn) {
      _clockInTime = DateTime.now();
    }
    notifyListeners();
  }

  // Dashboard status / holiday posts (local + SharedPreferences)
  static const _prefStatusFeed = 'hr360_status_feed';
  final List<Map<String, dynamic>> _statusFeed = [];
  List<Map<String, dynamic>> get statusFeed => List.unmodifiable(_statusFeed);

  List<Map<String, dynamic>> _birthdaysToday = [];
  List<Map<String, dynamic>> _anniversariesToday = [];
  List<Map<String, dynamic>> _upcomingBirthdays = [];
  List<Map<String, dynamic>> _upcomingAnniversaries = [];
  List<Map<String, dynamic>> get birthdaysToday =>
      List.unmodifiable(_birthdaysToday);
  List<Map<String, dynamic>> get anniversariesToday =>
      List.unmodifiable(_anniversariesToday);
  List<Map<String, dynamic>> get upcomingBirthdays =>
      List.unmodifiable(_upcomingBirthdays);
  List<Map<String, dynamic>> get upcomingAnniversaries =>
      List.unmodifiable(_upcomingAnniversaries);

  Future<void> loadStatusFeed() async {
    final repo = _feedRepo;
    if (repo == null) return;
    final snap = await repo.loadSnapshot();
    if (snap == null) return;
    _statusFeed
      ..clear()
      ..addAll(snap.posts);
    _birthdaysToday = snap.birthdays;
    _anniversariesToday = snap.anniversaries;
    _upcomingBirthdays = snap.upcomingBirthdays;
    _upcomingAnniversaries = snap.upcomingAnniversaries;
    notifyListeners();
    await _persistStatusFeed();
  }

  Future<void> postStatus({
    required String author,
    required String text,
    String type = 'status', // status | holiday | announcement | recognition
    String authorTitle = '',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    Map<String, dynamic>? remote;
    try {
      remote = await _feedRepo?.post(text: trimmed, type: type);
    } catch (_) {}

    final post = remote ?? {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'author': author,
      'author_title': authorTitle,
      'text': trimmed,
      'type': type,
      'created_at': DateTime.now().toIso8601String(),
      'likes': <String>[],
      'comments': <Map<String, dynamic>>[],
    };
    _statusFeed.removeWhere((p) => '${p['id']}' == '${post['id']}');
    _statusFeed.insert(0, post);
    if (_statusFeed.length > 50) {
      _statusFeed.removeRange(50, _statusFeed.length);
    }

    if (type == 'holiday' || type == 'announcement') {
      _notifications.insert(0, {
        'id': '${post['id']}',
        'title': type == 'holiday' ? 'Holiday' : 'Announcement',
        'desc': trimmed,
        'time': post['created_at'],
        'icon': type == 'holiday'
            ? Icons.celebration_outlined
            : Icons.campaign_outlined,
        'color': type == 'holiday'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF2A72B5),
        'read': false,
        'from': author,
      });
    }

    notifyListeners();
    await _persistStatusFeed();
  }

  Future<void> _persistStatusFeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefStatusFeed, jsonEncode(_statusFeed));
  }

  Future<void> _loadStatusFeed(SharedPreferences prefs) async {
    final raw = prefs.getString(_prefStatusFeed);
    if (raw == null || raw.isEmpty) return;
    _statusFeed.clear();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final e in decoded) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          m['likes'] = ((m['likes'] as List?) ?? []).map((x) => '$x').toList();
          m['comments'] = ((m['comments'] as List?) ?? [])
              .whereType<Map>()
              .map((x) => Map<String, dynamic>.from(x))
              .toList();
          _statusFeed.add(m);
        }
        return;
      }
    } catch (_) {
      // legacy pipe format
    }
    for (final line in raw.split('\n')) {
      final p = line.split('|');
      if (p.length < 5) continue;
      _statusFeed.add({
        'id': p[0],
        'author': p[1],
        'type': p[2],
        'created_at': p[3],
        'text': p.sublist(4).join('|'),
        'likes': <String>[],
        'comments': <Map<String, dynamic>>[],
      });
    }
  }

  Future<void> toggleFeedLike({required String postId, required String userName}) async {
    final i = _statusFeed.indexWhere((p) => '${p['id']}' == postId);
    if (i < 0) return;
    final likes = List<String>.from((_statusFeed[i]['likes'] as List?) ?? []);
    if (likes.contains(userName)) {
      likes.remove(userName);
    } else {
      likes.add(userName);
    }
    _statusFeed[i]['likes'] = likes;
    notifyListeners();
    _persistStatusFeed();
    try {
      final remote = await _feedRepo?.like(postId);
      if (remote != null) {
        _replaceFeedPost(remote);
      }
    } catch (_) {}
  }

  Future<void> addFeedComment({
    required String postId,
    required String author,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final i = _statusFeed.indexWhere((p) => '${p['id']}' == postId);
    if (i < 0) return;
    final comments =
        List<Map<String, dynamic>>.from((_statusFeed[i]['comments'] as List?) ?? []);
    comments.add({
      'author': author,
      'text': trimmed,
      'created_at': DateTime.now().toIso8601String(),
    });
    _statusFeed[i]['comments'] = comments;
    notifyListeners();
    _persistStatusFeed();
    try {
      final remote = await _feedRepo?.comment(postId: postId, text: trimmed);
      if (remote != null) {
        _replaceFeedPost(remote);
      }
    } catch (_) {}
  }

  void _replaceFeedPost(Map<String, dynamic> post) {
    final i = _statusFeed.indexWhere((p) => '${p['id']}' == '${post['id']}');
    if (i < 0) {
      _statusFeed.insert(0, post);
    } else {
      _statusFeed[i] = post;
    }
    notifyListeners();
    _persistStatusFeed();
  }

  // Sidebar Collapse
  bool _isSidebarCollapsed = false;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  // Search & Filters for Workforce
  String _employeeSearch = '';
  String _selectedDepartment = 'All';
  String _selectedStatus = 'All';

  String get employeeSearch => _employeeSearch;
  String get selectedDepartment => _selectedDepartment;
  String get selectedStatus => _selectedStatus;

  void setEmployeeSearch(String query) {
    _employeeSearch = query;
    notifyListeners();
  }

  void setDepartmentFilter(String dept) {
    _selectedDepartment = dept;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  // Selected Employee for Detail View
  Employee? _selectedEmployee;
  Employee? get selectedEmployee => _selectedEmployee;

  void selectEmployee(Employee? employee) {
    _selectedEmployee = employee;
    notifyListeners();
  }

  // Notification Drawer (demo / offline sample — live API replaces when logged in)
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Your acknowledgement is required for: (Resignations)',
      'desc': 'Demo Admin submitted a resignation request',
      'time': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
      'icon': Icons.person_off_outlined,
      'color': const Color(0xFFE11D48),
      'read': false,
      'from': 'Demo Admin',
    },
    {
      'id': '2',
      'title': 'Your acknowledgement is required for: (Leaves)',
      'desc': 'Annual Leave · 3 days pending approval',
      'time': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'icon': Icons.beach_access_rounded,
      'color': const Color(0xFF10B981),
      'read': false,
      'from': 'Ali Staff',
    },
    {
      'id': '3',
      'title': 'Approved: Leave request',
      'desc': 'Your leave request has been approved.',
      'time': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'icon': Icons.check_circle_outline,
      'color': const Color(0xFF2A72B5),
      'read': true,
      'from': 'HR Manager',
    },
    {
      'id': '4',
      'title': 'Submitted: Travel request',
      'desc': 'A new travel request was submitted.',
      'time': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      'icon': Icons.flight_takeoff,
      'color': const Color(0xFF06B6D4),
      'read': true,
      'from': 'Operations',
    },
  ];

  List<Map<String, dynamic>> get notifications => _notifications;

  int get unreadNotificationsCount =>
      _notifications.where((n) => n['read'] == false).length;

  void markAllNotificationsRead() {
    for (var n in _notifications) {
      n['read'] = true;
    }
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Data State: Employees
  // -------------------------------------------------------------
  final List<Employee> _employees = [
    const Employee(
      id: 'EMP-1001',
      name: 'Dr. Sarah Jenkins',
      email: 's.jenkins@hr360techx.io',
      role: 'Chief People Officer & VP HR',
      department: 'Human Resources',
      avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
      status: 'Active',
      rating: 4.9,
      joinDate: 'Jan 2021',
      phone: '+1 (555) 234-8890',
      location: 'San Francisco, USA',
      salary: 195000,
      competencies: {
        'Leadership': 0.95,
        'Innovation': 0.90,
        'Delivery': 0.96,
        'Collaboration': 0.98,
        'Strategic Thinking': 0.94,
      },
      recentReview: 'Outstanding executive leadership in establishing company-wide 360 feedback culture.',
    ),
    const Employee(
      id: 'EMP-1002',
      name: 'Alex Rivera',
      email: 'alex.rivera@hr360techx.io',
      role: 'Staff Flutter & Web Architect',
      department: 'Engineering',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      status: 'Active',
      rating: 4.95,
      joinDate: 'Mar 2022',
      phone: '+1 (555) 456-1234',
      location: 'Austin, TX',
      salary: 172000,
      competencies: {
        'Technical Execution': 0.98,
        'Problem Solving': 0.95,
        'Delivery': 0.94,
        'Collaboration': 0.90,
        'Mentorship': 0.88,
      },
      recentReview: 'Engineered high-performance Single Page Architecture with zero UI bottlenecks.',
    ),
    const Employee(
      id: 'EMP-1003',
      name: 'Marcus Chen',
      email: 'm.chen@hr360techx.io',
      role: 'Principal UX/UI Designer',
      department: 'Design',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      status: 'Active',
      rating: 4.85,
      joinDate: 'Nov 2022',
      phone: '+1 (555) 678-9012',
      location: 'Seattle, WA',
      salary: 158000,
      competencies: {
        'Design Systems': 0.96,
        'User Research': 0.92,
        'Innovation': 0.95,
        'Collaboration': 0.89,
        'Delivery': 0.91,
      },
      recentReview: 'Designed the HR360 fluid design tokens and micro-interaction suite.',
    ),
    const Employee(
      id: 'EMP-1004',
      name: 'Elena Rostova',
      email: 'e.rostova@hr360techx.io',
      role: 'Director of Talent Acquisition',
      department: 'Human Resources',
      avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
      status: 'Remote',
      rating: 4.80,
      joinDate: 'Jul 2023',
      phone: '+1 (555) 789-0123',
      location: 'New York, USA',
      salary: 145000,
      competencies: {
        'Talent Sourcing': 0.96,
        'Negotiation': 0.94,
        'Leadership': 0.88,
        'Communication': 0.95,
        'Delivery': 0.92,
      },
      recentReview: 'Reduced average hiring turnaround by 35% with our new pipeline workflow.',
    ),
    const Employee(
      id: 'EMP-1005',
      name: 'David Kim',
      email: 'david.kim@hr360techx.io',
      role: 'Senior Cloud & DevOps Engineer',
      department: 'Engineering',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      status: 'On Leave',
      rating: 4.75,
      joinDate: 'Feb 2023',
      phone: '+1 (555) 890-1234',
      location: 'Vancouver, Canada',
      salary: 160000,
      competencies: {
        'Infrastructure': 0.97,
        'Security': 0.93,
        'Problem Solving': 0.95,
        'Delivery': 0.89,
        'Collaboration': 0.85,
      },
      recentReview: 'Automated 99.99% uptime multi-region cloud deployment pipelines.',
    ),
    const Employee(
      id: 'EMP-1006',
      name: 'Amira Patel',
      email: 'a.patel@hr360techx.io',
      role: 'Lead Product Manager',
      department: 'Product',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      status: 'Active',
      rating: 4.90,
      joinDate: 'Sep 2021',
      phone: '+1 (555) 901-2345',
      location: 'Chicago, USA',
      salary: 165000,
      competencies: {
        'Product Strategy': 0.98,
        'Stakeholder Alignment': 0.95,
        'Data Driven': 0.92,
        'Delivery': 0.94,
        'Leadership': 0.91,
      },
      recentReview: 'Drove 40% adoption growth across our Enterprise clients.',
    ),
    const Employee(
      id: 'EMP-1007',
      name: 'Liam Gallagher',
      email: 'liam.g@hr360techx.io',
      role: 'VP of Growth & Marketing',
      department: 'Marketing',
      avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
      status: 'Remote',
      rating: 4.70,
      joinDate: 'Aug 2023',
      phone: '+1 (555) 012-3456',
      location: 'London, UK',
      salary: 170000,
      competencies: {
        'Growth Marketing': 0.95,
        'Campaign Strategy': 0.93,
        'Analytics': 0.88,
        'Leadership': 0.90,
        'Innovation': 0.92,
      },
      recentReview: 'Launched our global Q3 tech brand campaign exceeding all MQL targets.',
    ),
  ];

  List<Employee> get employees {
    return _employees.where((emp) {
      final matchesSearch = emp.name.toLowerCase().contains(_employeeSearch.toLowerCase()) ||
          emp.role.toLowerCase().contains(_employeeSearch.toLowerCase()) ||
          emp.email.toLowerCase().contains(_employeeSearch.toLowerCase()) ||
          emp.department.toLowerCase().contains(_employeeSearch.toLowerCase());

      final matchesDept = _selectedDepartment == 'All' || emp.department == _selectedDepartment;
      final matchesStatus = _selectedStatus == 'All' || emp.status == _selectedStatus;

      return matchesSearch && matchesDept && matchesStatus;
    }).toList();
  }

  List<Employee> get allEmployeesRaw => _employees;

  void addEmployee(Employee emp) {
    _employees.insert(0, emp);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Data State: Leave Requests
  // -------------------------------------------------------------
  final List<LeaveRequest> _leaveRequests = [
    LeaveRequest(
      id: 'LR-301',
      employeeName: 'David Kim',
      employeeRole: 'Senior Cloud & DevOps Engineer',
      employeeAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      type: 'Annual Leave',
      startDate: 'Sep 18, 2026',
      endDate: 'Sep 21, 2026',
      days: 3,
      reason: 'Family trip and personal time off.',
      status: 'Approved',
      submittedDate: 'Sep 14, 2026',
    ),
    LeaveRequest(
      id: 'LR-302',
      employeeName: 'Elena Rostova',
      employeeRole: 'Director of Talent Acquisition',
      employeeAvatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
      type: 'Work From Home',
      startDate: 'Sep 22, 2026',
      endDate: 'Sep 24, 2026',
      days: 3,
      reason: 'Home fiber line maintenance & focus sprint.',
      status: 'Pending',
      submittedDate: 'Sep 16, 2026',
    ),
    LeaveRequest(
      id: 'LR-303',
      employeeName: 'Marcus Chen',
      employeeRole: 'Principal UX/UI Designer',
      employeeAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      type: 'Casual Leave',
      startDate: 'Sep 28, 2026',
      endDate: 'Sep 29, 2026',
      days: 2,
      reason: 'Attending Design Systems Global Summit.',
      status: 'Pending',
      submittedDate: 'Sep 17, 2026',
    ),
  ];

  List<LeaveRequest> get leaveRequests => _leaveRequests;

  void addLeaveRequest(LeaveRequest req) {
    _leaveRequests.insert(0, req);
    notifyListeners();
  }

  void updateLeaveStatus(String id, String newStatus) {
    final index = _leaveRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      _leaveRequests[index].status = newStatus;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // Data State: 360 Reviews & Feedback
  // -------------------------------------------------------------
  final List<ReviewItem> _reviews = [
    const ReviewItem(
      id: 'REV-501',
      employeeId: 'EMP-1002',
      employeeName: 'Alex Rivera',
      reviewerName: 'Dr. Sarah Jenkins',
      reviewerRole: 'VP HR',
      reviewerAvatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
      reviewType: 'Manager Review',
      score: 4.95,
      feedback: 'Alex continues to raise the engineering bar across frontend and web platforms. Exceptional cross-functional collaboration.',
      date: 'Sep 15, 2026',
      scores: {
        'Technical Depth': 5.0,
        'Problem Solving': 5.0,
        'Collaboration': 4.8,
        'Innovation': 5.0,
        'Mentorship': 4.7,
      },
    ),
    const ReviewItem(
      id: 'REV-502',
      employeeId: 'EMP-1003',
      employeeName: 'Marcus Chen',
      reviewerName: 'Amira Patel',
      reviewerRole: 'Lead Product Manager',
      reviewerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      reviewType: 'Peer Review',
      score: 4.85,
      feedback: 'Marcus brings user empathy into every product feature. Rapid prototyping and pixel perfection make our team move 2x faster.',
      date: 'Sep 12, 2026',
      scores: {
        'Design Systems': 4.9,
        'User Centricity': 5.0,
        'Speed & Agility': 4.7,
        'Communication': 4.8,
        'Leadership': 4.6,
      },
    ),
    const ReviewItem(
      id: 'REV-503',
      employeeId: 'EMP-1006',
      employeeName: 'Amira Patel',
      reviewerName: 'Alex Rivera',
      reviewerRole: 'Staff Architect',
      reviewerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      reviewType: 'Peer Review',
      score: 4.90,
      feedback: 'Clear product specifications, transparent roadmap priorities, and remarkable ability to bridge business requirements with engineering reality.',
      date: 'Sep 10, 2026',
      scores: {
        'Product Strategy': 5.0,
        'Clarity & Specs': 4.9,
        'Execution': 4.8,
        'Team Synergy': 4.9,
        'Innovation': 4.8,
      },
    ),
  ];

  List<ReviewItem> get reviews => _reviews;

  void addReview(ReviewItem review) {
    _reviews.insert(0, review);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Data State: Recruitment Pipeline Kanban
  // -------------------------------------------------------------
  final List<Candidate> _candidates = [
    Candidate(
      id: 'CND-801',
      name: 'Elena Vance',
      role: 'Staff Site Reliability Engineer',
      department: 'Engineering',
      stage: 'Interview',
      experience: '7+ Years',
      rating: 4.9,
      appliedDate: 'Sep 10, 2026',
      skills: ['Kubernetes', 'Terraform', 'Go', 'GCP', 'Observability'],
      email: 'elena.vance@techdev.net',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
    ),
    Candidate(
      id: 'CND-802',
      name: 'Daniel Thorne',
      role: 'Senior Product Designer',
      department: 'Design',
      stage: 'Screening',
      experience: '5 Years',
      rating: 4.7,
      appliedDate: 'Sep 12, 2026',
      skills: ['Figma', 'Prototyping', 'Design Systems', 'Micro-interactions'],
      email: 'd.thorne@designcraft.io',
      avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
    ),
    Candidate(
      id: 'CND-803',
      name: 'Sofia Ramirez',
      role: 'Senior Frontend Engineer (Flutter)',
      department: 'Engineering',
      stage: 'Offer',
      experience: '6 Years',
      rating: 4.95,
      appliedDate: 'Sep 02, 2026',
      skills: ['Flutter Web', 'Dart', 'State Management', 'CI/CD'],
      email: 'sofia.ramirez@devhub.org',
      avatar: 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=150&auto=format&fit=crop&q=80',
    ),
    Candidate(
      id: 'CND-804',
      name: 'Zachary Taylor',
      role: 'HR Business Partner',
      department: 'Human Resources',
      stage: 'Applied',
      experience: '4 Years',
      rating: 4.4,
      appliedDate: 'Sep 15, 2026',
      skills: ['People Analytics', 'Talent Ops', 'Conflict Resolution'],
      email: 'z.taylor@workforce.co',
      avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
    ),
    Candidate(
      id: 'CND-805',
      name: 'Maya Lin',
      role: 'Lead Data Scientist',
      department: 'Engineering',
      stage: 'Hired',
      experience: '8 Years',
      rating: 5.0,
      appliedDate: 'Aug 20, 2026',
      skills: ['Python', 'MLOps', 'Predictive Modeling', 'PyTorch'],
      email: 'm.lin@analyticscloud.ai',
      avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
    ),
  ];

  List<Candidate> get candidates => _candidates;

  void moveCandidateStage(String id, String newStage) {
    final index = _candidates.indexWhere((c) => c.id == id);
    if (index != -1) {
      _candidates[index].stage = newStage;
      notifyListeners();
    }
  }

  void addCandidate(Candidate candidate) {
    _candidates.insert(0, candidate);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Computed KPI Metrics
  // -------------------------------------------------------------
  int get totalWorkforceCount => _employees.length;
  int get activeWorkforceCount => _employees.where((e) => e.status == 'Active').length;
  int get onLeaveCount => _employees.where((e) => e.status == 'On Leave').length;
  int get remoteCount => _employees.where((e) => e.status == 'Remote').length;

  double get averagePerformanceRating {
    if (_employees.isEmpty) return 0.0;
    double sum = _employees.fold(0.0, (prev, emp) => prev + emp.rating);
    return sum / _employees.length;
  }

  int get openRequisitionsCount => _candidates.where((c) => c.stage != 'Hired').length;

  double get monthlyPayrollSum {
    double total = _employees.fold(0.0, (prev, emp) => prev + (emp.salary / 12));
    return total;
  }
}
