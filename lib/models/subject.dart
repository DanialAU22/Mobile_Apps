import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String name;
  final int colorValue;

  const Subject({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Subject copyWith({
    String? id,
    String? name,
    int? colorValue,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': colorValue,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      name: map['name'] as String,
      colorValue: map['color'] as int,
    );
  }
}

