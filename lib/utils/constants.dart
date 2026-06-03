import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF1B5E20);
const Color kSecondaryColor = Color(0xFFD52B1E);
const Color kAccentGold = Color(0xFFF9A825);

const String kRevenueCatApiKey = 'appl_PLACEHOLDER';
const String kRevenueCatEntitlement = 'premium';

const String kEqBankUrl = 'https://www.eqbank.ca';
const String kWealthsimpleUrl = 'https://www.wealthsimple.com';
const String kRatehubUrl = 'https://www.ratehub.ca';

const Map<int, int> kTfsaAnnualLimits = {
  2009: 5000,
  2010: 5000,
  2011: 5000,
  2012: 5000,
  2013: 5500,
  2014: 5500,
  2015: 10000,
  2016: 5500,
  2017: 5500,
  2018: 5500,
  2019: 6000,
  2020: 6000,
  2021: 6000,
  2022: 6000,
  2023: 6500,
  2024: 7000,
  2025: 7000,
  2026: 7000,
};

const int kTfsaStartYear = 2009;

const String kAppName = 'MapleAlerts';
const String kOnboardingDoneKey = 'onboarding_done';
const String kNotificationsEnabledKey = 'notifications_enabled';
const String kTfsaBirthYearKey = 'tfsa_birth_year';
const String kRrspContributionKey = 'rrsp_contribution';

/// Structured MoneyProfile blob (JSON). Single key for all financial inputs the
/// Canadian Data Engine reads — see MoneyProfileStore.
const String kMoneyProfileKey = 'money_profile';

/// Which found-money topics the user is tracking (list of MoneyTopic names).
const String kEnabledTopicsKey = 'enabled_money_topics';

/// Cached Bank of Canada policy rate (JSON: rate + asOf date).
const String kBocRateKey = 'boc_rate_cache';

/// Bank of Canada Valet API: target for the overnight rate (policy rate).
const String kBocValetPolicyRateUrl =
    'https://www.bankofcanada.ca/valet/observations/V39079/json?recent=1';
const String kBocValetPolicySeries = 'V39079';

/// Standing spread of the chartered-bank prime rate over the BoC policy rate.
/// Prime is set by banks, not the BoC — shown as a "typical" derived figure.
const double kBocPrimeSpread = 2.20;

/// Prefs key: anonymous analytics opt-out (bool, default true = sharing on).
const String kAnalyticsEnabledKey = 'analytics_enabled_v1';

/// Hosted data pack — the one JSON file that keeps Canadian figures current
/// without an app release (see docs/superpowers/specs/2026-06-02-hosted-data-pack-design.md).
const String kDataPackUrl =
    'https://sss09.github.io/MapleAlerts/datapack/pack.json';

/// Prefs key: raw cached pack JSON.
const String kDataPackJsonKey = 'data_pack_json_v1';

/// Prefs key: ISO timestamp of the last successful pack fetch.
const String kDataPackFetchedAtKey = 'data_pack_fetched_at_v1';

/// Re-fetch the pack when the cache is older than this.
const Duration kDataPackTtl = Duration(hours: 24);
