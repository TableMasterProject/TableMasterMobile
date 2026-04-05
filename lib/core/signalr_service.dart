import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'app_config.dart';
import '../features/reservation/data/models/reservation_out.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final _storage = const FlutterSecureStorage();
  
  final _onReservationCreated = StreamController<ReservationOut>.broadcast();
  final _onReservationValidated = StreamController<ReservationOut>.broadcast();
  final _onReservationDeleted = StreamController<int>.broadcast();

  Stream<ReservationOut> get onReservationCreated => _onReservationCreated.stream;
  Stream<ReservationOut> get onReservationValidated => _onReservationValidated.stream;
  Stream<int> get onReservationDeleted => _onReservationDeleted.stream;

  Future<void> init() async {
    final baseUrl = AppConfig.apiUrl;
    final hubUrl = "$baseUrl/reservationHub";

    final httpOptions = HttpConnectionOptions(
      accessTokenFactory: () async {
        final token = await _storage.read(key: 'access_token');
        return token ?? "";
      },
      skipNegotiation: true,
      transport: HttpTransportType.WebSockets,
    );

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl, options: httpOptions)
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose(({error}) => print("SignalR Connection Closed: $error"));
    _hubConnection?.onreconnecting(({error}) => print("SignalR Reconnecting: $error"));
    _hubConnection?.onreconnected(({connectionId}) => print("SignalR Reconnected: $connectionId"));

    _hubConnection?.on("ReceiveReservationCreated", (arguments) {
      try {
        if (arguments != null && arguments.isNotEmpty) {
          print("SignalR ReceiveReservationCreated: Reçu -> ${arguments[0]}");
          final data = jsonDecode(arguments[0] as String);
          _onReservationCreated.add(ReservationOut.fromJson(data));
        }
      } catch (e) {
        print("SignalR Error Parsing Created: $e");
      }
    });

    _hubConnection?.on("ReceiveReservationValidate", (arguments) {
      try {
        if (arguments != null && arguments.isNotEmpty) {
          print("SignalR ReceiveReservationValidate: Reçu -> ${arguments[0]}");
          final data = jsonDecode(arguments[0] as String);
          _onReservationValidated.add(ReservationOut.fromJson(data));
        }
      } catch (e) {
        print("SignalR Error Parsing Validate: $e");
      }
    });

    _hubConnection?.on("ReceiveReservationDeleted", (arguments) {
      try {
        if (arguments != null && arguments.isNotEmpty) {
          _onReservationDeleted.add(arguments[0] as int);
        }
      } catch (e) {
        print("SignalR Error Parsing Deleted: $e");
      }
    });

    try {
      await _hubConnection?.start();
      print("SignalR Connected");
    } catch (e) {
      print("SignalR Connection Error: $e");
    }
  }

  Future<void> joinRestaurantGroup(int restaurantId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke("JoinRestaurantGroup", args: [restaurantId.toString()]);
    }
  }

  Future<void> leaveRestaurantGroup(int restaurantId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke("LeaveRestaurantGroup", args: [restaurantId.toString()]);
    }
  }

  void dispose() {
    _hubConnection?.stop();
    _onReservationCreated.close();
    _onReservationValidated.close();
    _onReservationDeleted.close();
  }
}
