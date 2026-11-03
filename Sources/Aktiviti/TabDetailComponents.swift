import SwiftUI
import AppKit

// MARK: - Hero Card

struct TabHeroCardView: View {
    let caption: String
    let mainValue: String
    let unit: String
    var statusBadge: (text: String, isNormal: Bool)? = nil
    let statRow1: (label: String, value: String)
    let statRow2: (label: String, value: String)
    let chartData: [Double]
    let chartTint: Color
    var chartMax: Double? = nil

    private let cardBackground = Color(red: 242/255, green: 242/255, blue: 245/255)

    init(
        caption: String,
        mainValue: String,
        unit: String,
        statusBadge: (text: String, isNormal: Bool)? = nil,
        statRow1: (label: String, value: String),
        statRow2: (label: String, value: String),
        chartData: [Double],
        chartTint: Color,
        chartMax: Double? = nil
    ) {
        self.caption = caption
        self.mainValue = mainValue
        self.unit = unit
        self.statusBadge = statusBadge
        self.statRow1 = statRow1
        self.statRow2 = statRow2
        self.chartData = chartData
        self.chartTint = chartTint
        self.chartMax = chartMax
    }

    var body: some View {
        HStack(spacing: 24) {
            // Left Metric Info Column
            VStack(alignment: .leading, spacing: 4) {
                Text(caption)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(mainValue)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 24/255))
                    Text(unit)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
                }

                if let badge = statusBadge {
                    HStack(spacing: 4) {
                        Image(systemName: badge.isNormal ? "checkmark" : "exclamationmark.triangle.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text(badge.text)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        badge.isNormal
                            ? Color(red: 215/255, green: 245/255, blue: 226/255)
                            : Color(red: 254/255, green: 235/255, blue: 200/255)
                    )
                    .foregroundStyle(
                        badge.isNormal
                            ? Color(red: 15/255, green: 130/255, blue: 66/255)
                            : Color(red: 180/255, green: 83/255, blue: 9/255)
                    )
                    .clipShape(Capsule())
                    .padding(.top, 2)
                }

                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(statRow1.label)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
                        Spacer()
                        Text(statRow1.value)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 24/255))
                    }

                    HStack {
                        Text(statRow2.label)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
                        Spacer()
                        Text(statRow2.value)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 24/255))
                    }
                }
                .frame(width: 175)
            }
            .frame(width: 180, alignment: .leading)

            // Right Smooth Area Spline Chart
            SmoothAreaChartView(
                data: chartData,
                tintColor: chartTint,
                maxValue: chartMax,
                showGrid: true
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(height: 190)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Subcard Row

enum SubcardStyle {
    case standard(subtitle: String)
    case badges(badges: [(text: String, bg: Color, fg: Color)])
    case progress(ratio: Double)
    case topApp(appName: String, appIcon: NSImage?)
}

struct TabSubcardView: View {
    let title: String
    let icon: String
    let value: String
    let tint: Color
    let style: SubcardStyle

    private let cardBackground = Color(red: 242/255, green: 242/255, blue: 245/255)

    init(
        title: String,
        icon: String,
        value: String,
        tint: Color,
        style: SubcardStyle
    ) {
        self.title = title
        self.icon = icon
        self.value = value
        self.tint = tint
        self.style = style
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Icon badge + Title
            HStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tint.opacity(0.18))
                        .frame(width: 20, height: 20)
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(tint)
                }

                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color(red: 75/255, green: 75/255, blue: 82/255))

                Spacer()

                if case .topApp = style {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(red: 170/255, green: 170/255, blue: 178/255))
                }
            }

            Spacer(minLength: 6)

            // Value or App Info
            switch style {
            case .standard(let subtitle):
                VStack(alignment: .leading, spacing: 3) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 24/255))
                    Text(subtitle)
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
                }

            case .badges(let badgeItems):
                VStack(alignment: .leading, spacing: 5) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 24/255))
                    HStack(spacing: 6) {
                        ForEach(badgeItems.indices, id: \.self) { idx in
                            let b = badgeItems[idx]
                            Text(b.text)
                                .font(.system(size: 10.5, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(b.bg)
                                .foregroundStyle(b.fg)
                                .clipShape(Capsule())
                        }
                    }
                }

            case .progress(let ratio):
                VStack(alignment: .leading, spacing: 7) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 24/255))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(red: 228/255, green: 228/255, blue: 233/255))
                                .frame(height: 5)
                            Capsule()
                                .fill(tint)
                                .frame(width: max(5, geo.size.width * CGFloat(min(max(ratio, 0.0), 1.0))), height: 5)
                        }
                    }
                    .frame(height: 5)
                }

            case .topApp(let appName, let appIcon):
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        if let iconImg = appIcon {
                            Image(nsImage: iconImg)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 19, height: 19)
                                .clipShape(RoundedRectangle(cornerRadius: 4.5, style: .continuous))
                        } else {
                            Image(systemName: "app.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
                        }
                        Text(appName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 24/255))
                            .lineLimit(1)
                    }

                    Text(value)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(height: 98)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Process Table Card

struct ProcessRowItem: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: NSImage
    let processCount: Int
    let valueString: String
    let ratio: Double

    init(
        id: String,
        name: String,
        icon: NSImage,
        processCount: Int,
        valueString: String,
        ratio: Double
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.processCount = processCount
        self.valueString = valueString
        self.ratio = ratio
    }
}

struct TabProcessTableView: View {
    let metricHeader: String
    let items: [ProcessRowItem]
    let tint: Color

    private let cardBackground = Color(red: 242/255, green: 242/255, blue: 245/255)

    init(metricHeader: String, items: [ProcessRowItem], tint: Color) {
        self.metricHeader = metricHeader
        self.items = items
        self.tint = tint
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack {
                Text("App")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
                Spacer()
                Text(metricHeader)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .overlay(Color(red: 232/255, green: 232/255, blue: 236/255))
                .padding(.horizontal, 14)

            // Rows
            VStack(spacing: 12) {
                ForEach(items.prefix(4)) { item in
                    HStack(spacing: 12) {
                        Image(nsImage: item.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 24/255))
                            Text("\(item.processCount) processes")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color(red: 142/255, green: 142/255, blue: 147/255))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 5) {
                            Text(item.valueString)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 24/255))

                            // Horizontal Bar
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(red: 228/255, green: 228/255, blue: 233/255))
                                    .frame(width: 110, height: 4.5)
                                Capsule()
                                    .fill(tint)
                                    .frame(width: max(4, 110 * CGFloat(min(max(item.ratio, 0.0), 1.0))), height: 4.5)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
            .padding(.vertical, 12)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
