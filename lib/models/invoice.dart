class InvoiceItem {
  final String productId;
  final String barcode;
  final String name;
  final double qty;
  final double price;
  final double cost;

  InvoiceItem({required this.productId, required this.barcode, required this.name, required this.qty, required this.price, required this.cost});

  double get total => qty * price;
  double get profit => qty * (price - cost);

  Map<String, dynamic> toJson() => {'productId': productId, 'barcode': barcode, 'name': name, 'qty': qty, 'price': price, 'cost': cost};

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
    productId: j['productId'] ?? '',
    barcode: j['barcode'] ?? '',
    name: j['name'] ?? '',
    qty: (j['qty'] ?? 0).toDouble(),
    price: (j['price'] ?? 0).toDouble(),
    cost: (j['cost'] ?? 0).toDouble(),
  );
}

class Invoice {
  final String id;
  final int number;
  final int date;
  final String paymentType;
  final String customerName;
  final List<InvoiceItem> items;

  Invoice({required this.id, required this.number, required this.date, required this.paymentType, required this.customerName, required this.items});

  double get total => items.fold(0, (s, i) => s + i.total);
  double get profit => items.fold(0, (s, i) => s + i.profit);

  Map<String, dynamic> toJson() => {
    'id': id, 'number': number, 'date': date, 'paymentType': paymentType, 'customerName': customerName,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
    id: j['id'] ?? '',
    number: j['number'] ?? 0,
    date: j['date'] ?? DateTime.now().millisecondsSinceEpoch,
    paymentType: j['paymentType'] ?? 'نقدي',
    customerName: j['customerName'] ?? '',
    items: ((j['items'] ?? []) as List).map((e) => InvoiceItem.fromJson(Map<String, dynamic>.from(e))).toList(),
  );
}
