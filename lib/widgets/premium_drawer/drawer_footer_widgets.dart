import 'package:flutter/material.dart';

class PremiumDrawerFooter extends StatelessWidget {
  final String lat;
  final String lon;
  final String mem;

  const PremiumDrawerFooter({super.key, required this.lat, required this.lon, required this.mem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        color: Colors.black.withValues(alpha: 0.3),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FooterData(label: "LAT", value: lat),
              _FooterData(label: "LON", value: lon),
              _FooterData(label: "MEM", value: mem),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 10, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 6),
              Text("SECURE CONNECTION // ENCRYPTED", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 8, letterSpacing: 1.5, fontFamily: 'Courier')),
            ],
          )
        ],
      ),
    );
  }
}

class _FooterData extends StatelessWidget {
  final String label;
  final String value;
  const _FooterData({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
      ],
    );
  }
}
