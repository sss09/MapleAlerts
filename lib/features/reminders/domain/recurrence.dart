enum RecurrenceFrequency { annual, monthly }

/// How often a [RecurringSchedule] repeats.
class Recurrence {
  final RecurrenceFrequency frequency;
  final int interval; // every N units (years for annual, months for monthly)

  const Recurrence({required this.frequency, this.interval = 1});

  Map<String, dynamic> toJson() => {
        'frequency': frequency.name,
        'interval': interval,
      };

  factory Recurrence.fromJson(Map<String, dynamic> json) => Recurrence(
        frequency: RecurrenceFrequency.values.firstWhere(
          (e) => e.name == json['frequency'],
          orElse: () => RecurrenceFrequency.annual,
        ),
        interval: (json['interval'] as int?) ?? 1,
      );
}
