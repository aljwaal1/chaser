import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';
import 'scanner_screen.dart';

class ProductFormScreen extends StatefulWidget {
  final String? initialBarcode;
  final Product? product;
  const ProductFormScreen({super.key, this.initialBarcode, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final store = StoreService.instance;
  late TextEditingController barcode;
  late TextEditingController name;
  late TextEditingController category;
  late TextEditingController purchase;
  late TextEditingController sale;
  late TextEditingController qty;
  late TextEditingController alert;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    barcode = TextEditingController(text: p?.barcode ?? widget.initialBarcode ?? '');
    name = TextEditingController(text: p?.name ?? '');
    category = TextEditingController(text: p?.category ?? '');
    purchase = TextEditingController(text: p == null ? '' : money(p.purchasePrice));
    sale = TextEditingController(text: p == null ? '' : money(p.salePrice));
    qty = TextEditingController(text: p == null ? '' : money(p.quantity));
    alert = TextEditingController(text: p == null ? '1' : money(p.alertQty));
  }

  Future<void> scan() async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ScannerScreen())));
    if (code != null) setState(() => barcode.text = code);
  }

  Future<void> save() async {
    final b = barcode.text.trim();
    final n = name.text.trim();
    if (b.isEmpty || n.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب الباركود واسم المنتج')));
      return;
    }

    final exists = store.byBarcode(b);
    if (exists != null && widget.product == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الباركود مسجل مسبقًا')));
      return;
    }

    final p = widget.product ?? Product(
      id: store.newId(), barcode: b, name: n, category: category.text.trim(),
      purchasePrice: double.tryParse(purchase.text.trim().replaceAll(',', '.')) ?? 0,
      salePrice: double.tryParse(sale.text.trim().replaceAll(',', '.')) ?? 0,
      quantity: double.tryParse(qty.text.trim().replaceAll(',', '.')) ?? 0,
      alertQty: double.tryParse(alert.text.trim().replaceAll(',', '.')) ?? 1,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    p.barcode = b; p.name = n; p.category = category.text.trim();
    p.purchasePrice = double.tryParse(purchase.text.trim().replaceAll(',', '.')) ?? 0;
    p.salePrice = double.tryParse(sale.text.trim().replaceAll(',', '.')) ?? 0;
    p.quantity = double.tryParse(qty.text.trim().replaceAll(',', '.')) ?? 0;
    p.alertQty = double.tryParse(alert.text.trim().replaceAll(',', '.')) ?? 1;

    if (widget.product == null) {
      await store.addProduct(p);
    } else {
      await store.updateProduct(p);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: Text(widget.product == null ? 'إضافة منتج' : 'تعديل منتج'), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(padding: const EdgeInsets.all(16), decoration: card(24), child: Column(children: [
          Row(children: [
            Expanded(child: TextField(controller: barcode, decoration: input('الباركود', Icons.qr_code))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: scan, icon: const Icon(Icons.qr_code_scanner)),
          ]),
          const SizedBox(height: 10),
          TextField(controller: name, decoration: input('اسم المنتج', Icons.inventory_2)),
          const SizedBox(height: 10),
          TextField(controller: category, decoration: input('التصنيف', Icons.category)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: purchase, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: input('سعر الشراء', Icons.shopping_cart))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: sale, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: input('سعر البيع', Icons.sell))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: input('الكمية', Icons.numbers))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: alert, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: input('حد التنبيه', Icons.warning))),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: const Text('حفظ المنتج'))),
        ])),
      ]),
    );
  }
}
