import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/usuario.dart';
import '../models/produto.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final caminho = join(await getDatabasesPath(), 'nokis.db');

    _database = await openDatabase(
      caminho,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            telefone TEXT NOT NULL DEFAULT ''
          )
        ''');

        await _criarTabelasLoja(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE usuarios
            ADD COLUMN telefone TEXT NOT NULL DEFAULT ''
          ''');
        }

        if (oldVersion < 3) {
          await _criarTabelasLoja(db);
        }
      },
    );

    return _database!;
  }

  Future<void> _criarTabelasLoja(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT NOT NULL,
        categoria TEXT NOT NULL,
        imagem TEXT NOT NULL DEFAULT '',
        tamanho TEXT NOT NULL,
        preco_centavos INTEGER NOT NULL
          CHECK(preco_centavos >= 0),
        estoque INTEGER NOT NULL DEFAULT 0
          CHECK(estoque >= 0)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pedidos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        total_centavos INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pendente',
        FOREIGN KEY(usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS itens_pedido (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pedido_id INTEGER NOT NULL,
        produto_id INTEGER,
        nome_produto TEXT NOT NULL,
        tamanho TEXT NOT NULL,
        quantidade INTEGER NOT NULL,
        preco_unitario_centavos INTEGER NOT NULL,
        FOREIGN KEY(pedido_id) REFERENCES pedidos(id),
        FOREIGN KEY(produto_id) REFERENCES produtos(id)
      )
    ''');
  }

  // ==========================================
  // CRUD DE USUÁRIOS
  // ==========================================

  Future<int> cadastrarUsuario(Usuario usuario) async {
    final db = await database;

    return db.insert('usuarios', usuario.toMap());
  }

  Future<List<Usuario>> listarUsuarios() async {
    final db = await database;

    final dados = await db.query('usuarios', orderBy: 'nome ASC');

    return dados.map((map) => Usuario.fromMap(map)).toList();
  }

  Future<int> atualizarUsuario(Usuario usuario) async {
    if (usuario.id == null) {
      throw ArgumentError('ID do usuário obrigatório');
    }

    final db = await database;

    return db.update(
      'usuarios',
      usuario.toMap(),
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
  }

  Future<int> excluirUsuario(int id) async {
    final db = await database;

    return db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // CRUD DE PRODUTOS
  // ==========================================

  Future<int> cadastrarProduto(Produto produto) async {
    final db = await database;

    return db.insert('produtos', produto.toMap());
  }

  Future<List<Produto>> listarProdutos() async {
    final db = await database;

    final dados = await db.query('produtos', orderBy: 'nome ASC');

    return dados.map((map) => Produto.fromMap(map)).toList();
  }

  Future<Produto?> buscarProduto(int id) async {
    final db = await database;

    final dados = await db.query(
      'produtos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (dados.isEmpty) return null;

    return Produto.fromMap(dados.first);
  }

  Future<int> atualizarProduto(Produto produto) async {
    if (produto.id == null) {
      throw ArgumentError('ID do produto obrigatório');
    }

    final db = await database;

    return db.update(
      'produtos',
      produto.toMap(),
      where: 'id = ?',
      whereArgs: [produto.id],
    );
  }

  Future<int> excluirProduto(int id) async {
    final db = await database;

    return db.delete('produtos', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // CADASTRO AUTOMÁTICO DOS 8 PRODUTOS NOKIS
  // ==========================================

  Future<void> cadastrarProdutosIniciais() async {
    final db = await database;

    final produtos = <Produto>[
      const Produto(
        nome: 'Camiseta Preta',
        descricao: 'Camiseta básica preta',
        categoria: 'Camisetas',
        imagem: 'assets/produtos/produto1.jpeg',
        tamanho: 'M',
        precoCentavos: 5990,
        estoque: 10,
      ),
      const Produto(
        nome: 'Moletom Branco',
        descricao: 'Moletom branco com capuz',
        categoria: 'Jaquetas',
        imagem: 'assets/produtos/produto2.jpeg',
        tamanho: 'G',
        precoCentavos: 12990,
        estoque: 8,
      ),
      const Produto(
        nome: 'Calça Preta',
        descricao: 'Calça preta casual',
        categoria: 'Calças',
        imagem: 'assets/produtos/produto3.jpeg',
        tamanho: 'M',
        precoCentavos: 9990,
        estoque: 12,
      ),
      const Produto(
        nome: 'Corta-Vento Branco',
        descricao: 'Jaqueta corta-vento branca',
        categoria: 'Jaquetas',
        imagem: 'assets/produtos/produto4.jpeg',
        tamanho: 'G',
        precoCentavos: 14990,
        estoque: 6,
      ),
      const Produto(
        nome: 'Moletom Azul',
        descricao: 'Moletom azul',
        categoria: 'Jaquetas',
        imagem: 'assets/produtos/produto5.jpg',
        tamanho: 'M',
        precoCentavos: 11990,
        estoque: 10,
      ),
      const Produto(
        nome: 'Camiseta Azul-Marinho',
        descricao: 'Camiseta azul-marinho oversized',
        categoria: 'Camisetas',
        imagem: 'assets/produtos/produto6.jpg',
        tamanho: 'G',
        precoCentavos: 6490,
        estoque: 15,
      ),
      const Produto(
        nome: 'Boné Preto',
        descricao: 'Boné preto aba reta',
        categoria: 'Acessórios',
        imagem: 'assets/produtos/produto7.jpg',
        tamanho: 'Único',
        precoCentavos: 4990,
        estoque: 20,
      ),
      const Produto(
        nome: 'Óculos de Sol',
        descricao: 'Óculos de sol esportivo preto',
        categoria: 'Acessórios',
        imagem: 'assets/produtos/produto8.jpg',
        tamanho: 'Único',
        precoCentavos: 7990,
        estoque: 10,
      ),
    ];

    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS configuracoes (
          chave TEXT PRIMARY KEY,
          valor TEXT NOT NULL
        )
      ''');

      final configuracao = await txn.query(
        'configuracoes',
        where: 'chave = ?',
        whereArgs: ['produtos_iniciais_v1'],
        limit: 1,
      );

      if (configuracao.isNotEmpty) return;

      final resultado = await txn.rawQuery('SELECT COUNT(*) FROM produtos');

      final total = Sqflite.firstIntValue(resultado) ?? 0;

      if (total == 0) {
        for (final produto in produtos) {
          await txn.insert('produtos', produto.toMap());
        }
      }

      await txn.insert('configuracoes', {
        'chave': 'produtos_iniciais_v1',
        'valor': 'concluido',
      });
    });
  }

  Future<int> finalizarPedido({
    required int usuarioId,
    required Map<int, int> quantidades,
  }) async {
    if (quantidades.isEmpty) throw StateError('Carrinho vazio');
    final db = await database;
    return db.transaction((txn) async {
      final usuarios = await txn.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [usuarioId],
      );
      if (usuarios.isEmpty) throw StateError('Usuário não encontrado');
      final itens = <Map<String, dynamic>>[];
      var total = 0;
      for (final entrada in quantidades.entries) {
        if (entrada.value <= 0) throw StateError('Quantidade inválida');
        final dados = await txn.query(
          'produtos',
          where: 'id = ?',
          whereArgs: [entrada.key],
        );
        if (dados.isEmpty) throw StateError('Produto não encontrado');
        final produto = Produto.fromMap(dados.first);
        if (produto.estoque < entrada.value) {
          throw StateError('Estoque insuficiente: ${produto.nome}');
        }
        total += produto.precoCentavos * entrada.value;
        itens.add({
          'produto_id': produto.id,
          'nome_produto': produto.nome,
          'tamanho': produto.tamanho,
          'quantidade': entrada.value,
          'preco_unitario_centavos': produto.precoCentavos,
        });
      }
      final id = await txn.insert('pedidos', {
        'usuario_id': usuarioId,
        'data': DateTime.now().toIso8601String(),
        'total_centavos': total,
        'status': 'Finalizado',
      });
      for (final item in itens) {
        await txn.insert('itens_pedido', {...item, 'pedido_id': id});
        final atualizados = await txn.rawUpdate(
          'UPDATE produtos SET estoque = estoque - ? WHERE id = ? AND estoque >= ?',
          [item['quantidade'], item['produto_id'], item['quantidade']],
        );
        if (atualizados != 1) throw StateError('Estoque insuficiente');
      }
      return id;
    });
  }

  Future<List<Map<String, dynamic>>> listarPedidos() async {
    final db = await database;
    return db.rawQuery(
      'SELECT p.*, u.nome AS nome_usuario FROM pedidos p JOIN usuarios u ON u.id = p.usuario_id ORDER BY p.id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> listarItensPedido(int pedidoId) async {
    final db = await database;
    return db.query(
      'itens_pedido',
      where: 'pedido_id = ?',
      whereArgs: [pedidoId],
    );
  }
}
