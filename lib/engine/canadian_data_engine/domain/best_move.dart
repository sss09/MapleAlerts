import 'figure_source.dart';

/// What kind of recommendation the best move is.
enum BestMoveKind {
  /// Stop an active penalty (over-contribution).
  fixGuardrail,

  /// Time-sensitive opportunity (e.g. RRSP contribution deadline near).
  deadline,

  /// Best standing opportunity (e.g. RRSP-vs-TFSA contribution).
  opportunity,
}

/// The single highest-value action the engine recommends right now, chosen by a
/// deterministic priority cascade across the user's accounts. Pure data.
class BestMove {
  final BestMoveKind kind;
  final String title;
  final String detail;

  /// The dollar magnitude of the move (penalty avoided / tax saved / sheltered).
  final double? dollarValue;

  /// Insight id of the account to act on ('rrsp_room' / 'tfsa_room'); the app
  /// maps it to a setup action. Engine stays free of presentation enums.
  final String? targetInsightId;

  final List<FigureSource> sources;
  final bool isEstimate;

  const BestMove({
    required this.kind,
    required this.title,
    required this.detail,
    this.dollarValue,
    this.targetInsightId,
    this.sources = const [],
    this.isEstimate = true,
  });
}
