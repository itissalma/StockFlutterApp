class Stock {
  final String stockName; // Change to stockName
  final int stockId;
  late final double price;

  Stock({
    required this.stockName, // Change to stockName
    required this.stockId,
    required this.price,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      stockName: json['stockName'], // Change to stockName
      stockId: json['stockId'],
      price: json['price'].toDouble(),
    );
  }
}
