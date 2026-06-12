import 'package:flutter/material.dart';
import '../widgets/ui.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'sale_screen.dart';
import 'invoices_screen.dart';
import 'reports_screen.dart';

enum AppTab { dashboard, products, sale, invoices, reports }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppTab tab = AppTab.dashboard;
  void refresh() => setState(() {});

  Widget page() {
    switch (tab) {
      case AppTab.dashboard:
        return DashboardScreen(onSale: () => setState(() => tab = AppTab.sale), onProducts: () => setState(() => tab = AppTab.products));
      case AppTab.products:
        return ProductsScreen(onChanged: refresh);
      case AppTab.sale:
        return SaleScreen(onChanged: refresh);
      case AppTab.invoices:
        return const InvoicesScreen();
      case AppTab.reports:
        return const ReportsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: bg, body: SafeArea(child: Column(children: [header(), nav(), Expanded(child: page())])));
  }

  Widget header() {
    return Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(14), decoration: card(28), child: Row(children: [
      Container(width: 54, height: 54, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00A8FF), primary]), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('كاشير باركود', style: TextStyle(color: darkText, fontSize: 25, fontWeight: FontWeight.w900)),
        Text('بيع ومخزون بدون إنترنت', style: TextStyle(color: softText, fontWeight: FontWeight.w800)),
      ])),
    ]));
  }

  Widget nav() {
    return SizedBox(height: 72, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
      navBtn('الرئيسية', Icons.dashboard, AppTab.dashboard),
      navBtn('المنتجات', Icons.inventory_2, AppTab.products),
      navBtn('بيع', Icons.point_of_sale, AppTab.sale),
      navBtn('الفواتير', Icons.receipt_long, AppTab.invoices),
      navBtn('التقارير', Icons.bar_chart, AppTab.reports),
    ]));
  }

  Widget navBtn(String text, IconData icon, AppTab t) {
    final active = tab == t;
    return Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => tab = t),
      child: Container(width: 94, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: active ? primary : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: active ? primary : border)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: active ? Colors.white : softText),
        Text(text, style: TextStyle(color: active ? Colors.white : softText, fontWeight: FontWeight.w900, fontSize: 12)),
      ])),
    ));
  }
}
