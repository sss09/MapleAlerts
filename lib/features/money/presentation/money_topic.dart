import 'money_insight.dart';

/// A money area the user can choose to track. Drives which cards appear in the
/// "Found money" section and the onboarding "what should we track?" step.
enum MoneyTopic {
  tfsa(
    insightId: 'tfsa_room',
    label: 'TFSA room',
    blurb: 'Contribution room + over-contribution guardrail',
    icon: 'wallet',
    setupAction: InsightAction.editTfsaProfile,
  ),
  rrsp(
    insightId: 'rrsp_room',
    label: 'RRSP',
    blurb: 'Unused room and the tax a contribution could save',
    icon: 'finance',
    setupAction: InsightAction.editRrspProfile,
  ),
  ccb(
    insightId: 'ccb',
    label: 'Child benefit',
    blurb: 'Estimate your monthly Canada Child Benefit',
    icon: 'family',
    setupAction: InsightAction.editCcbProfile,
  ),
  oas(
    insightId: 'oas',
    label: 'OAS clawback',
    blurb: 'See if your income triggers the OAS recovery tax (65+)',
    icon: 'bell',
    setupAction: InsightAction.editOasProfile,
  ),
  gic(
    insightId: 'gic',
    label: 'GIC maturity',
    blurb: 'Track a maturing GIC and where to shelter the cash',
    icon: 'clock',
    setupAction: InsightAction.editGicProfile,
  ),
  fhsa(
    insightId: 'fhsa',
    label: 'FHSA (first home)',
    blurb: 'First-home savings room — deductible and tax-free',
    icon: 'home',
    setupAction: InsightAction.editFhsaProfile,
  );

  const MoneyTopic({
    required this.insightId,
    required this.label,
    required this.blurb,
    required this.icon,
    required this.setupAction,
  });

  /// The `MoneyInsight.id` this topic produces.
  final String insightId;
  final String label;
  final String blurb;
  final String icon;
  final InsightAction setupAction;

  static MoneyTopic? fromInsightId(String id) {
    for (final t in values) {
      if (t.insightId == id) return t;
    }
    return null;
  }
}

/// Topics enabled by default for a new user — TFSA and RRSP apply to almost
/// everyone; CCB is opt-in (only parents).
const Set<MoneyTopic> kDefaultEnabledTopics = {MoneyTopic.tfsa, MoneyTopic.rrsp};

/// Serializes a topic set to stable string names for persistence.
List<String> topicsToNames(Set<MoneyTopic> topics) =>
    topics.map((t) => t.name).toList();

/// Deserializes persisted names back to a topic set. A null/absent value means
/// "never set" → the defaults; an explicit empty list means "user disabled all".
Set<MoneyTopic> topicsFromNames(List<String>? names) {
  if (names == null) return kDefaultEnabledTopics;
  final result = <MoneyTopic>{};
  for (final n in names) {
    for (final t in MoneyTopic.values) {
      if (t.name == n) result.add(t);
    }
  }
  return result;
}

/// The split the "Found money" section renders: real [cards] (configured
/// insights) and [setups] (enabled-but-unconfigured topics, collapsed into one
/// "get started" card). Insights for disabled topics are dropped.
class FoundMoneyView {
  final List<MoneyInsight> cards;
  final List<MoneyInsight> setups;
  const FoundMoneyView(this.cards, this.setups);
}

FoundMoneyView partitionFoundMoney(
  List<MoneyInsight> insights,
  Set<MoneyTopic> enabled,
) {
  final cards = <MoneyInsight>[];
  final setups = <MoneyInsight>[];
  for (final i in insights) {
    final topic = MoneyTopic.fromInsightId(i.id);
    if (topic != null && !enabled.contains(topic)) continue;
    if (i.kind == InsightKind.setup) {
      setups.add(i);
    } else {
      cards.add(i);
    }
  }
  return FoundMoneyView(cards, setups);
}
