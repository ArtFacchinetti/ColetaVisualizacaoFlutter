import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/features/localizacoes/data/repositories/repositorio_json.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';

void main() {
  late Directory pasta;
  late File arquivo;
  late RepositorioJson repositorio;
  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('localizacoes_teste_');
    arquivo = File('${pasta.path}/teste.json');
    repositorio = RepositorioJson(
      arquivoTeste: arquivo,
      carregarSeed: () async => '{"proximoId":1,"localizacoes":[]}',
    );
  });
  tearDown(() async => pasta.delete(recursive: true));

  Localizacao posicao(int indice) => Localizacao(
    latitude: -23.5,
    longitude: -46.6,
    precisao: 4.2,
    instante: DateTime.utc(2026, 11, 2).add(Duration(seconds: indice)),
  );

  test('Modelo converte números e persiste UTC ISO 8601', () {
    final modelo = Localizacao.fromMap({
      'id': 1,
      'latitude': -23,
      'longitude': -46,
      'precisao': 5,
      'instante': '2026-11-02T10:00:00-03:00',
    });
    expect(modelo.instante, DateTime.utc(2026, 11, 2, 13));
    expect(modelo.toMap()['instante'], '2026-11-02T13:00:00.000Z');
  });

  test(
    'Serializa inserções concorrentes, consulta 100 e preserva anteriores',
    () async {
      await Future.wait(
        List.generate(105, (i) => repositorio.inserir(posicao(i))),
      );
      final registros = await repositorio.consultar();
      expect(registros.length, 100);
      expect(registros.first.id, 105);
      expect(registros.last.id, 6);
      final dados = jsonDecode(await arquivo.readAsString()) as Map;
      expect((dados['localizacoes'] as List).length, 105);
    },
  );

  test(
    'Persiste entre instâncias; limpeza total não restaura seed nem IDs',
    () async {
      await repositorio.inserir(posicao(0));
      final reaberto = RepositorioJson(arquivoTeste: arquivo);
      expect((await reaberto.consultar()).length, 1);
      await reaberto.limpar();
      expect(await repositorio.consultar(), isEmpty);
      await repositorio.inserir(posicao(1));
      expect((await repositorio.consultar()).single.id, 2);
    },
  );

  test('Seed mock válido e ordem decrescente', () async {
    final mock = RepositorioJson(
      arquivoTeste: arquivo,
      carregarSeed: () => File('assets/mock/localizacoes.json').readAsString(),
    );
    final dados = await mock.consultar();
    expect(dados.length, 8);
    expect(dados.first.id, 8);
    await mock.limpar();
    expect(await RepositorioJson(arquivoTeste: arquivo).consultar(), isEmpty);
  });

  test('Erro de leitura pode ser corrigido e consultado novamente', () async {
    await arquivo.writeAsString('inválido');
    await expectLater(repositorio.consultar(), throwsFormatException);
    await arquivo.writeAsString('{"proximoId":1,"localizacoes":[]}');
    expect(await repositorio.consultar(), isEmpty);
  });
}
