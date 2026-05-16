enum ExpertRequestStatus { draft, queued, sent, received, answered, closed }

class ExpertRequest {
  final String id;
  final String parcelId;
  final String? photoPaths;
  final String context;
  final DateTime createdAt;
  final String? remoteId;
  final ExpertRequestStatus status;
  final String? answer;
  final DateTime? answeredAt;

  const ExpertRequest({
    required this.id,
    required this.parcelId,
    this.photoPaths,
    required this.context,
    required this.createdAt,
    this.remoteId,
    this.status = ExpertRequestStatus.draft,
    this.answer,
    this.answeredAt,
  });

  ExpertRequest copyWith({
    String? id,
    String? parcelId,
    String? photoPaths,
    String? context,
    DateTime? createdAt,
    String? remoteId,
    ExpertRequestStatus? status,
    String? answer,
    DateTime? answeredAt,
  }) {
    return ExpertRequest(
      id: id ?? this.id,
      parcelId: parcelId ?? this.parcelId,
      photoPaths: photoPaths ?? this.photoPaths,
      context: context ?? this.context,
      createdAt: createdAt ?? this.createdAt,
      remoteId: remoteId ?? this.remoteId,
      status: status ?? this.status,
      answer: answer ?? this.answer,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcelId': parcelId,
    'photoPaths': photoPaths,
    'context': context,
    'createdAt': createdAt.toIso8601String(),
    'remoteId': remoteId,
    'status': status.name,
    'answer': answer,
    'answeredAt': answeredAt?.toIso8601String(),
  };

  factory ExpertRequest.fromJson(Map<String, dynamic> json) => ExpertRequest(
    id: json['id'] as String,
    parcelId: json['parcelId'] as String,
    photoPaths: json['photoPaths'] as String?,
    context: json['context'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    remoteId: json['remoteId'] as String?,
    status: ExpertRequestStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ExpertRequestStatus.queued,
    ),
    answer: json['answer'] as String?,
    answeredAt: json['answeredAt'] != null ? DateTime.parse(json['answeredAt'] as String) : null,
  );
}
