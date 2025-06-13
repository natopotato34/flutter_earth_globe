import 'package:flutter_earth_globe/globe_coordinates.dart';

import 'point.dart';
import 'line_helper.dart';
import 'math_helper.dart';
import 'point_connection.dart';
import 'rod.dart';
import 'region_highlight.dart';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;

import 'misc.dart';

/// A custom painter that draws the foreground of the earth globe.
class ForegroundPainter extends CustomPainter {
  /// This painter is responsible for rendering the points, connections, and labels on the globe.
  /// It takes various parameters such as the list of connections, radius, rotation angles,
  /// zoom factor, points, hover point, click point, and callback functions for point interactions.
  ///
  /// The [hoverOverPoint] function is called when a point is being hovered over, providing the point ID,
  /// the 2D cartesian coordinates, and the hover state.
  ///
  /// The [onPointClicked] function is called when a point is clicked.
  ///
  /// The [connections] list contains the animated connections between points.
  ///
  /// The [hoverPoint] and [clickPoint] represent the current hover and click positions on the canvas.
  ///
  /// The [radius] determines the size of the globe.
  ///
  /// The [rotationZ], [rotationY], and [rotationX] angles control the rotation of the globe.
  ///
  /// The [zoomFactor] determines the zoom level of the globe.

  /// The [points] list contains the points to be rendered on the globe.
  ///
  /// Example usage:
  /// ```dart
  /// ForegroundPainter(
  ///  connections: connections,
  /// radius: 200,
  /// rotationZ: 0,
  /// rotationY: 0,
  /// rotationX: 0,
  /// zoomFactor: 1,
  /// points: points,
  /// hoverPoint: hoverPoint,
  /// clickPoint: clickPoint,
  /// onPointClicked: () {
  ///  print('Point clicked');
  /// },
  /// hoverOverPoint: (pointId, cartesian2D, isHovering, isVisible) {
  /// print('Hovering over point with ID: $pointId');
  /// },
  /// )
  /// ```
  ForegroundPainter({
    required this.connections,
    required this.radius,
    required this.rotationZ,
    required this.rotationY,
    required this.rotationX,
    required this.zoomFactor,
    required this.points,
    required this.rods,
    required this.regions,
    this.hoverPoint,
    this.clickPoint,
    this.onPointClicked,
    required this.hoverOverPoint,
    required this.hoverOverConnection,
  });

  Function(String pointId, Offset? hoverPoint, bool isHovering, bool isVisible)
      hoverOverPoint;
  Function(String connectionId, Offset? hoverPoint, bool isHovering,
      bool isVisible) hoverOverConnection;
  VoidCallback? onPointClicked;
  final List<AnimatedPointConnection> connections;
  final Offset? hoverPoint;
  final Offset? clickPoint;
  final double radius;
  final double rotationZ;
  final double rotationY;
  final double rotationX;
  final double zoomFactor;
  final List<Point> points;
  final List<Rod> rods;
  final List<RegionHighlight> regions;

