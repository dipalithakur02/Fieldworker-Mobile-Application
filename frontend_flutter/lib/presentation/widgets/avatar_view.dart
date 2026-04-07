import 'dart:io';

import 'package:flutter/material.dart';

class AvatarView extends StatelessWidget {
  final String? imagePath;
  final String fallbackLabel;
  final double radius;
  final Color backgroundColor;
  final IconData fallbackIcon;

  const AvatarView({
    required this.fallbackLabel,
    this.imagePath,
    this.radius = 24,
    this.backgroundColor = const Color(0xFF2E7D32),
    this.fallbackIcon = Icons.person,
    super.key,
  });

  bool get _hasLocalImage {
    final trimmed = imagePath?.trim();
    return trimmed != null &&
        trimmed.isNotEmpty &&
        !trimmed.startsWith('http') &&
        File(trimmed).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = imagePath?.trim();
    final label = fallbackLabel.trim();
    final fallbackText = label.isEmpty ? '' : label[0].toUpperCase();

    if (trimmed != null && trimmed.isNotEmpty) {
      if (trimmed.startsWith('http')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          backgroundImage: NetworkImage(trimmed),
        );
      }

      if (_hasLocalImage) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          backgroundImage: FileImage(File(trimmed)),
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: fallbackText.isNotEmpty
          ? Text(
              fallbackText,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w700,
              ),
            )
          : Icon(
              fallbackIcon,
              color: Colors.white,
              size: radius,
            ),
    );
  }
}
