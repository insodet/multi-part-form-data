//
//  MultiPartFormDataParser.swift
//  MultiPartFormDataCoder
//
//  Created by Roman Sukhorukov on 18.12.2024.
//

import Foundation

class MultiPartFormDataParser {
    private var data: Data
    private let boundary: String
    
    public init(boundary: String, data: Data) {
        self.data = data
        self.boundary = boundary
    }
    
    func readPart() -> (name:String, resource: ReadedResource)? {
        guard let startBoundaryRange = data.firstRange(of: "--\(boundary)\(String.crlf)"),
              let endBoundaryRange = data.firstRange(of: "\(String.crlf)--\(boundary)", in: startBoundaryRange.upperBound..<data.endIndex) else {
            return nil
        }
        var partData = data[startBoundaryRange.upperBound..<endBoundaryRange.lowerBound]
        self.data = data.dropFirst(endBoundaryRange.lowerBound-data.startIndex)
        var parameters = readDispositionParameters(from: readAndDropLine(from: &partData) ?? "")
        
        guard let name = parameters[ignoreCase: "name"] else {
            return nil
        }
        
        parameters.removeValue(forKey: "name", ignorCase: true)
        
        var headerLine = readAndDropLine(from: &partData)
        var headerLines = [String]()
        while ((headerLine?.count ?? 0) > 0) {
            if let headerLine {
                headerLines.append(headerLine)
            }
            headerLine = readAndDropLine(from: &partData)
        }
        var headers: [String: String] = Dictionary(
            uniqueKeysWithValues: headerLines.compactMap { line in
                let parts = line.split(separator: ":", maxSplits: 1)
                guard let first = parts.first?.trimmingCharacters(in: .whitespaces),
                      let second = parts.last?.trimmingCharacters(in: .whitespaces),
                      first != second else {
                    return nil
                }
                return (first, second)
            }
        )
        
        let contentType = headers[ignoreCase: Header.contentType.rawValue]
        headers.removeValue(forKey: Header.contentType.rawValue, ignorCase: true)
        
        let part = ReadedResource(
            contentType: contentType ?? defaultMimeType,
            dispositionParameters: parameters,
            extraHeaders: headers,
            data: partData
        )
        
        return (name, part)
    }
    
    private func readAndDropLine(from data: inout Data) -> String? {
        guard let lineRange = data.firstRange(of: .crlf) else {
            return nil
        }
        let result = String(data: data[data.startIndex..<lineRange.lowerBound], encoding: .utf8)
        data = data.dropFirst(lineRange.upperBound-data.startIndex)
        return result
    }
    
    private func readDispositionParameters(from line: String) -> [String: String] {
        let nsLine = (line as NSString)
        let parameters = (try? NSRegularExpression(pattern: "([^;=\\n ]*)[ ]?=[ ]?\"([^\";=]*)\""))?
            .matches(in: line, range: .init(location: 0, length: line.count))
            .compactMap { result->(String, String)? in
                guard result.numberOfRanges >= 3 else {
                    return nil
                }
                return (nsLine.substring(with: result.range(at: 1)), nsLine.substring(with: result.range(at: 2)))
            } ?? []
        return Dictionary(uniqueKeysWithValues: parameters)
    }
}

