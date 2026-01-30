import SwiftUI

struct CountriesCard: View {
    let countries: [CountryData]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("TOP COUNTRIES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
                .tracking(0.5)
                .padding(.bottom, 6)

            // Countries list
            VStack(spacing: 4) {
                ForEach(countries.prefix(4)) { country in
                    CountryRow(country: country)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

struct CountryRow: View {
    let country: CountryData

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Flag
            Text(country.flag)
                .font(.system(size: 14))

            // Country code
            Text(country.countryCode)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            // Percentage
            Text(AnalyticsService.formatPercentage(country.percentage))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(isHovered ? 0.05 : 0))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    CountriesCard(countries: [
        CountryData(countryCode: "US", countryName: "United States", users: 984, percentage: 42),
        CountryData(countryCode: "GB", countryName: "United Kingdom", users: 421, percentage: 18),
        CountryData(countryCode: "DE", countryName: "Germany", users: 281, percentage: 12),
        CountryData(countryCode: "FR", countryName: "France", users: 187, percentage: 8)
    ])
    .frame(width: 140)
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
