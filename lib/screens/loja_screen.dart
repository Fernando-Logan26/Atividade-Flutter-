import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/carrinho.dart';
import '../models/produto.dart';
import 'carrinho_screen.dart';

class LojaScreen extends StatefulWidget {
  const LojaScreen({super.key});
  @override
  State<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends State<LojaScreen> {
  late Future<List<Produto>> _produtos;
  String _categoria = 'Todos';
  final _categorias = [
    'Todos',
    'Camisetas',
    'Calças',
    'Jaquetas',
    'Acessórios',
  ];

  @override
  void initState() {
    super.initState();
    _produtos = _carregar();
  }

  Future<List<Produto>> _carregar() async {
    await DatabaseHelper.instance.cadastrarProdutosIniciais();
    return DatabaseHelper.instance.listarProdutos();
  }

  void _recarregar() =>
      setState(() => _produtos = DatabaseHelper.instance.listarProdutos());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NOKIS',
          style: TextStyle(letterSpacing: 5, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          AnimatedBuilder(
            animation: Carrinho.instance,
            builder: (context, _) => IconButton(
              tooltip: 'Carrinho (${Carrinho.instance.quantidadeTotal})',
              icon: Badge(
                label: Text('${Carrinho.instance.quantidadeTotal}'),
                isLabelVisible: Carrinho.instance.quantidadeTotal > 0,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
                );
                if (mounted) _recarregar();
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Produto>>(
        future: _produtos,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar produtos: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final produtos = snapshot.data!
              .where((p) => _categoria == 'Todos' || p.categoria == _categoria)
              .toList();
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'NOVA COLEÇÃO',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _categorias
                      .map(
                        (categoria) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(categoria),
                            selected: _categoria == categoria,
                            onSelected: (_) =>
                                setState(() => _categoria = categoria),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth > 650 ? 4 : 2,
                      mainAxisExtent: 320,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: produtos.length,
                    itemBuilder: (context, index) {
                      final p = produtos[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.asset(
                                p.imagem,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.image_not_supported),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.nome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Tamanho ${p.tamanho} • Estoque ${p.estoque}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    moeda(p.precoCentavos),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: p.estoque > 0
                                          ? () {
                                              final ok = Carrinho.instance
                                                  .adicionar(p);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    ok
                                                        ? '${p.nome} adicionado!'
                                                        : 'Limite de estoque atingido.',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 1,
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        p.estoque > 0
                                            ? 'ADICIONAR'
                                            : 'ESGOTADO',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
