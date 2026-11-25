import 'package:flutter/material.dart';

import '../../../../core/ui/finance_screen_style.dart';

class BudgetControlTabs extends StatelessWidget {
  const BudgetControlTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  final String activeTab;
  final ValueChanged<String> onTabChanged;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: Row(
      children: [
        for (final tab in ['Ngân sách', 'Mục tiêu', 'Hóa đơn'])
          Expanded(
            child: Semantics(
              selected: tab == activeTab,
              button: true,
              child: InkWell(
                onTap: () => onTabChanged(tab),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 46),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: tab == activeTab
                            ? FinanceScreenStyle.green
                            : FinanceScreenStyle.border,
                        width: tab == activeTab ? 3 : 1,
                      ),
                    ),
                  ),
                  child: Text(
                    tab,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tab == activeTab
                          ? FinanceScreenStyle.green
                          : FinanceScreenStyle.ink,
                      fontWeight: tab == activeTab
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
