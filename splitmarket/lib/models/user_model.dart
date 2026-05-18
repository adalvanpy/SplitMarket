class User {
  final String id;
  final String nome;
  final String email;
  final String? avatara_url;

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.avatara_url

  });

  factory User.fromJson(Map<String, dynamic> json){
    return User(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      avatara_url: json['avatara_url'],
    );

  }

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'avatara_url': avatara_url,
      
    };

  }
  @override
  String toString() {
    return 'User(id: $id, nome: $nome, email: $email)';
  }
}