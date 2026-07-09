# Tally

App flutuante de tarefas para **macOS**, nativo em **SwiftUI + AppKit**, com estética
macOS "Liquid Glass". Recriação fiel da variante **"Cartão compacto"** do protótipo
`Fluxo - Protótipo` (Claude Design).

Um widget always-on-top que mostra a tarefa **AGORA** com cronômetro ao vivo, a fila
**A SEGUIR**, tarefas **IMPEDIDAS**, captura rápida por **⌘K** e um **Resumo do dia**
pronto para copiar ao gestor.

## Arquitetura

- **`TallyCore`** (`Sources/TallyCore`) — lógica pura, só Foundation, **sem AppKit/SwiftUI**.
  Modelos, parser de quick-entry, motor de estados das tarefas, formatação de tempo e o
  gerador do relatório. É testável em qualquer plataforma (`swift test`).
- **`TallyApp`** (`Sources/TallyApp`) — a camada macOS (SwiftUI/AppKit): janela flutuante
  (`NSPanel`), vidro (`NSVisualEffectView`), o Cartão compacto, os overlays (⌘K, impedimento,
  Resumo do dia), menu bar, atalho global e persistência local.

Dados são **local-first**: um `TaskRepository` (protocolo) com implementação em arquivo
JSON (`FileTaskRepository`). Modelos já nascem *sync-ready* (`id`/`updatedAt`/`deletedAt`)
para um backend/sync futuro entrar sem reescrever a UI.

```
Sources/
  TallyCore/     lógica pura (testável)
  TallyApp/      app macOS (Xcode)
Tests/
  TallyCoreTests/  XCTest da lógica
Package.swift    SwiftPM (TallyCore + testes)
project.yml      XcodeGen → Tally.xcodeproj (o app)
```

## Como rodar

### Testes da lógica (multiplataforma)

Com um toolchain Swift instalado (macOS ou Linux):

```bash
swift test
```

Exercita parser, formatação, motor de tarefas e relatório.

### O app (requer macOS + Xcode)

O alvo do app usa SwiftUI/AppKit e **só compila no macOS/Xcode**. Geramos o projeto com
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open Tally.xcodeproj
# selecione o esquema "Tally" e ⌘R
```

> Sem XcodeGen? Crie um App macOS novo no Xcode (target macOS 14+, `LSUIElement = YES`),
> arraste `Sources/TallyApp/*` e adicione o pacote local `TallyCore` como dependência.

## Funcionalidades (Cartão compacto — completo)

- Tarefa **AGORA** com cronômetro ao vivo (1s) e **pausar/retomar**.
- **A SEGUIR**: fila com "começar agora" e "impedir".
- **IMPEDIDAS**: motivo + "retomar".
- **Concluir** tarefa (promove a próxima automaticamente).
- **Nova tarefa**: formulário (projeto/prioridade/estimativa) e **adição rápida**.
- **⌘K** (global): captura estilo Spotlight com parser `#projeto`, `!alta/!média/!baixa`,
  `30m`/`2h`, com chips de preview.
- **Diálogo de impedimento** com motivos rápidos.
- **Resumo do dia**: stats, barras de tempo por tarefa, listas e **texto para copiar**,
  navegável ←/→ por dias.
- **Arrastar** o widget (posição persistida).
- **Tema** claro/escuro, **acento** e **transparência** (Preferências).
- Ícone na **barra de menus** + menus do app.
- **Persistência local** (tarefas, projetos e preferências) entre execuções.

## Notas

- Distribuição fora da App Store requer conta Apple Developer para assinar/notarizar.
- O ⌘K global usa o Carbon `RegisterEventHotKey` (não exige permissão de acessibilidade).
