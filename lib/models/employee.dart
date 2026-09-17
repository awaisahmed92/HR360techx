class Employee {
  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final String avatar;
  final String status; // 'Active', 'On Leave', 'Remote'
  final double rating; // 1.0 to 5.0
  final String joinDate;
  final String phone;
  final String location;
  final double salary;
  final Map<String, double> competencies; // 0.0 to 1.0
  final String recentReview;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.avatar,
    required this.status,
    required this.rating,
    required this.joinDate,
    required this.phone,
    required this.location,
    required this.salary,
    required this.competencies,
    required this.recentReview,
  });

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? department,
    String? avatar,
    String? status,
    double? rating,
    String? joinDate,
    String? phone,
    String? location,
    double? salary,
    Map<String, double>? competencies,
    String? recentReview,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      joinDate: joinDate ?? this.joinDate,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      competencies: competencies ?? this.competencies,
      recentReview: recentReview ?? this.recentReview,
    );
  }
}
