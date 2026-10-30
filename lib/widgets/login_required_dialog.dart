import 'package:flutter/material.dart';

import '../utils/login_prompt.dart';

class LoginRequiredDialog {
  static Future<void> show(
    BuildContext context, {
    String message = 'continue',
  }) async {
    await requireLogin(context, action: message);
  }
}
