#!/usr/bin/env bash
#
# Gera o Tally.app (Release) e o empacota num .dmg com atalho para /Applications.
#
# Uso:
#   ./scripts/build-dmg.sh
#
# Assinatura/notarização opcionais — defina antes de rodar:
#   export SIGN_IDENTITY="Developer ID Application: Seu Nome (TEAMID)"
#   export NOTARY_PROFILE="tally-notary"   # perfil salvo com `xcrun notarytool store-credentials`
#
# Requer: macOS, Xcode, XcodeGen (brew install xcodegen).

set -euo pipefail

APP_NAME="Tally"
SCHEME="Tally"
BUILD_DIR="build"
DIST_DIR="dist"
PRODUCT="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
DMG="$DIST_DIR/$APP_NAME.dmg"

# Rodar sempre a partir da raiz do repositório.
cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null 2>&1 || { echo "✗ XcodeGen não encontrado. Instale com: brew install xcodegen"; exit 1; }
command -v xcodebuild >/dev/null 2>&1 || { echo "✗ xcodebuild não encontrado (instale o Xcode)."; exit 1; }

echo "▸ Gerando o projeto (xcodegen)…"
xcodegen generate

LOG="$BUILD_DIR/xcodebuild.log"
mkdir -p "$BUILD_DIR"
echo "▸ Compilando em Release… (log completo: $LOG)"
# Grava o log inteiro no arquivo; em caso de falha, mostra as últimas linhas
# (com o erro) e aponta para o log completo, em vez de truncar tudo.
if ! xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$SCHEME" \
    -configuration Release -derivedDataPath "$BUILD_DIR" \
    clean build > "$LOG" 2>&1; then
  echo "✗ Falha no build. Últimas linhas do log:"
  tail -40 "$LOG"
  echo "  → log completo em: $LOG"
  exit 1
fi

[[ -d "$PRODUCT" ]] || { echo "✗ Não encontrei $PRODUCT"; exit 1; }

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  echo "▸ Assinando o app com: $SIGN_IDENTITY"
  codesign --force --options runtime --timestamp --deep \
    --sign "$SIGN_IDENTITY" "$PRODUCT"
fi

echo "▸ Montando o DMG…"
rm -rf "$DIST_DIR/dmg" "$DMG"
mkdir -p "$DIST_DIR/dmg"
cp -R "$PRODUCT" "$DIST_DIR/dmg/"
ln -s /Applications "$DIST_DIR/dmg/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DIST_DIR/dmg" -ov -format UDZO "$DMG"
rm -rf "$DIST_DIR/dmg"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  echo "▸ Notarizando o DMG…"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
fi

echo "✓ Pronto: $DMG"
shasum -a 256 "$DMG"
