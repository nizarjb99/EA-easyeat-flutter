// lib/widgets/reward_card.dart

import 'package:flutter/material.dart';
import '../models/reward.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback? onTap;

  const RewardCard({
    super.key,
    required this.reward,
    required this.accentColor,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon = reward.isExpiringSoon;
    final daysLeft = reward.daysUntilExpiry;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpiringSoon
                ? Colors.orange.withValues(alpha: 0.5)
                : accentColor.withValues(alpha: 0.2),
            width: isExpiringSoon ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and points row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.card_giftcard_rounded, color: accentColor, size: 26),
                if (isExpiringSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$daysLeft d',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            // Reward name
            Text(
              reward.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: accentColor,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Points required
            Text(
              '${reward.pointsRequired} points',
              style: TextStyle(
                color: accentColor.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (reward.timesRedeemed > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${reward.timesRedeemed}x redeemed',
                style: TextStyle(
                  color: accentColor.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for reward card while loading
class RewardCardSkeleton extends StatefulWidget {
  final Color accentColor;
  final Color bgColor;

  const RewardCardSkeleton({
    super.key,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  State<RewardCardSkeleton> createState() => _RewardCardSkeletonState();
}

class _RewardCardSkeletonState extends State<RewardCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.2),
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon skeleton
          _ShimmerBox(
            width: 26,
            height: 26,
            borderRadius: 6,
            controller: _controller,
            baseColor: widget.accentColor.withOpacity(0.1),
            highlightColor: widget.accentColor.withOpacity(0.2),
          ),
          const Spacer(),
          // Text skeleton
          _ShimmerBox(
            width: double.infinity,
            height: 13,
            borderRadius: 4,
            controller: _controller,
            baseColor: widget.accentColor.withOpacity(0.1),
            highlightColor: widget.accentColor.withOpacity(0.2),
          ),
          const SizedBox(height: 6),
          _ShimmerBox(
            width: 80,
            height: 11,
            borderRadius: 4,
            controller: _controller,
            baseColor: widget.accentColor.withOpacity(0.1),
            highlightColor: widget.accentColor.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}

/// Shimmer animation helper
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final AnimationController controller;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.controller,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Color.lerp(baseColor, highlightColor, controller.value) ??
                baseColor,
          ),
        );
      },
    );
  }
}

