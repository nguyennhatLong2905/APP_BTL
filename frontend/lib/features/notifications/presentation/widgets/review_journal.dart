import 'package:flutter/material.dart';

import '../../../../core/ui/finance_screen_style.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/models/review_analytics.dart';
import '../../domain/models/timeline_item.dart';
import '../providers/timeline_provider.dart';

typedef _Draft = ({EmotionRating? rating, String note});

class ReviewJournal extends StatefulWidget {
  const ReviewJournal({
    super.key,
    required this.state,
    required this.onSave,
    required this.onSkip,
    required this.onHistory,
  });

  final TimelineState state;
  final Future<String?> Function(
    String transactionId,
    EmotionRating rating, {
    String? note,
  })
  onSave;
  final Future<String?> Function(String transactionId) onSkip;
  final VoidCallback onHistory;

  @override
  State<ReviewJournal> createState() => _ReviewJournalState();
}

class _ReviewJournalState extends State<ReviewJournal> {
  final _drafts = <String, _Draft>{};
  String? _expandedId;
  bool _submitting = false;

  static String _id(JournalEntry entry) =>
      entry.id.isNotEmpty ? entry.id : entry.transactionId;

  @override
  void initState() {
    super.initState();
    final first =
        widget.state.awaitingReview.firstOrNull ??
        widget.state.tracking.firstOrNull;
    if (first != null) _expandedId = _id(first);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final entries = [...state.awaitingReview, ...state.tracking];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              flex: 5,
              child: Text(
                'Nhật ký dùng tiền',
                style: FinanceScreenStyle.heading,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${state.summary.awaitingReview} khoản chờ đánh giá',
                  textAlign: TextAlign.end,
                  style: FinanceScreenStyle.detail,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          FinanceCard(
            child: Text(
              state.journal.isEmpty
                  ? 'Chưa có khoản chi trong nhật ký.'
                  : 'Bạn đã xử lý các khoản chi trong nhật ký.',
              style: FinanceScreenStyle.detail,
            ),
          )
        else
          FinanceCard(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: FinanceScreenStyle.border),
                  _entryTile(entries[i]),
                ],
              ],
            ),
          ),
        if (state.ratedCount + state.skippedCount > 0)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onHistory,
              style: TextButton.styleFrom(
                foregroundColor: FinanceScreenStyle.green,
              ),
              child: const Text('Xem lịch sử đánh giá'),
            ),
          ),
      ],
    );
  }

  Widget _entryTile(JournalEntry entry) {
    final id = _id(entry);
    final expanded = id == _expandedId;
    return Column(
      key: ValueKey(id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: expanded,
          button: true,
          child: InkWell(
            onTap: () => setState(() => _expandedId = expanded ? null : id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  FinanceCategoryIcon(billCategoryIcon(entry.categoryLabel)),
                  const SizedBox(width: 9),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: FinanceScreenStyle.strong.copyWith(
                            fontSize: 15,
                          ),
                        ),
                        if (entry.dateText.isNotEmpty)
                          Text(
                            entry.dateText,
                            style: FinanceScreenStyle.detail,
                          ),
                        if (entry.isAwaitingReview)
                          const Text(
                            'Bấm để đánh giá giao dịch',
                            style: TextStyle(
                              color: FinanceScreenStyle.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        FinanceScreenStyle.money(-entry.amount.abs()),
                        textAlign: TextAlign.end,
                        style: FinanceScreenStyle.strong,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: FinanceScreenStyle.ink,
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: entry.isAwaitingReview || entry.isTracking
                ? _editor(entry)
                : Text(entry.countdownLabel, style: FinanceScreenStyle.detail),
          ),
      ],
    );
  }

  Widget _editor(JournalEntry entry) {
    final id = _id(entry);
    final draft = _drafts[id] ?? (rating: null, note: entry.note ?? '');
    final enabled = !_submitting && !widget.state.isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (rating, label, icon) in const [
                (
                  EmotionRating.worthIt,
                  'Đáng tiền',
                  Icons.sentiment_very_satisfied_outlined,
                ),
                (
                  EmotionRating.normal,
                  'Bình thường',
                  Icons.sentiment_satisfied_outlined,
                ),
                (
                  EmotionRating.considerAgain,
                  'Cân nhắc lại',
                  Icons.sentiment_neutral_outlined,
                ),
              ]) ...[
                if (rating != EmotionRating.worthIt) const SizedBox(width: 5),
                Expanded(
                  child: _RatingButton(
                    label: label,
                    icon: icon,
                    selected: draft.rating == rating,
                    onTap: !enabled
                        ? null
                        : () {
                            setState(
                              () => _drafts[id] = (
                                rating: rating,
                                note: draft.note,
                              ),
                            );
                          },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: ValueKey('note-$id'),
          initialValue: draft.note,
          readOnly: !enabled,
          maxLength: 2000,
          minLines: 1,
          maxLines: 3,
          style: const TextStyle(color: FinanceScreenStyle.ink, fontSize: 13),
          onChanged: (note) {
            _drafts[id] = (rating: _drafts[id]?.rating, note: note);
          },
          decoration: InputDecoration(
            hintText: 'Ghi thêm lý do (tùy chọn)',
            hintStyle: FinanceScreenStyle.detail,
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF6FAF9),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: FinanceScreenStyle.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: FinanceScreenStyle.green),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Flexible(
              child: TextButton(
                onPressed: enabled ? () => _submit(entry, skip: true) : null,
                style: TextButton.styleFrom(
                  foregroundColor: FinanceScreenStyle.muted,
                ),
                child: const Text('Bỏ qua'),
              ),
            ),
            const Spacer(),
            Flexible(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: enabled && draft.rating != null
                      ? () => _submit(entry)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: FinanceScreenStyle.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'Lưu cảm nhận',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit(JournalEntry entry, {bool skip = false}) async {
    final id = _id(entry);
    final draft = _drafts[id];
    final rating = draft?.rating;
    if (_submitting || (!skip && rating == null)) return;
    setState(() => _submitting = true);
    final error = skip
        ? await widget.onSkip(id)
        : await widget.onSave(id, rating!, note: draft!.note.trim());
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (error == null) {
        _drafts.remove(id);
        if (_expandedId == id) _expandedId = null;
      }
    });
    if (error != null) {
      AppSnackBar.showError(context, error);
    } else {
      AppSnackBar.showSuccess(
        context,
        skip ? 'Đã bỏ qua khoản chi' : 'Đã lưu cảm nhận',
      );
    }
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected
            ? FinanceScreenStyle.green
            : FinanceScreenStyle.ink,
        backgroundColor: selected ? FinanceScreenStyle.mint : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        side: BorderSide(
          color: selected
              ? FinanceScreenStyle.green
              : FinanceScreenStyle.border,
          width: selected ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check : icon,
            size: 19,
            color: selected
                ? FinanceScreenStyle.green
                : const Color(0xFFB46300),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
