import SwiftUI

/// Appearance preferences — theme, accent and transparency — mapping the
/// prototype's DC props (`aparencia`, `acento`, `transparencia`) to a real
/// Settings window.
struct PreferencesView: View {
    @EnvironmentObject private var store: AppStore

    private let accents = ["#0A84FF", "#BF5AF2", "#FF9F0A", "#30D158"]

    var body: some View {
        Form {
            Section("Aparência") {
                Picker("Tema", selection: Binding(
                    get: { store.themeMode },
                    set: { store.themeMode = $0 }
                )) {
                    Text("Escuro").tag(Theme.Mode.dark)
                    Text("Claro").tag(Theme.Mode.light)
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Acento")
                    Spacer()
                    ForEach(accents, id: \.self) { hex in
                        accentSwatch(hex)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Transparência: \(Int(store.transparency))%")
                    Slider(
                        value: Binding(get: { store.transparency }, set: { store.setTransparency($0) }),
                        in: 0...85, step: 5
                    )
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .padding(.vertical, 8)
    }

    private func accentSwatch(_ hex: String) -> some View {
        let isSelected = store.accentHex.lowercased() == hex.lowercased()
        return Button {
            store.setAccent(hex)
        } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle().strokeBorder(.white, lineWidth: isSelected ? 2 : 0)
                )
                .overlay(
                    Circle().strokeBorder(Color(hex: hex).opacity(isSelected ? 1 : 0), lineWidth: 1).padding(-2)
                )
                .shadow(radius: isSelected ? 2 : 0)
        }
        .buttonStyle(.plain)
    }
}
