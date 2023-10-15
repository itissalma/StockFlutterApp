class OrderWithStockName {
  int orderId;
  int quantity;
  double price;
  String stockName;
  int stockId;
  int status;

  OrderWithStockName({
    required this.orderId,
    required this.quantity,
    required this.price,
    required this.stockName,
    required this.stockId,
    required this.status,
  });

  factory OrderWithStockName.fromJson(Map<String, dynamic> json) {
    return OrderWithStockName(
      orderId: json['orderId'],
      quantity: json['quantity'],
      price: json['price'],
      stockName: json['stockName'],
      stockId: json['stockId'],
      status: json['status'],
    );
  }
}
