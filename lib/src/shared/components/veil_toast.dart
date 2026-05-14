import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

void showVeilToast(BuildContext context, String message) {
  final size = MediaQuery.sizeOf(context);
  final top = MediaQuery.paddingOf(context).top + 14;
  final bottom = math.max(16.0, size.height - top - 82);
  final messenger = ScaffoldMessenger.of(context);

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      backgroundColor: VeilColors.red,
      behavior: SnackBarBehavior.floating,
      elevation: 14,
      margin: EdgeInsets.fromLTRB(16, top, 16, bottom),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 2),
    ),
  );
}
