//
//  ReadedResource.swift
//  MultiPartFormDataCoder
//
//  Created by Roman Sukhorukov on 18.12.2024.
//

import Foundation

public struct ReadedResource: DataResource {
    
    public var contentType: String
    public var dispositionParameters: [String: String]
    public var extraHeaders: [String: String]
    public var data: Data
    
    init(contentType: String, dispositionParameters: [String : String], extraHeaders: [String : String], data: Data) {
        self.contentType = contentType
        self.dispositionParameters = dispositionParameters
        self.extraHeaders = extraHeaders
        self.data = data
    }
}
