class ExpenseModel {

  final int? id;
  final String description;
  final double value;
  final String payer;

  ExpenseModel({
    this.id,
    required this.description,
    required this.value,
    required this.payer,
  });

  Map<String, dynamic> toMap(){
    return{
      'id': id, 
      'description': description,
      'value': value,
      'payer': payer,
    };
  }
  factory ExpenseModel.fromMap(
    Map<String, dynamic> map,
  ){
    return ExpenseModel(
      id: map['id'],
      description: map['description'],
      value: map['value'],
      payer: map['payer'],
    );
  }
}