//
//  Extensions.swift
//  MultiPartFormDataCoder
//
//  Created by Roman Sukhorukov on 17.12.2024.
//

import Foundation
import UniformTypeIdentifiers

let defaultMimeType = "application/octet-stream"

public extension MultiPartFormData {
    func createURLRequest(toUrl url: URL, method: String? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        self.addData(toRequest: &request)
        return request
    }
    
    func addData(toRequest request: inout URLRequest) {
        request.httpBody = self.data
        request.setValue(self.contentType, forHTTPHeaderField: Header.contentType.rawValue)
    }
}

public extension HTTPURLResponse {
    func createMultiPartFormDataReader(withData data: Data) -> MultiPartFormDataReader? {
        guard let boundary = self.value(forHTTPHeaderField: Header.contentType.rawValue)?.boundaryFromContentTypeHeader else {
            return nil
        }
        return .init(boundary: boundary, data: data)
    }
}

extension URL {
    func mimeType() -> String {
        UTType.mimeType(forPathExtension: self.pathExtension)
    }
}

extension UTType {
    static func mimeType(forPathExtension pathExtension: String) -> String {
        UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? defaultMimeType
    }
}

extension String {
    static var crlf: String {
        "\r\n"
    }
    
    var filenameExtension: String? {
        guard let index = self.lastIndex(of: ".") else {
            return nil
        }
        return String(self[index...]).replacingOccurrences(of: ".", with: "")
    }
    
    var filenameMimeType: String {
        guard let filenameExtension else {
            return defaultMimeType
        }
        return UTType.mimeType(forPathExtension: filenameExtension)
    }
    
    var boundaryFromContentTypeHeader: String? {
        guard let regex = try? NSRegularExpression(pattern: "(?<=boundary=).+$", options: [.caseInsensitive]),
              let range = regex.firstMatch(in: self, range: NSRange(location: 0, length: self.count))?.range else {
            return nil
        }
        return (self as NSString).substring(with: range)
    }
}

extension Data {
    mutating func append(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.append(data)
    }
    
    mutating func addLine(_ string: String) {
        self.append("\(string)\(String.crlf)")
    }
    
    mutating func addHeader(name: String, value: String) {
        self.addLine("\(name) : \(value)")
    }
    
    mutating func add(header: Header, value: String) {
        self.addHeader(name: header.rawValue, value: value)
    }
    
    func firstRange(of string: String) -> Range<Self.Index>? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        return self.firstRange(of: data)
    }
    
    func firstRange<R:RangeExpression>(of string: String, in range: R) -> Range<Self.Index>? where R.Bound == Self.Index {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        return self.firstRange(of: data, in: range)
    }
}

extension Dictionary where Key == String, Value == String {
    var parametersEncoded: String {
        self
            .map{(key, value) in "\(key)=\"\(value)\"" }
            .sorted(by: <)
            .joined(separator: "; ")
    }
    
    subscript(ignoreCase key: Key) -> Value? {
        get {
            guard let found = self.keys.first(where: { $0.lowercased() == key.lowercased() }) else {
                return nil
            }
            return self[found]
        }
        set {
            if let found = self.keys.first(where: { $0.lowercased() == key.lowercased() }) {
                self[found] = newValue
            } else {
                self[key] = newValue
            }
        }
    }
    
    mutating func removeValue(forKey key: Key, ignorCase: Bool) {
        if ignorCase {
            if let found = self.keys.first(where: { $0.lowercased() == key.lowercased() }) {
                self.removeValue(forKey: found)
            }
        } else {
            self.removeValue(forKey: key)
        }
    }
}
