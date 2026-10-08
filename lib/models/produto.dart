class Produto {
  final int? id;
  final String nome;
  final String descricao;
  final String categoria;
  final String imagem;
  final String tamanho;
  final int precoCentavos;
  final int estoque;

  const Produto({
    this.id,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.imagem,
    required this.tamanho,
    required this.precoCentavos,
    required this.estoque,
  });

  double get preco => precoCentavos / 100;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'categoria': categoria,
      'imagem': imagem,
      'tamanho': tamanho,
      'preco_centavos': precoCentavos,
      'estoque': estoque,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'] as int,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String,
      categoria: map['categoria'] as String,
      imagem: map['imagem'] as String,
      tamanho: map['tamanho'] as String,
      precoCentavos: map['preco_centavos'] as int,
      estoque: map['estoque'] as int,
    );
  }
}
