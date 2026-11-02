import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/repositorio_localizacoes.dart';
import '../models/localizacao.dart';
import 'servico_localizacao.dart';

/// Vive na raiz do aplicativo, não nas rotas de histórico ou mapa.
class ControladorColeta extends ChangeNotifier {
  ControladorColeta(this.repositorio, this.servico);
  final RepositorioLocalizacoes repositorio;
  final ServicoLocalizacao servico;
  StreamSubscription<Localizacao>? _assinatura;
  Future<void> _fila = Future<void>.value();
  bool ativa = false;
  bool ocupada = false;
  bool _encerrado = false;
  String? erro;
  Localizacao? ultima;
  int salvas = 0;

  void _avisar() {
    if (!_encerrado) notifyListeners();
  }

  Future<void> iniciar() async {
    if (ativa || ocupada || _encerrado) return;
    ocupada = true;
    erro = null;
    _avisar();
    try {
      await servico.verificarPermissoes();
      if (_encerrado) return;
      ativa = true;
      _assinatura = servico.posicoes().listen(
        (localizacao) {
          // Cada escrita aguarda a anterior, sem perder posições recebidas.
          _fila = _fila.then((_) async {
            try {
              await repositorio.inserir(localizacao);
              ultima = localizacao;
              salvas++;
            } catch (e) {
              erro = 'Não foi possível salvar a posição: $e';
            }
            _avisar();
          });
        },
        onError: (Object e) {
          erro = 'Falha na localização: $e';
          unawaited(parar());
        },
        onDone: () {
          ativa = false;
          _assinatura = null;
          _avisar();
        },
      );
    } catch (e) {
      erro = e.toString();
      ativa = false;
    } finally {
      ocupada = false;
      _avisar();
    }
  }

  Future<void> parar() async {
    if (ocupada || _encerrado) return;
    ocupada = true;
    _avisar();
    try {
      await _assinatura?.cancel();
      _assinatura = null;
      await _fila;
      ativa = false;
    } catch (e) {
      erro = 'Não foi possível parar a coleta: $e';
    } finally {
      ocupada = false;
      _avisar();
    }
  }

  @override
  void dispose() {
    _encerrado = true;
    unawaited(_fechar());
    super.dispose();
  }

  Future<void> _fechar() async {
    await _assinatura?.cancel();
    await _fila;
    await repositorio.fechar();
  }
}
