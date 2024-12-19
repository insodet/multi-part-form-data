//
//  UrlFileResource.swift
//  MultiPartFormDataCoder
//
//  Created by Roman Sukhorukov on 17.12.2024.
//

import Foundation

public struct UrlFileResource: DataResource {
    
    public let url: URL
    public let contentType: String
    
    public init(url: URL) {
        self.url = url
        self.contentType = url.mimeType()
    }
    
    public var dispositionParameters: [String : String] {
        [
            "filename" : url.lastPathComponent
        ]
    }
    
    public var data: Data {
       (try? Data(contentsOf: url)) ?? Data()
    }
}
