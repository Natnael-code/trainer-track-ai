import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../models/fitness_models.dart';
import '../services/database_service.dart';

class ClientProvider with ChangeNotifier {
  List<ClientModel> _clients = [];
  List<GroupModel> _groups = [];

  List<ClientModel> get clients => [..._clients];
  List<GroupModel> get groups => [..._groups];

  int get totalActiveClients =>
      _clients.where((c) => c.status == 'active').length;
  int get totalActiveGroups =>
      _groups.where((g) => g.status == 'active').length;

  Future<void> loadClientsFromDatabase() async {
    _clients = await DatabaseService.instance.fetchAllClients();
    _groups = await DatabaseService.instance.fetchAllGroups();
    notifyListeners();
  }

  Future<void> addClient(ClientModel newClient) async {
    await DatabaseService.instance.insertClient(newClient);
    _clients.add(newClient);
    notifyListeners();
  }

  Future<void> addGroup(GroupModel newGroup) async {
    await DatabaseService.instance.insertGroup(newGroup);
    _groups.add(newGroup);
    notifyListeners();
  }

  Future<void> assignClientToGroup(String clientId, String groupId) async {
    final clientIndex = _clients.indexWhere((c) => c.id == clientId);
    if (clientIndex != -1) {
      final currentClient = _clients[clientIndex];
      final updatedClient = ClientModel(
        id: currentClient.id,
        name: currentClient.name,
        phoneNumber: currentClient.phoneNumber,
        age: currentClient.age,
        gender: currentClient.gender,
        startingWeight: currentClient.startingWeight,
        height: currentClient.height,
        startingBodyFat: currentClient.startingBodyFat,
        localProfileImagePath: currentClient.localProfileImagePath,
        injuries: currentClient.injuries,
        medicalConditions: currentClient.medicalConditions,
        experienceLevel: currentClient.experienceLevel,
        lifestyleType: currentClient.lifestyleType,
        joinedDate: currentClient.joinedDate,
        status: currentClient.status,
        groupId: groupId, // Assigned to shared group context
      );

      await DatabaseService.instance.insertClient(updatedClient);
      _clients[clientIndex] = updatedClient;
      notifyListeners();
    }
  }

  Future<void> backupData() async {
    await DatabaseService.instance.exportDatabaseBackup();
  }
}
