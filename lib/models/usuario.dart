class Usuario {
  final int? id;
  final String nome;
  final String email;
  final String telefone;

  const Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'email': email,
    'telefone': telefone,
  };

  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
    id: map['id'] as int,
    nome: map['nome'] as String,
    email: map['email'] as String,
    telefone: (map['telefone'] as String?) ?? '',
  );
}
