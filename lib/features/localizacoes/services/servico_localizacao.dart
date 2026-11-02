import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissoes;

import '../models/localizacao.dart';

class ServicoLocalizacao {
  const ServicoLocalizacao({required this.demonstracao});
  final bool demonstracao;

  Future<void> verificarPermissoes() async {
    if (demonstracao) return;
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception(
        'GPS desligado. Ative a localização nas configurações do aparelho.',
      );
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'Permissão bloqueada. Use Configurações de permissão para autorizar a localização.',
      );
    }
    if (permissao == LocationPermission.denied) {
      throw Exception(
        'Permissão negada. Autorize a localização para iniciar a coleta.',
      );
    }
    if (Platform.isAndroid &&
        !await permissoes.Permission.notification.request().isGranted) {
      throw Exception(
        'Autorize as notificações nas configurações do aplicativo para manter a coleta visível.',
      );
    }
  }

  Stream<Localizacao> posicoes() {
    if (demonstracao) return _simular();
    final LocationSettings settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            intervalDuration: const Duration(seconds: 20),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Localizações • coleta ativa',
              notificationText:
                  'Sua localização está sendo salva neste aparelho.',
              enableWakeLock: true,
            ),
          )
        : const LocationSettings(accuracy: LocationAccuracy.high);
    return Geolocator.getPositionStream(locationSettings: settings).map(
      (p) => Localizacao(
        latitude: p.latitude,
        longitude: p.longitude,
        precisao: p.accuracy,
        instante: p.timestamp.toUtc(),
      ),
    );
  }

  Stream<Localizacao> _simular() {
    final cancelado = Completer<void>();
    late final StreamController<Localizacao> controller;
    Future<void> emitir() async {
      var indice = 0;
      while (!cancelado.isCompleted) {
        controller.add(
          Localizacao(
            latitude: -23.550520 + (indice % 12) * 0.00016,
            longitude: -46.633308 + (indice % 12) * 0.00012,
            precisao: 4.0 + indice % 4,
            instante: DateTime.now().toUtc(),
          ),
        );
        indice++;
        await Future.any([
          Future<void>.delayed(const Duration(seconds: 20)),
          cancelado.future,
        ]);
      }
      await controller.close();
    }

    controller = StreamController<Localizacao>(
      onListen: () => unawaited(emitir()),
      onCancel: () {
        if (!cancelado.isCompleted) cancelado.complete();
      },
    );
    return controller.stream;
  }

  Future<bool> abrirConfiguracoes() => Geolocator.openAppSettings();
}
