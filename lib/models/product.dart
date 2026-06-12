class Product {
  final String id;
  String barcode;
  String name;
  String category;
  double purchasePrice;
  double salePrice;
  double quantity;
  double alertQty;
  int createdAt;

  Product({required this.id, required this.barcode, required this.name, required this.category, required this.purchasePrice, required this.salePrice, required this.quantity, required this.alertQty, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'id': id, 'barcode': barcode, 'name': name, 'category': category, 'purchasePrice': purchasePrice,
    'salePrice': salePrice, 'quantity': quantity, 'alertQty': alertQty, 'createdAt': createdAt,
  };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] ?? '',
    barcode: j['barcode'] ?? '',
    name: j['name'] ?? '',
    category: j['category'] ?? '',
    purchasePrice: (j['purchasePrice'] ?? 0).toDouble(),
    salePrice: (j['salePrice'] ?? 0).toDouble(),
    quantity: (j['quantity'] ?? 0).toDouble(),
    alertQty: (j['alertQty'] ?? 0).toDouble(),
    createdAt: j['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
  );
}
