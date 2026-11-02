import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/app.dart';

void main() {
  testWidgets('Tela inicial indica demonstração e desabilita parar', (
    tester,
  ) async {
    await tester.pumpWidget(const Aplicativo());
    expect(find.text('Iniciar coleta'), findsOneWidget);
    expect(find.textContaining('DEMONSTRAÇÃO'), findsOneWidget);
    final parar = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Parar coleta'),
    );
    expect(parar.onPressed, isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Consultar histórico'), findsOneWidget);
    expect(find.text('Ver mapa'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
