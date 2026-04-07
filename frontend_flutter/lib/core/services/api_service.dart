import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {"Content-Type": "application/json"},
    ),
  );

  static Future<String?> Function()? _onRefreshToken;
  static Future<void> Function()? _onSessionExpired;
  static Future<String?>? _refreshOperation;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {"Content-Type": "application/json"},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final requestOptions = error.requestOptions;
          final statusCode = error.response?.statusCode;
          final isRetry = requestOptions.extra['retried'] == true;
          final isRefreshRequest =
              requestOptions.path.contains('/auth/refresh');
          final isLoginRequest = requestOptions.path.contains('/auth/login');
          final isRegisterRequest =
              requestOptions.path.contains('/auth/register');

          if (statusCode == 401 &&
              !isRetry &&
              !isRefreshRequest &&
              !isLoginRequest &&
              !isRegisterRequest &&
              _onRefreshToken != null) {
            final newToken = await _refreshAccessToken();

            if (newToken != null && newToken.isNotEmpty) {
              requestOptions.headers['Authorization'] = 'Bearer $newToken';
              requestOptions.extra['retried'] = true;

              final response = await _dio.fetch(requestOptions);
              return handler.resolve(response);
            }

            if (_onSessionExpired != null) {
              await _onSessionExpired!();
            }
          }

          return handler.next(error);
        },
      ),
    );

  static void configureAuth({
    required Future<String?> Function() onRefreshToken,
    required Future<void> Function() onSessionExpired,
  }) {
    _onRefreshToken = onRefreshToken;
    _onSessionExpired = onSessionExpired;
  }

  /// Set JWT token after login
  static void setToken(String token) {
    _dio.options.headers["Authorization"] = "Bearer $token";
    _refreshDio.options.headers["Authorization"] = "Bearer $token";
  }

  static void clearToken() {
    _dio.options.headers.remove("Authorization");
    _refreshDio.options.headers.remove("Authorization");
  }

  /// GET
  static Future<Response> get(String path) async {
    try {
      return await _dio.get(path);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// POST
  static Future<Response> post(String path, dynamic data) async {
    try {
      final options =
          data is FormData ? Options(contentType: 'multipart/form-data') : null;
      return await _dio.post(path, data: data, options: options);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// PUT
  static Future<Response> put(String path, dynamic data) async {
    try {
      final options =
          data is FormData ? Options(contentType: 'multipart/form-data') : null;
      return await _dio.put(path, data: data, options: options);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// PATCH
  static Future<Response> patch(String path, dynamic data) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// DELETE
  static Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Handle API errors
  static String _handleError(DioException error) {
    if (error.response != null) {
      return error.response?.data["message"] ?? "Server error";
    }

    if (error.type == DioExceptionType.connectionTimeout) {
      return "Connection timeout";
    }

    if (error.type == DioExceptionType.connectionError) {
      return "No internet connection";
    }

    return "Unexpected error occurred";
  }

  static Future<String?> _refreshAccessToken() async {
    if (_refreshOperation != null) {
      return _refreshOperation;
    }

    _refreshOperation = _onRefreshToken!.call();

    try {
      return await _refreshOperation;
    } finally {
      _refreshOperation = null;
    }
  }
}
