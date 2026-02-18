import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    required this.text,
    this.onPressed,
  });
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String text;
  final void Function()? onPressed;

  const AppButton.ok({super.key, this.onPressed})
    : foregroundColor = Colors.white,
      backgroundColor = Colors.grey,
      text = 'Ок';
  const AppButton.settings({super.key, this.onPressed})
    : foregroundColor = Colors.white,
      backgroundColor = Colors.green,
      text = 'Настройки';

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
      onPressed: onPressed,
      child: Text(text, style: TextStyle(fontSize: 18)),
    );
  }
}
