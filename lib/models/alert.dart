enum AlertType { rrsp, tfsa, gic, mortgage, boc, ccb, osap, tax, custom }

extension AlertTypeExtension on AlertType {
  String get name {
    switch (this) {
      case AlertType.rrsp:
        return 'rrsp';
      case AlertType.tfsa:
        return 'tfsa';
      case AlertType.gic:
        return 'gic';
      case AlertType.mortgage:
        return 'mortgage';
      case AlertType.boc:
        return 'boc';
      case AlertType.ccb:
        return 'ccb';
      case AlertType.osap:
        return 'osap';
      case AlertType.tax:
        return 'tax';
      case AlertType.custom:
        return 'custom';
    }
  }

  static AlertType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'rrsp':
        return AlertType.rrsp;
      case 'tfsa':
        return AlertType.tfsa;
      case 'gic':
        return AlertType.gic;
      case 'mortgage':
        return AlertType.mortgage;
      case 'boc':
        return AlertType.boc;
      case 'ccb':
        return AlertType.ccb;
      case 'osap':
        return AlertType.osap;
      case 'tax':
        return AlertType.tax;
      default:
        return AlertType.custom;
    }
  }
}

class Alert {
  final String id;
  final String title;
  final String description;
  final AlertType type;
  final DateTime deadline;
  final bool reminderEnabled;
  final bool isPremium;
  final Map<String, dynamic> metadata;

  const Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.deadline,
    this.reminderEnabled = true,
    this.isPremium = false,
    this.metadata = const {},
  });

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      type: AlertTypeExtension.fromString(map['type'] as String? ?? 'custom'),
      deadline: DateTime.parse(map['deadline'] as String),
      reminderEnabled: (map['reminderEnabled'] as int? ?? 1) == 1,
      isPremium: (map['isPremium'] as int? ?? 0) == 1,
      metadata: _parseMetadata(map['metadata']),
    );
  }

  static Map<String, dynamic> _parseMetadata(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        // Will be decoded by database_service using jsonDecode
        return {};
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'deadline': deadline.toIso8601String(),
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'isPremium': isPremium ? 1 : 0,
      'metadata': metadata,
    };
  }

  factory Alert.fromJson(Map<String, dynamic> json) => Alert.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  Alert copyWith({
    String? id,
    String? title,
    String? description,
    AlertType? type,
    DateTime? deadline,
    bool? reminderEnabled,
    bool? isPremium,
    Map<String, dynamic>? metadata,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      deadline: deadline ?? this.deadline,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isPremium: isPremium ?? this.isPremium,
      metadata: metadata ?? this.metadata,
    );
  }
}
