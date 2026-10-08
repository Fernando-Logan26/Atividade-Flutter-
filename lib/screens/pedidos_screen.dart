import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'carrinho_screen.dart';

class PedidosScreen extends StatelessWidget {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PEDIDOS'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.listarPedidos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final pedidos = snapshot.data!;
          if (pedidos.isEmpty) {
            return const Center(child: Text('Nenhum pedido registrado.'));
          }
          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              final id = pedido['id'] as int;
              return ExpansionTile(
                title: Text('Pedido #$id — ${pedido['nome_usuario']}'),
                subtitle: Text(
                  '${moeda(pedido['total_centavos'] as int)} • ${pedido['status']}',
                ),
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: DatabaseHelper.instance.listarItensPedido(id),
                    builder: (context, itensSnapshot) {
                      if (itensSnapshot.hasError) {
                        return Text('Erro: ${itensSnapshot.error}');
                      }
                      if (!itensSnapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      return Column(
                        children: itensSnapshot.data!
                            .map(
                              (item) => ListTile(
                                title: Text(
                                  '${item['quantidade']}x ${item['nome_produto']}',
                                ),
                                subtitle: Text('Tamanho: ${item['tamanho']}'),
                                trailing: Text(
                                  moeda(
                                    (item['quantidade'] as int) *
                                        (item['preco_unitario_centavos']
                                            as int),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
