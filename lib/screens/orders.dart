import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test_app/models/order_class.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/logged_in_layout.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<OrderWithStockName> currentOrders = [];
  List<OrderWithStockName> boughtOrders = [];
  List<OrderWithStockName> soldOrders = [];
  List<OrderWithStockName> ordersWithStockNames = [];

  @override
  void initState() {
    super.initState();
    fetchOrdersWithStockNames();
  }


  Future<void> fetchOrdersWithStockNames() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String jwtToken = prefs.getString('jwtToken') ?? '';
    final String userName = prefs.getString('username') ?? '';

    try {
      final boughtResponse = await http.get(
        Uri.parse('http://10.0.2.2:5262/api/Order/GetOrdersWithStockNames/$userName'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      ).timeout(Duration(seconds: 5));
      print('Bought Response Body: ${boughtResponse.body}');

      final currentResponse = await http.get(
        Uri.parse('http://10.0.2.2:5262/api/Order/GetCurrentOrders/$userName'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      ).timeout(Duration(seconds: 5));
      print('Current Response Body: ${currentResponse.body}');

      final soldResponse = await http.get(
        Uri.parse('http://10.0.2.2:5262/api/Order/GetSoldOrders/$userName'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      ).timeout(Duration(seconds: 5));

      print("before mounted");
      if (mounted) {
        print("mounted");
        print('Sold Response Body: ${soldResponse.body}');
        print("the sold status code is ${soldResponse.statusCode}");
        if (soldResponse.statusCode == 200) {
          print("sold heeere");
          final List<dynamic> soldData = json.decode(soldResponse.body);
          setState(() {
            soldOrders = soldData.map((item) => OrderWithStockName.fromJson(item)).toList();
          });
        } else {
          print("Failed to load sold orders with stock names");
          throw Exception('Failed to load sold orders with stock names');
        }

        if (boughtResponse.statusCode == 200) {
          final List<dynamic> boughtData = json.decode(boughtResponse.body);
          setState(() {
            boughtOrders = boughtData.map((item) => OrderWithStockName.fromJson(item)).toList();
          });
        } else {
          print("Failed to load bought orders with stock names");
          throw Exception('Failed to load bought orders with stock names');
        }

        if (currentResponse.statusCode == 200) {
          print("in current yo");
          final List<dynamic> currentData = json.decode(currentResponse.body);
          print("after list");
          setState(() {
            print("in set state");
            currentOrders = currentData.map((item) => OrderWithStockName.fromJson(item)).toList();
            print("after in set state");
          });
          print("currentorders are ");
        } else {
          print("Failed to load current orders with stock names");
          throw Exception('Failed to load current orders with stock names');
        }

      }
    } on TimeoutException {
      print('Request took too long');
      // Handle the timeout exception here
    }
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Orders'),
          backgroundColor: Color(0xFF221E1F),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Current'),
              Tab(text: 'Bought'),
              Tab(text: 'Sold'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OrdersList(ordersWithStockNames: currentOrders, orderStatus: OrderStatus.Current),
            OrdersList(ordersWithStockNames: boughtOrders, orderStatus: OrderStatus.Bought),
            OrdersList(ordersWithStockNames: soldOrders, orderStatus: OrderStatus.Sold),
          ],
        ),
      ),
    );
  }
}


class OrdersList extends StatelessWidget {
  final List<OrderWithStockName> ordersWithStockNames;
  final OrderStatus orderStatus;

  OrdersList({required this.ordersWithStockNames, required this.orderStatus});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: ordersWithStockNames.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: OrderTile(orderWithStockName: ordersWithStockNames[index], orderStatus: orderStatus),
        );
      },
    );
  }
}
class OrderTile extends StatelessWidget {
  final OrderWithStockName orderWithStockName;
  final OrderStatus orderStatus;

  OrderTile({required this.orderWithStockName, required this.orderStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align elements to the right and left
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Name: ${orderWithStockName.stockName}',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              if (orderStatus != OrderStatus.Current) // Show price for non-Current tabs
                Text(
                  'Price: \$${orderWithStockName.price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16.0, color: Colors.green),
                ),
              SizedBox(height: 8.0),
              Text(
                'Quantity: ${orderWithStockName.quantity}',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
          if (orderStatus == OrderStatus.Current) // Show Buy button for the Current tab
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8.0), // Adjust the padding here
                child: ElevatedButton(
                  onPressed: () {
                    _showSellPopup(context, orderWithStockName);
                    // Handle the buy button click here
                  },
                  child: Text('Sell'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showSellPopup(BuildContext context, OrderWithStockName order) {
  int quantity = 1;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SellStockPopup(orderr: order);
    },
  );
}

class SellStockPopup extends StatefulWidget {
  final OrderWithStockName orderr;

  SellStockPopup({required this.orderr});

  @override
  _SellStockPopupState createState() => _SellStockPopupState();
}

class _SellStockPopupState extends State<SellStockPopup> {
  int quantity = 1;
  int price = 0; // Add this line

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.orderr.price * quantity;

    return AlertDialog(
      title: Center(child: Text('Sell ${widget.orderr.stockName} Stock')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Enter quantity:'),
          Center(
            child: Column( // Wrap the TextFields in a Column
              children: [
                Container(
                  width: 200, // Set the width of the container
                  child: TextField(
                    textAlign: TextAlign.center, // Center align the text
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        quantity = int.tryParse(value) ?? 1;
                      });
                    },
                  ),
                ),
                SizedBox(height: 30), // Add some spacing
                Text('Enter Price:'),
                Container(
                  width: 200, // Set the width of the container
                  child: TextField(
                    textAlign: TextAlign.center, // Center align the text
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        price = int.tryParse(value) ?? 1;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
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
                  _performSellAction(context, widget.orderr, quantity);
                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF0AB7CD),
                ),
                child: Text('Sell'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _performSellAction(BuildContext context, OrderWithStockName orderr,
      int quantity ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('username') ?? '';
    final String jwtToken = prefs.getString('jwtToken') ?? '';

    final encodedEmail = Uri.encodeQueryComponent(userName);

    final apiUrl = 'http://10.0.2.2:5262/api/Order/sell-order';
    final url = Uri.parse(
        '$apiUrl?stockId=${orderr.stockId}&userName=$encodedEmail&quantity=$quantity&price=$price');

    print("the url is $url");
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
      _showOrderMadePopup(context); // Show the order placed popup
      print('Order created successfully: $responseData');
    } else {
      print('Failed to create order. Status code: ${response.statusCode}');
    }
  }

  void _showOrderMadePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Future.delayed(Duration(seconds: 5), () {
          Navigator.of(context).pop(); // Close the popup after 5 seconds
        });
        return AlertDialog(
          title: Center(child: Text('Stock Sold Successfully!')),
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

enum OrderStatus {
  Bought,
  Sold,
  Current
}
