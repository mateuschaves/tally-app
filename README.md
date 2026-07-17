# Tally

**Tally** é um widget flutuante de tarefas para **macOS**, nativo em **SwiftUI + AppKit**,
com estética "Liquid Glass". Uma janela pequena, sempre no topo, que mostra a tarefa
**AGORA** com cronômetro ao vivo, a fila **A SEGUIR**, tarefas **IMPEDIDAS**, captura
rápida por **⌘K** e um **Resumo do dia** pronto para copiar ao gestor.

É a recriação nativa e fiel da variante **"Cartão compacto"** do protótipo
`Fluxo - Protótipo` (Claude Design).

- **Plataforma:** macOS 14 (Sonoma) ou superior
- **Stack:** SwiftUI + AppKit, lógica pura em Swift (Foundation), persistência em SQLite
- **Sem dependências externas** de runtime (usa o `libsqlite3` do próprio sistema)

## Sumário

- [Funcionalidades](#funcionalidades)
- [Atalhos de teclado](#atalhos-de-teclado)
- [Arquitetura](#arquitetura)
- [Estrutura de pastas](#estrutura-de-pastas)
- [Requisitos](#requisitos)
- [Começando (desenvolvimento)](#começando-desenvolvimento)
- [Testes](#testes)
- [Dados & persistência (SQLite)](#dados--persistência-sqlite)
- [Build de release](#build-de-release)
- [Assinatura & notarização](#assinatura--notarização)
- [Gerar um DMG](#gerar-um-dmg)
- [Publicar no Homebrew](#publicar-no-homebrew)
- [Roadmap](#roadmap)

## Funcionalidades

- Tarefa **AGORA** com cronômetro ao vivo (1s) e **pausar/retomar**.
- **A SEGUIR**: fila com "começar agora" e "impedir".
- **IMPEDIDAS**: motivo do impedimento + "retomar".
- **Concluir** tarefa (promove a próxima da fila automaticamente).
- **Nova tarefa**: formulário detalhado (**descrição** / projeto / prioridade / estimativa) e **adição rápida**.
- **Descrição** opcional nas tarefas (exibida no cartão, no form e no ⌘K).
- **Cadastrar projetos**: botão "+ Novo" no form abre um modal (nome + paleta de cores).
- **Estimativas** em horas: 1h / 2h / 4h / 8h / 16h.
- **Fechar** o widget pelo botão vermelho (traffic light) do cabeçalho — ao abrir o app,
  ele sempre volta **centralizado** na tela.
- **Editar tarefa** pelo lápis (na AGORA, na fila e nas impedidas): ajusta **projeto**,
  **prioridade**, **estimativa** e **tempo registrado** (⏎ salva / esc cancela).
- **Apagar tarefa** pela lixeira da fila, com diálogo de confirmação (⏎ confirma / esc cancela).
- **⌘K** (global): captura estilo Spotlight com parser de linguagem natural
  (`#projeto`, `!alta/!média/!baixa`, `30m`/`2h`) e chips de preview.
- **Atalhos de teclado configuráveis** (Preferências → Atalhos): regravar qualquer combinação,
  ativar/desativar, buscar e **Restaurar padrões** — os globais valem no sistema todo (Carbon).
- **Diálogo de impedimento** com motivos rápidos.
- **Resumo do dia**: estatísticas, barras de tempo por tarefa, listas e **texto para copiar**,
  navegável ←/→ entre dias (histórico real, baseado nas conclusões).
- **Arrastar** o widget pelo cabeçalho; **Centralizar widget** pelo menu.
- **Tema** escuro/claro/**Sistema**, **7 cores de acento** e **transparência** (em Preferências).
- Ícone na **barra de menus** com as ações principais.
- **Ocultar/mostrar** o widget (menu da barra ou clique direito no cartão); "Sair" encerra o app.
- **Persistência local** em SQLite (tarefas, projetos e preferências).
- **Começa vazio** — sem nenhum dado de exemplo.

## Atalhos de teclado

Todos os atalhos abaixo são os **padrões** — dá para regravar, ativar/desativar e
restaurar em **Preferências → Atalhos** (os com modificador valem no sistema todo):

| Atalho | Ação |
| --- | --- |
| **⌘K** (global) | Abrir captura rápida de tarefa |
| **⇧⌘D** (global) | Concluir tarefa atual |
| **⇧⌘B** (global) | Marcar impedimento |
| **⌘.** (global) | Pausar / retomar cronômetro |
| **⌥⌘T** (global) | Mostrar / ocultar o widget |
| **⌘R** (global) | Abrir Resumo do dia |
| **⌘,** (global) | Abrir Preferências |
| **⏎** | Adicionar (nos campos de texto) · confirmar exclusão |
| **⌘⏎** | Confirmar impedimento (no diálogo) |
| **Esc** | Fechar overlay (captura / impedimento / resumo / exclusão) |
| **← / →** | Navegar entre dias no Resumo do dia |
| **⌘Q** | Sair do Tally |

## Arquitetura

Dois alvos, separados por dependência de plataforma:

- **`TallyCore`** (`Sources/TallyCore`) — **lógica pura**, só Foundation, **sem AppKit/SwiftUI**.
  Modelos (`TaskItem`, `Priority`, `TaskState`), o motor de estados (`TaskEngine`), o parser
  de quick-entry (`QuickParse`), formatação de tempo/datas e o gerador do relatório
  (`ReportBuilder`). É **testável em qualquer plataforma** com `swift test`.
- **`TallyApp`** (`Sources/TallyApp`) — a **camada macOS** (SwiftUI/AppKit): janela flutuante
  (`NSPanel`), vidro (`NSVisualEffectView`), o Cartão compacto, os overlays, a barra de menus,
  o atalho global (Carbon) e a persistência.

**Fluxo de dados** (unidirecional, espelhando o componente React do protótipo):

```
   View (SwiftUI)  ──ações──▶  AppStore (@MainActor, ObservableObject)
        ▲                           │  usa
        │  @Published               ▼
   re-render  ◀───────────  TaskEngine / QuickParse / ReportBuilder   (TallyCore, puro)
                                    │  persiste
                                    ▼
                          TaskRepository (protocolo)
                                    │
                                    ▼
                        SQLiteTaskRepository (libsqlite3)
```

- `AppStore` é a **fonte única de estado**: tarefas, preferências, estado efêmero de UI e o
  timer de 1s. Toda mutação passa pelo `TaskEngine` (imutável) e persiste via `TaskRepository`.
- Modelos já nascem **sync-ready** (`id: UUID`, `updatedAt`, `deletedAt`): um futuro
  `SyncingTaskRepository` (CloudKit ou API própria) entra sem tocar na UI.

## Estrutura de pastas

```
tally-app/
├── Package.swift                 SwiftPM: TallyCore + testes (multiplataforma)
├── project.yml                   XcodeGen: gera o Tally.xcodeproj (o app macOS)
├── scripts/
│   └── build-dmg.sh              build de release + empacotamento em .dmg
├── Sources/
│   ├── TallyCore/                lógica pura (testável)
│   │   ├── Models/               TaskItem, Priority, TaskState
│   │   ├── TaskEngine.swift      transições: seed/normalize/complete/start/block/unblock/add/tick
│   │   ├── QuickParse.swift      parser #projeto / !prioridade / 30m·2h
│   │   ├── ReportBuilder.swift   Resumo do dia (modelo + texto para copiar)
│   │   ├── TimeFormat.swift      formatação de tempo
│   │   └── PtBrDates.swift       datas/horas em pt-BR
│   └── TallyApp/                 app macOS (Xcode)
│       ├── App/                  TallyApp, AppDelegate, FloatingPanel, OverlayWindow,
│       │                         PanelController, HotKeyCenter
│       ├── State/                AppStore, ProjectInfo
│       ├── Persistence/          TaskRepository (protocolo), SQLiteTaskRepository
│       ├── Theme/                Theme (tokens), VisualEffectBackground
│       ├── Services/             ClipboardService
│       └── Views/                CompactCardView, Card/, Overlays/, Components/, Preferences
└── Tests/
    └── TallyCoreTests/           XCTest da lógica pura
```

## Requisitos

- **macOS 14 (Sonoma)+** e **Xcode 15+** (para compilar/rodar o app).
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** para gerar o projeto: `brew install xcodegen`.
- (Opcional) toolchain Swift para rodar os testes do `TallyCore` fora do Xcode.
- (Opcional, distribuição) conta **Apple Developer** ($99/ano) para assinar/notarizar.

## Começando (desenvolvimento)

```bash
git clone https://github.com/mateuschaves/tally-app.git
cd tally-app

brew install xcodegen        # se ainda não tiver
xcodegen generate            # gera o Tally.xcodeproj a partir do project.yml
open Tally.xcodeproj         # selecione o esquema "Tally" e ⌘R
```

> **⚠️ Importante — regenere o projeto ao adicionar/remover arquivos.**
> O `Tally.xcodeproj` é **gerado** e fica no `.gitignore` (não vem no `git pull`). O
> `project.yml` monta a lista de arquivos **no momento** em que você roda `xcodegen generate`.
> Se um `git pull` **adicionar ou remover** arquivos-fonte, rode `xcodegen generate` de novo
> (e, no Xcode, **Product → Clean Build Folder**, ⇧⌘K). Erros do tipo
> *"Build input file cannot be found"* costumam ser isso.

> Sem XcodeGen? Crie um App macOS novo no Xcode (target macOS 14+, `LSUIElement = YES`),
> arraste `Sources/TallyApp/*` para o target e adicione o pacote local `TallyCore` como dependência.

## Testes

A lógica de negócio vive no `TallyCore`, que não depende de AppKit/SwiftUI e roda em
qualquer plataforma com toolchain Swift:

```bash
swift test
```

Cobre o parser de quick-entry, formatação de tempo, as transições do `TaskEngine` e o
`ReportBuilder` (incluindo histórico real e dias vazios).

## Dados & persistência (SQLite)

Persistência **local-first** via `SQLiteTaskRepository` (usa o `libsqlite3` do sistema — sem
dependência externa), atrás do protocolo `TaskRepository`.

- **Arquivo:** `~/Library/Application Support/Tally/tally.sqlite3`
- **Tabelas:**
  - `tasks(id, title, project, priority, estimate, seconds, state, reason, doneAt, createdAt, updatedAt, deletedAt)`
  - `projects(name, colorHex, ord)`
- **Começa vazio:** uma base nova não tem linhas, então o app abre sem nenhuma tarefa (nada mocado).

Inspecionar/depurar:

```bash
sqlite3 "~/Library/Application Support/Tally/tally.sqlite3" \
  "SELECT title, state, seconds FROM tasks;"
```

Resetar os dados (apaga tudo): feche o app e remova o arquivo `tally.sqlite3`.

## Build de release

Gera o `Tally.app` em Release (sem assinatura):

```bash
xcodegen generate
xcodebuild -project Tally.xcodeproj -scheme Tally \
  -configuration Release -derivedDataPath build \
  clean build

# resultado:
open build/Build/Products/Release/
```

O `.app` resultante roda localmente. Para distribuir a **outras máquinas** sem avisos do
Gatekeeper, assine e notarize (abaixo).

## Assinatura & notarização

Distribuir fora da App Store exige um certificado **Developer ID Application** (Apple Developer
Program). O projeto já habilita o **Hardened Runtime** (necessário para notarizar).

```bash
# 1) Assinar o app
codesign --force --options runtime --timestamp --deep \
  --sign "Developer ID Application: Seu Nome (TEAMID)" \
  build/Build/Products/Release/Tally.app

# 2) Guardar credenciais de notarização uma única vez (usa uma app-specific password)
xcrun notarytool store-credentials "tally-notary" \
  --apple-id "voce@exemplo.com" --team-id "TEAMID" --password "abcd-efgh-ijkl-mnop"

# 3) Enviar para notarização e "grampear" (staple) o ticket
ditto -c -k --keepParent build/Build/Products/Release/Tally.app Tally.zip
xcrun notarytool submit Tally.zip --keychain-profile "tally-notary" --wait
xcrun stapler staple build/Build/Products/Release/Tally.app
```

> Substitua `Seu Nome`, `TEAMID`, o Apple ID e a *app-specific password*
> (gerada em https://appleid.apple.com → Segurança → Senhas específicas de app).

## Gerar um DMG

O jeito mais simples usa o **script incluído**, que compila em Release e empacota num `.dmg`
com atalho para `/Applications` (arrastar-e-soltar):

```bash
./scripts/build-dmg.sh
# → dist/Tally.dmg  (e imprime o sha256, útil para o Homebrew)
```

Para **assinar e notarizar o DMG** automaticamente, exporte as variáveis antes:

```bash
export SIGN_IDENTITY="Developer ID Application: Seu Nome (TEAMID)"
export NOTARY_PROFILE="tally-notary"     # perfil salvo com notarytool store-credentials
./scripts/build-dmg.sh
```

### Manualmente (sem o script)

```bash
APP="build/Build/Products/Release/Tally.app"
mkdir -p dist/dmg && cp -R "$APP" dist/dmg/
ln -s /Applications dist/dmg/Applications
hdiutil create -volname "Tally" -srcfolder dist/dmg -ov -format UDZO dist/Tally.dmg
rm -rf dist/dmg
```

### Alternativa: `create-dmg` (layout mais bonito)

```bash
brew install create-dmg
create-dmg --volname "Tally" --app-drop-link 380 170 --icon "Tally.app" 130 170 \
  dist/Tally.dmg build/Build/Products/Release/Tally.app
```

## Publicar no Homebrew

Apps macOS de interface são distribuídos como **Homebrew Cask** (não "formula"). O deploy é
**automatizado** pelo workflow [`Release`](.github/workflows/release.yml): ele roda os testes,
builda o `Tally-<versão>.dmg` num runner macOS, publica o **GitHub Release** e atualiza o
cask [`Casks/tally.rb`](Casks/tally.rb) (versão + sha256) no `main` — o cask é servido pelo
próprio repositório, sem precisar de um repo `homebrew-*` separado.

**Publicar uma versão** (qualquer um dos dois):

```bash
# a) por tag:
git tag v0.1.0 && git push origin v0.1.0

# b) pelo site: Actions → "Release" → Run workflow → informe a versão (ex.: 0.1.0)
```

**Instalar via Homebrew** (após o primeiro release):

```bash
brew tap mateuschaves/tally https://github.com/mateuschaves/tally-app.git
brew install --cask tally
```

> **Gatekeeper:** o CI assina o app **ad-hoc** (sem conta Apple Developer), então a primeira
> abertura pode ser bloqueada — libere em Ajustes do Sistema → Privacidade e Segurança →
> "Abrir mesmo assim", ou instale com `brew install --cask --no-quarantine tally`. Para uma
> experiência limpa, assine e notarize com Developer ID (seção acima) — no CI isso exige
> importar o certificado via secrets (follow-up).
>
> **Tap dedicado (opcional):** para o comando curto `brew tap mateuschaves/tally` sem URL,
> crie o repositório `mateuschaves/homebrew-tally` e adicione um secret `HOMEBREW_TAP_TOKEN`
> (PAT com escrita nesse repo) — o workflow passa a sincronizar o cask para lá a cada release.
>
> **Cask oficial (`homebrew-cask`):** só faz sentido depois de tração/estabilidade — o
> repositório oficial exige critérios de notoriedade e versionamento. Comece com o tap próprio.

## Compatibilidade com macOS 26 (Tahoe) e 27

**Resumo: roda.** O deployment target é macOS 14, e apps antigos são forward-compatible —
o Tally executa normalmente em macOS 26 e 27. Pontos que valem atenção:

- **Vidro do widget/overlays:** desenhado com `NSVisualEffectView` (material `.hudWindow`),
  que continua suportado. No Tahoe ele **já assume o visual de "Liquid Glass" novo
  automaticamente** — ou seja, tende a ficar até mais fiel à cara do sistema.
- **Controles padrão (Preferências: `Form`/`Picker`/`Slider`, menus):** ao **recompilar com o
  Xcode 26 (SDK do macOS 26)**, adotam o Liquid Glass nativo. É mudança visual, não quebra
  funcional. Enquanto você continuar compilando com um SDK anterior, o app mantém o visual
  atual — a adoção do Liquid Glass só acontece ao buildar contra o SDK do macOS 26.
- **Atalho global ⌘K (Carbon `RegisterEventHotKey`):** ainda funciona no 26/27 e é o caminho
  padrão para hotkey global sem permissão de acessibilidade. É uma API **legada** (item de
  atenção para o futuro), mas sem substituto de primeira classe hoje.
- **Deprecações leves:** algumas chamadas (ex.: `foregroundColor`) são *soft-deprecated* em
  favor de `foregroundStyle` — geram apenas *warnings* no SDK novo, **não quebram** o build.
- **Janela flutuante (`NSPanel`, all-Spaces, não-ativante):** comportamento mantido no 26/27.

**Verificação recomendada (no Mac, com macOS 26/27):** compilar com Xcode 26+, e checar os
pontos sensíveis — o widget flutua e aparece em todos os Spaces; o vidro renderiza bem em
claro/escuro; o ⌘K global abre a captura; drag/persistência ok.

**Melhoria opcional (Liquid Glass nativo):** o modificador `.glassEffect(...)` do SwiftUI é
uma API **disponível a partir do macOS 26** ([docs da Apple](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))).
Dá para adotá-lo no cartão e nos overlays mantendo o deployment target atual (macOS 14),
desde que se faça o gate com `if #available(macOS 26, *)` e o fallback para
`NSVisualEffectView` nas versões anteriores. Como referenciar o símbolo exige **compilar com
o SDK do macOS 26** (Xcode 26), fica como follow-up para não travar quem builda com Xcode
mais antigo.

## Roadmap

Fora do escopo atual (uma variante, local-first):

- Sync/backend real (CloudKit ou API própria) via `SyncingTaskRepository`.
- As outras 3 variantes do widget (Pílula, Agenda do dia, Vidro puro).
- Auto-update (Sparkle) e assinatura Developer ID + notarização no CI de release.
- Liquid Glass nativo (`.glassEffect`) no macOS 26+, com fallback para `NSVisualEffectView`.
- Notificações / modo foco; exportação (CSV/Markdown).

---

Feito com Swift, para macOS.
