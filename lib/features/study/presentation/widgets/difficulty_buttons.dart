import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/utils/helpers/sm2_algorithm.dart';
import '../../../cards/data/models/card_model.dart';

class DifficultyButtons extends StatelessWidget {
  final CardModel card;
  final void Function(DifficultyRating rating) onRate;

  const DifficultyButtons({
    super.key,
    required this.card,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'How well did you know this?',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DifficultyButton(
                  rating: DifficultyRating.again,
                  label: 'Again',
                  subtitle: DifficultyRating.again.getNextInterval(card),
                  color: AppColors.error,
                  onTap: () => onRate(DifficultyRating.again),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DifficultyButton(
                  rating: DifficultyRating.hard,
                  label: 'Hard',
                  subtitle: DifficultyRating.hard.getNextInterval(card),
                  color: AppColors.warning,
                  onTap: () => onRate(DifficultyRating.hard),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DifficultyButton(
                  rating: DifficultyRating.good,
                  label: 'Good',
                  subtitle: DifficultyRating.good.getNextInterval(card),
                  color: AppColors.success,
                  onTap: () => onRate(DifficultyRating.good),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DifficultyButton(
                  rating: DifficultyRating.easy,
                  label: 'Easy',
                  subtitle: DifficultyRating.easy.getNextInterval(card),
                  color: AppColors.primary,
                  onTap: () => onRate(DifficultyRating.easy),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final DifficultyRating rating;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.rating,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
