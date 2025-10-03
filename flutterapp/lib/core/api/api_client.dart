import 'package:dio/dio.dart';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../exceptions/app_exception.dart';
import '../storage/token_store.dart';

class ApiClient {
  ApiClient({required AppConfig config, required TokenStore tokenStore})
      : _dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
        _tokenStore = tokenStore {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStore.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Token $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response != null) {
            handler.next(error);
          } else {
            handler.reject(
              DioException(requestOptions: error.requestOptions, error: error.error),
            );
          }
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStore _tokenStore;

  String get baseUrl => _dio.options.baseUrl;

  String resolveUrl(String path) {
    if (path.isEmpty) {
      return baseUrl;
    }
    final uri = Uri.parse(baseUrl);
    if (path.startsWith('http')) {
      return path;
    }
    return uri.resolve(path).toString();
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw AppException('GET $path failed', cause: error);
    }
  }

  Future<Response<T>> post<T>(String path, {Object? data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post<T>(path, data: data, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw AppException('POST $path failed', cause: error);
    }
  }

  Future<Response<T>> put<T>(String path, {Object? data}) async {
    try {
      return await _dio.put<T>(path, data: data);
    } on DioException catch (error) {
      throw AppException('PUT $path failed', cause: error);
    }
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) async {
    try {
      return await _dio.patch<T>(path, data: data);
    } on DioException catch (error) {
      throw AppException('PATCH $path failed', cause: error);
    }
  }

  Future<Response<T>> delete<T>(String path, {Object? data}) async {
    try {
      return await _dio.delete<T>(path, data: data);
    } on DioException catch (error) {
      throw AppException('DELETE $path failed', cause: error);
    }
  }
}
