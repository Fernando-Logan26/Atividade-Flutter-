import 'package:flutter/material.dart';

import 'cadastro_screen.dart';
import 'login_screen.dart';

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
                'SEU ESTILO, SUA IDENTIDADE',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, letterSpacing: 2),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
                icon: const Icon(Icons.login),
                label: const Text('LOGIN'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(18), backgroundColor: Colors.white,
                  foregroundColor: Colors.black),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final criou = await Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (_) => const CadastroScreen()));
                  if (criou == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cadastro realizado! Entre com seu e-mail e senha.')));
                  }
                },
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('NOVO CADASTRO'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18),
                  foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
