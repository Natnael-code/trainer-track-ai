import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../services/database_service.dart';

class ClientProvider with ChangeNotifier {
  List<ClientModel> _clients = [];

  List<ClientModel> get clients => [..._clients];

  int get totalActiveClients =>
      _clients.where((c) => c.status == 'active').length;

  // Pull records out of SQLite storage database on launch
  Future<void> loadClientsFromDatabase() async {
    _clients = await DatabaseService.instance.fetchAllClients();
    notifyListeners();
  }

  // Push new client details cleanly down into persistent storage hardware
  Future<void> addClient(ClientModel newClient) async {
    await DatabaseService.instance.insertClient(newClient);
    _clients.add(newClient);
    notifyListeners();
  }

  // Trigger file compilation for security export transfers
  Future<void> backupData() async {
    await DatabaseService.instance.exportDatabaseBackup();
  }
}
