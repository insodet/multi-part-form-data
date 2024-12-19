//
//  DataResource.swift
//  MultiPartFormDataCoder
//
//  Created by Roman Sukhorukov on 13.12.2024.
//

import Foundation

public protocol DataResource {
    var contentType: String {get}
    var dispositionParameters: [String: String] {get}
    var extraHeaders: [String: String] {get}
    var data: Data {get}
}

public extension DataResource {
    var contentType: String {
        defaultMimeType
    }
    
    var extraHeaders: [String: String] {
        [:]
    }
    
    var dispositionParameters: [String: String] {
        [:]
    }
}
