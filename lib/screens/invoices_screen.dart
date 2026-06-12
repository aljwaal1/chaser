import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  String invoiceText(Invoice i) {
    final b = StringBuffer();
    b.writeln('فاتورة بيع رقم ${i.number}');
    b.writeln(dateTimeText(i.date));
    if (i.customerName.isNotEmpty) b.writeln('العميل: ${i.customerName}');
    b.writeln('طريقة الدفع: ${i.paymentType}');
    b.writeln('-----------------------');
    for (final item in i.items) { b.writeln('${item.name} × ${money(item.qty)} = ${money(item.total)}'); }
    b.writeln('-----------------------');
    b.writeln('الإجمالي: ${money(i.total)} دينار');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreService.instance;
    final list = [...store.invoices]..sort((a, b) => b.date.compareTo(a.date));
    if (list.isEmpty) return empty('لا توجد فواتير بعد.');
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final inv = list[i];
        return Container(margin: const EdgeInsets.only(bottom: 10), decoration: card(22), child: ExpansionTile(
          title: Text('فاتورة رقم ${inv.number}', style: const TextStyle(color: darkText, fontWeight: FontWeight.w900)),
          subtitle: Text('${dateTimeText(inv.date)} | ${inv.paymentType} | ${money(inv.total)} دينار'),
          children: [
            ...inv.items.map((item) => ListTile(title: Text(item.name), subtitle: Text('${money(item.qty)} × ${money(item.price)}'), trailing: Text(money(item.total), style: const TextStyle(fontWeight: FontWeight.w900)))),
            TextButton.icon(onPressed: () => Share.share(invoiceText(inv)), icon: const Icon(Icons.share), label: const Text('مشاركة الفاتورة')),
          ],
        ));
      },
    );
  }
}
