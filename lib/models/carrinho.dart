import 'package:flutter/foundation.dart';

import 'item_carrinho.dart';
import 'produto.dart';

class Carrinho extends ChangeNotifier {
  Carrinho._();
  static final Carrinho instance = Carrinho._();
  final List<ItemCarrinho> _itens = [];
  List<ItemCarrinho> get itens => List.unmodifiable(_itens);
  int get quantidadeTotal => _itens.fold(0, (s, i) => s + i.quantidade);
  int get totalCentavos => _itens.fold(0, (s, i) => s + i.subtotalCentavos);

  bool adicionar(Produto produto) {
    if (produto.id == null || produto.estoque <= 0) return false;
    final indice = _itens.indexWhere((i) => i.produto.id == produto.id);
    if (indice >= 0) {
      if (_itens[indice].quantidade >= produto.estoque) return false;
      _itens[indice].quantidade++;
    } else {
      _itens.add(ItemCarrinho(produto: produto));
    }
    notifyListeners();
    return true;
  }

  void alterarQuantidade(int produtoId, int quantidade) {
    final indice = _itens.indexWhere((i) => i.produto.id == produtoId);
    if (indice < 0) return;
    if (quantidade <= 0) {
      _itens.removeAt(indice);
    } else if (quantidade <= _itens[indice].produto.estoque) {
      _itens[indice].quantidade = quantidade;
    }
    notifyListeners();
  }

  void limpar() {
    _itens.clear();
    notifyListeners();
  }
}
