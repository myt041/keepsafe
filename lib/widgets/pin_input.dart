import 'package:flutter/material.dart';
import 'package:keepsafe/utils/theme.dart';

class PinInput extends StatelessWidget {
  final int pinLength;
  final Function(String) onChanged;
  final String pin;

  const PinInput({
    Key? key,
    required this.pinLength,
    required this.onChanged,
    required this.pin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pin visualization
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            pinLength,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < pin.length
                    ? AppTheme.primaryColor
                    : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        // Number pad
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 30,
          runSpacing: 20,
          children: List.generate(
            9,
            (index) => _buildNumberButton(context, index + 1),
          )..addAll([
            _buildEmptySpace(),
            _buildNumberButton(context, 0),
            _buildBackspaceButton(context),
          ]),
        ),
      ],
    );
  }

  Widget _buildNumberButton(BuildContext context, int number) {
    return InkWell(
      onTap: () {
        if (pin.length < pinLength) {
          onChanged('$pin$number');
        }
      },
      customBorder: const CircleBorder(),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$number',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(BuildContext context) {
    return InkWell(
      onTap: () {
        if (pin.isNotEmpty) {
          onChanged(pin.substring(0, pin.length - 1));
        }
      },
      customBorder: const CircleBorder(),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 28,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySpace() {
    return const SizedBox(
      width: 70,
      height: 70,
    );
  }
} 