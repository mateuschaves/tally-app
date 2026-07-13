# Cask do Homebrew servido pelo próprio repositório (tap "solto"):
#
#   brew tap mateuschaves/tally https://github.com/mateuschaves/tally-app.git
#   brew install --cask tally
#
# `version` e `sha256` são atualizados automaticamente pelo workflow de release
# (.github/workflows/release.yml) a cada tag `v*` — não edite à mão.
cask "tally" do
  version "0.2.0"
  sha256 "8ac5557f3a9f0812b77c2f5baf449b3fade5761d3687cc6517394a919b77be3b"

  url "https://github.com/mateuschaves/tally-app/releases/download/v#{version}/Tally-#{version}.dmg"
  name "Tally"
  desc "Widget flutuante de tarefas para macOS"
  homepage "https://github.com/mateuschaves/tally-app"

  depends_on macos: ">= :sonoma"

  app "Tally.app"

  zap trash: [
    "~/Library/Application Support/Tally",
    "~/Library/Preferences/com.tally.app.plist",
  ]

  caveats do
    <<~EOS
      O Tally é distribuído com assinatura ad-hoc (sem notarização da Apple).
      Se o macOS bloquear a primeira abertura, libere em
      Ajustes do Sistema → Privacidade e Segurança → "Abrir mesmo assim",
      ou instale sem a quarentena:

        brew install --cask --no-quarantine tally
    EOS
  end
end
