//
//  MultiPartFormDataReader.swift
//  MultiPartFormDataCoder
//
//  Created by Roman Sukhorukov on 19.12.2024.
//

import Foundation

public class MultiPartFormDataReader {
    let parts: [String: [ReadedResource]]
    
    public init(boundary: String, data: Data) {
        var parts = [String: [ReadedResource]]()
        let parser = MultiPartFormDataParser(boundary: boundary, data: data)
        
        var parsedPart = parser.readPart()
        
        while parsedPart != nil {
            if let (name, part) = parsedPart {
                var value = parts[name] ?? []
                value.append(part)
                parts[name] = value
            }
            parsedPart = parser.readPart()
        }
        
        self.parts = parts
    }
    
    public func convertedArray<Output>(named name: String, converter: (ReadedResource)->Output) -> [Output] {
        parts[name]?.map(converter) ?? []
    }
    
    public func convertedParameter<Output>(named name: String, converter: (ReadedResource)->Output) -> Output? {
        guard let part = parts[name]?.first else { return nil }
        return converter(part)
    }
    
    public func arrayParameter(named name: String) -> [ReadedResource] {
        parts[name] ?? []
    }
    
    public func singleParameter(named name: String) -> ReadedResource? {
        parts[name]?.first
    }
}
