import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/storage/offline_queue.dart';
import 'models.dart';

enum InspectionSubmissionStatus { submitted, queued, failed }

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

  Future<List<VehicleMakeOption>> fetchVehicleMakes({String? search}) async {
    final response = await _apiClient.get<dynamic>(ApiEndpoints.vehicleMakes, queryParameters: search != null && search.isNotEmpty ? {'search': search} : null);
    final list = _extractList(response.data);
    return list.map(VehicleMakeOption.fromJson).toList();
  }

  Future<List<VehicleModelOption>> fetchVehicleModels({int? makeId, String? makeName, String? search}) async {
    final params = <String, dynamic>{};
    if (makeId != null) params['make'] = makeId;
    if (makeName != null && makeName.isNotEmpty) params['make_name'] = makeName;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await _apiClient.get<dynamic>(ApiEndpoints.vehicleModels, queryParameters: params.isEmpty ? null : params);
    final list = _extractList(response.data);
    return list.map(VehicleModelOption.fromJson).toList();
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

  Future<String> fetchReportHtml(int id) async {
    final response = await _apiClient.get<dynamic>('${ApiEndpoints.inspections}$id/report/');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final html = data['html'];
      if (html is String) return html;
    }
    if (data is String) {
      return data;
    }
    return '';
  }

  Future<String?> downloadReportPdf(int id) async {
    final bytes = await _apiClient.getBytes('${ApiEndpoints.inspections}$id/${ApiEndpoints.inspectionReportPdf}');
    if (bytes.isEmpty) return null;
    final dir = await getApplicationDocumentsDirectory();
    final filename = 'inspection_${id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
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
    final raw = draft.toOfflinePayload();
    final cleaned = Map<String, dynamic>.from(raw)..remove('inspector');
    final formData = await _formDataFromPayload(cleaned);
    try {
      final response = await _apiClient.post<dynamic>(ApiEndpoints.inspections, data: formData);
      final data = response.data;
      if (data is Map<String, dynamic> && data['id'] is int) {
        final id = data['id'] as int;
        await _apiClient.post<dynamic>('${ApiEndpoints.inspections}$id/${ApiEndpoints.inspectionSubmit}');
      }
      return const InspectionSubmissionResult(status: InspectionSubmissionStatus.submitted);
    } on AppException catch (error) {
      final cause = error.cause;
      if (cause is DioException) {
        final status = cause.response?.statusCode;
        final isConnectivity = cause.type == DioExceptionType.connectionError ||
            cause.type == DioExceptionType.connectionTimeout ||
            cause.type == DioExceptionType.unknown && cause.response == null;
        if (isConnectivity || status == null) {
          await _offlineQueueService.enqueueInspection(raw);
          return InspectionSubmissionResult(status: InspectionSubmissionStatus.queued, error: error);
        }
        return InspectionSubmissionResult(status: InspectionSubmissionStatus.failed, error: error);
      }
      return InspectionSubmissionResult(status: InspectionSubmissionStatus.failed, error: error);
    }
  }

  Future<int> syncPendingInspections() async {
    final pending = await _offlineQueueService.pendingInspections();
    var processed = 0;
    for (final payload in pending) {
      try {
        final cleaned = Map<String, dynamic>.from(payload)..remove('inspector');
        final formData = await _formDataFromPayload(cleaned);
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
    
    // Collect all photos to be sent as separate multipart files
    final List<MultipartFile> photoFiles = [];
    final transformed = <Map<String, dynamic>>[];
    
    for (int i = 0; i < rawResponses.length; i++) {
      final response = rawResponses[i];
      final responseCopy = Map<String, dynamic>.from(response);
      final photos = responseCopy.remove('photos');
      
      if (photos is List) {
        final photoRefs = <Map<String, dynamic>>[];
        for (final entry in photos) {
          if (entry is! String || entry.isEmpty) {
            continue;
          }
          
          if (kIsWeb) {
            if (entry.startsWith('data:image')) {
              final base64Part = entry.split(',').last;
              try {
                final bytes = base64Decode(base64Part);
                final multipart = MultipartFile.fromBytes(bytes, filename: 'photo_${DateTime.now().millisecondsSinceEpoch}_${photoFiles.length}.png');
                photoFiles.add(multipart);
                // Add reference to this photo
                photoRefs.add({'is_local_file': true});
              } catch (_) {
                continue;
              }
            }
            continue;
          }
          
          // Handle file paths consistently
          String filePath;
          if (entry.startsWith('file://')) {
            filePath = entry.substring(7); // Remove the file:// prefix
          } else {
            filePath = entry; // Assume it's already a valid path
          }
          final file = File(filePath);
          if (!await file.exists()) {
            continue;
          }
          final multipart = await MultipartFile.fromFile(file.path, filename: p.basename(file.path));
          photoFiles.add(multipart);
          // Add reference to this photo
          photoRefs.add({'is_local_file': true});
        }
        
        if (photoRefs.isNotEmpty) {
          responseCopy['photos'] = photoRefs;
        }
      }
      transformed.add(responseCopy);
    }
    
    body['item_responses'] = transformed;
    
    // Create FormData with both fields and files
    final formData = FormData();
    
    // Add all fields
    body.forEach((key, value) {
      if (key != 'item_responses') {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });
    
    // Add item_responses as JSON string
    formData.fields.add(MapEntry('item_responses', jsonEncode(transformed)));
    
    // Add all photo files
    for (int i = 0; i < photoFiles.length; i++) {
      formData.files.add(MapEntry('photos', photoFiles[i]));
    }
    
    return formData;
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
