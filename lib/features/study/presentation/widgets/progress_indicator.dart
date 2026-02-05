import 'package:flutter/material.dart';

class StudyProgressIndicator extends StatelessWidget {
  final double progress;
  final Color? color;
  final double height;

  const StudyProgressIndicator({
    super.key,
    required this.progress,
    this.color,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? theme.colorScheme.primary,
            borderRadius: BorderRadius.horizontal(
              right: Radius.circular(height / 2),
            ),
          ),
        ),
      ),
    );
  }
}
