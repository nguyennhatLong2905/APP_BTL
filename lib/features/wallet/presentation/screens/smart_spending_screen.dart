import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/currency_text_field.dart';
import '../providers/wallet_provider.dart';
import '../widgets/buy_now_card.dart';
import '../widgets/cash_flow_impact_card.dart';
import '../widgets/item_details_card.dart';
import '../widgets/mindful_delay_card.dart';
import '../widgets/safety_fund_card.dart';

class SmartSpendingScreen extends ConsumerWidget {
  const SmartSpendingScreen({super.key});

  void _showEditItemDialog(
      BuildContext context, WidgetRef ref, WalletState state) {
    final nameController = TextEditingController(text: state.itemName);
    final priceController =
        TextEditingController(text: state.itemPrice.toInt().toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Chỉnh Sửa Món Đồ Cân Nhắc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên món đồ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              CurrencyTextField(
                controller: priceController,
                labelText: 'Giá dự kiến',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = CurrencyTextField.getRawAmount(priceController);
                if (name.isNotEmpty && price > 0) {
                  ref.read(walletProvider.notifier).updateItemDetails(
                        name: name,
                        price: price,
                      );
                  AppSnackBar.showSuccess(
                      context, 'Đã cập nhật thông tin món đồ!');
                }
                Navigator.pop(context);
              },
              child: const Text('Cập nhật'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE3F5F1), // Background mint pastel
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go(AppConstants.splashRoute),
          tooltip: 'Quay lại',
        ),
        title: const Text(
          'Ví An Mua Hay Chờ?',
          style: TextStyle(
            color: Color(0xFF0F5B47),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => context.go(AppConstants.splashRoute),
            tooltip: 'Đóng',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2F0E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco_outlined,
                          size: 14, color: Color(0xFF0F5B47)),
                      SizedBox(width: 4),
                      Text(
                        'Mô phỏng tài chính chánh niệm',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F5B47),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: const Text(
                    'Ví An',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F5B47),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Giúp bạn nhìn rõ tác động tới dòng tiền thực tế trước khi quẹt thẻ, hoàn toàn không phán xét.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // Card 1: Món đồ đang cân nhắc
            ItemDetailsCard(
              itemName: state.itemName,
              itemPrice: state.itemPrice,
              categoryTag: state.categoryTag,
              daysLeft: state.daysLeftInPeriod,
              salaryDate: state.salaryDateText,
              onEditName: () => _showEditItemDialog(context, ref, state),
            ),
            const SizedBox(height: 12),

            // Card 2: Tác động dòng tiền (14 ngày kế tiếp)
            CashFlowImpactCard(
              currentFreeBalance: state.currentFreeBalance,
              freeBalanceAfter: state.freeBalanceAfterPurchase,
              itemPrice: state.itemPrice,
              dailyAvgCurrent: state.dailyAvgCurrent,
              dailyAvgAfter: state.dailyAvgAfterPurchase,
              daysLeft: state.daysLeftInPeriod,
            ),
            const SizedBox(height: 12),

            // Card 3: Túi an toàn được bảo toàn
            SafetyFundCard(
              fixedBills: state.fixedBillsAmount,
              emergencyFund: state.emergencyFundAmount,
            ),
            const SizedBox(height: 20),

            // Section Text
            const Text(
              'Lựa chọn của bạn hôm nay\nBạn luôn toàn quyền quyết định lối sống của mình.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F5B47),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // Card 4: Mua ngay hôm nay
            BuyNowCard(
              itemPrice: state.itemPrice,
              onBuyPressed: () {
                AppSnackBar.showSuccess(
                  context,
                  'Mở form giao dịch ${state.itemName} (${state.itemPrice.toInt()} ₫)!',
                );
              },
            ),
            const SizedBox(height: 12),

            // Card 5: Khuyến dùng chánh niệm (Chờ & Tích lũy)
            MindfulDelayCard(
              dailySavingGoal: state.dailySavingGoal,
              savingDays: state.savingDaysGoal,
              reminderDate: '17/10/2026',
              onCreatePlanPressed: () {
                AppSnackBar.showSuccess(
                  context,
                  'Đã tạo lộ trình tích lũy ${state.dailySavingGoal.toInt()} ₫/ngày!',
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
