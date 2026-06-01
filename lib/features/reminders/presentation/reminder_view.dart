import 'package:flutter/foundation.dart';

@immutable
class ReminderView {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String status;
  final String section;
  final String whenLabel;
  final double progress;
  final String? amount;

  const ReminderView({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.status,
    required this.section,
    required this.whenLabel,
    required this.progress,
    this.amount,
  });
}
