import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import '../network/dio_provider.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/parcels/presentation/parcels_providers.dart';

enum DiagnosticStatus { pending, analyzed, validated, rejected }

class AiDiagnosticResult {
  final String label;
  final double confidence;
  final List<String> suggestedSymptoms;
  final String recommendations;

  const AiDiagnosticResult({
    required this.label,
    required this.confidence,
    required this.suggestedSymptoms,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'confidence': confidence,
    'suggestedSymptoms': suggestedSymptoms,
    'recommendations': recommendations,
  };

  factory AiDiagnosticResult.fromJson(Map<String, dynamic> json) => AiDiagnosticResult(
    label: json['label'],
    confidence: (json['confidence'] as num).toDouble(),
    suggestedSymptoms: List<String>.from(json['suggestedSymptoms']),
    recommendations: json['recommendations'] ?? '',
  );
}

class DiagnosticRequest {
  final String id;
  final String parcelId;
  final String ownerName;
  final String ownerPhone;
  final String photoUrl;
  final DateTime createdAt;
  final DiagnosticStatus status;
  final AiDiagnosticResult? aiResult; // Claude API analysis
  final String? adminComment;
  final DateTime? validatedAt;

  const DiagnosticRequest({
    required this.id,
    required this.parcelId,
    required this.ownerName,
    required this.ownerPhone,
    required this.photoUrl,
    required this.createdAt,
    this.status = DiagnosticStatus.pending,
    this.aiResult,
    this.adminComment,
    this.validatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcelId': parcelId,
    'ownerName': ownerName,
    'ownerPhone': ownerPhone,
    'photoUrl': photoUrl,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'aiResult': aiResult?.toJson(),
    'adminComment': adminComment,
    'validatedAt': validatedAt?.toIso8601String(),
  };

  factory DiagnosticRequest.fromJson(Map<String, dynamic> json) => DiagnosticRequest(
    id: json['id'],
    parcelId: json['parcelId'],
    ownerName: json['ownerName'] ?? 'Inconnu',
    ownerPhone: json['ownerPhone'] ?? '',
    photoUrl: json['photoUrl'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    status: DiagnosticStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['status'] as String).toLowerCase(),
      orElse: () => DiagnosticStatus.pending,
    ),
    aiResult: json['aiResult'] != null ? AiDiagnosticResult.fromJson(json['aiResult']) : null,
    adminComment: json['adminComment'],
    validatedAt: json['validatedAt'] != null ? DateTime.parse(json['validatedAt']) : null,
  );
}

class AiDiagnosticService {
  final Dio _dio;
  AiDiagnosticService(this._dio);

  static const String boxName = 'diagnostic_requests';

  Future<void> init() async {
    await Hive.openBox(boxName);
  }

  /// Soumet une demande de diagnostic au backend.
  Future<String> submitRequest({
    required String parcelId,
    required String ownerName,
    required String ownerPhone,
    required String photoPath,
    Uint8List? photoBytes,
  }) async {
    MultipartFile photoFile;
    if (kIsWeb && photoBytes != null) {
      photoFile = MultipartFile.fromBytes(photoBytes, filename: 'leaf.jpg');
    } else {
      photoFile = await MultipartFile.fromFile(photoPath, filename: 'leaf.jpg');
    }

    final formData = FormData.fromMap({
      'parcelId': parcelId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'photo': photoFile,
    });

    final response = await _dio.post('/diagnostics', data: formData);
    final data = response.data;
    
    // On garde une copie locale pour le suivi immédiat
    final id = data['id'];
    final request = DiagnosticRequest.fromJson(data);
    
    final box = Hive.box(boxName);
    await box.put(id, request.toJson());

    return id;
  }

  Future<List<DiagnosticRequest>> fetchRequests() async {
    try {
      final response = await _dio.get('/diagnostics');
      final List data = response.data;
      final requests = data.map((e) => DiagnosticRequest.fromJson(e)).toList();
      
      // Sync local box
      final box = Hive.box(boxName);
      for (final r in requests) {
        await box.put(r.id, r.toJson());
      }
      
      return requests;
    } catch (e) {
      // Fallback to local
      return getLocalRequests();
    }
  }

  List<DiagnosticRequest> getLocalRequests() {
    final box = Hive.box(boxName);
    return box.values
        .map((e) => DiagnosticRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

final aiDiagnosticServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final service = AiDiagnosticService(dio);
  service.init();
  return service;
});

final diagnosticRequestsProvider = StreamProvider<List<DiagnosticRequest>>((ref) async* {
  final service = ref.watch(aiDiagnosticServiceProvider);
  final currentUser = ref.watch(authStateProvider).value?.user;
  final techName = currentUser?.name;
  final parcels = ref.watch(parcelsProvider);
  final parcelsMap = {for (final p in parcels) p.id: p};

  List<DiagnosticRequest> filter(List<DiagnosticRequest> list) {
    if (techName == null || techName.isEmpty) return list;
    return list.where((req) {
      final p = parcelsMap[req.parcelId];
      if (p != null && p.technician != null && p.technician != 'Non affecté' && p.technician != techName) {
        return false; // Appartenant à un autre technicien
      }
      return true;
    }).toList();
  }
  
  // Initial fetch
  yield filter(await service.fetchRequests());

  // Simple polling for the demo (every 10s)
  while (true) {
    await Future.delayed(const Duration(seconds: 10));
    yield filter(await service.fetchRequests());
  }
});
