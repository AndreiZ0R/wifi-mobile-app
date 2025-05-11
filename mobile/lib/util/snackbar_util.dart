import 'package:flutter/material.dart';

class SnackBarUtil {
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.greenAccent,
        ),
      );
    }
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
