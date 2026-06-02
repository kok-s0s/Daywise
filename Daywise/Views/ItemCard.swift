import SwiftUI

struct ItemCard: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                statusBadge
                Spacer()
                Text(item.category)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DaywiseTheme.accent.opacity(0.82))
                    .lineLimit(1)
            }

            Text(item.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 6)

            Text(CostCalculator.formatDays(item.daysInService))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text(CostCalculator.formatDailyCost(item.dailyCost))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(DaywiseTheme.accent)
                Spacer(minLength: 6)
                Text(CostCalculator.formatPrice(item.price))
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Text(item.purchaseDate.formatted(.dateTime.year().month().day()))
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                .fill(DaywiseTheme.elevatedSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
        .shadow(color: DaywiseTheme.shadow, radius: 3, x: 0, y: 1)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            Text(item.displayStatus)
                .font(.system(size: 11))
                .foregroundStyle(statusColor)
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .serving: return DaywiseTheme.accent
        case .retired: return .secondary
        case .sold: return Color(.systemGray)
        }
    }
}
