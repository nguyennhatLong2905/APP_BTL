import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/dashboard_data.dart';
import 'home_style.dart';

class MoneyLayers extends StatelessWidget {
  const MoneyLayers({super.key, required this.data, required this.visible});

  final DashboardData data;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final total = data.totalBalance;
    final reserved = data.obligations;
    final spendable = data.spendable;
    final hasShortfall = data.shortfall > 0;
    final canChart =
        visible &&
        !hasShortfall &&
        total > 0 &&
        reserved >= 0 &&
        (reserved + spendable - total).abs() < 0.5;

    String money(double value) => HomeStyle.money(value, visible: visible);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            HomeIcon(Icons.layers_outlined, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text('3 lớp tiền minh bạch', style: HomeStyle.heading),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HomeStyle.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lớp 1 · Tổng tiền hiện có', style: HomeStyle.label),
              const SizedBox(height: 2),
              Text(
                money(total),
                style: HomeStyle.heading.copyWith(fontSize: 28, height: 1.15),
              ),
              if (data.walletBreakdown.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  data.walletBreakdown
                      .map(
                        (wallet) => '${wallet.name} ${money(wallet.balance)}',
                      )
                      .join(' · '),
                  style: HomeStyle.detail,
                ),
              ],
              const SizedBox(height: 12),
              if (visible && !canChart) ...[
                Text(
                  hasShortfall
                      ? 'Còn thiếu ${money(data.shortfall)} để đủ khoản đã dành riêng.'
                      : total == 0
                      ? 'Chưa có số dư để tính tỷ trọng.'
                      : 'Chưa đủ dữ liệu để tính tỷ trọng.',
                  style: HomeStyle.detail,
                ),
                const SizedBox(height: 12),
              ],
              if (canChart)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final reservedFraction = reserved / total;
                    final reservedWidth = width * reservedFraction;
                    final availableWidth = width - reservedWidth;
                    final format = NumberFormat.decimalPercentPattern(
                      locale: 'vi_VN',
                      decimalDigits: 1,
                    );
                    final reservedLabel =
                        'Lớp 2 · ${format.format(reservedFraction)}';
                    final availableLabel =
                        'Lớp 3 · ${format.format(spendable / total)}';
                    const lightLabel = TextStyle(
                      color: HomeStyle.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    );
                    final darkLabel = lightLabel.copyWith(color: Colors.white);
                    final reservedFits = _fits(
                      context,
                      reservedLabel,
                      lightLabel,
                      reservedWidth,
                    );
                    final availableFits = _fits(
                      context,
                      availableLabel,
                      darkLabel,
                      availableWidth,
                    );
                    return Column(
                      children: [
                        Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFF98B9AE)),
                              left: BorderSide(color: Color(0xFF98B9AE)),
                              right: BorderSide(color: Color(0xFF98B9AE)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 42),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    width: reservedWidth,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: HomeStyle.reserved,
                                      border:
                                          reservedWidth >= 2 &&
                                              availableWidth >= 2
                                          ? const Border(
                                              right: BorderSide(
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                    child: reservedFits
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Text(
                                              reservedLabel,
                                              style: lightLabel,
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Container(
                                    width: availableWidth,
                                    alignment: Alignment.center,
                                    color: HomeStyle.spendable,
                                    child: availableFits
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Text(
                                              availableLabel,
                                              style: darkLabel,
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _legend(
                          money,
                          reservedLabel: reservedFits ? null : reservedLabel,
                          availableLabel: availableFits ? null : availableLabel,
                        ),
                      ],
                    );
                  },
                )
              else
                _legend(money),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(
    String Function(double) money, {
    String? reservedLabel,
    String? availableLabel,
  }) {
    return Column(
      children: [
        _LegendItem(
          title: 'Tiền đã dành riêng',
          amount: money(data.obligations),
          color: HomeStyle.reserved,
          ratioLabel: reservedLabel,
          detail:
              'Hóa đơn ${money(data.unpaidBills)} · Dự phòng ${money(data.protectedMoney)}',
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: HomeStyle.outline),
        ),
        _LegendItem(
          title: 'Tiền còn để chi',
          amount: money(data.spendable),
          color: HomeStyle.spendable,
          ratioLabel: availableLabel,
          emphasis: true,
        ),
      ],
    );
  }

  bool _fits(
    BuildContext context,
    String label,
    TextStyle style,
    double width,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final fits = painter.width + 8 <= width;
    painter.dispose();
    return fits;
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.title,
    required this.amount,
    required this.color,
    this.ratioLabel,
    this.detail,
    this.emphasis = false,
  });

  final String title;
  final String amount;
  final Color color;
  final String? ratioLabel;
  final String? detail;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.label.copyWith(
      fontWeight: FontWeight.w700,
      color: emphasis ? HomeStyle.primary : HomeStyle.ink,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeLabelRow(
          leading: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: emphasis
                  ? null
                  : Border.all(color: const Color(0xFF98B9AE)),
            ),
          ),
          title: Text(title, style: style),
          trailing: Text(amount, textAlign: TextAlign.end, style: style),
        ),
        if (ratioLabel != null || detail != null)
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 4),
            child: Text(
              [?ratioLabel, ?detail].join('\n'),
              style: HomeStyle.detail,
            ),
          ),
      ],
    );
  }
}
