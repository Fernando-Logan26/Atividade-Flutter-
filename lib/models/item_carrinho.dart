import 'produto.dart';

class ItemCarrinho {
  final Produto produto;
  int quantidade;

  ItemCarrinho({required this.produto, this.quantidade = 1});

  int get subtotalCentavos => produto.precoCentavos * quantidade;
}
