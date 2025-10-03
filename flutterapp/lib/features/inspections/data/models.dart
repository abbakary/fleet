import 'dart:collection';

import 'dart:collection';

class PortalProfile {
  const PortalProfile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.organization,
  });

  static const roleAdmin = 'admin';
  static const roleInspector = 'inspector';
  static const roleCustomer = 'customer';

  final int id;
  final String role;
  final String fullName;
  final String organization;

  bool get isInspector => role == roleInspector;
  bool get isCustomer => role == roleCustomer;
  bool get isAdmin => role == roleAdmin;

  factory PortalProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final firstName = (user['first_name'] as String? ?? '').trim();
    final lastName = (user['last_name'] as String? ?? '').trim();
    final username = (user['username'] as String? ?? '').trim();
    final fullNameCandidate = '$firstName $lastName'.trim();
    final resolvedName = fullNameCandidate.isEmpty ? username : fullNameCandidate;
    return PortalProfile(
      id: json['id'] as int,
      role: json['role'] as String,
      fullName: resolvedName,
      organization: json['organization'] as String? ?? '',
    );
  }
}

class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.legalName,
    required this.contactEmail,
    required this.contactPhone,
    required this.city,
    required this.state,
    required this.country,
    this.profile,
  });

  final int id;
  final String legalName;
  final String contactEmail;
  final String contactPhone;
  final String city;
  final String state;
  final String country;
  final PortalProfile? profile;

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] as int,
        legalName: json['legal_name'] as String? ?? '',
        contactEmail: json['contact_email'] as String? ?? '',
        contactPhone: json['contact_phone'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        country: json['country'] as String? ?? '',
        profile: json['profile'] is Map<String, dynamic>
            ? PortalProfile.fromJson(json['profile'] as Map<String, dynamic>)
            : null,
      );

  factory CustomerModel.minimal(int id) => CustomerModel(
        id: id,
        legalName: '',
        contactEmail: '',
        contactPhone: '',
        city: '',
        state: '',
        country: '',
      );
}

class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.licensePlate,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.vehicleType,
    required this.mileage,
    this.customerId,
    this.customerName,
  });

  final int id;
  final String licensePlate;
  final String vin;
  final String make;
  final String model;
  final int year;
  final String vehicleType;
  final int mileage;
  final int? customerId;
  final String? customerName;

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
        id: json['id'] as int,
        licensePlate: json['license_plate'] as String? ?? '',
        vin: json['vin'] as String? ?? '',
        make: json['make'] as String? ?? '',
        model: json['model'] as String? ?? '',
        year: json['year'] as int? ?? 0,
        vehicleType: json['vehicle_type'] as String? ?? '',
        mileage: json['mileage'] as int? ?? 0,
        customerId: json['customer'] as int?,
        customerName: json['customer_display'] as String?,
      );

  factory VehicleModel.minimal(int id) => VehicleModel(
        id: id,
        licensePlate: '',
        vin: '',
        make: '',
        model: '',
        year: 0,
        vehicleType: '',
        mileage: 0,
      );
}

class ChecklistItemModel {
  const ChecklistItemModel({
    required this.id,
    required this.category,
    required this.categoryName,
    required this.code,
    required this.title,
    required this.description,
    required this.requiresPhoto,
  });

  final int id;
  final int category;
  final String categoryName;
  final String code;
  final String title;
  final String description;
  final bool requiresPhoto;

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) => ChecklistItemModel(
        id: json['id'] as int,
        category: json['category'] as int? ?? 0,
        categoryName: json['category_name'] as String? ?? '',
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        requiresPhoto: json['requires_photo'] as bool? ?? false,
      );
}

