import 'package:flutter/material.dart';

import 'features/localizacoes/data/database/banco_localizacoes.dart';
import 'features/localizacoes/data/repositories/repositorio_json.dart';
import 'features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'features/localizacoes/presentation/screens/tela_coleta.dart';
import 'features/localizacoes/services/controlador_coleta.dart';
import 'features/localizacoes/services/servico_localizacao.dart';

const modoDemonstracao = bool.fromEnvironment('DEMO', defaultValue: true);

class Aplicativo extends StatefulWidget {
  const Aplicativo({super.key});
  @override
  State<Aplicativo> createState() => _AplicativoState();
}

class _AplicativoState extends State<Aplicativo> {
  late final controlador = ControladorColeta(
    modoDemonstracao
        ? RepositorioJson()
        : RepositorioSqlite(BancoLocalizacoes()),
    const ServicoLocalizacao(demonstracao: modoDemonstracao),
  );

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Localizações',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF126B66)),
      scaffoldBackgroundColor: const Color(0xFFF5F8F7),
      appBarTheme: const AppBarTheme(centerTitle: false),
    ),
    home: TelaColeta(controlador: controlador),
  );
}
