import 'dart:io';

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/storage/offline_queue.dart';
import 'models.dart';

enum InspectionSubmissionStatus { submitted, queued }

class InspectionSubmissionResult {
  const InspectionSubmissionResult({required this.status, this.error});

  final InspectionSubmissionStatus status;
  final AppException? error;

  bool get isSubmitted => status == InspectionSubmissionStatus.submitted;
  bool get isQueued => status == InspectionSubmissionStatus.queued;
}

class InspectionsRepository {
  InspectionsRepository({required ApiClient apiClient, required OfflineQueueService offlineQueueService})
      : _apiClient = apiClient,
        _offlineQueueService = offlineQueueService;

  final ApiClient _apiClient;
  final OfflineQueueService _offlineQueueService;

  Future<List<VehicleModel>> fetchVehicles() async {
    final response = await _apiClient.get<dynamic>(ApiEndpoints.vehicles);
    final list = _extractList(response.data);
    return list.map(VehicleModel.fromJson).toList();
  }

  Future<List<VehicleAssignmentModel>> fetchAssignments() async {
    final response = await _apiClient.get<dynamic>(ApiEndpoints.assignments);
    final list = _extractList(response.data);
    return list.map(VehicleAssignmentModel.fromJson).toList();
  }

  Future<List<InspectionCategoryModel>> fetchCategories() async {
    final response = await _apiClient.get<dynamic>(ApiEndpoints.categories);
    final list = _extractList(response.data);
    return list.map(InspectionCategoryModel.fromJson).toList();
  }

  Future<List<ChecklistItemModel>> fetchChecklistItems() async {
    final response = await _apiClient.get<dynamic>(ApiEndpoints.checklistItems);
    final list = _extractList(response.data);
    return list.map(ChecklistItemModel.fromJson).toList();
  }

  Future<List<InspectionSummaryModel>> fetchInspections() async {
    final response = await _apiClient.get<dynamic>(ApiEndpoints.inspections);
    final list = _extractList(response.data);
    return list.map(InspectionSummaryModel.fromJson).toList();
  }

  Future<InspectionDetailModel> fetchInspectionDetail(int id) async {
    final response = await _apiClient.get<dynamic>('${ApiEndpoints.inspections}$id/');
    final json = _extractMap(response.data);
    return InspectionDetailModel.fromJson(json);
  }

  Future<int?> createVehicle({
    required int customerId,
    required String vin,
    required String licensePlate,
    required String make,
    required String model,
    required int year,
    required String vehicleType,
    String? axleConfiguration,
    int mileage = 0,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'customer': customerId,
      'vin': vin,
      'license_plate': licensePlate,
      'make': make,
      'model': model,
      'year': year,
      'vehicle_type': vehicleType,
      'axle_configuration': axleConfiguration ?? '',
      'mileage': mileage,
      'notes': notes ?? '',
    };
    final response = await _apiClient.post<dynamic>(ApiEndpoints.vehicles, data: payload);
    final data = response.data;
    if (data is Map<String, dynamic> && data['id'] is int) {
      return data['id'] as int;
    }
    return null;
  }

  Future<InspectionSubmissionResult> submitInspection(InspectionDraftModel draft) async {
    final payload = draft.toOfflinePayload();
    final formData = await _formDataFromPayload(payload);
    try {
      final response = await _apiClient.post<dynamic>(ApiEndpoints.inspections, data: formData);
      final data = response.data;
      if (data is Map<String, dynamic> && data['id'] is int) {
        final id = data['id'] as int;
        await _apiClient.post<dynamic>('${ApiEndpoints.inspections}$id/${ApiEndpoints.inspectionSubmit}');
      }
      return const InspectionSubmissionResult(status: InspectionSubmissionStatus.submitted);
    } on AppException catch (error) {
      await _offlineQueueService.enqueueInspection(payload);
      return InspectionSubmissionResult(status: InspectionSubmissionStatus.queued, error: error);
    }
  }

  Future<int> syncPendingInspections() async {
    final pending = await _offlineQueueService.pendingInspections();
    var processed = 0;
    for (final payload in pending) {
      try {
        final formData = await _formDataFromPayload(payload);
        final response = await _apiClient.post<dynamic>(ApiEndpoints.inspections, data: formData);
        final data = response.data;
        if (data is Map<String, dynamic> && data['id'] is int) {
          final id = data['id'] as int;
          await _apiClient.post<dynamic>('${ApiEndpoints.inspections}$id/${ApiEndpoints.inspectionSubmit}');
        }
        await _offlineQueueService.clearInspection(payload);
        processed += 1;
      } on AppException {
        continue;
      }
    }
    return processed;
  }

  String resolveMediaUrl(String path) => _apiClient.resolveUrl(path);

  Future<FormData> _formDataFromPayload(Map<String, dynamic> payload) async {
    final body = Map<String, dynamic>.from(payload);
    final rawResponses = (payload['item_responses'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    final transformed = <Map<String, dynamic>>[];
    for (final response in rawResponses) {
      final responseCopy = Map<String, dynamic>.from(response);
      final photos = responseCopy.remove('photos');
      if (photos is List) {
        final uploads = <Map<String, dynamic>>[];
        for (final entry in photos) {
          if (entry is! String || entry.isEmpty) {
            continue;
          }
          final filePath = entry.startsWith('file://') ? entry.substring(7) : entry;
          final file = File(filePath);
          if (!await file.exists()) {
            continue;
          }
          final multipart = await MultipartFile.fromFile(file.path, filename: p.basename(file.path));
          uploads.add({'image': multipart});
        }
        if (uploads.isNotEmpty) {
          responseCopy['photos'] = uploads;
        }
      }
      transformed.add(responseCopy);
    }
    body['item_responses'] = transformed;
    return FormData.fromMap(body);
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw AppException('Expected map response but received ${data.runtimeType}');
  }
}