  bool isSame(GlobeCoordinates c1, GlobeCoordinates c2) {
    return c1.latitude == c2.latitude && c1.longitude == c2.longitude;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final localHover = hoverPoint;
    final localClick = clickPoint;

    // Draw highlighted regions clipped by the horizon so only the
    // front-facing portion remains visible.
    vector.Vector3 clipToHorizon(vector.Vector3 a, vector.Vector3 b) {
      double t = -a.x / (b.x - a.x);
      return a + (b - a) * t;
    }

    Offset toOffset(vector.Vector3 v) =>
        Offset(center.dx + v.y, center.dy - v.z);

    for (var region in regions) {
      final paint = Paint()
        ..color = region.color
        ..style = PaintingStyle.fill;

      List<GlobeCoordinates> coords;
      if (region.type == RegionHighlightType.circle) {
        coords = [];
        // Use many segments so the clipped edge hugs the horizon
        for (int i = 0; i < 180; i++) {
          final bearing = i * 2.0;
          coords.add(offsetCoordinates(
              region.coordinates.first, region.radius, bearing));
        }
      } else {
        coords = region.coordinates;
      }

      final projected = coords
          .map((c) => getSpherePosition3D(c, radius + 0.5, rotationY, rotationZ))
          .toList();

      if (projected.isEmpty) continue;

      // Clip polygon against the plane x >= 0 (the visible hemisphere).
      List<vector.Vector3> clipped = [];
      for (int i = 0; i < projected.length; i++) {
        final s = projected[i];
        final e = projected[(i + 1) % projected.length];
        final sFront = s.x >= 0;
        final eFront = e.x >= 0;

        if (sFront && eFront) {
          // both visible
          clipped.add(e);
        } else if (sFront && !eFront) {
          // leaving visible hemisphere
          clipped.add(clipToHorizon(s, e));
        } else if (!sFront && eFront) {
          // entering visible hemisphere
          clipped.add(clipToHorizon(s, e));
          clipped.add(e);
        }
      }

      if (clipped.isEmpty) continue;

      Path path = Path()..moveTo(toOffset(clipped.first).dx, toOffset(clipped.first).dy);
      for (int i = 1; i < clipped.length; i++) {
        final p = clipped[i];
        path.lineTo(toOffset(p).dx, toOffset(p).dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    for (var point in points) {
      final pointPaint = Paint()..color = point.style.color;
      vector.Vector3 cartesian3D =
          getSpherePosition3D(point.coordinates, radius, rotationY, rotationZ);
      Offset cartesian2D =
          Offset(center.dx + cartesian3D.y, center.dy - cartesian3D.z);

      // final c2 = hoverOffsetToSphereCoordinates(
      //     cartesian2D, center, radius, rotationY, rotationZ);
      // if (c2 != null && cartesian3D.x > 0) {
      //   print('${isSame(point.coordinates, c2)}');
      // }

      // print(
      //     'new: $cartesian3D ---- converted: ${getVector3FromGlobeCoordinates(cartesian2D, center, radius, rotationZ)}');
      // print(
      //     'center: $center - point: ${point.coordinates} cartesian2D: $cartesian2D - cartesian3D: $cartesian3D');

      if (cartesian3D.x > 0) {
        final rect = getRectOnSphere(cartesian3D, cartesian2D, center, radius,
            zoomFactor, point.style.size);
        canvas.drawOval(rect, pointPaint);
        // if(rect.contains())
        if (localHover != null && rect.contains(localHover)) {
          Future.delayed(Duration.zero, () {
            point.onHover?.call();
            hoverOverPoint(point.id, cartesian2D, true, true);
          });
        } else {
          hoverOverPoint(point.id, cartesian2D, false, true);
        }

        if (localClick != null && rect.contains(localClick)) {
          Future.delayed(Duration.zero, () {
            point.onTap?.call();
            onPointClicked?.call();
          });
        }

      if ((point.isLabelVisible &&
              point.label != null &&
              point.label != '') &&
          point.labelBuilder == null) {
        paintText(point.label ?? '', point.labelTextStyle, cartesian2D, size,
            canvas);
      }
    } else {
      hoverOverPoint(point.id, cartesian2D, false, false);
    }
  }

    // Draw rods with the segment inside the sphere hidden

    for (var rod in rods) {
      final stickOut = rod.stickOutMiles / kEarthRadiusMiles * radius;

      final startSurface =
          getSpherePosition3D(rod.start, radius, rotationY, rotationZ);
      final endSurface =
          getSpherePosition3D(rod.end, radius, rotationY, rotationZ);

      final direction = (endSurface - startSurface).normalized();
      final startOuter = startSurface - direction * stickOut;
      final endOuter = endSurface + direction * stickOut;

      final paint = Paint()
        ..color = rod.color
        ..strokeWidth = rod.width
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(toOffset(startSurface), toOffset(startOuter), paint);
      canvas.drawLine(toOffset(endSurface), toOffset(endOuter), paint);
    }


    for (var connection in connections) {
      Map? info = drawAnimatedLine(canvas, connection, radius, rotationY,
          rotationZ, connection.animationProgress, size, hoverPoint);

      if (info?['path'] != null) {
        if (localHover != null &&
            isPointOnPath(localHover, info?['path'], connection.strokeWidth)) {
          Future.delayed(Duration.zero, () {
            connection.onHover?.call();
            hoverOverConnection(connection.id, info?['midPoint'], true, true);
          });
        } else {
          hoverOverConnection(connection.id, info?['midPoint'], false, true);
        }
        if (localClick != null &&
            isPointOnPath(localClick, info?['path'], connection.strokeWidth)) {
          Future.delayed(Duration.zero, () {
            connection.onTap?.call();
            onPointClicked?.call();
          });
        }
      } else {
        hoverOverConnection(connection.id, info?['midPoint'], false, false);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
