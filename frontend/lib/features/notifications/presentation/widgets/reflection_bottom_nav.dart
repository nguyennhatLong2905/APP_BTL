import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/ui/finance_screen_style.dart';

class ReflectionBottomNav extends StatelessWidget {
  const ReflectionBottomNav({super.key});

  @override
  Widget build(BuildContext context) =>
      const FinanceBottomNav(selectedRoute: AppConstants.timelineRoute);
}
