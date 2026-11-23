import Foundation

/// A date where only the year is required: "2024", "March 2024" or "12 March 2024".
nonisolated struct PartialDate: Hashable {
    var year: Int
    var month: Int?
    var day: Int?

    static var today: PartialDate {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return PartialDate(year: c.year ?? 2000, month: c.month, day: c.day)
    }

    var formatted: String {
        var components = DateComponents(year: year, month: month ?? 1, day: day ?? 1)
        components.calendar = Calendar.current
        guard let date = components.date else { return String(year) }
        if month != nil, day != nil {
            return date.formatted(.dateTime.day().month(.wide).year())
        } else if month != nil {
            return date.formatted(.dateTime.month(.wide).year())
        }
        return String(year)
    }
}
