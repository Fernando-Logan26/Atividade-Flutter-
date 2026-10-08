import 'package:flutter/material.dart';

import 'cadastro_screen.dart';
import 'usuarios_screen.dart';
import 'loja_screen.dart';
import 'pedidos_screen.dart';
import 'produtos_admin_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: Colors.white,
                size: 75,
              ),
              const SizedBox(height: 20),
              const Text(
                'NOKIS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'GERENCIAMENTO DE USUÁRIOS',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, letterSpacing: 2),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LojaScreen()),
                ),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('ENTRAR NA LOJA'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PedidosScreen()),
                ),
                icon: const Icon(Icons.receipt_long),
                label: const Text('HISTÓRICO DE PEDIDOS'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProdutosAdminScreen(),
                  ),
                ),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('GERENCIAR PRODUTOS'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CadastroScreen()),
                ),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('CADASTRAR USUÁRIO'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                ),
                icon: const Icon(Icons.people_outline),
                label: const Text('LISTAR USUÁRIOS'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
