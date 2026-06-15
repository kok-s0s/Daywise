import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var items: [Item]

    var body: some View {
        NavigationStack {
            ZStack {
                DaywiseTheme.pageBackground.ignoresSafeArea()

                List {
                    dataSection
                    aboutSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Sections

    private var dataSection: some View {
        Section {
            ShareLink(
                item: generateCSV(),
                preview: SharePreview("daywise_export.csv", icon: Image(systemName: "tablecells"))
            ) {
                HStack(spacing: 14) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundStyle(DaywiseTheme.accent)
                        .frame(width: 28)
                    Text("导出为 CSV")
                    Spacer()
                    Text("\(items.count) 条记录")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .foregroundStyle(.primary)
                .padding(.vertical, 2)
            }
        } header: {
            Text("数据")
        } footer: {
            Text("将所有物品记录导出为 CSV 文件，可用 Numbers、Excel 等工具打开。")
                .font(.caption)
        }
    }

    private var aboutSection: some View {
        Section("关于") {
            aboutRow(icon: "app.badge.fill",  label: "版本",  value: appVersion,  color: .primary)
            aboutRow(icon: "hammer.fill",     label: "开发者", value: "kok-s0s",  color: .primary)
            aboutRow(icon: "iphone",          label: "平台",  value: "iOS 17+",   color: .primary)
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
            Text(value).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - CSV

    private func generateCSV() -> String {
        var lines = ["名称,价格,净成本,购入日期,分类,状态,出售价格,出售日期,日耗(元/天),单次成本(元/次),使用次数,满意度,服役天数,备注"]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        for item in items {
            let row: [String] = [
                csv(item.name),
                String(format: "%.2f", item.price),
                String(format: "%.2f", item.netCost),
                df.string(from: item.purchaseDate),
                csv(item.category),
                item.displayStatus,
                item.soldPrice.map { String(format: "%.2f", $0) } ?? "",
                item.soldDate.map { df.string(from: $0) } ?? "",
                String(format: "%.4f", item.dailyCost),
                item.costPerUse.map { String(format: "%.4f", $0) } ?? "",
                item.useCount.map(String.init) ?? "",
                item.satisfactionScore.map(String.init) ?? "",
                "\(item.daysInService)",
                csv(item.note ?? "")
            ]
            lines.append(row.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private func csv(_ s: String) -> String {
        guard s.contains(",") || s.contains("\"") || s.contains("\n") else { return s }
        return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
