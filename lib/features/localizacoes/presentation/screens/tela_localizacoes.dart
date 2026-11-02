import 'package:flutter/material.dart';

import '../../models/localizacao.dart';
import '../../services/controlador_coleta.dart';
import '../widgets/item_localizacao.dart';

class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({super.key, required this.controlador});
  final ControladorColeta controlador;
  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  late Future<List<Localizacao>> _consulta;
  bool _limpando = false;

  @override
  void initState() {
    super.initState();
    _consulta = widget.controlador.repositorio.consultar();
  }

  Future<void> _atualizar() async {
    final consulta = widget.controlador.repositorio.consultar();
    setState(() => _consulta = consulta);
    try {
      await consulta;
    } catch (_) {
      /* FutureBuilder apresenta a falha. */
    }
  }

  Future<void> _limpar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar todo o histórico?'),
        content: Text(
          'Esta operação é permanente e remove todos os registros, inclusive os anteriores aos 100 exibidos.'
          '${widget.controlador.ativa ? '\nA coleta está ativa: novos registros continuarão sendo salvos.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _limpando = true);
    try {
      await widget.controlador.repositorio.limpar();
      if (!mounted) return;
      await _atualizar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Histórico limpo com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao limpar o histórico: $e')));
    } finally {
      if (mounted) setState(() => _limpando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Histórico'),
      actions: [
        IconButton(
          tooltip: 'Atualizar registros',
          onPressed: _limpando ? null : _atualizar,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Limpar histórico',
          onPressed: _limpando ? null : _limpar,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: _limpando
        ? const Center(child: CircularProgressIndicator())
        : FutureBuilder<List<Localizacao>>(
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
                      Text('Erro ao consultar histórico: ${snapshot.error}'),
                      TextButton(
                        onPressed: _atualizar,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }
              final dados = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _atualizar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${dados.length} registros • últimos 100 • horário local',
                    ),
                    const SizedBox(height: 12),
                    if (dados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Nenhuma localização salva. Inicie uma coleta.',
                        ),
                      ),
                    for (var i = 0; i < dados.length; i++)
                      ItemLocalizacao(localizacao: dados[i], recente: i == 0),
                  ],
                ),
              );
            },
          ),
  );
}
