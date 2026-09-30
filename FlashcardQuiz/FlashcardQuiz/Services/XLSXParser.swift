//
//  XLSXParser.swift
//  Reads the first worksheet of an .xlsx workbook using CoreXLSX
//  (https://github.com/CoreOffice/CoreXLSX, added via Swift Package Manager).
//  Column A = term, column B = definition.
//

import Foundation
import CoreXLSX

enum XLSXParser {

    /// Returns rows of [column A, column B] strings from the first worksheet.
    static func parseRows(from data: Data) throws -> [[String]] {
        // In current CoreXLSX versions this initializer throws (it isn't failable).
        let file: XLSXFile
        do {
            file = try XLSXFile(data: data)
        } catch {
            throw ImportError.unreadable
        }

        let sharedStrings = try? file.parseSharedStrings()

        guard let workbook = try file.parseWorkbooks().first,
              let (_, path) = try file.parseWorksheetPathsAndNames(workbook: workbook).first
        else {
            throw ImportError.noWorksheet
        }

        let worksheet = try file.parseWorksheet(at: path)
        var result: [[String]] = []

        for row in worksheet.data?.rows ?? [] {
            var a = "", b = ""
            for cell in row.cells {
                let text = stringValue(of: cell, sharedStrings: sharedStrings)
                switch cell.reference.column.value {
                case "A": a = text
                case "B": b = text
                default: break
                }
            }
            result.append([a, b])
        }
        return result
    }

    private static func stringValue(of cell: Cell, sharedStrings: SharedStrings?) -> String {
        if let shared = sharedStrings, let s = cell.stringValue(shared) { return s }
        if let inline = cell.inlineString?.text { return inline }
        return cell.value ?? ""
    }
}