class InspectionCategoryModel {
  const InspectionCategoryModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.items,
  });

  final int id;
  final String code;
  final String name;
  final String description;
  final List<ChecklistItemModel> items;

  factory InspectionCategoryModel.fromJson(Map<String, dynamic> json) => InspectionCategoryModel(
        id: json['id'] as int,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        items: (json['items'] as List<dynamic>? ?? <dynamic>[])
            .map((item) => ChecklistItemModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class InspectionItemResponse {
  static const String RESULT_PASS = 'pass';
  static const String RESULT_FAIL = 'fail';
  static const String RESULT_NA = 'not_applicable';
}

class InspectionItemModel {
  InspectionItemModel({
    required this.checklistItemId,
    required this.result,
    required this.severity,
    required this.notes,
    List<String>? photoUris,
  }) : photoUris = UnmodifiableListView(photoUris ?? <String>[]);

  final int checklistItemId;
  final String result;
  final int severity;
  final String notes;
  final UnmodifiableListView<String> photoUris;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'checklist_item': checklistItemId,
        'result': result,
        'severity': severity,
        'notes': notes,
      };

  Map<String, dynamic> toOfflineJson() => <String, dynamic>{
        ...toJson(),
        'photos': photoUris.toList(),
      };

  InspectionItemModel copyWith({String? result, int? severity, String? notes, List<String>? photoUris}) {
    return InspectionItemModel(
      checklistItemId: checklistItemId,
      result: result ?? this.result,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      photoUris: photoUris ?? this.photoUris,
    );
  }

  factory InspectionItemModel.initialFromChecklist(ChecklistItemModel item) => InspectionItemModel(
        checklistItemId: item.id,
        result: 'pass',
        severity: 1,
        notes: '',
      );
}

class InspectionDraftModel {
  InspectionDraftModel({
    required this.vehicleId,
    required this.inspectorId,
    required this.odometerReading,
    required this.generalNotes,
    required List<InspectionItemModel> items,
    this.assignmentId,
  }) : items = List<InspectionItemModel>.unmodifiable(items);

  final int? assignmentId;
  final int vehicleId;
  final int inspectorId;
  final int odometerReading;
  final String generalNotes;
  final List<InspectionItemModel> items;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (assignmentId != null) 'assignment': assignmentId,
        'vehicle': vehicleId,
        'inspector': inspectorId,
        'status': 'in_progress',
        'odometer_reading': odometerReading,
        'general_notes': generalNotes,
        'item_responses': items.map((item) => item.toJson()).toList(),
      };

  Map<String, dynamic> toOfflinePayload() => <String, dynamic>{
        if (assignmentId != null) 'assignment': assignmentId,
        'vehicle': vehicleId,
        'inspector': inspectorId,
        'status': 'in_progress',
        'odometer_reading': odometerReading,
        'general_notes': generalNotes,
        'item_responses': items.map((item) => item.toOfflineJson()).toList(),
      };

  static InspectionDraftModel fromOfflinePayload(Map<String, dynamic> payload) {
    final responses = payload['item_responses'] as List<dynamic>? ?? <dynamic>[];
    return InspectionDraftModel(
      assignmentId: payload['assignment'] as int?,
      vehicleId: payload['vehicle'] as int,
      inspectorId: payload['inspector'] as int,
      odometerReading: payload['odometer_reading'] as int? ?? 0,
      generalNotes: payload['general_notes'] as String? ?? '',
      items: responses
          .whereType<Map<String, dynamic>>()
          .map(
            (response) => InspectionItemModel(
              checklistItemId: response['checklist_item'] as int,
              result: response['result'] as String? ?? 'pass',
              severity: response['severity'] as int? ?? 1,
              notes: response['notes'] as String? ?? '',
              photoUris: (response['photos'] as List<dynamic>? ?? <dynamic>[])
                  .whereType<String>()
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}

class VehicleAssignmentModel {
  const VehicleAssignmentModel({
    required this.id,
    required this.vehicleId,
    required this.inspectorId,
    required this.assignedById,
    required this.scheduledFor,
    required this.status,
    required this.remarks,
  });

  final int id;
  final int vehicleId;
  final int inspectorId;
  final int? assignedById;
  final DateTime scheduledFor;
  final String status;
  final String remarks;

  factory VehicleAssignmentModel.fromJson(Map<String, dynamic> json) => VehicleAssignmentModel(
        id: json['id'] as int,
        vehicleId: json['vehicle'] as int,
        inspectorId: json['inspector'] as int,
        assignedById: json['assigned_by'] as int?,
        scheduledFor: DateTime.parse(json['scheduled_for'] as String),
        status: json['status'] as String? ?? 'assigned',
        remarks: json['remarks'] as String? ?? '',
      );
}

class InspectorProfileModel {
  const InspectorProfileModel({
    required this.id,
    required this.badgeId,
    required this.certifications,
    required this.isActive,
    required this.maxDailyInspections,
    required this.profile,
  });

  final int id;
  final String badgeId;
  final String certifications;
  final bool isActive;
  final int maxDailyInspections;
  final PortalProfile profile;

  factory InspectorProfileModel.fromJson(Map<String, dynamic> json) => InspectorProfileModel(
        id: json['id'] as int,
        badgeId: json['badge_id'] as String? ?? '',
        certifications: json['certifications'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? false,
        maxDailyInspections: json['max_daily_inspections'] as int? ?? 0,
        profile: PortalProfile.fromJson(json['profile'] as Map<String, dynamic>),
      );
}

class InspectionSummaryModel {
  const InspectionSummaryModel({
    required this.id,
    required this.reference,
    required this.vehicle,
    required this.status,
    required this.statusDisplay,
    required this.createdAt,
    this.customer,
    this.inspector,
  });

  final int id;
  final String reference;
  final VehicleModel vehicle;
  final String status;
  final String statusDisplay;
  final DateTime createdAt;
  final CustomerModel? customer;
  final InspectorProfileModel? inspector;

  factory InspectionSummaryModel.fromJson(Map<String, dynamic> json) => InspectionSummaryModel(
        id: json['id'] as int,
        reference: json['reference'] as String? ?? '',
        vehicle: VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>),
        status: json['status'] as String? ?? '',
        statusDisplay: json['status_display'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        customer: json['customer'] is Map<String, dynamic>
            ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
            : null,
        inspector: json['inspector'] is Map<String, dynamic>
            ? InspectorProfileModel.fromJson(json['inspector'] as Map<String, dynamic>)
            : null,
      );
}

class InspectionDetailItemModel {
  const InspectionDetailItemModel({
    required this.id,
    required this.checklistItem,
    required this.result,
    required this.severity,
    required this.notes,
    required this.photoPaths,
  });

  final int id;
  final ChecklistItemModel checklistItem;
  final String result;
  final int severity;
  final String notes;
  final List<String> photoPaths;

  factory InspectionDetailItemModel.fromJson(Map<String, dynamic> json) {
    final detail = json['checklist_item_detail'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final checklistJson = <String, dynamic>{
      'id': detail['id'] as int? ?? json['checklist_item'] as int? ?? 0,
      'category': detail['category'] as int? ?? 0,
      'category_name': detail['category_name'] as String? ?? '',
      'code': detail['code'] as String? ?? '',
      'title': detail['title'] as String? ?? '',
      'description': detail['description'] as String? ?? '',
      'requires_photo': detail['requires_photo'] as bool? ?? false,
    };
    return InspectionDetailItemModel(
      id: json['id'] as int,
      checklistItem: ChecklistItemModel.fromJson(checklistJson),
      result: json['result'] as String? ?? 'pass',
      severity: json['severity'] as int? ?? 1,
      notes: json['notes'] as String? ?? '',
      photoPaths: (json['photos'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map((photo) => photo['image'] as String? ?? '')
          .where((path) => path.isNotEmpty)
          .toList(),
    );
  }
}

class CustomerReportModel {
  const CustomerReportModel({
    required this.summary,
    required this.recommendedActions,
    required this.publishedAt,
  });

  final String summary;
  final String recommendedActions;
  final DateTime? publishedAt;

  factory CustomerReportModel.fromJson(Map<String, dynamic> json) => CustomerReportModel(
        summary: json['summary'] as String? ?? '',
        recommendedActions: json['recommended_actions'] as String? ?? '',
        publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : null,
      );
}

class InspectionDetailModel {
  const InspectionDetailModel({
    required this.id,
    required this.reference,
    required this.vehicle,
    required this.customer,
    required this.status,
    required this.createdAt,
    required this.odometerReading,
    required this.generalNotes,
    required this.responses,
    this.inspectorId,
    this.startedAt,
    this.completedAt,
    this.customerReport,
  });

  final int id;
  final String reference;
  final VehicleModel vehicle;
  final CustomerModel customer;
  final String status;
  final DateTime createdAt;
  final int odometerReading;
  final String generalNotes;
  final List<InspectionDetailItemModel> responses;
  final int? inspectorId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final CustomerReportModel? customerReport;

  factory InspectionDetailModel.fromJson(Map<String, dynamic> json) {
    final vehicleField = json['vehicle'];
    final vehicle = vehicleField is Map<String, dynamic>
        ? VehicleModel.fromJson(vehicleField)
        : VehicleModel.minimal(vehicleField as int? ?? 0);
    final customerField = json['customer'];
    final customer = customerField is Map<String, dynamic>
        ? CustomerModel.fromJson(customerField)
        : CustomerModel.minimal(customerField as int? ?? 0);
    return InspectionDetailModel(
      id: json['id'] as int,
      reference: json['reference'] as String? ?? '',
      vehicle: vehicle,
      customer: customer,
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      odometerReading: json['odometer_reading'] as int? ?? 0,
      generalNotes: json['general_notes'] as String? ?? '',
      responses: (json['item_responses'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(InspectionDetailItemModel.fromJson)
          .toList(),
      inspectorId: json['inspector'] as int?,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      customerReport: json['customer_report'] is Map<String, dynamic>
          ? CustomerReportModel.fromJson(json['customer_report'] as Map<String, dynamic>)
          : null,
    );
  }
}
