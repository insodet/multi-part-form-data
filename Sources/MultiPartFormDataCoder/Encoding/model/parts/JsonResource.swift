//
//  JsonResource.swift
//  MultiPartFormDataCoder
//
//  Created by Roman Sukhorukov on 17.12.2024.
//

import Foundation

public struct JsonResource: DataResource {
    public let contentType: String = "application/json"
    
    public var data: Data
    
    public init<Object: Encodable>(_ object: Object) throws {
        self.data = try JSONEncoder().encode(object)
    }
}
