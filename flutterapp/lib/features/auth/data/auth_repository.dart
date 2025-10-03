import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/storage/token_store.dart';
import '../../inspections/data/models.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient, required TokenStore tokenStore})
      : _apiClient = apiClient,
        _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;

  Future<PortalProfile> login({required String username, required String password}) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.login,
      data: jsonEncode({'username': username, 'password': password}),
    );
    final data = response.data as Map<String, dynamic>?;
    if (data == null || data['token'] == null) {
      throw AppException('Authentication response missing token');
    }
    await _tokenStore.persistToken(data['token'] as String);
    final profileJson = data['profile'] as Map<String, dynamic>?;
    if (profileJson == null) {
      throw AppException('Authentication response missing profile');
    }
    return PortalProfile.fromJson(profileJson);
  }

  Future<void> logout() => _tokenStore.clear();
}
