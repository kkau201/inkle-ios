import SwiftUI

/// Year is required; month and day are optional (day needs a month).
struct PartialDatePicker: View {
    @Binding var date: PartialDate

    private let calendar = Calendar.current

    var body: some View {
        Group {
            Picker("Year", selection: $date.year) {
                ForEach(years, id: \.self) { Text(String($0)).tag($0) }
            }
            Picker("Month", selection: $date.month) {
                Text("Not set").tag(Int?.none)
                ForEach(1...12, id: \.self) { Text(calendar.monthSymbols[$0 - 1]).tag(Int?.some($0)) }
            }
            if date.month != nil {
                Picker("Day", selection: $date.day) {
                    Text("Not set").tag(Int?.none)
                    ForEach(1...daysInMonth, id: \.self) { Text(String($0)).tag(Int?.some($0)) }
                }
            }
        }
        .onChange(of: date.month) { clampDay() }
        .onChange(of: date.year) { clampDay() }
    }

    private var years: [Int] {
        let current = calendar.component(.year, from: .now)
        return Array((min(1900, date.year)...max(current, date.year)).reversed())
    }

    private var daysInMonth: Int {
        guard let month = date.month,
              let first = calendar.date(from: DateComponents(year: date.year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: first) else { return 31 }
        return range.count
    }

    private func clampDay() {
        if date.month == nil {
            date.day = nil
        } else if let day = date.day, day > daysInMonth {
            date.day = daysInMonth
        }
    }
}

#Preview {
    @Previewable @State var date = PartialDate.today
    Form { PartialDatePicker(date: $date) }
}
