import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';

/// 4 nút quick action: Thu / Chi / Chuyển / Mục tiêu
class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'Thu',
        icon: Icons.add_circle_outline_rounded,
        color: const Color(0xFF2EC4B6),
        bgColor: const Color(0xFFE8FAF8),
        onTap: () => context.push(AppConstants.addTransactionRoute,
            extra: 'income'),
      ),
      _QuickAction(
        label: 'Chi',
        icon: Icons.remove_circle_outline_rounded,
        color: const Color(0xFFE71D36),
        bgColor: const Color(0xFFFDE8EA),
        onTap: () => context.push(AppConstants.addTransactionRoute,
            extra: 'expense'),
      ),
      _QuickAction(
        label: 'Chuyển',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF6C63FF),
        bgColor: const Color(0xFFEEEDFF),
        onTap: () {
          // TODO: Navigate đến màn chuyển khoản
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tính năng chuyển khoản đang phát triển'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      _QuickAction(
        label: 'Mục tiêu',
        icon: Icons.flag_outlined,
        color: const Color(0xFFFF9F1C),
        bgColor: const Color(0xFFFFF3E0),
        onTap: () {
          // TODO: Navigate đến màn mục tiêu
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tính năng mục tiêu đang phát triển'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions.map((action) => _QuickActionButton(action: action)).toList(),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}

class _QuickActionButton extends StatefulWidget {
  final _QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.reverse();
  void _onTapUp(TapUpDetails _) {
    _controller.forward();
    widget.action.onTap();
  }

  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.action.bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.action.color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.action.icon,
                color: widget.action.color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.action.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
