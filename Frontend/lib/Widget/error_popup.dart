import 'package:flutter/material.dart';
import '../Config/Themes/app_colors.dart';
import 'translate_text.dart';

class CustomAlertDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    IconData iconData;
    Color iconColor;

    if (title.toLowerCase().contains('success')) {
      iconData = Icons.check_circle;
      iconColor = Colors.green;
    } else if (title.toLowerCase().contains('error') ||
        title.toLowerCase().contains('fail')) {
      iconData = Icons.cancel;
      iconColor = Colors.red;
    } else {
      iconData = Icons.info;
      iconColor = Colors.blue;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.dark_navbar, // Ensure this exists or use safe fallback
          title: Row(
            children: [
              Icon(iconData, color: iconColor, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Translate.get(context, title),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Text(
            Translate.get(context, content),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(Translate.get(context, 'Ok')),
            ),
          ],
        );
      },
    );
  }
}
