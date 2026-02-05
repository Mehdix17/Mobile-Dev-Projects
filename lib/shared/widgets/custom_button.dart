import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final Color? color;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.color,
  });

  const CustomButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.color,
  }) : type = ButtonType.primary;

  const CustomButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.color,
  }) : type = ButtonType.secondary;

  const CustomButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.color,
  }) : type = ButtonType.outline;

  const CustomButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.color,
  }) : type = ButtonType.text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final buttonStyle = _getButtonStyle(theme);
    final padding = _getPadding();
    final textStyle = _getTextStyle();

    final Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == ButtonType.primary
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _getIconSize()),
                const SizedBox(width: 8),
              ],
              Text(label, style: textStyle),
            ],
          );

    Widget button;

    switch (type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStatePropertyAll(padding),
          ),
          child: child,
        );
        break;
      case ButtonType.secondary:
        button = FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStatePropertyAll(padding),
          ),
          child: child,
        );
        break;
      case ButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStatePropertyAll(padding),
          ),
          child: child,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStatePropertyAll(padding),
          ),
          child: child,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  ButtonStyle _getButtonStyle(ThemeData theme) {
    final baseColor = color ?? theme.colorScheme.primary;

    return ButtonStyle(
      backgroundColor:
          type == ButtonType.primary ? WidgetStatePropertyAll(baseColor) : null,
      foregroundColor: type == ButtonType.primary
          ? WidgetStatePropertyAll(theme.colorScheme.onPrimary)
          : WidgetStatePropertyAll(baseColor),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 18);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return const TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
      case ButtonSize.medium:
        return const TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
      case ButtonSize.large:
        return const TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
}

enum ButtonType { primary, secondary, outline, text }

enum ButtonSize { small, medium, large }
