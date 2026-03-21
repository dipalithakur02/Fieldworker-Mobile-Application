import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class ApiService {

  static final Dio _dio = Dio(
    BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          "Content-Type": "application/json"
        }
    ),
  );

  /// Set JWT token after login
  static void setToken(String token) {
    _dio.options.headers["Authorization"] = "Bearer $token";
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
      final options = data is FormData
          ? Options(contentType: 'multipart/form-data')
          : null;
      return await _dio.post(path, data: data, options: options);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// PUT
  static Future<Response> put(String path, dynamic data) async {
    try {
      return await _dio.put(path, data: data);
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
}