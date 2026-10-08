import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nokis/main.dart';

void main() {
  testWidgets('NOKIS inicia corretamente', (tester) async {
    await tester.pumpWidget(const NokisApp());

    expect(find.text('NOKIS'), findsOneWidget);
    expect(find.text('CADASTRAR USUÁRIO'), findsOneWidget);
    expect(find.text('LISTAR USUÁRIOS'), findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
  });
}
