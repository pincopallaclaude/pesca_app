// /lib/widgets/system_metrics.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemMetrics extends StatelessWidget {
  final List<double> latencyHistory;
  final AnimationController pulseController;

  const SystemMetrics({
    super.key,
    required this.latencyHistory,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NeonCard(
                title: "SQLITE",
                icon: Icons.storage,
                color: Colors.blue,
                pulseController: pulseController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "452",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Episodes Stored",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "STATUS: HEALTHY",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NeonCard(
                title: "CHROMADB",
                icon: Icons.hub,
                color: Colors.purple,
                pulseController: pulseController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "15ms",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Vector Latency",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 20,
                      child: CustomPaint(
                        painter: SparklinePainter(
                          data: latencyHistory,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniStatus(
                label: "CRON: PROACTIVE",
                value: "03:00 UTC",
                status: true,
                pulseController: pulseController,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStatus(
                label: "CRON: CLEANUP",
                value: "IDLE",
                status: true,
                color: Colors.orange,
                pulseController: pulseController,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NeonCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final AnimationController pulseController;

  const _NeonCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    required this.pulseController,
  });

  @override
  State<_NeonCard> createState() => _NeonCardState();
}

class _NeonCardState extends State<_NeonCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: widget.pulseController,
        builder: (context, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_isPressed ? 0.08 : 0.05),
              border: Border.all(
                color: _isPressed
                    ? widget.color.withOpacity(0.7)
                    : const Color(0xFF334155).withOpacity(0.5),
                width: _isPressed ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 15,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color:
                            _isPressed ? widget.color : const Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isPressed
                            ? widget.color.withOpacity(0.15)
                            : Colors.transparent,
                        boxShadow: _isPressed
                            ? [
                                BoxShadow(
                                  color: widget.color.withOpacity(
                                      0.3 * widget.pulseController.value),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 14,
                        color:
                            _isPressed ? widget.color : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                widget.child,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniStatus extends StatefulWidget {
  final String label;
  final String value;
  final bool status;
  final Color color;
  final AnimationController pulseController;

  const _MiniStatus({
    required this.label,
    required this.value,
    required this.status,
    this.color = Colors.green,
    required this.pulseController,
  });

  @override
  State<_MiniStatus> createState() => _MiniStatusState();
}

class _MiniStatusState extends State<_MiniStatus> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: widget.pulseController,
        builder: (context, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isPressed
                    ? widget.color.withOpacity(0.6)
                    : const Color(0xFF334155).withOpacity(0.5),
                width: _isPressed ? 2 : 1,
              ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color,
                        boxShadow: _isPressed
                            ? [
                                BoxShadow(
                                  color: widget.color.withOpacity(
                                      0.5 * widget.pulseController.value),
                                  blurRadius: 6,
                                ),
                              ]
                            : [],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color:
                            _isPressed ? Colors.white : const Color(0xFF64748B),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    final glowPath = Path();

    double maxVal = data.reduce(max);
    double minVal = data.reduce(min);
    double range = (maxVal - minVal) == 0 ? 1 : maxVal - minVal;
    double stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        glowPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        glowPath.lineTo(x, y);
      }
    }

    canvas.drawPath(glowPath, glowPaint);
    canvas.drawPath(path, paint);

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final pointGlowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = 0; i < data.length; i += 5) {
      double x = i * stepX;
      double y = size.height - ((data[i] - minVal) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 3, pointGlowPaint);
      canvas.drawCircle(Offset(x, y), 1.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
