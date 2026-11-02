import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  Future<Database>? _abertura;

  Future<Database> abrir() => _abertura ??= _abrir();

  Future<Database> _abrir() async {
    try {
      return await openDatabase(
        p.join(await getDatabasesPath(), 'localizacoes.db'),
        version: 1,
        onCreate: (db, version) => db.execute('''
          CREATE TABLE localizacoes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            precisao REAL NOT NULL,
            instante TEXT NOT NULL
          )
        '''),
      );
    } catch (_) {
      _abertura = null;
      rethrow;
    }
  }

  Future<void> fechar() async {
    final abertura = _abertura;
    if (abertura != null) await (await abertura).close();
    _abertura = null;
  }
}
