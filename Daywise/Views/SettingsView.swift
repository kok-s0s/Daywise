import SwiftUI

struct SettingsView: View {
    @State private var iCloudEnabled: Bool = NSUbiquitousKeyValueStore.default.synchronize()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#F0F4FF").ignoresSafeArea()

                List {
                    iCloudSection
                    aboutSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var iCloudSection: some View {
        Section {
            HStack(spacing: 14) {
                Image(systemName: "icloud.fill")
                    .font(.title3)
                    .foregroundStyle(Color(hex: "#2962FF"))
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text("iCloud 同步")
                        .font(.subheadline)
                    Text(iCloudSyncStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: iCloudEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(iCloudEnabled ? .green : Color(.systemGray3))
            }
            .padding(.vertical, 4)
        } header: {
            Text("数据同步")
        } footer: {
            Text("iCloud 同步需要在设备设置中登录 Apple ID 并开启 iCloud。数据将在您的所有设备间自动同步。")
                .font(.caption)
        }
    }

    private var aboutSection: some View {
        Section("关于") {
            aboutRow(icon: "app.badge.fill", label: "版本", value: appVersion, color: Color(hex: "#2962FF"))
            aboutRow(icon: "hammer.fill", label: "开发者", value: "kok-s0s", color: .orange)
            aboutRow(icon: "iphone", label: "平台", value: "iOS 17+", color: .green)
        }
    }

    private func aboutRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var iCloudSyncStatus: String {
        let status = FileManager.default.ubiquityIdentityToken
        return status != nil ? "已连接 iCloud" : "未登录 iCloud"
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
