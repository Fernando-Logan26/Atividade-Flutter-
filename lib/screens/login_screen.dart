import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'cadastro_screen.dart';
import 'loja_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocultar = true;
  bool _ocupado = false;
  bool _precisaAdmin = false;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final precisa = await DatabaseHelper.instance.precisaAdministrador();
      if (mounted) setState(() => _precisaAdmin = precisa);
    } catch (e) {
      if (mounted) setState(() => _erro = 'Não foi possível abrir o banco: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _entrar() async {
    if (_ocupado || !_form.currentState!.validate()) return;
    setState(() => _ocupado = true);
    try {
      await DatabaseHelper.instance.entrar(_email.text, _senha.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LojaScreen()), (_) => false);
    } catch (e) {
      if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$e')),
  );
}
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LOGIN NOKIS')),
      body: _carregando ? const Center(child: CircularProgressIndicator())
        : _erro != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erro!), TextButton(onPressed: _verificar, child: const Text('Tentar novamente'))]))
        : Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460),
          child: Form(key: _form, child: ListView(shrinkWrap: true,
            padding: const EdgeInsets.all(24), children: [
              const Icon(Icons.lock_outline, size: 64),
              const SizedBox(height: 24),
              TextFormField(controller: _email, enabled: !_ocupado,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o e-mail.' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _senha, enabled: !_ocupado, obscureText: _ocultar,
                enableSuggestions: false, autocorrect: false,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _entrar(),
                decoration: InputDecoration(labelText: 'Senha', prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(tooltip: _ocultar ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                    icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off))),
                validator: (v) => (v ?? '').isEmpty ? 'Informe a senha.' : null),
              const SizedBox(height: 24),
              FilledButton(onPressed: _ocupado ? null : _entrar,
                child: Text(_ocupado ? 'ENTRANDO...' : 'ENTRAR')),
              if (_precisaAdmin) ...[
                const SizedBox(height: 24),
                const Text('Primeiro acesso: configure a conta do administrador desta loja.'),
                OutlinedButton(onPressed: _ocupado ? null : () async {
                  await Navigator.push<bool>(context, MaterialPageRoute(
                    builder: (_) => const CadastroScreen(primeiroAdmin: true)));
                  if (mounted) await _verificar();
                }, child: const Text('CONFIGURAR ADMINISTRADOR')),
              ],
            ])))),
    );
  }
}
