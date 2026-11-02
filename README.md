# Localizações 📍

Atividade 1 — Coleta e visualização de localizações, Programação para Dispositivos Móveis I — Prof. Arley, Fatec.

**Integrantes: preencher com o(s) nome(s) completo(s) antes da entrega.**

Aplicativo Flutter para **Android** com coleta por stream, histórico, mapa OpenStreetMap e ícone original. Não utiliza backend.

## Dois modos de execução

### Demonstração com JSON (padrão)

```sh
flutter pub get
flutter run
```

- Não exige SQLite nem GPS: usa um stream de posições **simuladas**, com emissão inicial e novas posições a cada 20 segundos.
- Oito pontos fictícios, sem histórico pessoal, estão em `assets/mock/localizacoes.json`.
- Na primeira consulta ou gravação, o JSON é copiado para `localizacoes_mock.json` na pasta privada de documentos do aplicativo. Depois disso, alterações persistem entre execuções.
- A limpeza não recarrega os mocks. Para restaurá-los, limpe os dados do aplicativo ou reinstale-o.
- A simulação serve para demonstrar a interface e a persistência, **não garante coleta com o aplicativo minimizado** nem cria serviço Android.
- Esse modo é uma adaptação pedida para o ambiente sem SQLite; para cumprir o requisito de SQLite do enunciado, use o modo real abaixo.

### GPS real + SQLite

```sh
flutter run --dart-define=DEMO=false
```

O `sqflite` utiliza o SQLite nativo do Android. **Não é necessário instalar o executável SQLite nem apontar para uma pasta de código-fonte no computador.**

- Banco privado `localizacoes.db`, versão 1, tabela `localizacoes` com `id INTEGER PRIMARY KEY AUTOINCREMENT`, `latitude REAL NOT NULL`, `longitude REAL NOT NULL`, `precisao REAL NOT NULL` e `instante TEXT NOT NULL`.
- O banco começa vazio; dados fictícios não são inseridos no histórico real.
- GPS e permissão são verificados antes da coleta. Notificações são solicitadas no Android 13+; se negadas, a coleta não inicia até a autorização.
- `Geolocator.getPositionStream` usa alta precisão e intervalo solicitado de 20 segundos. O Android pode entregar posições em outros intervalos.
- Serviço em primeiro plano do Geolocator, com notificação e wake lock, mantém a coleta ao navegar e minimizar. Inicie a coleta com o app aberto. Não há reinício automático após encerrar o processo ou reiniciar o aparelho.
- Não é necessário pedir `ACCESS_BACKGROUND_LOCATION`: o serviço de localização é iniciado enquanto a tela está visível. Fabricantes e políticas de bateria ainda podem interromper serviços; verificar no aparelho-alvo.
- Os modos têm armazenamentos independentes. Nenhuma migração automática é realizada.

## Funcionalidades

- Iniciar/parar coleta sem assinaturas duplicadas; fila de escrita para evitar gravações sobrepostas.
- Histórico e mapa consultam somente os 100 registros mais recentes, sem apagar registros antigos.
- Instantes persistidos em UTC ISO 8601; apresentação no horário local, coordenadas com seis casas e precisão com uma.
- Atualização manual e gesto de puxar no histórico. Limpeza permanente de **todos** os registros com confirmação e aviso de coleta ativa.
- Mapa com ruas, marcadores interativos, ponto mais recente vermelho, enquadramento inicial e botão para reenquadrar.
- Estados de carregamento, vazio e erro; tratamento de GPS, permissões, persistência e falha de tiles.

## Organização

```text
lib/
  main.dart                         # Inicialização
  app.dart                          # Tema, composição e modo de execução
  features/localizacoes/
    models/localizacao.dart         # Modelo e conversão para persistência
    data/database/                  # Conexão SQLite reutilizada e abertura com nova tentativa
    data/repositories/              # Contrato e implementações SQLite/JSON
    services/                       # GPS, cache e controlador da coleta
    presentation/screens/           # Coleta, histórico e mapa
    presentation/widgets/           # Registro e mapa reutilizáveis
assets/mock/localizacoes.json       # Dados estritamente fictícios
assets/icons/localizacoes.png       # Ícone original
```

O controlador pertence ao widget raiz e permanece vivo ao trocar de rota. Ele cancela a assinatura, aguarda a fila e fecha o repositório no encerramento. As telas não executam SQL nem manipulam mapas brutos da persistência. A camada JSON serializa leitura, gravação e limpeza com lock; a escrita passa por arquivo temporário antes da substituição.

## Mapas e privacidade

Tiles de `https://tile.openstreetmap.org/{z}/{x}/{y}.png`, identificação do aplicativo e atribuição visível e clicável **© OpenStreetMap contributors**. O cache nativo do `flutter_map` é preparado em pasta privada antes de criar o mapa e respeita os cabeçalhos HTTP do provedor. Não há download em massa, pré-carregamento ou promessa de mapas offline.

- [Direitos e atribuição](https://www.openstreetmap.org/copyright)
- [Política de uso dos tiles](https://operations.osmfoundation.org/policies/tiles/)

O mapa precisa de internet para áreas não disponíveis no cache. O provedor recebe solicitações dos tiles visualizados, mas as posições não são enviadas a um backend de histórico. Bancos reais e arquivos privados estão ignorados pelo Git.

## Ícone

Ícone original: pin branco e detalhe dourado sobre verde. Configurados PNGs para as cinco densidades Android e ícone adaptativo para API 26+. O script `tool/gerar_icones.ps1` permite regenerar as imagens no Windows:

```powershell
powershell -ExecutionPolicy Bypass -File tool/gerar_icones.ps1
```

## Validação

Requer Flutter 3.47.7 / Dart 3.13.5 ou versão compatível e Android SDK configurado. O projeto contém somente a plataforma Android; iOS/web/desktop não foram configurados.

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define=DEMO=false
```

Validação executada neste ambiente: **`flutter analyze` sem problemas e 10 testes aprovados**.

Testes cobrem modelo UTC, seed JSON, limite de consulta, conservação dos registros antigos, inserções concorrentes, reabertura, limpeza, recuperação de erro, assinatura única, fila de coleta, falhas de stream/permissão/escrita, liberação de recursos e interface inicial. O comportamento nativo de GPS/SQLite/serviço e a instalação do ícone devem ser verificados em Android.

### Checklist manual no aparelho

1. Abrir em modo real; testar GPS desligado, negar permissão e bloquear permissão; usar configurações para autorizar.
2. Autorizar notificações, iniciar, verificar notificação e impedir início duplicado.
3. Navegar ao histórico/mapa e minimizar; retornar e atualizar para confirmar posições recebidas.
4. Parar; confirmar desaparecimento da notificação e ausência de novas gravações.
5. Fechar/reabrir e confirmar persistência; testar mais de 100 registros.
6. Cancelar e confirmar a limpeza, inclusive durante coleta ativa.
7. Verificar ruas, atribuição, detalhes, marcador vermelho e reenquadramento.
8. Verificar ícone no launcher e na lista de aplicativos, eventualmente reinstalando para renovar o cache do launcher.

**Limitação do ambiente de desenvolvimento:** Android SDK ausente; APK, serviço em segundo plano e aparência do ícone após instalação não foram validados aqui.

## Entrega

O Git foi inicializado localmente na branch `main`. Antes de enviar ao professor, preencher os integrantes, publicar em um repositório remoto e enviar o link pelo Teams. Nenhum repositório remoto é criado automaticamente.
