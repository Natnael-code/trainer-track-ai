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

    // Automatically save initial registration step as the first progress entry with photo
    final initialProgress = ClientProgressModel(
      id: 'progress_init_${newClient.id}',
      clientId: newClient.id,
      weight: newClient.startingWeight,
      height: newClient.height,
      bmi: newClient.bmi,
      imagePath: newClient.localProfileImagePath,
      date: newClient.joinedDate,
      notes: 'Initial Registration Baseline',
    );
    await DatabaseService.instance.insertClientProgress(initialProgress);

    _clients.removeWhere((c) => c.id == newClient.id);
    _clients.add(newClient);
    notifyListeners();
  }

  // Adds a group-only member directly to a designated group
  Future<void> addGroupMember({
    required String name,
    required String phoneNumber,
    required double weight,
    required String groupId,
  }) async {
    final client = ClientModel(
      id: 'member_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phoneNumber: phoneNumber,
      startingWeight: weight,
      joinedDate: DateTime.now(),
      groupId: groupId,
    );

    await DatabaseService.instance.insertClient(client);
    await DatabaseService.instance.addClientToGroup(client.id, groupId);
    _clients.removeWhere((c) => c.id == client.id);
    _clients.add(client);
    notifyListeners();
  }

  Future<void> addGroup(GroupModel newGroup) async {
    await DatabaseService.instance.insertGroup(newGroup);
    _groups.removeWhere((g) => g.id == newGroup.id);
    _groups.add(newGroup);
    notifyListeners();
  }

  Future<void> assignClientToGroup(String clientId, String groupId) async {
    final clientIndex = _clients.indexWhere((c) => c.id == clientId);
    if (clientIndex != -1) {
      final current = _clients[clientIndex];
      final updated = ClientModel(
        id: current.id,
        name: current.name,
        phoneNumber: current.phoneNumber,
        age: current.age,
        gender: current.gender,
        startingWeight: current.startingWeight,
        height: current.height,
        startingBodyFat: current.startingBodyFat,
        localProfileImagePath: current.localProfileImagePath,
        injuries: current.injuries,
        medicalConditions: current.medicalConditions,
        experienceLevel: current.experienceLevel,
        lifestyleType: current.lifestyleType,
        joinedDate: current.joinedDate,
        status: current.status,
        groupId: groupId,
        availableDaysPerWeek: current.availableDaysPerWeek,
        workoutSessionsPerDay: current.workoutSessionsPerDay,
        fitnessGoal: current.fitnessGoal,
      );

      await DatabaseService.instance.insertClient(updated);
      await DatabaseService.instance.addClientToGroup(clientId, groupId);
      _clients[clientIndex] = updated;
      notifyListeners();
    }
  }

  Future<void> removeClientFromGroup(String clientId, String groupId) async {
    final clientIndex = _clients.indexWhere((c) => c.id == clientId);
    if (clientIndex != -1) {
      final current = _clients[clientIndex];
      final updated = ClientModel(
        id: current.id,
        name: current.name,
        phoneNumber: current.phoneNumber,
        age: current.age,
        gender: current.gender,
        startingWeight: current.startingWeight,
        height: current.height,
        startingBodyFat: current.startingBodyFat,
        localProfileImagePath: current.localProfileImagePath,
        injuries: current.injuries,
        medicalConditions: current.medicalConditions,
        experienceLevel: current.experienceLevel,
        lifestyleType: current.lifestyleType,
        joinedDate: current.joinedDate,
        status: current.status,
        groupId: null,
        availableDaysPerWeek: current.availableDaysPerWeek,
        workoutSessionsPerDay: current.workoutSessionsPerDay,
        fitnessGoal: current.fitnessGoal,
      );

      await DatabaseService.instance.insertClient(updated);
      await DatabaseService.instance.removeClientFromGroup(clientId, groupId);
      _clients[clientIndex] = updated;
      notifyListeners();
    }
  }

  // Adds a progress entry for a personal client
  Future<void> addClientProgress(ClientProgressModel progress) async {
    await DatabaseService.instance.insertClientProgress(progress);
    notifyListeners();
  }

  Future<void> backupData() async {
    await DatabaseService.instance.exportDatabaseBackup();
  }
}
