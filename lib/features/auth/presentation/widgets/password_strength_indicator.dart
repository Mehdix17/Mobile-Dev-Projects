import 'package:flutter/material.dart';

enum PasswordStrength {
  weak,
  medium,
  strong,
}

class PasswordStrengthData {
  final PasswordStrength strength;
  final String message;
  final Color color;
  final double progress;

  const PasswordStrengthData({
    required this.strength,
    required this.message,
    required this.color,
    required this.progress,
  });
}

class PasswordStrengthCalculator {
  static PasswordStrengthData calculateStrength(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthData(
        strength: PasswordStrength.weak,
        message: '',
        color: Colors.grey,
        progress: 0,
      );
    }

    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) score++; // lowercase
    if (password.contains(RegExp(r'[A-Z]'))) score++; // uppercase
    if (password.contains(RegExp(r'[0-9]'))) score++; // numbers
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++; // special chars
    
    if (score <= 2) {
      return const PasswordStrengthData(
        strength: PasswordStrength.weak,
        message: 'Weak - Add numbers, symbols, or more characters',
        color: Colors.red,
        progress: 0.33,
      );
    } else if (score <= 4) {
      return const PasswordStrengthData(
        strength: PasswordStrength.medium,
        message: 'Medium - Add special characters for stronger security',
        color: Colors.orange,
        progress: 0.66,
      );
    } else {
      return const PasswordStrengthData(
        strength: PasswordStrength.strong,
        message: 'Strong - Your password is secure',
        color: Colors.green,
        progress: 1.0,
      );
    }
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final strengthData = PasswordStrengthCalculator.calculateStrength(password);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strengthData.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(strengthData.color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        // Message
        Text(
          strengthData.message,
          style: TextStyle(
            fontSize: 12,
            color: strengthData.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
