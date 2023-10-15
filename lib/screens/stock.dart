import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test_app/models/stock_class.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/Services/SignalRService.dart'; //

class StockPage extends StatefulWidget {
  @override
  _StockPageState createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  Timer? stockUpdateTimer; // Declare the timer

  final String serverUrl = "http://10.0.2.2:5262/stockPriceHub";
  late SignalRService signalRService;

  List<Stock> stocks = [];

  @override
  void initState() {
    super.initState();
    fetchStocks();
    signalRService = SignalRService(serverUrl);
    startStockUpdates();
  }

  Future<void> fetchStocks() async {
    // Get the JWT token from SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String jwtToken = prefs.getString('jwtToken') ?? '';

    final response = await http.get(
      Uri.parse('http://10.0.2.2:5262/api/Stock'),
      headers: {
        'Authorization': 'Bearer $jwtToken', // Include the JWT token in the headers
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      setState(() {
        stocks = data.map((item) => Stock.fromJson(item)).toList();
      });
    } else {
      print("Failed to load stocks");
      throw Exception('Failed to load stocks');
    }
  }

  void startStockUpdates() async {
    await signalRService.startConnection();

    signalRService.updateStockPrices((stockId, newPrice) {
      setState(() {
        final stockToUpdate = stocks.firstWhere((stock) => stock.stockId == stockId);
        if (stockToUpdate != null) {
          stockToUpdate.price = newPrice;
          print("Updating price for stock: ${stockToUpdate.stockName}");
        }
      });
    });

    Timer.periodic(Duration(seconds: 5), (timer) {
      fetchStocks();
    });
  }

  @override
  void dispose() {
    stockUpdateTimer?.cancel();
    signalRService.stopConnection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stocks'),
        backgroundColor: Color(0xFF221E1F),
      ),
      body: ListView.builder(
        itemCount: stocks.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: StockTile(stock: stocks[index]),
          );
        },
      ),
    );
  }
}

class StockTile extends StatelessWidget {
  final Stock stock;

  StockTile({required this.stock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stock.stockName,
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(
                '\$${stock.price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16.0, color: Colors.green),
              ),
              SizedBox(height: 16.0),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  _showBuyPopup(context, stock);
                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF0AB7CD),
                ),
                child: Text('Buy'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBuyPopup(BuildContext context, Stock stock) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BuyStockPopup(stock: stock);
      },
    );
  }
}

class BuyStockPopup extends StatefulWidget {
  final Stock stock;

  BuyStockPopup({required this.stock});

  @override
  _BuyStockPopupState createState() => _BuyStockPopupState();
}

class _BuyStockPopupState extends State<BuyStockPopup> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.stock.price * quantity;

    return AlertDialog(
      title: Center(child: Text('Buy ${widget.stock.stockName} Stock')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Stock price: \$${widget.stock.price.toStringAsFixed(2)}'),
          SizedBox(height: 10),
          Text('Enter quantity:'),
          SizedBox(height: 10),
          Center(
            child: Container(
              width: 200, // Set the width of the container
              child: TextField(
                textAlign: TextAlign.center, // Center align the text
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    quantity = int.tryParse(value) ?? 1;
                    totalPrice = widget.stock.price * quantity;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 10),
          Text('Total price: \$${totalPrice.toStringAsFixed(2)}'),
        ],
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  _performBuyAction(context, widget.stock, quantity);
                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF0AB7CD),
                ),
                child: Text('Buy'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _performBuyAction(BuildContext context, Stock stock,
      int quantity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('username') ?? '';
    final String jwtToken = prefs.getString('jwtToken') ?? '';

    final apiUrl = 'http://10.0.2.2:5262/api/Order/createOrder';
    final url = Uri.parse(
        '$apiUrl?stockId=${stock.stockId}&userName=$userName&price=${stock
            .price}&quantity=$quantity&status=0');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      Navigator.of(context).pop(); // Close the BuyStockPopup
      _showOrderPlacedPopup(context); // Show the order placed popup
      print('Order created successfully: $responseData');
    } else {
      print('Failed to create order. Status code: ${response.statusCode}');
    }
  }

  void _showOrderPlacedPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Future.delayed(Duration(seconds: 5), () {
          Navigator.of(context).pop(); // Close the popup after 5 seconds
        });
        return AlertDialog(
          title: Center(child: Text('Order Placed Successfully!')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64.0,
              ),
            ],
          ),
        );
      },
    );
  }
}
