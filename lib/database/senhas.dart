import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class Senhas {
  static const iteracoes = 600000;
  static Future<String> criar(String senha) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final chave = await Pbkdf2(macAlgorithm: Hmac.sha256(),
      iterations: iteracoes, bits: 256).deriveKeyFromPassword(
        password: senha, nonce: salt);
    return '$iteracoes:${base64Encode(salt)}:${base64Encode(await chave.extractBytes())}';
  }

  static Future<bool> conferir(String senha, String registro) async {
    if (registro.isEmpty) return false;
    final partes = registro.split(':');
    if (partes.length != 3) return false;
    final chave = await Pbkdf2(macAlgorithm: Hmac.sha256(),
      iterations: int.parse(partes[0]), bits: 256).deriveKeyFromPassword(
        password: senha, nonce: base64Decode(partes[1]));
    final atual = await chave.extractBytes();
    final esperado = base64Decode(partes[2]);
    if (atual.length != esperado.length) return false;
    var diferenca = 0;
    for (var i = 0; i < atual.length; i++) {
      diferenca |= atual[i] ^ esperado[i];
    }
    return diferenca == 0;
  }
}
