import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:localizacoes/features/localizacoes/services/controlador_coleta.dart';
import 'package:localizacoes/features/localizacoes/services/servico_localizacao.dart';

class ServicoTeste extends ServicoLocalizacao {
  ServicoTeste() : super(demonstracao: true);
  final stream = StreamController<Localizacao>();
  int assinaturas = 0;
  bool negar = false;

  @override
  Future<void> verificarPermissoes() async {
    if (negar) throw Exception('Permissão negada');
  }

  @override
  Stream<Localizacao> posicoes() {
    assinaturas++;
    return stream.stream;
  }
}

class RepositorioTeste implements RepositorioLocalizacoes {
  final dados = <Localizacao>[];
  int simultaneas = 0;
  int maximoSimultaneas = 0;
  bool falhar = false;
  bool fechado = false;

  @override
  Future<void> inserir(Localizacao localizacao) async {
    simultaneas++;
    if (simultaneas > maximoSimultaneas) maximoSimultaneas = simultaneas;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    simultaneas--;
    if (falhar) {
      falhar = false;
      throw Exception('Falha de escrita');
    }
    dados.add(localizacao);
  }

  @override
  Future<List<Localizacao>> consultar() async =>
      dados.reversed.take(100).toList();
  @override
  Future<void> limpar() async => dados.clear();
  @override
  Future<void> fechar() async {
    fechado = true;
  }
}

void main() {
  Localizacao posicao() => Localizacao(
    latitude: -23.5,
    longitude: -46.6,
    precisao: 5,
    instante: DateTime.now().toUtc(),
  );

  test('Impede assinatura duplicada e serializa todas as posições', () async {
    final repo = RepositorioTeste();
    final servico = ServicoTeste();
    final controlador = ControladorColeta(repo, servico);
    await Future.wait([controlador.iniciar(), controlador.iniciar()]);
    expect(servico.assinaturas, 1);
    for (var i = 0; i < 5; i++) {
      servico.stream.add(posicao());
    }
    await Future<void>.delayed(Duration.zero);
    await controlador.parar();
    expect(repo.dados.length, 5);
    expect(repo.maximoSimultaneas, 1);
    expect(controlador.ativa, isFalse);
    expect(servico.stream.hasListener, isFalse);
    controlador.dispose();
    await servico.stream.close();
  });

  test('Permissão negada não cria stream e permite nova tentativa', () async {
    final servico = ServicoTeste()..negar = true;
    final controlador = ControladorColeta(RepositorioTeste(), servico);
    await controlador.iniciar();
    expect(controlador.ativa, isFalse);
    expect(controlador.ocupada, isFalse);
    expect(controlador.erro, contains('Permissão negada'));
    expect(servico.assinaturas, 0);
    servico.negar = false;
    await controlador.iniciar();
    expect(controlador.ativa, isTrue);
    await controlador.parar();
    controlador.dispose();
    await servico.stream.close();
  });

  test('Falha de escrita é informada sem quebrar a fila', () async {
    final repo = RepositorioTeste()..falhar = true;
    final servico = ServicoTeste();
    final controlador = ControladorColeta(repo, servico);
    await controlador.iniciar();
    servico.stream.add(posicao());
    servico.stream.add(posicao());
    await Future<void>.delayed(Duration.zero);
    await controlador.parar();
    expect(controlador.erro, contains('Não foi possível salvar'));
    expect(repo.dados.length, 1);
    expect(controlador.salvas, 1);
    controlador.dispose();
    await servico.stream.close();
  });

  test('Erro do stream cancela a coleta e dispose fecha recursos', () async {
    final repo = RepositorioTeste();
    final servico = ServicoTeste();
    final controlador = ControladorColeta(repo, servico);
    await controlador.iniciar();
    servico.stream.addError(Exception('GPS indisponível'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(controlador.ativa, isFalse);
    expect(controlador.erro, contains('GPS indisponível'));
    controlador.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(repo.fechado, isTrue);
    await servico.stream.close();
  });
}
