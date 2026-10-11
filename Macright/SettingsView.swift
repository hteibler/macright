import SwiftUI
import ServiceManagement
import FinderSync

struct SettingsView: View {
    @AppStorage(MacrightShared.showMenuBarIconKey, store: MacrightShared.defaults)
    private var showMenuBarIcon = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                if let loginError {
                    Text(loginError).font(.caption).foregroundStyle(.red)
                }
                Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
            }
            Section("Context menu items") {
                ForEach(MenuFeature.allCases, id: \.self) { feature in
                    FeatureToggle(feature: feature)
                }
            }
            Section("Finder extension") {
                Text("macright needs its Finder extension enabled once.")
                    .font(.callout).foregroundStyle(.secondary)
                Button("Open Extension Settings…") {
                    FIFinderSyncController.showExtensionManagementInterface()
                }
            }
            Section {
                Button("Help") { WindowManager.shared.show(.help) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = error.localizedDescription
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

private struct FeatureToggle: View {
    let feature: MenuFeature
    @AppStorage private var isOn: Bool

    init(feature: MenuFeature) {
        self.feature = feature
        _isOn = AppStorage(wrappedValue: true, feature.defaultsKey, store: MacrightShared.defaults)
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(feature.title, systemImage: feature.symbol)
        }
    }
}
