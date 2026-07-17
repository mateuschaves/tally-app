import SwiftUI

/// A compact hours + minutes editor used by the "Editar tarefa" overlay for the
/// estimate and the logged time. Each unit is a plain numeric field flanked by a
/// small up/down stepper; the parent owns the model mapping and this view just
/// edits two `Int` bindings.
///
/// Typing overflow (e.g. "90" into minutes) is absorbed by the parent's
/// modular bindings — the extra minutes carry into hours — and any stray
/// negative is clamped when `TaskEngine.edit` persists, so the arrows only need
/// to floor at zero (and keep minutes ≤ 59).
struct DurationStepper: View {
    let theme: Theme
    @Binding var hours: Int
    @Binding var minutes: Int

    var body: some View {
        HStack(spacing: 10) {
            unit(value: $hours, max: 999, suffix: "h")
            unit(value: $minutes, max: 59, suffix: "min")
            Spacer(minLength: 0)
        }
    }

    private func unit(value: Binding<Int>, max upperBound: Int, suffix: String) -> some View {
        HStack(spacing: 6) {
            TextField("", value: value, format: .number)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .foregroundColor(theme.tx1)
                .frame(width: 36)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(theme.selection))
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(theme.line, lineWidth: 1))

            VStack(spacing: 2) {
                arrow("chevron.up") { value.wrappedValue = min(upperBound, value.wrappedValue + 1) }
                arrow("chevron.down") { value.wrappedValue = Swift.max(0, value.wrappedValue - 1) }
            }

            Text(suffix)
                .font(.system(size: 11))
                .foregroundColor(theme.tx3)
        }
    }

    private func arrow(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(theme.tx2)
                .frame(width: 20, height: 11)
                .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(theme.selection))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
