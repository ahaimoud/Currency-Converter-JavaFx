//
//  CSVParser.swift
//  A small RFC-4180 style CSV parser (quoted fields, escaped quotes,
//  embedded newlines, CRLF, BOM, and comma / semicolon / tab delimiters).
//  Written in-house so the app needs no CSV dependency.
//

import Foundation

enum CSVParser {

    /// Parses CSV text into rows of fields.
    static func parse(_ text: String) -> [[String]] {
        var input = text
        if input.hasPrefix("\u{FEFF}") { input.removeFirst() }   // strip BOM

        let delimiter = detectDelimiter(in: input)

        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false

        let chars = Array(input)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" {
                        field.append("\"")          // escaped quote
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(c)
                }
            } else {
                switch c {
                case "\"":
                    inQuotes = true
                case delimiter:
                    row.append(field); field = ""
                case "\n", "\r\n", "\r":
                    // Swift treats "\r\n" as a single Character, so this covers CRLF too.
                    row.append(field); field = ""
                    rows.append(row); row = []
                default:
                    field.append(c)
                }
            }
            i += 1
        }
        // Flush the last field/row if the file has no trailing newline.
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }

    /// Picks the most frequent candidate delimiter on the first line.
    private static func detectDelimiter(in text: String) -> Character {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        let candidates: [Character] = [",", ";", "\t"]
        return candidates.max { a, b in
            firstLine.filter { $0 == a }.count < firstLine.filter { $0 == b }.count
        } ?? ","
    }
}
