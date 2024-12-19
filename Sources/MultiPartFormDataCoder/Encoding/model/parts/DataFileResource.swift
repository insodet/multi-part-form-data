//
//  DataFileResource.swift
//  MultiPartFormDataCoder
//
//  Created by Roman Sukhorukov on 17.12.2024.
//

import Foundation
import UniformTypeIdentifiers

public struct DataFileResource: DataResource {
    
    public let dispositionParameters: [String : String]
    public let data: Data
    public let contentType: String
    
    public init(filename: String, data: Data, mimeType: String? = nil) {
        self.dispositionParameters = [
            "filename" : filename
        ]
        self.contentType = mimeType ?? filename.filenameMimeType
        self.data = data
    }
}
