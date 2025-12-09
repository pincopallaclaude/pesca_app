import 'package:flutter/material.dart';
import 'core_widgets.dart';

Widget buildInfraStatus(
    String name,
    String val,
    String primaryMetric,
    String secondaryLabel,
    double secondaryValue,
    VoidCallback onAction,
    bool isActionActive,
    Color color,
    IconData icon,
    AnimationController pulseController) {
  Color activityColor = isActionActive ? Colors.redAccent : color;
  IconData activityIcon = isActionActive ? Icons.sync : Icons.check;

  return PlatinumCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name,
                style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: isActionActive
                    ? RotationTransition(
                        turns: Tween(begin: 0.0, end: 1.0)
                            .animate(pulseController),
                        child:
                            Icon(activityIcon, size: 16, color: activityColor))
                    : Icon(activityIcon, size: 16, color: activityColor),
                onPressed: onAction,
                tooltip: isActionActive ? "Syncing..." : "Force Sync",
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(val,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
                shadows: [BoxShadow(color: Colors.white10, blurRadius: 5)])),
        Text(primaryMetric,
            style: const TextStyle(color: Colors.white54, fontSize: 9)),
        const SizedBox(height: 12),
        Text(secondaryLabel,
            style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                    value: secondaryValue,
                    backgroundColor: Colors.white10,
                    color: activityColor,
                    minHeight: 4),
              ),
            ),
            const SizedBox(width: 8),
            Text(secondaryLabel == "DISK IO" ? "\%" : "\%",
                style: TextStyle(
                    color: activityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier')),
          ],
        ),
      ],
    ),
  );
}

Widget buildCronJobCard({
  required String title,
  required IconData icon,
  required Color color,
  required String statusLabel,
  required String detailLabel,
  VoidCallback? onTrigger,
}) {
  bool isTimer = title == "PROACTIVE";
  Widget statusText = Text(statusLabel,
      style: TextStyle(
          color: color,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
          fontSize: 14,
          shadows: isTimer
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5)]
              : []));
  Widget iconWidget = Icon(icon, size: 20, color: color);

  return PlatinumCard(
    child: SizedBox(
      height: 75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              if (onTrigger != null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.flash_on,
                        size: 16, color: color.withValues(alpha: 0.8)),
                    onPressed: onTrigger,
                    tooltip: "Trigger Now",
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [iconWidget, const SizedBox(width: 8), statusText]),
          const SizedBox(height: 6),
          Text(detailLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ],
      ),
    ),
  );
}

