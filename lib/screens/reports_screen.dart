import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = StoreService.instance;
    final today = s.todayInvoices();
    return ListView(padding: const EdgeInsets.all(14), children: [
      Wrap(spacing: 10, runSpacing: 10, children: [
        kpi('مبيعات اليوم', money(s.totalSalesToday()), Icons.point_of_sale, success),
        kpi('ربح اليوم تقديري', money(s.totalProfitToday()), Icons.trending_up, primary),
        kpi('عدد فواتير اليوم', today.length.toString(), Icons.receipt_long, purple),
        kpi('قيمة المخزون', money(s.stockValue()), Icons.inventory, warning),
        kpi('منتجات منخفضة', s.lowStock().length.toString(), Icons.warning, danger),
        kpi('عدد المنتجات', s.products.length.toString(), Icons.category, primary),
      ]),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(14), decoration: card(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('تنبيهات المخزون', style: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (s.lowStock().isEmpty) const Text('لا توجد منتجات منخفضة.', style: TextStyle(color: softText, fontWeight: FontWeight.w800))
        else ...s.lowStock().map((p) => ListTile(leading: const Icon(Icons.warning, color: danger), title: Text(p.name), subtitle: Text('المتاح ${money(p.quantity)} | حد التنبيه ${money(p.alertQty)}'))),
      ])),
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
