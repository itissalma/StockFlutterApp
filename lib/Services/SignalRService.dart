import 'package:signalr_netcore/signalr_client.dart';
import 'package:test_app/models/stock_class.dart';

class SignalRService {
  final String serverUrl;

  late HubConnection hubConnection;

  SignalRService(this.serverUrl) {
    hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl)
        .build();
  }

  Future<void> startConnection() async {
    await hubConnection.start();
    print('SignalR connection started');
  }

  void stopConnection() {
    hubConnection.stop();
    print('SignalR connection stopped');
  }

  void updateStockPrices(void Function(int stockId, double newPrice) onUpdate) {
    hubConnection.on("UpdateStockPrice", (arguments) {
      final stockId = arguments?[0] as int;
      final newPrice = (arguments?[1] as double).toDouble();
      onUpdate(stockId, newPrice);
    });
  }


}
