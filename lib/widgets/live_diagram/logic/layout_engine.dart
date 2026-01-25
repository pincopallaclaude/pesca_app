import 'dart:math';
import 'package:flutter/material.dart';
import '../ai/models/node_metadata.dart';

class LayoutEngine {
  static Map<String, Offset> applyForceDirected(Map<String, Offset> positions, int iterations, {double margin = 0.12, bool useAdaptiveGravity = false}) {
    var current = Map<String, Offset>.from(positions);
    for (int iter = 0; iter < iterations; iter++) {
      final forces = <String, Offset>{};
      current.forEach((nodeA, posA) {
        var force = Offset.zero;
        final metaA = GlobalNodeRegistry.get(nodeA);
        final radiusA = metaA?.collisionRadius ?? 0.15;
        current.forEach((nodeB, posB) {
          if (nodeA != nodeB) {
            final diff = posA - posB; final dist = diff.distance;
            final metaB = GlobalNodeRegistry.get(nodeB);
            final radiusB = metaB?.collisionRadius ?? 0.15;
            final minSafe = radiusA + radiusB + 0.05;
            if (dist < minSafe) force += (diff / (dist + 0.001)) * ((minSafe - dist) / minSafe) * 0.2;
          }
        });
        if (!useAdaptiveGravity) {
          final meta = GlobalNodeRegistry.get(nodeA);
          force += (meta?.defaultPosition != null) ? (meta!.defaultPosition! - posA) * 0.05 : (const Offset(0.5, 0.5) - posA) * 0.01;
        } else { force += (const Offset(0.5, 0.5) - posA) * 0.001; }
        forces[nodeA] = force;
      });
      current.forEach((node, pos) {
        final nP = pos + forces[node]!;
        current[node] = Offset(nP.dx.clamp(margin, 1.0 - margin), nP.dy.clamp(margin, 1.0 - margin));
      });
    }
    return current;
  }

  static Map<String, Offset> repelFromPaths(Map<String, Offset> positions, int iterations) {
    var current = Map<String, Offset>.from(positions);
    final paths = <(String, String)>[];
    positions.forEach((f, _) => positions.forEach((t, _) { if (f != t) paths.add((f, t)); }));
    for (int iter = 0; iter < iterations; iter++) {
      current.forEach((id, nodePos) {
        var force = Offset.zero;
        for (final (f, t) in paths) {
          if (id == f || id == t) continue;
          final p1 = current[f]!; final p2 = current[t]!;
          final d = p2 - p1; final lenSq = d.dx * d.dx + d.dy * d.dy;
          if (lenSq < 0.001) continue;
          final dot = ((nodePos.dx - p1.dx) * d.dx + (nodePos.dy - p1.dy) * d.dy) / lenSq;
          final closest = p1 + d * dot.clamp(0.0, 1.0);
          final distV = nodePos - closest; final dist = distV.distance;
          if (dist < 0.08 && dist > 0.001) force += distV / (dist + 0.001) * ((0.08 - dist) / 0.08) * 0.05;
        }
        final nP = nodePos + force;
        current[id] = Offset(nP.dx.clamp(0.05, 0.95), nP.dy.clamp(0.05, 0.95));
      });
    }
    return current;
  }
}
