import 'parsers.dart';
import 'source.dart';

// WORKING SOURCE URLs (captured 2026-06-03, see parsers.dart header for notes):
//   TFSA + RRSP: https://www.canada.ca/en/revenue-agency/services/tax/registered-plans-administrators/pspa/mp-rrsp-dpsp-tfsa-limits-ympe.html
//   OAS:         https://www.canada.ca/en/services/benefits/publicpensions/old-age-security/recovery-tax.html
//   CCB:         https://www.canada.ca/en/revenue-agency/services/child-family-benefits/canada-child-benefit/how-much.html

/// All watched figures (v1: indexed single-numbers; tax brackets stay manual).
/// CCB exposes four separate sources sharing one fetch (the runner caches by
/// URL so the page is fetched once).
List<WatchedSource> watchedSources() => [
      WatchedSource(
          id: 'tfsa',
          label: 'TFSA annual limit',
          url: Uri.parse(
              'https://www.canada.ca/en/revenue-agency/services/tax/registered-plans-administrators/pspa/mp-rrsp-dpsp-tfsa-limits-ympe.html'),
          parse: parseTfsaLimit,
          min: 5000,
          max: 20000,
          step: 500),
      WatchedSource(
          id: 'rrsp',
          label: 'RRSP dollar maximum',
          url: Uri.parse(
              'https://www.canada.ca/en/revenue-agency/services/tax/registered-plans-administrators/pspa/mp-rrsp-dpsp-tfsa-limits-ympe.html'),
          parse: parseRrspMax,
          min: 25000,
          max: 60000,
          step: 10),
      WatchedSource(
          id: 'oas',
          label: 'OAS recovery threshold',
          url: Uri.parse(
              'https://www.canada.ca/en/services/benefits/publicpensions/old-age-security/recovery-tax.html'),
          parse: parseOasRecoveryThreshold,
          min: 60000,
          max: 200000,
          step: null),
      WatchedSource(
          id: 'ccb_maxUnder6',
          label: 'CCB max (under 6)',
          url: Uri.parse(
              'https://www.canada.ca/en/revenue-agency/services/child-family-benefits/canada-child-benefit/how-much.html'),
          parse: (h) => parseCcb(h)?.maxUnder6,
          min: 5000,
          max: 12000,
          step: null),
      WatchedSource(
          id: 'ccb_max6to17',
          label: 'CCB max (6–17)',
          url: Uri.parse(
              'https://www.canada.ca/en/revenue-agency/services/child-family-benefits/canada-child-benefit/how-much.html'),
          parse: (h) => parseCcb(h)?.max6to17,
          min: 4000,
          max: 11000,
          step: null),
      WatchedSource(
          id: 'ccb_threshold1',
          label: 'CCB phase-out threshold 1',
          url: Uri.parse(
              'https://www.canada.ca/en/revenue-agency/services/child-family-benefits/canada-child-benefit/how-much.html'),
          parse: (h) => parseCcb(h)?.threshold1,
          min: 25000,
          max: 60000,
          step: null),
      WatchedSource(
          id: 'ccb_threshold2',
          label: 'CCB phase-out threshold 2',
          url: Uri.parse(
              'https://www.canada.ca/en/revenue-agency/services/child-family-benefits/canada-child-benefit/how-much.html'),
          parse: (h) => parseCcb(h)?.threshold2,
          min: 60000,
          max: 120000,
          step: null),
    ];
