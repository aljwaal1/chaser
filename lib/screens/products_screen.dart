import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';
import 'product_form_screen.dart';
import 'scanner_screen.dart';

class ProductsScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const ProductsScreen({super.key, required this.onChanged});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final store = StoreService.instance;
  String query = '';

  Future<void> addByBarcode() async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: ScannerScreen())));
    if (code == null) return;
    final found = store.byBarcode(code);
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: ProductFormScreen(product: found, initialBarcode: found == null ? code : null))));
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final list = store.products.where((p) {
      final q = query.trim();
      return q.isEmpty || p.name.contains(q) || p.barcode.contains(q) || p.category.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(onPressed: addByBarcode, icon: const Icon(Icons.qr_code_scanner), label: const Text('إضافة بالباركود')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(14), child: TextField(onChanged: (v) => setState(() => query = v), decoration: input('بحث باسم المنتج أو الباركود', Icons.search))),
        Expanded(child: list.isEmpty ? empty('لا توجد منتجات بعد.\nاضغط إضافة بالباركود للبدء.') : ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
          itemCount: list.length,
          itemBuilder: (_, i) => productCard(list[i]),
        )),
      ]),
    );
  }

  Widget productCard(Product p) {
    final low = p.quantity <= p.alertQty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: card(22),
      child: InkWell(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: ProductFormScreen(product: p))));
          setState(() {});
          widget.onChanged();
        },
        child: Row(children: [
          CircleAvatar(backgroundColor: low ? danger.withOpacity(.12) : primary.withOpacity(.12), child: Icon(low ? Icons.warning : Icons.inventory_2, color: low ? danger : primary)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(color: darkText, fontWeight: FontWeight.w900, fontSize: 16)),
            Text(p.barcode, style: const TextStyle(color: softText, fontWeight: FontWeight.w700, fontSize: 12)),
            if (p.category.isNotEmpty) Text(p.category, style: const TextStyle(color: softText, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${money(p.salePrice)} د', style: const TextStyle(color: success, fontWeight: FontWeight.w900, fontSize: 17)),
            Text('كمية: ${money(p.quantity)}', style: TextStyle(color: low ? danger : softText, fontWeight: FontWeight.w800)),
          ]),
        ]),
      ),
    );
  }
}
