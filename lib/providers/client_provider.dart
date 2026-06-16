import 'package:flutter/material.dart';
import '../models/client_model.dart';

class ClientProvider with ChangeNotifier {
  // Direct internal memory tracker for active clients
  final List<ClientModel> _clients = [];

  // Expose the list to the UI without allowing direct external manipulation
  List<ClientModel> get clients => [..._clients];

  // Calculated Business Intelligence Metrics for our Dashboard Status Cards
  int get totalActiveClients =>
      _clients.where((c) => c.status == 'active').length;

  // Function to insert a freshly registered client profile
  void addClient(ClientModel newClient) {
    _clients.add(newClient);

    // CRITICAL: Tells Flutter to redraw any screen listening to this data
    notifyListeners();
  }
}
