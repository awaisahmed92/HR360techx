import 'package:dio/dio.dart';
import '../config/app_config.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({TokenProvider? tokenProvider})
      : _tokenProvider = tokenProvider,
        dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    assert(() {
      // ignore: avoid_print
      print('[HR360] API base → ${AppConfig.apiBaseUrl}');
      return true;
    }());
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_tokenProvider != null) {
            final token = await _tokenProvider!();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final TokenProvider? _tokenProvider;

  void updateBaseUrl(String url) {
    dio.options.baseUrl = url;
  }
}
