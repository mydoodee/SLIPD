import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String name;
  final String icon;
  final String type; // 'income', 'expense', 'both'

  const CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'type': type,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      type: map['type'] as String,
    );
  }

  IconData get iconData {
    switch (icon) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'phone_android':
        return Icons.phone_android;
      case 'savings':
        return Icons.savings;
      case 'work':
        return Icons.work;
      case 'trending_up':
        return Icons.trending_up;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}
