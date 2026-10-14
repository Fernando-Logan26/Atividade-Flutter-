import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/produto.dart';

class ProdutosAdminScreen extends StatefulWidget {
  const ProdutosAdminScreen({super.key});

  @override
  State<ProdutosAdminScreen> createState() => _ProdutosAdminScreenState();
}

class _ProdutosAdminScreenState extends State<ProdutosAdminScreen> {
  late Future<List<Produto>> _dados;

  @override
  void initState() {
    super.initState();
    _dados = DatabaseHelper.instance.listarProdutos();
  }

  void _recarregar() {
    if (!mounted) return;
    setState(() {
      _dados = DatabaseHelper.instance.listarProdutos();
    });
  }

  String _preco(int valor) =>
      'R\$ ${(valor / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _abrirFormulario([Produto? produto]) async {
    final nome = TextEditingController(text: produto?.nome ?? '');
    final descricao = TextEditingController(text: produto?.descricao ?? '');
    final categoria = TextEditingController(text: produto?.categoria ?? '');
    final tamanho = TextEditingController(text: produto?.tamanho ?? '');
    final preco = TextEditingController(
      text: produto == null
          ? ''
          : (produto.precoCentavos / 100)
                .toStringAsFixed(2)
                .replaceAll('.', ','),
    );
    final estoque = TextEditingController(
      text: produto?.estoque.toString() ?? '0',
    );
    String imagem = produto?.imagem ?? 'assets/produtos/produto1.jpeg';
    final imagens = [
      for (var i = 1; i <= 8; i++)
        'assets/produtos/produto$i.${i <= 4 ? 'jpeg' : 'jpg'}',
    ];
    final formKey = GlobalKey<FormState>();
    try {
      final salvou = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, atualizarDialogo) => AlertDialog(
            title: Text(produto == null ? 'Novo produto' : 'Editar produto'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _campo(nome, 'Nome'),
                      _campo(descricao, 'Descrição'),
                      _campo(categoria, 'Categoria'),
                      _campo(tamanho, 'Tamanho'),
                      _campo(preco, 'Preço (R\$)', numero: true),
                      _campo(estoque, 'Estoque', inteiro: true),
                      DropdownButtonFormField<String>(
                        initialValue: imagem,
                        decoration: const InputDecoration(labelText: 'Imagem'),
                        items: imagens
                            .map(
                              (caminho) => DropdownMenuItem(
                                value: caminho,
                                child: Text(caminho.split('/').last),
                              ),
                            )
                            .toList(),
                        onChanged: (valor) {
                          if (valor != null) {
                            atualizarDialogo(() => imagem = valor);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Image.asset(
                        imagem,
                        height: 90,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('CANCELAR'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final valor = double.tryParse(
                    preco.text.replaceAll(',', '.'),
                  );
                  final quantidade = int.tryParse(estoque.text);
                  if (valor == null ||
                      !valor.isFinite ||
                      valor < 0 ||
                      quantidade == null ||
                      quantidade < 0) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Preço ou estoque inválido'),
                      ),
                    );
                    return;
                  }
                  final novo = Produto(
                    id: produto?.id,
                    nome: nome.text.trim(),
                    descricao: descricao.text.trim(),
                    categoria: categoria.text.trim(),
                    imagem: imagem,
                    tamanho: tamanho.text.trim(),
                    precoCentavos: (valor * 100).round(),
                    estoque: quantidade,
                  );
                  try {
                    if (produto == null) {
                      await DatabaseHelper.instance.cadastrarProduto(novo);
                    } else {
                      await DatabaseHelper.instance.atualizarProduto(novo);
                    }
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  } catch (erro) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Erro ao salvar: $erro')),
                      );
                    }
                  }
                },
                child: const Text('SALVAR'),
              ),
            ],
          ),
        ),
      );
      if (salvou == true && mounted) _recarregar();
    } finally {
      // Dispose após a rota de diálogo encerrar a animação.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      nome.dispose();
      descricao.dispose();
      categoria.dispose();
      tamanho.dispose();
      preco.dispose();
      estoque.dispose();
    }
  }

  Widget _campo(
    TextEditingController controller,
    String titulo, {
    bool numero = false,
    bool inteiro = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: titulo),
      keyboardType: numero || inteiro
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: inteiro
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: (valor) =>
          valor == null || valor.trim().isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Future<void> _excluir(Produto produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: Text(
          'Deseja excluir ${produto.nome}? Os pedidos anteriores serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await DatabaseHelper.instance.excluirProduto(produto.id!);
      if (mounted) _recarregar();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível excluir o produto. Tente novamente.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (DatabaseHelper.instance.usuarioAtual?.isAdmin != true) {
      return Scaffold(appBar: AppBar(title: const Text('Acesso restrito')),
        body: const Center(child: Text('Somente administradores podem acessar esta tela.')));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('NOKIS | Produtos'),
        actions: [
          IconButton(onPressed: _recarregar, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('NOVO PRODUTO'),
      ),
      body: FutureBuilder<List<Produto>>(
        future: _dados,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum produto cadastrado'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, indice) {
              final produto = snapshot.data![indice];
              return Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 58,
                    child: Image.asset(
                      produto.imagem,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(produto.nome),
                  subtitle: Text(
                    '${_preco(produto.precoCentavos)} • ${produto.tamanho} • Estoque: ${produto.estoque}',
                  ),
                  trailing: Wrap(
                    spacing: 0,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _abrirFormulario(produto),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _excluir(produto),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
