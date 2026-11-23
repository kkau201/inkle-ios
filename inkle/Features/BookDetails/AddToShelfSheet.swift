import SwiftData
import SwiftUI

struct AddToShelfSheet: View {
    let volume: Volume

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var status: ReadingStatus = .wantToRead
    @State private var pageText = ""
    @State private var finished = PartialDate.today

    private var pageCount: Int? { volume.volumeInfo.knownPageCount }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(ReadingStatus.allCases) { option in
                        Button {
                            status = option
                        } label: {
                            HStack {
                                Text(option.label)
                                Spacer()
                                if status == option { Image(systemName: "checkmark").foregroundStyle(.inkInk) }
                            }
                            .contentShape(Rectangle())
                        }
                        .foregroundStyle(.inkInk)
                        .accessibilityAddTraits(status == option ? .isSelected : [])
                    }
                }
                if status == .reading {
                    Section {
                        TextField("Page you're on", text: $pageText)
                            .keyboardType(.numberPad)
                            .onChange(of: pageText) { sanitizePage() }
                    } footer: {
                        if let pageCount { Text("This book has \(pageCount) pages.") }
                    }
                }
                if status == .finished {
                    Section("Finished on") { PartialDatePicker(date: $finished) }
                }
            }
            .navigationTitle("Add to your shelf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Add") { add() } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    /// Numbers only, clamped to the page count when known.
    private func sanitizePage() {
        var digits = pageText.filter(\.isNumber)
        if let pageCount, let n = Int(digits), n > pageCount { digits = String(pageCount) }
        if digits != pageText { pageText = digits }
    }

    private func add() {
        let id = volume.id
        let existing = (try? modelContext.fetch(
            FetchDescriptor<SavedBook>(predicate: #Predicate { $0.volumeID == id }))) ?? []
        if existing.isEmpty {
            let book = SavedBook(volume: volume)
            book.setStatus(status, currentPage: Int(pageText), finishedOn: finished)
            modelContext.insert(book)
        }
        dismiss()
    }
}

#Preview {
    Text("Host").sheet(isPresented: .constant(true)) { AddToShelfSheet(volume: .richSample) }
        .modelContainer(for: SavedBook.self, inMemory: true)
}
