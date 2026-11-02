import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

import '../../models/localizacao.dart';
import 'repositorio_localizacoes.dart';

/// Alternativa demonstrativa: arquivo privado, sem SQLite ou backend.
class RepositorioJson implements RepositorioLocalizacoes {
  RepositorioJson({this.arquivoTeste, this.carregarSeed});
  final File? arquivoTeste;
  final Future<String> Function()? carregarSeed;
  final Lock _lock = Lock();
  File? _arquivo;

  Future<File> _abrir() async {
    if (_arquivo != null) return _arquivo!;
    final arquivo =
        arquivoTeste ??
        File(
          p.join(
            (await getApplicationDocumentsDirectory()).path,
            'localizacoes_mock.json',
          ),
        );
    // O seed só entra na primeira execução; limpar não o restaura.
    if (!await arquivo.exists()) {
      final seed =
          await (carregarSeed?.call() ??
              rootBundle.loadString('assets/mock/localizacoes.json'));
      await arquivo.writeAsString(seed, flush: true);
    }
    _arquivo = arquivo;
    return arquivo;
  }

  Future<Map<String, dynamic>> _ler() async =>
      jsonDecode(await (await _abrir()).readAsString()) as Map<String, dynamic>;

  Future<void> _gravar(Map<String, dynamic> dados) async {
    final arquivo = await _abrir();
    final temporario = File('${arquivo.path}.tmp');
    await temporario.writeAsString(jsonEncode(dados), flush: true);
    await temporario.rename(arquivo.path);
  }

  @override
  Future<void> inserir(Localizacao localizacao) => _lock.synchronized(() async {
    final dados = await _ler();
    final id = dados['proximoId'] as int;
    (dados['localizacoes'] as List).add({...localizacao.toMap(), 'id': id});
    dados['proximoId'] = id + 1;
    await _gravar(dados);
  });

  @override
  Future<List<Localizacao>> consultar() => _lock.synchronized(() async {
    final dados = await _ler();
    final lista = (dados['localizacoes'] as List)
        .map((e) => Localizacao.fromMap(Map<String, Object?>.from(e as Map)))
        .toList();
    lista.sort((a, b) {
      final comparacao = b.instante.compareTo(a.instante);
      return comparacao != 0 ? comparacao : b.id!.compareTo(a.id!);
    });
    return lista.take(100).toList();
  });

  @override
  Future<void> limpar() => _lock.synchronized(() async {
    final dados = await _ler();
    dados['localizacoes'] = <Object>[];
    await _gravar(dados);
  });

  @override
  Future<void> fechar() async {}
}
