import 'package:flutter/material.dart';

import 'globe_coordinates.dart';

/// Type of region highlight.
enum RegionHighlightType { polygon, circle }

/// Represents a highlighted region on the globe.
class RegionHighlight {
  final String id;
  final RegionHighlightType type;
  final List<GlobeCoordinates> coordinates;
  final double radius;
  final Color color;

  /// Creates a polygon highlight with the given [coordinates].
  RegionHighlight.polygon({
    required this.id,
    required List<GlobeCoordinates> coordinates,
    this.color = const Color(0x88FF0000),
  })  : type = RegionHighlightType.polygon,
        radius = 0,
        coordinates = coordinates;

  /// Creates a circular highlight with [center] and [radius] in degrees.
  RegionHighlight.circle({
    required this.id,
    required GlobeCoordinates center,
    required this.radius,
    this.color = const Color(0x8844FF44),
  })  : type = RegionHighlightType.circle,
        coordinates = [center];
}
