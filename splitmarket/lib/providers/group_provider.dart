import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/api_service.dart';

class GroupProvider extends ChangeNotifier{
  final ApiService _service = 
      ApiService();

  List<GroupModel> grupos = [];

  bool carregando = false;

  Future<void> carregarGrupos() async{
    carregando = true;
    notifyListeners();

    grupos =
        await _service.listarGrupos();

    carregando = false;
    notifyListeners();
  }
}