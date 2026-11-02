import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/localizacao.dart';
import 'item_localizacao.dart';

class MapaLocalizacoes extends StatefulWidget {
  const MapaLocalizacoes({super.key, required this.localizacoes});
  final List<Localizacao> localizacoes;
  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  final _controller = MapController();
  bool _falhaTiles = false;
  List<LatLng> get _pontos =>
      widget.localizacoes.map((e) => LatLng(e.latitude, e.longitude)).toList();

  CameraFit get _enquadramento => CameraFit.bounds(
    bounds: LatLngBounds.fromPoints(_pontos),
    padding: const EdgeInsets.all(56),
    maxZoom: 17,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _atribuicao() async {
    try {
      if (!await launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
      )) {
        throw Exception('Não foi possível abrir a atribuição.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      FlutterMap(
        mapController: _controller,
        options: MapOptions(initialCameraFit: _enquadramento, maxZoom: 19),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'br.edu.fatec.localizacoes',
            maxNativeZoom: 19,
            errorTileCallback: (tile, error, stackTrace) {
              if (mounted && !_falhaTiles) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _falhaTiles = true);
                });
              }
            },
          ),
          MarkerLayer(
            markers: [
              // Desenha o mais recente por último para não ocultar o vermelho.
              for (var i = widget.localizacoes.length - 1; i >= 0; i--)
                Marker(
                  point: _pontos[i],
                  width: 44,
                  height: 44,
                  child: IconButton(
                    tooltip: i == 0
                        ? 'Localização mais recente'
                        : 'Ver localização',
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ItemLocalizacao(
                            localizacao: widget.localizacoes[i],
                            recente: i == 0,
                          ),
                        ),
                      ),
                    ),
                    icon: Icon(
                      Icons.location_on,
                      size: 34,
                      color: i == 0 ? Colors.red : const Color(0xFF126B66),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      Positioned(
        top: 12,
        left: 12,
        right: 12,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _falhaTiles
                  ? 'Falha ao carregar ruas. Verifique a conexão e atualize o mapa.'
                  : '${widget.localizacoes.length} pontos • vermelho: mais recente',
            ),
          ),
        ),
      ),
      Positioned(
        right: 16,
        bottom: 64,
        child: FloatingActionButton(
          tooltip: 'Enquadrar todos os pontos',
          onPressed: () => _controller.fitCamera(_enquadramento),
          child: const Icon(Icons.center_focus_strong),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: ColoredBox(
          color: Colors.white,
          child: TextButton(
            onPressed: _atribuicao,
            child: const Text('© OpenStreetMap contributors'),
          ),
        ),
      ),
    ],
  );
}
