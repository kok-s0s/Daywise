import SwiftUI

struct SimulatorView: View {
    @State private var priceText = ""
    @State private var months = 12.0
    @State private var usesPerWeek = 3.0

    private var price: Double {
        Double(priceText) ?? 0
    }

    private var totalDays: Double {
        max(1, months * 30)
    }

    private var totalUses: Double {
        max(1, months * 4.345 * usesPerWeek)
    }

    private var dailyCost: Double {
        price / totalDays
    }

    private var costPerUse: Double {
        price / totalUses
    }

    private var verdict: String {
        guard price > 0 else { return "输入价格后开始模拟" }
        if costPerUse <= 10 { return "可以买，使用密度足够高" }
        if costPerUse <= 50 { return "谨慎买，先确认真实使用场景" }
        return "先别买，单次成本偏高"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DaywiseTheme.pageBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        resultDeck
                        inputCard
                        scenarioCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("模拟器")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var resultDeck: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BUY / HOLD")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(DaywiseTheme.accent)
            Text(verdict)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            HStack(spacing: 8) {
                resultMetric("日耗", value: CostCalculator.formatDailyCost(dailyCost), icon: "calendar")
                resultMetric("单次", value: CostCalculator.formatCostPerUse(costPerUse), icon: "cursorarrow.click")
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [DaywiseTheme.elevatedSurface, DaywiseTheme.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
        .shadow(color: DaywiseTheme.glow, radius: 18, x: 0, y: 0)
        .shadow(color: DaywiseTheme.shadow, radius: 16, x: 0, y: 12)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("购买参数")
                .font(.headline)
            HStack {
                Text("价格")
                Spacer()
                Text("¥")
                    .foregroundStyle(.secondary)
                TextField("0", text: $priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
            Divider()
            sliderRow("预计使用", value: $months, range: 1...60, step: 1, suffix: "个月")
            sliderRow("每周使用", value: $usesPerWeek, range: 1...14, step: 1, suffix: "次")
        }
        .padding(16)
        .background(DaywiseTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
    }

    private var scenarioCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("成本阶梯")
                .font(.headline)
            scenarioRow("使用 30 次", value: price > 0 ? CostCalculator.formatCostPerUse(price / 30) : "¥0/次")
            scenarioRow("使用 100 次", value: price > 0 ? CostCalculator.formatCostPerUse(price / 100) : "¥0/次")
            scenarioRow("使用 365 天", value: price > 0 ? CostCalculator.formatDailyCost(price / 365) : "¥0/天")
        }
        .padding(16)
        .background(DaywiseTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
    }

    private func resultMetric(_ title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(DaywiseTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(DaywiseTheme.softSurface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue))\(suffix)")
                    .font(.subheadline.bold())
                    .foregroundStyle(DaywiseTheme.accent)
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func scenarioRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

#Preview {
    SimulatorView()
}
