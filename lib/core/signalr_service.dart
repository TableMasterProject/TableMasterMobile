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
  final _onReservationUpdateStatus = StreamController<ReservationOut>.broadcast();
  final _onReservationDeleted = StreamController<int>.broadcast();

  Stream<ReservationOut> get onReservationCreated => _onReservationCreated.stream;
  Stream<ReservationOut> get onReservationUpdateStatus => _onReservationUpdateStatus.stream;
  Stream<int> get onReservationDeleted => _onReservationDeleted.stream;

  Future<void> init() async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) return;

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

    _hubConnection?.on("ReceiveReservationCreated", (arguments) {
      try {
        if (arguments != null && arguments.isNotEmpty) {
          final data = jsonDecode(arguments[0] as String);
          _onReservationCreated.add(ReservationOut.fromJson(data));
        }
      } catch (e) { print("SignalR Error: $e"); }
    });

    _hubConnection?.on("ReceiveReservationUpdateStatus", (arguments) {
      try {
        if (arguments != null && arguments.isNotEmpty) {
          final data = jsonDecode(arguments[0] as String);
          _onReservationUpdateStatus.add(ReservationOut.fromJson(data));
        }
      } catch (e) { print("SignalR Error: $e"); }
    });

    _hubConnection?.on("ReceiveReservationDeleted", (arguments) {
      try {
        if (arguments != null && arguments.isNotEmpty) {
          _onReservationDeleted.add(arguments[0] as int);
        }
      } catch (e) { print("SignalR Error: $e"); }
    });

    try {
      await _hubConnection?.start();
    } catch (e) { print("SignalR Connection Error: $e"); }
  }

  Future<void> joinRestaurantGroup(int restaurantId) async {
    await init();
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke("JoinRestaurantGroup", args: [restaurantId.toString()]);
    }
  }

  Future<void> leaveRestaurantGroup(int restaurantId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke("LeaveRestaurantGroup", args: [restaurantId.toString()]);
    }
  }

  // AJOUT : Rejoindre le groupe privé de l'utilisateur
  Future<void> joinUserGroup(int userId) async {
    await init();
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke("JoinUserGroup", args: [userId.toString()]);
    }
  }

  Future<void> leaveUserGroup(int userId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke("LeaveUserGroup", args: [userId.toString()]);
    }
  }

  void dispose() {
    _hubConnection?.stop();
    _onReservationCreated.close();
    _onReservationUpdateStatus.close();
    _onReservationDeleted.close();
  }
}
