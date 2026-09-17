class Candidate {
  final String id;
  final String name;
  final String role;
  final String department;
  String stage; // 'Applied', 'Screening', 'Interview', 'Offered', 'Hired'
  final String experience;
  final double rating;
  final String appliedDate;
  final List<String> skills;
  final String email;
  final String avatar;

  Candidate({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.stage,
    required this.experience,
    required this.rating,
    required this.appliedDate,
    required this.skills,
    required this.email,
    required this.avatar,
  });
}
