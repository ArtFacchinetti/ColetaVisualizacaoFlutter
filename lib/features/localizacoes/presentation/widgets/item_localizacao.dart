import 'package:flutter/material.dart';

import '../../models/localizacao.dart';

class ItemLocalizacao extends StatelessWidget {
  const ItemLocalizacao({
    super.key,
    required this.localizacao,
    this.recente = false,
  });
  final Localizacao localizacao;
  final bool recente;

  @override
  Widget build(BuildContext context) {
    final data = localizacao.instante.toLocal();
    String dois(int n) => n.toString().padLeft(2, '0');
    final horario =
        '${dois(data.day)}/${dois(data.month)}/${data.year} '
        '${dois(data.hour)}:${dois(data.minute)}:${dois(data.second)}';
    return Card(
      child: ListTile(
        isThreeLine: true,
        leading: Icon(
          Icons.location_on,
          color: recente ? Colors.red : Theme.of(context).colorScheme.primary,
        ),
        title: Text(horario),
        subtitle: Text(
          '${localizacao.latitude.toStringAsFixed(6)}, ${localizacao.longitude.toStringAsFixed(6)}\n'
          'Precisão: ${localizacao.precisao.toStringAsFixed(1)} m${recente ? ' • Mais recente' : ''}',
        ),
      ),
    );
  }
}
