//
//  FileImporter.swift
//  Turns a file picked in the Files app / document picker into [Flashcard].
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum ImportError: LocalizedError {
    case unsupportedType(String)
    case unreadable
    case noWorksheet
    case noCards
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .unsupportedType(let ext):
            return "Unsupported file type “.\(ext)”. Please choose a .csv or .xlsx file."
        case .unreadable:
            return "The file could not be read. It may be corrupted or in an unexpected encoding."
        case .noWorksheet:
            return "The Excel workbook contains no worksheets."
        case .noCards:
            return "No term/definition pairs were found. Put terms in column 1 and definitions in column 2."
        case .accessDenied:
            return "The app doesn't have permission to open that file."
        }
    }
}

enum FileImporter {

    /// File types offered in the document picker.
    static let allowedTypes: [UTType] = {
        var types: [UTType] = [.commaSeparatedText, .plainText]
        if let xlsx = UTType("org.openxmlformats.spreadsheetml.sheet")
            ?? UTType(filenameExtension: "xlsx") {
            types.append(xlsx)
        }
        return types
    }()

    /// Reads and parses the picked file.
    static func loadCards(from url: URL) throws -> [Flashcard] {
        // Files outside the sandbox require security-scoped access.
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let ext = url.pathExtension.lowercased()
        let rows: [[String]]

        switch ext {
        case "xlsx":
            guard let data = try? Data(contentsOf: url) else { throw ImportError.accessDenied }
            rows = try XLSXParser.parseRows(from: data)
        case "csv", "txt", "tsv":
            guard let data = try? Data(contentsOf: url) else { throw ImportError.accessDenied }
            // Try UTF-8 first, then common fallbacks (Excel often exports Windows-1252).
            guard let text = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .windowsCP1252)
                    ?? String(data: data, encoding: .isoLatin1)
            else { throw ImportError.unreadable }
            rows = CSVParser.parse(text)
        default:
            throw ImportError.unsupportedType(ext)
        }

        let cards = makeCards(from: rows)
        guard !cards.isEmpty else { throw ImportError.noCards }
        return cards
    }

    /// Converts raw rows to flashcards: skips a header row, blank rows, and rows missing a side.
    static func makeCards(from rows: [[String]]) -> [Flashcard] {
        var rows = rows

        // Drop a header row such as "Term,Definition".
        if let first = rows.first, first.count >= 2 {
            let headerTerms: Set<String> = ["term", "terms", "word", "front", "question"]
            let headerDefs: Set<String> = ["definition", "definitions", "meaning", "back", "answer"]
            let t = first[0].trimmingCharacters(in: .whitespaces).lowercased()
            let d = first[1].trimmingCharacters(in: .whitespaces).lowercased()
            if headerTerms.contains(t) && headerDefs.contains(d) { rows.removeFirst() }
        }

        return rows.compactMap { row in
            guard row.count >= 2 else { return nil }
            let term = row[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let definition = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty, !definition.isEmpty else { return nil }
            return Flashcard(term: term, definition: definition)
        }
    }
}
