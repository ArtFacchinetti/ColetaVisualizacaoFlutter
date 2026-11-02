import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

abstract class RepositorioLocalizacoes {
  Future<void> inserir(Localizacao localizacao);
  Future<List<Localizacao>> consultar();
  Future<void> limpar();
  Future<void> fechar();
}

class RepositorioSqlite implements RepositorioLocalizacoes {
  RepositorioSqlite(this.banco);
  final BancoLocalizacoes banco;

  @override
  Future<void> inserir(Localizacao localizacao) async {
    await (await banco.abrir()).insert('localizacoes', localizacao.toMap());
  }

  @override
  Future<List<Localizacao>> consultar() async {
    final linhas = await (await banco.abrir()).query(
      'localizacoes',
      orderBy: 'instante DESC, id DESC',
      limit: 100,
    );
    return linhas.map(Localizacao.fromMap).toList();
  }

  @override
  Future<void> limpar() async {
    await (await banco.abrir()).delete('localizacoes');
  }

  @override
  Future<void> fechar() => banco.fechar();
}
