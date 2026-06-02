import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/money/presentation/money_topic.dart';
import '../utils/constants.dart';

/// The set of found-money topics the user is tracking. Controls which cards
/// appear in the Home "Found money" section. Defaults to TFSA + RRSP; persisted
/// as a list of topic names.
final enabledTopicsProvider =
    StateNotifierProvider<EnabledTopicsNotifier, Set<MoneyTopic>>((ref) {
  return EnabledTopicsNotifier();
});

class EnabledTopicsNotifier extends StateNotifier<Set<MoneyTopic>> {
  EnabledTopicsNotifier() : super(kDefaultEnabledTopics) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(kEnabledTopicsKey);
    state = topicsFromNames(names);
  }

  Future<void> _persist(Set<MoneyTopic> next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(kEnabledTopicsKey, topicsToNames(next));
  }

  bool isEnabled(MoneyTopic topic) => state.contains(topic);

  Future<void> setEnabled(MoneyTopic topic, bool enabled) {
    final next = {...state};
    if (enabled) {
      next.add(topic);
    } else {
      next.remove(topic);
    }
    return _persist(next);
  }

  Future<void> toggle(MoneyTopic topic) =>
      setEnabled(topic, !state.contains(topic));
}
