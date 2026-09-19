import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../auth/auth_state.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';

class UploadService {
  UploadService(this._auth);

  final AuthState _auth;

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  Future<({String? path, String? url, String? error})> pickAndUploadCompanyLogo() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return (path: null, url: null, error: null);
    }
    final f = picked.files.first;
    final bytes = f.bytes;
    if (bytes == null) return (path: null, url: null, error: 'Could not read file.');
    return _postMultipart(
      '/uploads/company-logo',
      filename: f.name,
      bytes: bytes,
    );
  }

  Future<({String? path, String? url, String? error})> pickAndUploadEmployeePhoto(int employeeId) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return (path: null, url: null, error: null);
    }
    final f = picked.files.first;
    final bytes = f.bytes;
    if (bytes == null) return (path: null, url: null, error: 'Could not read file.');
    return _postMultipart(
      '/uploads/employees/$employeeId/photo',
      filename: f.name,
      bytes: bytes,
    );
  }

  Future<({String? path, String? url, String? error})> _postMultipart(
    String path, {
    required String filename,
    required List<int> bytes,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await _api.dio.post(
        path,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final d = res.data;
      if (d is Map && d['success'] == true) {
        final p = d['path']?.toString();
        final u = d['url']?.toString() ?? AppConfig.resolveMediaUrl(p);
        return (path: p, url: u, error: null);
      }
      return (
        path: null,
        url: null,
        error: (d is Map ? d['message'] : null)?.toString() ?? 'Upload failed',
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        return (path: null, url: null, error: body['message'].toString());
      }
      return (path: null, url: null, error: e.message ?? 'Network error');
    }
  }
}
