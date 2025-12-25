import 'package:flutter/material.dart';

enum SuggestionType {
  cutExpense,
  increaseIncome,
  invest,
}

enum Priority {
  high,
  medium,
  low,
}

class Suggestion {
  final String id;
  final String title;
  final String description;
  final String category;
  final SuggestionType type;
  final double? potentialSavings;
  final double? potentialGain;
  final Priority priority;
  final IconData icon;
  final Color color;
  final List<String> actionSteps;

  Suggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    this.potentialSavings,
    this.potentialGain,
    required this.priority,
    required this.icon,
    required this.color,
    required this.actionSteps,
  });
}



