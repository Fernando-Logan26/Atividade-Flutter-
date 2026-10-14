import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/usuario.dart';
import '../models/produto.dart';
import '../models/carrinho.dart';
import 'senhas.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;
  Future<Database>? _abrindo;
  Usuario? _usuarioAtual;
  Usuario? get usuarioAtual => _usuarioAtual;

  void sair() {
    _usuarioAtual = null;
    Carrinho.instance.limpar();
  }

  Future<Usuario> _exigirLogin() async {
    final id = _usuarioAtual?.id;
    if (id == null) throw StateError('Faça login para continuar.');
    final db = await database;
    final dados = await db.query('usuarios', where: 'id = ?', whereArgs: [id]);
    if (dados.isEmpty) {
      sair();
      throw StateError('Sua conta não existe mais.');
    }
    return _usuarioAtual = Usuario.fromMap(dados.first);
  }

  Future<Usuario> _exigirAdmin() async {
    final usuario = await _exigirLogin();
    if (!usuario.isAdmin) throw StateError('Acesso exclusivo do administrador.');
    return usuario;
  }

  Future<bool> precisaAdministrador() async {
    final db = await database;
    final dados = await db.query('usuarios', where: 'is_admin = 1', limit: 1);
    return dados.isEmpty;
  }

  Future<Usuario> entrar(String email, String senha) async {
    sair();
    final db = await database;
    final dados = await db.query('usuarios', where: 'email = ? COLLATE NOCASE',
      whereArgs: [email.trim()], limit: 1);
    if (dados.isEmpty || !await Senhas.conferir(senha, dados.first['senha_hash'] as String)) {
      throw StateError('E-mail ou senha incorretos. Cadastros antigos precisam de uma senha definida pelo administrador.');
    }
    return _usuarioAtual = Usuario.fromMap(dados.first);
  }

  void _validarUsuario(Usuario usuario) {
    if (usuario.nome.trim().isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(usuario.email.trim()) ||
        !RegExp(r'^\d{10,11}$').hasMatch(usuario.telefone.replaceAll(RegExp(r'\D'), ''))) {
      throw ArgumentError('Nome, e-mail ou telefone inválido.');
    }
  }

  void _validarSenha(String senha) {
    if (senha.length < 8) throw ArgumentError('Use uma senha com pelo menos 8 caracteres.');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    return _abrindo ??= _abrirBanco().catchError((Object erro) {
      _abrindo = null;
      throw erro;
    });
  }

  Future<Database> _abrirBanco() async {
    final caminho = join(await getDatabasesPath(), 'nokis.db');

    _database = await openDatabase(
      caminho,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            telefone TEXT NOT NULL DEFAULT '',
            senha_hash TEXT NOT NULL DEFAULT '',
            is_admin INTEGER NOT NULL DEFAULT 0 CHECK(is_admin IN (0, 1))
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
        if (oldVersion < 4) {
          await db.execute("ALTER TABLE usuarios ADD COLUMN senha_hash TEXT NOT NULL DEFAULT ''");
          await db.execute('ALTER TABLE usuarios ADD COLUMN is_admin INTEGER NOT NULL DEFAULT 0 CHECK(is_admin IN (0, 1))');
          // Reconstrói pedidos e itens sem apagar vendas existentes.
          await db.execute('CREATE TEMP TABLE backup_pedidos AS SELECT p.*, u.nome AS nome_comprador FROM pedidos p JOIN usuarios u ON u.id = p.usuario_id');
          await db.execute('CREATE TEMP TABLE backup_itens AS SELECT * FROM itens_pedido');
          await db.execute('DROP TABLE itens_pedido');
          await db.execute('DROP TABLE pedidos');
          await _criarTabelasLoja(db);
          await db.execute('INSERT INTO pedidos (id, usuario_id, nome_comprador, data, total_centavos, status) SELECT id, usuario_id, nome_comprador, data, total_centavos, status FROM backup_pedidos');
          await db.execute('INSERT INTO itens_pedido SELECT * FROM backup_itens');
          await db.execute('DROP TABLE backup_itens');
          await db.execute('DROP TABLE backup_pedidos');
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
        usuario_id INTEGER,
        nome_comprador TEXT NOT NULL DEFAULT '',
        data TEXT NOT NULL,
        total_centavos INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pendente',
        FOREIGN KEY(usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
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
        FOREIGN KEY(produto_id) REFERENCES produtos(id) ON DELETE SET NULL
      )
    ''');
  }

  // ==========================================
  // CRUD DE USUÁRIOS
  // ==========================================

  Future<int> cadastrarUsuario(Usuario usuario, {required String senha}) async {
    _validarUsuario(usuario);
    _validarSenha(senha);
    if (usuario.isAdmin) await _exigirAdmin();
    final db = await database;
    return db.insert('usuarios', {...usuario.toMap(),
      'email': usuario.email.trim().toLowerCase(), 'senha_hash': await Senhas.criar(senha)});
  }

  Future<void> criarPrimeiroAdministrador(Usuario usuario, String senha) async {
    _validarUsuario(usuario);
    _validarSenha(senha);
    final hash = await Senhas.criar(senha);
    final db = await database;
    await db.transaction((txn) async {
      final admins = await txn.query('usuarios', where: 'is_admin = 1', limit: 1);
      if (admins.isNotEmpty) throw StateError('O administrador já foi configurado.');
      await txn.insert('usuarios', {...usuario.toMap(), 'is_admin': 1,
        'email': usuario.email.trim().toLowerCase(), 'senha_hash': hash});
    });
  }

  Future<List<Usuario>> listarUsuarios() async {
    await _exigirAdmin();
    final db = await database;
    final dados = await db.query('usuarios', orderBy: 'nome ASC');
    return dados.map(Usuario.fromMap).toList();
  }

  Future<int> atualizarUsuario(Usuario usuario, {String? novaSenha}) async {
    final admin = await _exigirAdmin();
    _validarUsuario(usuario);
    if (usuario.id == null) throw ArgumentError('ID do usuário obrigatório');
    if (admin.id == usuario.id && !usuario.isAdmin) {
      throw StateError('Você não pode remover sua própria permissão de administrador.');
    }
    final dados = {...usuario.toMap(), 'email': usuario.email.trim().toLowerCase()};
    if (novaSenha != null && novaSenha.isNotEmpty) {
      _validarSenha(novaSenha);
      dados['senha_hash'] = await Senhas.criar(novaSenha);
    }
    final db = await database;
    final total = await db.update('usuarios', dados, where: 'id = ?', whereArgs: [usuario.id]);
    if (admin.id == usuario.id) _usuarioAtual = usuario;
    return total;
  }

  Future<int> excluirUsuario(int id) async {
    final admin = await _exigirAdmin();
    if (admin.id == id) throw StateError('Você não pode excluir sua própria conta de administrador.');
    final db = await database;
    // ON DELETE SET NULL desvincula as vendas e preserva os comprovantes.
    return db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // CRUD DE PRODUTOS
  // ==========================================

  Future<int> cadastrarProduto(Produto produto) async {
    await _exigirAdmin();
    final db = await database;

    return db.insert('produtos', produto.toMap());
  }

  Future<List<Produto>> listarProdutos() async {
    await _exigirLogin();
    final db = await database;

    final dados = await db.query('produtos', orderBy: 'nome ASC');

    return dados.map((map) => Produto.fromMap(map)).toList();
  }

  Future<Produto?> buscarProduto(int id) async {
    await _exigirLogin();
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
    await _exigirAdmin();
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
    await _exigirAdmin();
    final db = await database;

    return db.delete('produtos', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // CADASTRO AUTOMÁTICO DOS 8 PRODUTOS NOKIS
  // ==========================================

  Future<void> cadastrarProdutosIniciais() async {
    await _exigirLogin();
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
    final comprador = await _exigirLogin();
    if (usuarioId != comprador.id) throw StateError('Só é possível comprar com a própria conta.');
    if (quantidades.isEmpty) throw StateError('Carrinho vazio');
    final db = await database;
    final pedidoId = await db.transaction((txn) async {
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
        'nome_comprador': comprador.nome,
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
    Carrinho.instance.limpar();
    return pedidoId;
  }

  Future<List<Map<String, dynamic>>> listarPedidos() async {
    final usuario = await _exigirLogin();
    final db = await database;
    return db.rawQuery(
      'SELECT p.*, p.nome_comprador AS nome_usuario FROM pedidos p '
      '${usuario.isAdmin ? '' : 'WHERE p.usuario_id = ? '}ORDER BY p.id DESC',
      usuario.isAdmin ? [] : [usuario.id],
    );
  }

  Future<List<Map<String, dynamic>>> listarItensPedido(int pedidoId) async {
    final usuario = await _exigirLogin();
    final db = await database;
    final pedido = await db.query('pedidos', where: 'id = ?', whereArgs: [pedidoId]);
    if (pedido.isEmpty || (!usuario.isAdmin && pedido.first['usuario_id'] != usuario.id)) {
      throw StateError('Você não pode consultar este pedido.');
    }
    return db.query('itens_pedido', where: 'pedido_id = ?', whereArgs: [pedidoId]);
  }
}
