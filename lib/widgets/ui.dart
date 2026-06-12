import 'package:flutter/material.dart';
const primary = Color(0xFF1267E3);
const bg = Color(0xFFF4F8FF);
const darkText = Color(0xFF063B63);
const softText = Color(0xFF6B8198);
const border = Color(0xFFDCEEFA);
const success = Color(0xFF00A96B);
const danger = Color(0xFFE63946);
const warning = Color(0xFFFF9800);
const purple = Color(0xFF7B61FF);

String money(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

String dateTimeText(int ts) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}/${two(d.month)}/${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

BoxDecoration card([double radius = 22]) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: border),
  boxShadow: [
    BoxShadow(color: const Color(0xFF0069AA).withOpacity(.08), blurRadius: 24, offset: const Offset(0, 10)),
  ],
);

InputDecoration input(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Icon(icon),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
);

Widget empty(String text) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: softText, fontWeight: FontWeight.w800, height: 1.8)),
  ),
);
