import 'package:dio/dio.dart';

import '../network/api_client.dart';

class SignupException implements Exception {
  SignupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Outcome of a successful sign-up: the organization code and admin login.
class SignupResult {
  const SignupResult({
    required this.organization,
    required this.userName,
    required this.companyName,
    required this.message,
  });

  final String organization;
  final String userName;
  final String companyName;
  final String message;
}

/// Public self sign-up: creates an organization with its own tenant database.
class SignupService {
  SignupService({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  /// Null when the code can be used, otherwise the reason it cannot.
  Future<String?> checkCode(String code) async {
    final cleaned = code.trim();
    if (cleaned.isEmpty) return null;
    try {
      final res = await _api.dio.get(
        '/signup/availability',
        queryParameters: {'code': cleaned},
      );
      final data = res.data;
      if (data is! Map) return null;
      if (data['available'] == true) return null;
      return data['message']?.toString() ?? 'That company code cannot be used.';
    } on DioException {
      // Availability is a convenience; the final submit re-validates anyway.
      return null;
    }
  }

  Future<SignupResult> submit({
    required String name,
    required String companyName,
    required String companyCode,
    required String designation,
    required String industry,
    required String country,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final res = await _api.dio.post(
        '/signup',
        data: {
          'name': name.trim(),
          'company_name': companyName.trim(),
          'company_code': companyCode.trim(),
          'designation': designation.trim(),
          'industry': industry,
          'country': country,
          'email': email.trim(),
          'password': password,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw SignupException(
          data is Map && data['message'] != null
              ? data['message'].toString()
              : 'Sign-up failed. Please try again.',
        );
      }
      return SignupResult(
        organization: data['organization']?.toString() ?? companyCode.trim(),
        userName: data['user_name']?.toString() ?? '',
        companyName: data['company_name']?.toString() ?? companyName.trim(),
        message: data['message']?.toString() ?? 'Your organization is ready.',
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map) {
        if (body['message'] != null) {
          throw SignupException(body['message'].toString());
        }
        // Laravel validation errors
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          throw SignupException(
            first is List && first.isNotEmpty ? first.first.toString() : 'Please check your details.',
          );
        }
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw SignupException('Cannot reach the server. Please try again shortly.');
      }
      throw SignupException('Network error: ${e.message}');
    }
  }
}
