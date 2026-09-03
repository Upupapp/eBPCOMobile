import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_typography.dart';

/// Tappable date field that opens the platform date picker, wired as a
/// [FormField] so it participates in the wizard step's `Form.validate()`
/// like any other field. Handles a cancelled picker (returns null) and a
/// never-selected date safely — no unsafe null assertions.
class DatePickerField extends FormField<DateTime> {
  DatePickerField({
    super.key,
    required String label,
    DateTime? value,
    required ValueChanged<DateTime?> onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    super.validator,
    String? hint,

    /// Say so when the chosen date has already passed.
    ///
    /// Set on every PRC Validity field. The wizards collect a professional's
    /// PRC validity date at eighteen places and **not one of them compared it
    /// to anything** — a licence that lapsed in 2019 was accepted, filed, and
    /// returned by the office weeks later, with the citizen paying for the
    /// delay. `ProfessionalsProvider.professionalsNeedingAttention` says in
    /// its own doc comment that it "drives the credential warning"; there was
    /// no credential warning anywhere, and nothing read that getter either.
    ///
    /// A warning and not a validator on purpose. Refusing the date would stop
    /// a citizen filing while a renewal is in progress, which the office
    /// accepts and this app has no business overruling. It tells them what
    /// will happen and lets them decide.
    bool warnIfPast = false,

    /// Say so when the date falls in an earlier calendar year.
    ///
    /// Set on every PTR Date Issued field. A Professional Tax Receipt is valid
    /// only for the year it was issued, so last year's will not be accepted on
    /// a new filing — `ProfessionalModel.isPtrStale` has encoded exactly that
    /// since it was written, and no wizard compared the year to anything.
    ///
    /// The wizards did already warn when a PTR date was in the FUTURE, which
    /// is the implausible case a citizen would notice themselves. The one that
    /// gets a filing refused was unguarded.
    bool warnIfStaleYear = false,
    DateTime Function()? clock,
  }) : super(
         initialValue: value,
         autovalidateMode: AutovalidateMode.onUserInteraction,
         builder: (state) {
           final format = DateFormat('MMM d, yyyy');
           final now = (clock ?? DateTime.now)();
           final chosen = state.value;
           final today = DateTime(now.year, now.month, now.day);
           final hasLapsed =
               warnIfPast && chosen != null && chosen.isBefore(today);
           // Matches `ProfessionalModel.prcNeedsAttention`, which warns from
           // 60 days out so there is time to renew BEFORE the next filing
           // rather than after a submission is refused. The first version of
           // this field warned only once the licence had already lapsed,
           // which is the point at which the advice is no longer useful.
           final expiringSoon =
               warnIfPast &&
               chosen != null &&
               !hasLapsed &&
               chosen.difference(today).inDays <= 60;
           final staleYear =
               warnIfStaleYear && chosen != null && chosen.year < now.year;
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               InkWell(
                 borderRadius: BorderRadius.circular(
                   AppConstants.borderRadiusSmall,
                 ),
                 onTap: () async {
                   final picked = await showDatePicker(
                     context: state.context,
                     initialDate: state.value ?? now,
                     firstDate: firstDate ?? DateTime(now.year - 20),
                     lastDate: lastDate ?? DateTime(now.year + 20),
                   );
                   // The field (or the whole wizard step) may have been
                   // unmounted while the picker dialog was open — calling
                   // setState on a disposed FormFieldState throws.
                   if (!state.mounted) return;
                   // showDatePicker returns null when the user cancels or
                   // dismisses the dialog — leave the field's value untouched.
                   if (picked != null) {
                     state.didChange(picked);
                     onChanged(picked);
                   }
                 },
                 child: InputDecorator(
                   decoration: InputDecoration(
                     labelText: label,
                     hintText: hint,
                     suffixIcon: const Icon(
                       Icons.calendar_today_outlined,
                       size: 20,
                     ),
                     errorText: state.errorText,
                   ),
                   child: Text(
                     state.value != null
                         ? format.format(state.value!)
                         : 'Select a date',
                     style: state.value != null
                         ? AppTypography.body
                         : AppTypography.helper,
                   ),
                 ),
               ),
               if (expiringSoon) ...[
                 const SizedBox(height: 4),
                 _FieldNotice(
                   text:
                       'This licence expires on ${format.format(chosen)}, in '
                       '${chosen.difference(today).inDays} days. Renew it '
                       'before the office assesses this application.',
                 ),
               ],
               if (staleYear) ...[
                 const SizedBox(height: 4),
                 _FieldNotice(
                   text:
                       'This was issued in ${chosen.year}. A Professional Tax '
                       'Receipt is only valid for the year it was issued, so '
                       'the office will not accept it on a ${now.year} '
                       'filing.',
                 ),
               ],
               if (hasLapsed) ...[
                 const SizedBox(height: 4),
                 _FieldNotice(
                   text:
                       'This licence expired on ${format.format(chosen)}. The '
                       'office returns applications sealed by a lapsed '
                       'licence. You can still file, but check with the '
                       'professional first.',
                 ),
               ],
             ],
           );
         },
       );
}

/// One warning line under a date field.
///
/// Amber, never red: none of these refuse the filing. The office accepts an
/// application while a renewal is in progress, and this app has no business
/// overruling it — it names the consequence and lets the citizen decide.
class _FieldNotice extends StatelessWidget {
  final String text;

  const _FieldNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_outlined,
          size: 16,
          color: AppColors.statusPending,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.helper.copyWith(
              color: AppColors.statusPending,
            ),
          ),
        ),
      ],
    );
  }
}
