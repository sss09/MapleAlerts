import 'package:uuid/uuid.dart';

import '../models/alert.dart';
import '../utils/date_helpers.dart';

class CanadianDatesService {
  CanadianDatesService._();

  static const _uuid = Uuid();

  /// Returns all built-in Canadian financial alerts for a given [year].
  /// Free alerts: RRSP deadline, TFSA room, first CCB date.
  /// Premium alerts: BoC announcements, remaining CCB dates, OSAP.
  static List<Alert> getBuiltInAlerts(int year) {
    final alerts = <Alert>[];

    // ── RRSP Deadline ───────────────────────────────────────────────────────
    alerts.add(Alert(
      id: 'rrsp_deadline_$year',
      title: 'RRSP Contribution Deadline',
      description:
          'Last day to contribute to your RRSP for the ${year - 1} tax year and '
          'claim the deduction on your CRA T1 return. Your limit is 18% of prior-'
          'year earned income up to the annual CRA maximum, minus any pension '
          'adjustment. Unused room carries forward indefinitely.',
      type: AlertType.rrsp,
      deadline: rrspDeadline(year),
      reminderEnabled: true,
      isPremium: false,
      metadata: {'taxYear': year - 1},
    ));

    // ── TFSA Room Opens ──────────────────────────────────────────────────────
    alerts.add(Alert(
      id: 'tfsa_room_${year + 1}',
      title: 'New TFSA Contribution Room',
      description:
          'On January 1, ${year + 1}, all eligible Canadians aged 18+ receive '
          'new TFSA contribution room. The limit for ${year + 1} is expected to '
          'follow CRA indexation. Withdrawals from $year are also re-added to '
          'your room on January 1, ${year + 1}.',
      type: AlertType.tfsa,
      deadline: DateTime(year + 1, 1, 1),
      reminderEnabled: true,
      isPremium: false,
      metadata: {'year': year + 1},
    ));

    // ── Bank of Canada Announcement Dates ───────────────────────────────────
    final bocDates = bocAnnouncementDates(year);
    for (int i = 0; i < bocDates.length; i++) {
      alerts.add(Alert(
        id: 'boc_${year}_$i',
        title: 'Bank of Canada Rate Decision',
        description:
            'The Bank of Canada announces its overnight interest rate target. '
            'Rate changes directly affect variable-rate mortgages, HELOCs, '
            'and savings account yields (e.g., EQ Bank, Wealthsimple Cash). '
            'Watch for the Monetary Policy Report on select dates.',
        type: AlertType.boc,
        deadline: bocDates[i],
        reminderEnabled: true,
        isPremium: true,
        metadata: {'announcementIndex': i, 'year': year},
      ));
    }

    // ── Canada Child Benefit Payment Dates ───────────────────────────────────
    final ccbDates = ccbPaymentDates(year);
    for (int i = 0; i < ccbDates.length; i++) {
      final date = ccbDates[i];
      final monthName = _monthName(date.month);
      alerts.add(Alert(
        id: 'ccb_${date.year}_${date.month}',
        title: 'CCB Payment — $monthName ${date.year}',
        description:
            'Your Canada Child Benefit payment is deposited today. CCB is '
            'tax-free and based on your family net income from the prior tax '
            'year. Ensure your CRA My Account banking info is current for '
            'direct deposit. Amounts are recalculated each July.',
        type: AlertType.ccb,
        deadline: date,
        reminderEnabled: true,
        isPremium: i > 0, // First CCB date is free, rest are premium
        metadata: {'paymentMonth': date.month, 'paymentYear': date.year},
      ));
    }

    // ── OSAP Grace Period End ────────────────────────────────────────────────
    // Example: OSAP repayment starts 6 months after leaving school.
    // We use September 30 as a representative annual reminder.
    alerts.add(Alert(
      id: 'osap_grace_$year',
      title: 'OSAP Repayment Grace Period Reminder',
      description:
          'Ontario Student Assistance Program (OSAP) loans enter a 6-month '
          'non-repayment period after graduation or leaving school. Interest '
          'does not accrue during this period. Set up your National Student '
          'Loans Service Centre (NSLSC) repayment plan before this period ends '
          'to avoid penalties.',
      type: AlertType.osap,
      deadline: DateTime(year, 9, 30),
      reminderEnabled: true,
      isPremium: true,
      metadata: {'year': year},
    ));

    // ── Personal Tax Filing Deadline ─────────────────────────────────────────
    alerts.add(Alert(
      id: 'tax_filing_$year',
      title: 'Personal Tax Return Deadline',
      description:
          'Deadline to file your T1 personal income tax return with CRA. Late '
          'filing triggers a 5% penalty on any balance owing, plus 1% per '
          'additional month. Filing on time is required even if you can\'t pay '
          'in full.',
      type: AlertType.tax,
      deadline: DateTime(year, 4, 30),
      reminderEnabled: true,
      isPremium: false,
    ));

    // ── Tax Balance Owing Payment Deadline ───────────────────────────────────
    alerts.add(Alert(
      id: 'tax_payment_$year',
      title: 'Tax Balance Owing — Payment Deadline',
      description:
          'Any balance owing to CRA must be paid by April 30 to avoid daily '
          'compound interest. Applies even if you file by the June 15 '
          'self-employed extension.',
      type: AlertType.tax,
      deadline: DateTime(year, 4, 30),
      reminderEnabled: true,
      isPremium: false,
    ));

    // ── Self-Employed Tax Filing Deadline ────────────────────────────────────
    alerts.add(Alert(
      id: 'tax_selfemployed_$year',
      title: 'Self-Employed Tax Filing Deadline',
      description:
          'If you or your spouse/partner had self-employment income, your T1 '
          'return is due June 15. Note: any balance owing is still due April '
          '30 — late payment triggers interest from May 1 even if you file by '
          'June 15.',
      type: AlertType.tax,
      deadline: DateTime(year, 6, 15),
      reminderEnabled: true,
      isPremium: false,
    ));

    // ── FHSA Annual Contribution Deadline ────────────────────────────────────
    alerts.add(Alert(
      id: 'fhsa_deadline_$year',
      title: 'FHSA Annual Contribution Deadline',
      description:
          r'Last day to make FHSA contributions for this tax year — up to '
          r'$8,000/year, $40,000 lifetime. Unused FHSA room only carries '
          'forward one year.',
      type: AlertType.tax,
      deadline: DateTime(year, 12, 31),
      reminderEnabled: true,
      isPremium: false,
    ));

    // ── Home Buyers' Plan RRSP Repayment ─────────────────────────────────────
    alerts.add(Alert(
      id: 'hbp_repayment_$year',
      title: "Home Buyers' Plan Repayment",
      description:
          'If you withdrew from your RRSP under the Home Buyers\' Plan, your '
          'annual repayment is due by March 1 (if applicable). Miss it and '
          'CRA adds the required amount to your taxable income. Check CRA My '
          'Account for your schedule.',
      type: AlertType.rrsp,
      deadline: DateTime(year, 3, 1),
      reminderEnabled: true,
      isPremium: false,
    ));

    // ── GST/HST Instalments (Quarterly) ──────────────────────────────────────
    final gstDates = [
      DateTime(year, 3, 31),
      DateTime(year, 6, 15),
      DateTime(year, 9, 15),
      DateTime(year, 12, 15),
    ];
    for (int n = 1; n <= 4; n++) {
      alerts.add(Alert(
        id: 'gst_instalment_${year}_q$n',
        title: 'GST/HST Instalment Due — Q$n',
        description:
            'Quarterly GST/HST instalment for self-employed individuals/'
            'businesses who collected more than \$3,000 in net tax last year '
            '(if applicable). Missing instalments triggers daily compound '
            'interest.',
        type: AlertType.tax,
        deadline: gstDates[n - 1],
        reminderEnabled: true,
        isPremium: false,
      ));
    }

    // ── Custom alert example slot ─────────────────────────────────────────────
    // (Users add their own custom alerts via the UI; none generated here.)

    return alerts;
  }

  /// Returns a new unique ID suitable for user-created alerts.
  static String newId() => _uuid.v4();

  static String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }
}
