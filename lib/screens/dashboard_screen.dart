import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onSale;
  final VoidCallback onProducts;
  const DashboardScreen({super.key, required this.onSale, required this.onProducts});

  @override
  Widget build(BuildContext context) {
    final s = StoreService.instance;
    return ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(16), decoration: card(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('كاشير باركود أوفلاين', style: TextStyle(color: darkText, fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('أضف المنتجات بالباركود، وبِع بالمسح، والبيانات محفوظة داخل الهاتف.', style: TextStyle(color: softText, fontWeight: FontWeight.w800, height: 1.6)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: onSale, icon: const Icon(Icons.qr_code_scanner), label: const Text('بيع بالباركود'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: onProducts, icon: const Icon(Icons.add_box), label: const Text('إضافة منتج'))),
        ]),
      ])),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: [
        kpi('المنتجات', s.products.length.toString(), Icons.inventory_2, primary),
        kpi('فواتير اليوم', s.todayInvoices().length.toString(), Icons.receipt_long, purple),
        kpi('مبيعات اليوم', money(s.totalSalesToday()), Icons.point_of_sale, success),
        kpi('قيمة المخزون', money(s.stockValue()), Icons.warehouse, warning),
        kpi('تنبيه مخزون', s.lowStock().length.toString(), Icons.warning, danger),
      ]),
    ]);
  }

  Widget kpi(String title, String value, IconData icon, Color color) {
    return Container(width: 170, padding: const EdgeInsets.all(14), decoration: card(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color)),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(color: softText, fontWeight: FontWeight.w900, fontSize: 13)),
      FittedBox(child: Text(value, style: TextStyle(color: color, fontSize: 23, fontWeight: FontWeight.w900))),
    ]));
  }
}
