import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/usuario.dart';
import 'cadastro_screen.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Usuario> usuarios = [];
  String pesquisa = '';
  bool carregando = true;
  String? erro;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final lista = await DatabaseHelper.instance.listarUsuarios();
      if (!mounted) return;
      setState(() {
        usuarios = lista;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = e.toString();
        carregando = false;
      });
    }
  }

  Future<void> abrirCadastro([Usuario? usuario]) async {
    final alterou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CadastroScreen(usuario: usuario)),
    );

    if (alterou == true) {
      await carregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados salvos com sucesso!')),
      );
    }
  }

  Future<void> excluir(Usuario usuario) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Excluir ${usuario.nome}? Os pedidos já finalizados serão preservados e desvinculados desta conta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmou != true || usuario.id == null) return;

    try {
      await DatabaseHelper.instance.excluirUsuario(usuario.id!);
      await carregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Usuário excluído!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (DatabaseHelper.instance.usuarioAtual?.isAdmin != true) {
      return Scaffold(appBar: AppBar(title: const Text('Acesso restrito')),
        body: const Center(child: Text('Somente administradores podem acessar esta tela.')));
    }
    final filtrados = usuarios.where((u) {
      final termo = pesquisa.toLowerCase();
      return u.nome.toLowerCase().contains(termo) ||
          u.email.toLowerCase().contains(termo);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('USUÁRIOS NOKIS'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: carregar),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () => abrirCadastro(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Pesquisar nome ou e-mail',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (valor) {
                setState(() => pesquisa = valor);
              },
            ),
          ),
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : erro != null
                ? Center(child: Text('Erro: $erro'))
                : filtrados.isEmpty
                ? const Center(child: Text('Nenhum usuário encontrado.'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final u = filtrados[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.black,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(u.nome),
                          subtitle: Text('${u.email}\n${u.telefone} • ${u.isAdmin ? 'Admin' : 'Cliente'}'),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (opcao) {
                              if (opcao == 'editar') {
                                abrirCadastro(u);
                              } else if (opcao == 'excluir') {
                                excluir(u);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'excluir',
                                child: Text('Excluir'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
