import 'package:flutter/material.dart';

class NavItemModel {
  final IconData icon;
  final String title;
  final bool isActive;

  const NavItemModel({
    required this.icon,
    required this.title,
    this.isActive = false,
  });

  NavItemModel copyWith({
    IconData? icon,
    String? title,
    bool? isActive,
  }) {
    return NavItemModel(
      icon: icon ?? this.icon,
      title: title ?? this.title,
      isActive: isActive ?? this.isActive,
    );
  }
}