import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import './storage_service.dart';
class ApiService {
  final Dio dio = Dio();
  final StorageService _storageService;
  ApiService(this._storageService) {
    dio.options.baseUrl = ApiEndpoints.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Append the active access token as a Bearer authorization header if it exists
          final token = _storageService.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Automatically intercept 401 Unauthorized errors and attempt to refresh tokens
          if (error.response?.statusCode == 401 && _storageService.refreshToken != null) {
            try {
              final refreshResponse = await _refreshAccessToken();
              if (refreshResponse != null) {
                final newAccessToken = refreshResponse['access_token'];
                final newRefreshToken = refreshResponse['refresh_token'];
                // Update stored token values
                await _storageService.updateAccessToken(newAccessToken);
                if (newRefreshToken != null) {
                  await _storageService.saveSession(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                    role: _storageService.userRole ?? '',
                    userId: _storageService.userId ?? '',
                    username: _storageService.username ?? '',
                  );
                }
                // Update header of original request and trigger retry
                final requestOptions = error.requestOptions;
                requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final retryResponse = await dio.fetch(requestOptions);
                return handler.resolve(retryResponse);
              }
            } catch (e) {
              // Refresh failed: logout user to prevent loops
              await _storageService.clearSession();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
  /// Private helper using a clean Dio client to execute token refresh requests.
  Future<Map<String, dynamic>?> _refreshAccessToken() async {
    final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
    try {
      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': _storageService.refreshToken},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }
}
