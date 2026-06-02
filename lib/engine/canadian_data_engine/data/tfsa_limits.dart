/// TFSA annual contribution limits by calendar year, in dollars.
///
/// SOURCE OF TRUTH: Canada Revenue Agency. These values are the moat — they
/// must match the official CRA TFSA contribution-room schedule exactly.
/// Verified against CRA at time of writing; the 2026 value follows the
/// announced indexed limit. When CRA publishes a new year, add the entry and
/// bump [kTfsaDataPackVersion].
///
/// A future hosted JSON "data pack" can override these without an app release
/// (see [DataPack]); this const table is the embedded fallback / first slice.
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

/// Version string for the embedded data pack vintage. Bump when the table
/// changes so we can tell which numbers a given build shipped with.
const String kTfsaDataPackVersion = 'tfsa-embedded-2026.1';
