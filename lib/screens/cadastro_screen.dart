import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/usuario.dart';

class CadastroScreen extends StatefulWidget {
  final Usuario? usuario;

  const CadastroScreen({super.key, this.usuario});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final formKey = GlobalKey<FormState>();
  final nome = TextEditingController();
  final email = TextEditingController();
  final telefone = TextEditingController();
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    final usuario = widget.usuario;
    if (usuario != null) {
      nome.text = usuario.nome;
      email.text = usuario.email;
      telefone.text = usuario.telefone;
    }
  }

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    telefone.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate() || salvando) return;
    setState(() => salvando = true);

    try {
      final usuario = Usuario(
        id: widget.usuario?.id,
        nome: nome.text.trim(),
        email: email.text.trim().toLowerCase(),
        telefone: telefone.text.trim(),
      );

      if (widget.usuario == null) {
        await DatabaseHelper.instance.cadastrarUsuario(usuario);
      } else {
        await DatabaseHelper.instance.atualizarUsuario(usuario);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on DatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.isUniqueConstraintError()
                ? 'Este e-mail já está cadastrado.'
                : 'Erro ao salvar no banco: $e',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.usuario != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'EDITAR USUÁRIO' : 'CADASTRO NOKIS'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.person_outline, size: 64),
            const SizedBox(height: 24),
            TextFormField(
              controller: nome,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (v) {
                final valor = v?.trim() ?? '';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor)) {
                  return 'Informe um e-mail válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: telefone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (v) {
                final numeros = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (numeros.length < 10 || numeros.length > 11) {
                  return 'Informe um telefone com DDD';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: salvando ? null : salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(18),
              ),
              child: Text(
                salvando
                    ? 'SALVANDO...'
                    : editando
                    ? 'SALVAR ALTERAÇÕES'
                    : 'CADASTRAR',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
