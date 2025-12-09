import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pesca_app/screens/mission_control/mission_control_screen.dart';

class DrawerMenuList extends StatelessWidget {
  const DrawerMenuList({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          HoloMenuItem(
            icon: Icons.monitor_heart,
            title: "Mission Control",
            subtitle: "System Status & Logs",
            color: Colors.redAccent,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionControlScreen()));
            },
          ),
          const SizedBox(height: 12),
          HoloMenuItem(
            icon: Icons.history,
            title: "Forecast History",
            subtitle: "Previous Sessions",
            color: Colors.blueAccent,
            onTap: () { HapticFeedback.lightImpact(); },
          ),
          const SizedBox(height: 12),
          HoloMenuItem(
            icon: Icons.map_outlined,
            title: "Tactical Map",
            subtitle: "Spots & Zones",
            color: Colors.cyanAccent,
            onTap: () { HapticFeedback.lightImpact(); },
          ),
          const SizedBox(height: 12),
          HoloMenuItem(
            icon: Icons.settings_input_component,
            title: "Neural Config",
            subtitle: "Agent Parameters",
            color: Colors.purpleAccent,
            onTap: () { HapticFeedback.lightImpact(); },
          ),
        ],
      ),
    );
  }
}

class HoloMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const HoloMenuItem({super.key, required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.02)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 0)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12)],
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 1)
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'Courier')),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 14, color: color.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}
