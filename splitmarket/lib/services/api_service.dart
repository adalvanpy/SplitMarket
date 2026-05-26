import '../models/group_model.dart';

class ApiService {
  Future<List<GroupModel>> listarGrupos() async{
    await Future.delayed(
      const Duration(seconds:1),
    );
    return[
      GroupModel(id: '1', nome: 'Casa'),
      GroupModel(id: '2', nome: 'Faculdade'),
    ];
  }
}