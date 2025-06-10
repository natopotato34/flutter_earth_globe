import 'package:flutter/material.dart';

import 'globe_coordinates.dart';

/// Represents a rod that goes through the globe.
class Rod {
  final GlobeCoordinates start;
  final GlobeCoordinates end;
  final String id;
  final Color color;
  final double width;
  final double stickOutMiles;


  /// Creates a new [Rod].
  const Rod({
    required this.start,
    required this.end,
    required this.id,
    this.color = Colors.white,
    this.width = 2,
    this.stickOutMiles = 10,

  });

  /// Returns a copy of this rod with the given fields replaced.
  Rod copyWith({
    GlobeCoordinates? start,
    GlobeCoordinates? end,
    String? id,
    Color? color,
    double? width,
    double? stickOutMiles,
  }) {
    return Rod(
      start: start ?? this.start,
      end: end ?? this.end,
      id: id ?? this.id,
      color: color ?? this.color,
      width: width ?? this.width,
      stickOutMiles: stickOutMiles ?? this.stickOutMiles,
    );
  }
}
