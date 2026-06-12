import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/invoice.dart';

class StoreService {
  static final StoreService instance = StoreService._();
  StoreService._();

  List<Product> products = [];
  List<Invoice> invoices = [];

  String newId() => '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final rawProducts = p.getString('products_v1');
    final rawInvoices = p.getString('invoices_v1');

    if (rawProducts != null) {
      products = (jsonDecode(rawProducts) as List).map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    if (rawInvoices != null) {
      invoices = (jsonDecode(rawInvoices) as List).map((e) => Invoice.fromJson(Map<String, dynamic>.from(e))).toList();
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('products_v1', jsonEncode(products.map((e) => e.toJson()).toList()));
    await p.setString('invoices_v1', jsonEncode(invoices.map((e) => e.toJson()).toList()));
  }

  Product? byBarcode(String barcode) {
    try { return products.firstWhere((p) => p.barcode == barcode); } catch (_) { return null; }
  }

  Future<void> addProduct(Product p) async {
    products.add(p);
    products.sort((a, b) => a.name.compareTo(b.name));
    await save();
  }

  Future<void> updateProduct(Product p) async => save();

  int nextInvoiceNumber() => invoices.isEmpty ? 1 : invoices.map((e) => e.number).reduce(max) + 1;

  Future<void> addInvoice(Invoice invoice) async {
    invoices.add(invoice);
    await save();
  }

  double stockValue() => products.fold(0, (s, p) => s + (p.quantity * p.purchasePrice));
  List<Invoice> todayInvoices() {
    final now = DateTime.now();
    return invoices.where((i) {
      final d = DateTime.fromMillisecondsSinceEpoch(i.date);
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }
  double totalSalesToday() => todayInvoices().fold(0, (s, i) => s + i.total);
  double totalProfitToday() => todayInvoices().fold(0, (s, i) => s + i.profit);
  List<Product> lowStock() => products.where((p) => p.quantity <= p.alertQty).toList();
}
