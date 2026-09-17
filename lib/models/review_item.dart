class ReviewItem {
  final String id;
  final String employeeId;
  final String employeeName;
  final String reviewerName;
  final String reviewerRole;
  final String reviewerAvatar;
  final String reviewType; // 'Peer Review', 'Manager Review', 'Self Review', '360 Synthesis'
  final double score; // 1.0 to 5.0
  final String feedback;
  final String date;
  final Map<String, double> scores; // 'Leadership': 4.5, 'Teamwork': 4.8, etc.

  const ReviewItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.reviewerName,
    required this.reviewerRole,
    required this.reviewerAvatar,
    required this.reviewType,
    required this.score,
    required this.feedback,
    required this.date,
    required this.scores,
  });
}
