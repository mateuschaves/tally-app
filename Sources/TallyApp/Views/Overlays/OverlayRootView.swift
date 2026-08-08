import SwiftUI

/// Full-screen host for the modal overlays. Renders the dim scrim (tap to close),
/// the active overlay's box, and wires Esc → close. Shown/hidden by
/// `PanelController` following `store.overlay`.
struct OverlayRootView: View {
    @EnvironmentObject private var store: AppStore

    private var theme: Theme { store.theme }

    private var dimOpacity: Double {
        switch store.overlay {
        case .none: return 0
        case .quickEntry: return 0.16
        case .block: return 0.20
        case .report: return 0.26
        case .newProject: return 0.28
        case .deleteTask: return 0.28
        case .editTask: return 0.28
        }
    }

    var body: some View {
        ZStack {
            if store.overlay != .none {
                Color.black.opacity(dimOpacity)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Tapping outside the "Novo projeto" modal only closes it,
                        // leaving the add form underneath open.
                        if store.overlay == .newProject { store.closeNewProject() }
                        else { store.closeAll() }
                    }

                content
                    .transition(.opacity)

                // Esc closes any overlay.
                Button("") { store.closeAll() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.plain)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.theme, theme)
        .animation(.easeOut(duration: 0.15), value: store.overlay)
    }

    @ViewBuilder
    private var content: some View {
        switch store.overlay {
        case .none:
            EmptyView()
        case .quickEntry:
            QuickEntryView()
        case .block:
            BlockDialogView()
        case .report:
            DayReportView()
        case .newProject:
            NewProjectView()
        case .deleteTask:
            DeleteTaskView()
        case .editTask:
            EditTaskView()
        }
    }
}
