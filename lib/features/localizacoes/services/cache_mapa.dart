import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CacheMapa {
  static Future<void> preparar() async {
    final pasta = Directory(
      p.join((await getApplicationCacheDirectory()).path, 'mapa'),
    );
    await pasta.create(recursive: true);
    // Cache HTTP nativo respeita os cabeçalhos do provedor, sem pré-download.
    BuiltInMapCachingProvider.getOrCreateInstance(cacheDirectory: pasta.path);
  }
}
