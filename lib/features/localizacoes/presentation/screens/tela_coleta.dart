import 'package:flutter/material.dart';

import '../../services/controlador_coleta.dart';
import '../widgets/item_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

class TelaColeta extends StatelessWidget {
  const TelaColeta({super.key, required this.controlador});
  final ControladorColeta controlador;

  Future<void> _configuracoes(BuildContext context) async {
    if (controlador.servico.demonstracao) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Modo demonstração: não solicita GPS nem permissões reais.',
          ),
        ),
      );
      return;
    }
    try {
      if (!await controlador.servico.abrirConfiguracoes()) {
        throw Exception('Não foi possível abrir as configurações.');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controlador,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Localizações')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Seu caminho,\nponto a ponto.',
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Colete posições e explore seu histórico. Os registros ficam apenas neste aparelho.',
            ),
            const SizedBox(height: 24),
            if (controlador.servico.demonstracao)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'DEMONSTRAÇÃO • JSON\nDados fictícios e GPS simulado. A simulação não garante execução em segundo plano.',
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      controlador.ativa ? Icons.gps_fixed : Icons.gps_not_fixed,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controlador.ativa
                          ? 'Coleta em andamento'
                          : 'Pronto para explorar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${controlador.salvas} posições salvas nesta sessão • intervalo solicitado: 20 s',
                    ),
                    if (controlador.ocupada) const LinearProgressIndicator(),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: controlador.ativa || controlador.ocupada
                              ? null
                              : controlador.iniciar,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Iniciar coleta'),
                        ),
                        OutlinedButton.icon(
                          onPressed: !controlador.ativa || controlador.ocupada
                              ? null
                              : controlador.parar,
                          icon: const Icon(Icons.stop),
                          label: const Text('Parar coleta'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (controlador.erro != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  controlador.erro!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (controlador.ultima != null)
              ItemLocalizacao(localizacao: controlador.ultima!, recente: true),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TelaLocalizacoes(controlador: controlador),
                ),
              ),
              icon: const Icon(Icons.history),
              label: const Text('Consultar histórico'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      TelaMapa(repositorio: controlador.repositorio),
                ),
              ),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ver mapa'),
            ),
            TextButton.icon(
              onPressed: () => _configuracoes(context),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Configurações de permissão'),
            ),
          ],
        ),
      ),
    ),
  );
}
