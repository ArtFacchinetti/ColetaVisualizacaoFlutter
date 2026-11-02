import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../widgets/mapa_localizacoes.dart';

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key, required this.repositorio});
  final RepositorioLocalizacoes repositorio;
  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  late Future<List<Localizacao>> _consulta;
  int _versao = 0;

  @override
  void initState() {
    super.initState();
    _consulta = _carregar();
  }

  Future<List<Localizacao>> _carregar() async {
    await CacheMapa.preparar();
    return widget.repositorio.consultar();
  }

  void _atualizar() => setState(() {
    _versao++;
    _consulta = _carregar();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mapa de localizações'),
      actions: [
        IconButton(
          tooltip: 'Atualizar registros',
          onPressed: _atualizar,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Localizacao>>(
      future: _consulta,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Não foi possível carregar o mapa: ${snapshot.error}'),
                TextButton(
                  onPressed: _atualizar,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }
        final dados = snapshot.data!;
        if (dados.isEmpty) {
          return const Center(
            child: Text('Nenhuma localização salva para exibir no mapa.'),
          );
        }
        return MapaLocalizacoes(key: ValueKey(_versao), localizacoes: dados);
      },
    ),
  );
}
