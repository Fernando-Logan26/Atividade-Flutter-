import 'package:flutter/material.dart';

import '../models/carrinho.dart';
import '../database/database_helper.dart';

String moeda(int centavos) =>
    'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({super.key});
  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  bool _salvando = false;
  Future<void> _finalizar() async {
    final carrinho = Carrinho.instance;
    if (carrinho.itens.isEmpty || _salvando) return;
    try {
      final usuario = DatabaseHelper.instance.usuarioAtual;
      if (usuario?.id == null) throw StateError('Faça login para finalizar.');
      setState(() => _salvando = true);
      final quantidades = {
        for (final item in carrinho.itens) item.produto.id!: item.quantidade,
      };
      final id = await DatabaseHelper.instance.finalizarPedido(
        usuarioId: usuario!.id!,
        quantidades: quantidades,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Pedido #$id finalizado!')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível finalizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CARRINHO'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: Carrinho.instance,
        builder: (context, _) {
          final carrinho = Carrinho.instance;
          if (carrinho.itens.isEmpty) {
            return const Center(child: Text('Seu carrinho está vazio.'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: carrinho.itens.length,
                  itemBuilder: (context, index) {
                    final item = carrinho.itens[index];
                    return ListTile(
                      leading: Image.asset(
                        item.produto.imagem,
                        width: 56,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.shopping_bag),
                      ),
                      title: Text(item.produto.nome),
                      subtitle: Text(
                        '${moeda(item.subtotalCentavos)}  •  ${item.produto.tamanho}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Remover item',
                            onPressed: () => carrinho.alterarQuantidade(item.produto.id!, 0),
                            icon: const Icon(Icons.delete_outline)),
                          IconButton(
                            onPressed: () => carrinho.alterarQuantidade(
                              item.produto.id!,
                              item.quantidade - 1,
                            ),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${item.quantidade}'),
                          IconButton(
                            onPressed: item.quantidade < item.produto.estoque
                                ? () => carrinho.alterarQuantidade(
                                    item.produto.id!,
                                    item.quantidade + 1,
                                  )
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Total: ${moeda(carrinho.totalCentavos)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _salvando ? null : _finalizar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _salvando ? 'SALVANDO...' : 'FINALIZAR PEDIDO',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
