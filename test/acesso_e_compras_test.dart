import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_nokis/database/database_helper.dart';
import 'package:flutter_nokis/models/usuario.dart';
import 'package:flutter_nokis/models/produto.dart';
import 'package:flutter_nokis/models/carrinho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Migração, permissões, compra e exclusão preservam vendas', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final pasta = await Directory.systemTemp.createTemp('nokis_teste_');
    await databaseFactory.setDatabasesPath(pasta.path);
    final antigo = await openDatabase('${pasta.path}/nokis.db', version: 3,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE usuarios (id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT NOT NULL, email TEXT NOT NULL UNIQUE, telefone TEXT NOT NULL)');
        await db.execute('CREATE TABLE produtos (id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT NOT NULL, descricao TEXT NOT NULL, categoria TEXT NOT NULL, imagem TEXT NOT NULL, tamanho TEXT NOT NULL, preco_centavos INTEGER NOT NULL, estoque INTEGER NOT NULL)');
        await db.execute('CREATE TABLE pedidos (id INTEGER PRIMARY KEY AUTOINCREMENT, usuario_id INTEGER NOT NULL, data TEXT NOT NULL, total_centavos INTEGER NOT NULL, status TEXT NOT NULL, FOREIGN KEY(usuario_id) REFERENCES usuarios(id))');
        await db.execute('CREATE TABLE itens_pedido (id INTEGER PRIMARY KEY AUTOINCREMENT, pedido_id INTEGER NOT NULL, produto_id INTEGER, nome_produto TEXT NOT NULL, tamanho TEXT NOT NULL, quantidade INTEGER NOT NULL, preco_unitario_centavos INTEGER NOT NULL, FOREIGN KEY(pedido_id) REFERENCES pedidos(id), FOREIGN KEY(produto_id) REFERENCES produtos(id))');
        await db.insert('usuarios', {'id': 1, 'nome': 'Cliente antigo', 'email': 'antigo@teste.com', 'telefone': '69999999999'});
        await db.insert('produtos', {'id': 1, 'nome': 'Camiseta', 'descricao': 'Básica', 'categoria': 'Camisetas', 'imagem': '', 'tamanho': 'M', 'preco_centavos': 5000, 'estoque': 5});
        await db.insert('pedidos', {'id': 1, 'usuario_id': 1, 'data': '2026-01-01', 'total_centavos': 5000, 'status': 'Finalizado'});
        await db.insert('itens_pedido', {'id': 1, 'pedido_id': 1, 'produto_id': 1, 'nome_produto': 'Camiseta', 'tamanho': 'M', 'quantidade': 1, 'preco_unitario_centavos': 5000});
      });
    await antigo.close();
    final helper = DatabaseHelper.instance;
    try {
      expect(await helper.precisaAdministrador(), isTrue);
      await expectLater(helper.listarUsuarios(), throwsStateError);
      const admin = Usuario(nome: 'Admin', email: 'admin@teste.com', telefone: '69999999999');
      await helper.criarPrimeiroAdministrador(admin, 'senhaAdmin123');
      expect(await helper.precisaAdministrador(), isFalse);
      await expectLater(helper.criarPrimeiroAdministrador(admin, 'senhaAdmin123'), throwsStateError);
      await helper.entrar('ADMIN@TESTE.COM', 'senhaAdmin123');
      expect(helper.usuarioAtual!.isAdmin, isTrue);
      final usuarios = await helper.listarUsuarios();
      expect(usuarios.length, 2);
      final clienteAntigo = usuarios.firstWhere((u) => u.id == 1);
      await helper.atualizarUsuario(clienteAntigo, novaSenha: 'cliente123');
      final cliente2 = await helper.cadastrarUsuario(const Usuario(
        nome: 'Outra conta', email: 'outro@teste.com', telefone: '69999999999'), senha: 'cliente456');
      await expectLater(helper.excluirUsuario(helper.usuarioAtual!.id!), throwsStateError);
      await helper.entrar('antigo@teste.com', 'cliente123');
      expect(helper.usuarioAtual!.isAdmin, isFalse);
      await expectLater(helper.listarUsuarios(), throwsStateError);
      await expectLater(helper.excluirUsuario(cliente2), throwsStateError);
      await expectLater(helper.atualizarUsuario(clienteAntigo, novaSenha: 'senhaNova123'), throwsStateError);
      await expectLater(helper.cadastrarUsuario(const Usuario(nome: 'Invasor', email: 'invasor@teste.com', telefone: '69999999999', isAdmin: true), senha: 'invasor123'), throwsStateError);
      const roupa = Produto(nome: 'Nova roupa', descricao: 'Teste', categoria: 'Camisetas', imagem: '', tamanho: 'M', precoCentavos: 2000, estoque: 1);
      await expectLater(helper.cadastrarProduto(roupa), throwsStateError);
      await expectLater(helper.excluirProduto(1), throwsStateError);
      await expectLater(helper.finalizarPedido(usuarioId: cliente2, quantidades: {1: 1}), throwsStateError);
      final estoqueAntes = (await helper.buscarProduto(1))!.estoque;
      await expectLater(helper.finalizarPedido(usuarioId: 1, quantidades: {1: estoqueAntes + 1}), throwsStateError);
      expect((await helper.buscarProduto(1))!.estoque, estoqueAntes);
      final carrinho = Carrinho.instance;
      carrinho.adicionar((await helper.buscarProduto(1))!);
      final pedido = await helper.finalizarPedido(usuarioId: 1, quantidades: {1: 1});
      expect(carrinho.itens, isEmpty);
      expect((await helper.buscarProduto(1))!.estoque, estoqueAntes - 1);
      expect((await helper.listarPedidos()).length, 2);
      expect((await helper.listarItensPedido(pedido)).length, 1);
      carrinho.adicionar((await helper.buscarProduto(1))!);
      helper.sair();
      expect(carrinho.itens, isEmpty);
      await helper.entrar('outro@teste.com', 'cliente456');
      expect(await helper.listarPedidos(), isEmpty);
      await expectLater(helper.listarItensPedido(pedido), throwsStateError);
      await helper.entrar('admin@teste.com', 'senhaAdmin123');
      await helper.excluirUsuario(1);
      final historico = await helper.listarPedidos();
      expect(historico.length, 2);
      expect(historico.every((p) => p['usuario_id'] == null), isTrue);
      expect(historico.first['nome_usuario'], 'Cliente antigo');
      await helper.excluirProduto(1);
      expect((await helper.listarItensPedido(pedido)).first['produto_id'], isNull);
      await expectLater(helper.entrar('antigo@teste.com', 'cliente123'), throwsStateError);
      expect(helper.usuarioAtual, isNull);
    } finally {
      helper.sair();
      await (await helper.database).close();
      await pasta.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
