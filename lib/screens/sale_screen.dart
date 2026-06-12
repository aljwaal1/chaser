import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';
import 'product_form_screen.dart';
import 'scanner_screen.dart';

class CartLine {
  final Product product;
  double qty;
  CartLine({required this.product, this.qty = 1});
  double get total => qty * product.salePrice;
}

class SaleScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const SaleScreen({super.key, required this.onChanged});
  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final store = StoreService.instance;
  final customer = TextEditingController();
  List<CartLine> cart = [];
  String paymentType = 'نقدي';
  double get total => cart.fold(0, (s, l) => s + l.total);

  Future<void> scanSale() async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ScannerScreen())));
    if (code == null) return;
    final p = store.byBarcode(code);
    if (p == null) {
      if (!mounted) return;
      final add = await showDialog<bool>(context: context, builder: (_) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
        title: const Text('الصنف غير مسجل'),
        content: Text('الباركود:\n$code\nهل تريد إضافة الصنف الآن؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إضافة')),
        ],
      )));
      if (add == true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: ProductFormScreen(initialBarcode: code))));
        setState(() {});
        widget.onChanged();
      }
      return;
    }
    final existing = cart.where((l) => l.product.id == p.id).toList();
    setState(() {
      if (existing.isEmpty) cart.add(CartLine(product: p)); else existing.first.qty += 1;
    });
  }

  Future<void> saveInvoice() async {
    if (cart.isEmpty) return;
    for (final l in cart) {
      if (l.qty > l.product.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الكمية غير كافية: ${l.product.name}')));
        return;
      }
    }
    final invoice = Invoice(
      id: store.newId(),
      number: store.nextInvoiceNumber(),
      date: DateTime.now().millisecondsSinceEpoch,
      paymentType: paymentType,
      customerName: customer.text.trim(),
      items: cart.map((l) => InvoiceItem(productId: l.product.id, barcode: l.product.barcode, name: l.product.name, qty: l.qty, price: l.product.salePrice, cost: l.product.purchasePrice)).toList(),
    );
    for (final l in cart) {
      l.product.quantity -= l.qty;
      if (l.product.quantity < 0) l.product.quantity = 0;
    }
    await store.addInvoice(invoice);
    if (!mounted) return;
    final share = await showDialog<bool>(context: context, builder: (_) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('تم حفظ الفاتورة'),
      content: Text('فاتورة رقم ${invoice.number}\nالإجمالي: ${money(invoice.total)} دينار\nهل تريد مشاركتها؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('مشاركة')),
      ],
    )));
    if (share == true) await Share.share(invoiceText(invoice));
    setState(() { cart.clear(); customer.clear(); paymentType = 'نقدي'; });
    widget.onChanged();
  }

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
    return ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(14), decoration: card(24), child: Column(children: [
        Row(children: [
          const Expanded(child: Text('بيع جديد', style: TextStyle(color: darkText, fontSize: 24, fontWeight: FontWeight.w900))),
          Text('الإجمالي: ${money(total)}', style: const TextStyle(color: success, fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 12),
        TextField(controller: customer, decoration: input('اسم العميل اختياري', Icons.person)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: paymentType, items: ['نقدي', 'آجل / دين'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => paymentType = v ?? paymentType), decoration: input('طريقة الدفع', Icons.payments)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: scanSale, icon: const Icon(Icons.qr_code_scanner), label: const Text('مسح للبيع'))),
      ])),
      const SizedBox(height: 12),
      if (cart.isEmpty)
        Container(padding: const EdgeInsets.all(24), decoration: card(22), child: const Text('السلة فارغة.\nاضغط مسح للبيع وامسح باركود المنتج.', textAlign: TextAlign.center, style: TextStyle(color: softText, fontWeight: FontWeight.w800, height: 1.7)))
      else ...cart.map(cartCard),
      if (cart.isNotEmpty) ...[
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: saveInvoice, icon: const Icon(Icons.save), label: const Text('حفظ الفاتورة وخصم المخزون'))),
      ],
    ]);
  }

  Widget cartCard(CartLine l) {
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(13), decoration: card(22), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.product.name, style: const TextStyle(color: darkText, fontWeight: FontWeight.w900, fontSize: 16)),
        Text('المتاح: ${money(l.product.quantity)} | السعر: ${money(l.product.salePrice)}', style: const TextStyle(color: softText, fontWeight: FontWeight.w700)),
      ])),
      IconButton(onPressed: () => setState(() { if (l.qty > 1) l.qty -= 1; }), icon: const Icon(Icons.remove_circle_outline)),
      Text(money(l.qty), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      IconButton(onPressed: () => setState(() => l.qty += 1), icon: const Icon(Icons.add_circle_outline)),
      Text(money(l.total), style: const TextStyle(color: success, fontWeight: FontWeight.w900)),
      IconButton(onPressed: () => setState(() => cart.remove(l)), icon: const Icon(Icons.delete_outline, color: danger)),
    ]));
  }
}
