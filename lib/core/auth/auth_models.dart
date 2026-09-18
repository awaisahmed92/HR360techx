class AuthUser {
  final int employeeId;
  final String name;
  final String userName;
  final String email;
  final int designationId;
  final String designationName;
  final int userStatus;
  final bool isFirstLogin;
  final String? profilePicture;
  final bool isSuperuser;

  const AuthUser({
    required this.employeeId,
    required this.name,
    required this.userName,
    required this.email,
    required this.designationId,
    required this.designationName,
    required this.userStatus,
    required this.isFirstLogin,
    this.profilePicture,
    required this.isSuperuser,
  });

  bool get isAdmin => userStatus == 2 || isSuperuser;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      employeeId: (json['employee_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      userName: (json['user_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      designationId: (json['designation_id'] as num?)?.toInt() ?? 0,
      designationName: (json['designation_name'] ?? '').toString(),
      userStatus: (json['user_status'] as num?)?.toInt() ?? 0,
      isFirstLogin: (json['is_first_login'] as num?)?.toInt() == 1,
      profilePicture: json['profile_picture']?.toString(),
      isSuperuser: json['is_superuser'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'name': name,
        'user_name': userName,
        'email': email,
        'designation_id': designationId,
        'designation_name': designationName,
        'user_status': userStatus,
        'is_first_login': isFirstLogin ? 1 : 0,
        'profile_picture': profilePicture,
        'is_superuser': isSuperuser,
      };
}

class AuthCompany {
  final String name;
  final String code;
  final String? logo;
  final String currency;
  final String dateFormat;
  final String subdomain;

  const AuthCompany({
    required this.name,
    required this.code,
    this.logo,
    required this.currency,
    required this.dateFormat,
    required this.subdomain,
  });

  factory AuthCompany.fromJson(Map<String, dynamic> json) {
    return AuthCompany(
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      logo: json['logo']?.toString(),
      currency: (json['currency'] ?? 'PKR').toString(),
      dateFormat: (json['date_format'] ?? 'd-m-Y').toString(),
      subdomain: (json['subdomain'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'logo': logo,
        'currency': currency,
        'date_format': dateFormat,
        'subdomain': subdomain,
      };
}

class ScreenPermission {
  final bool view;
  final bool add;
  final bool edit;
  final bool delete;

  const ScreenPermission({
    this.view = false,
    this.add = false,
    this.edit = false,
    this.delete = false,
  });

  factory ScreenPermission.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ScreenPermission();
    return ScreenPermission(
      view: json['view'] == true,
      add: json['add'] == true,
      edit: json['edit'] == true,
      delete: json['delete'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'view': view,
        'add': add,
        'edit': edit,
        'delete': delete,
      };
}

class ModulePermission {
  final bool enabled;
  final Map<String, ScreenPermission> screens;

  const ModulePermission({
    this.enabled = false,
    this.screens = const {},
  });

  factory ModulePermission.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ModulePermission();
    final rawScreens = json['screens'];
    final screens = <String, ScreenPermission>{};
    if (rawScreens is Map) {
      rawScreens.forEach((key, value) {
        screens[key.toString()] = ScreenPermission.fromJson(
          value is Map<String, dynamic>
              ? value
              : Map<String, dynamic>.from(value as Map),
        );
      });
    }
    return ModulePermission(
      enabled: json['enabled'] == true,
      screens: screens,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'screens': screens.map((k, v) => MapEntry(k, v.toJson())),
      };
}

class AuthPermissions {
  final bool all;
  final Map<String, ModulePermission> modules;

  const AuthPermissions({
    this.all = false,
    this.modules = const {},
  });

  factory AuthPermissions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AuthPermissions();
    final rawModules = json['modules'];
    final modules = <String, ModulePermission>{};
    if (rawModules is Map) {
      rawModules.forEach((key, value) {
        modules[key.toString()] = ModulePermission.fromJson(
          value is Map<String, dynamic>
              ? value
              : Map<String, dynamic>.from(value as Map),
        );
      });
    }
    return AuthPermissions(
      all: json['all'] == true,
      modules: modules,
    );
  }

  Map<String, dynamic> toJson() => {
        'all': all,
        'modules': modules.map((k, v) => MapEntry(k, v.toJson())),
      };

  bool canViewModule(String module) {
    if (all) return true;
    final m = modules[module];
    if (m == null) return false;
    if (m.enabled) return true;
    return m.screens.values.any((s) => s.view);
  }

  bool canView(String module, String screen) {
    if (all) return true;
    final m = modules[module];
    if (m == null) return false;
    final s = m.screens[screen];
    return s?.view == true;
  }

  bool canAdd(String module, String screen) {
    if (all) return true;
    return modules[module]?.screens[screen]?.add == true;
  }

  bool canEdit(String module, String screen) {
    if (all) return true;
    return modules[module]?.screens[screen]?.edit == true;
  }

  bool canDelete(String module, String screen) {
    if (all) return true;
    return modules[module]?.screens[screen]?.delete == true;
  }
}

class AuthSession {
  final String token;
  final AuthUser user;
  final AuthCompany company;
  final AuthPermissions permissions;
  final bool isDemo;

  const AuthSession({
    required this.token,
    required this.user,
    required this.company,
    required this.permissions,
    this.isDemo = false,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: (json['token'] ?? '').toString(),
      user: AuthUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? {}),
      ),
      company: AuthCompany.fromJson(
        Map<String, dynamic>.from(json['company'] as Map? ?? {}),
      ),
      permissions: AuthPermissions.fromJson(
        json['permissions'] is Map
            ? Map<String, dynamic>.from(json['permissions'] as Map)
            : null,
      ),
      isDemo: json['is_demo'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'user': user.toJson(),
        'company': company.toJson(),
        'permissions': permissions.toJson(),
        'is_demo': isDemo,
      };
}
