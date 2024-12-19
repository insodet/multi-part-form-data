// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public class MultiPartFormData {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public let boundary: String
    public var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    public let data: Data
    
    private init(boundary: String, data: Data) {
        self.boundary = boundary
        self.data = data
    }
    
    public class Builder {
        
        private var resources: [String:[DataResource]] = [:]
        
        fileprivate init() {}
        
        func add(resource: DataResource, named name: String) -> Builder {
            if var value = self.resources[name] {
                value.append(resource)
                resources[name] = value
            } else {
                resources[name] = [resource]
            }
            return self
        }
        
        func add<Resources: Sequence>(contentsOf array: Resources, named name: String) -> Builder where Resources.Element == any DataResource {
            if var value = self.resources[name] {
                value.append(contentsOf: array)
                resources[name] = value
            } else {
                resources[name] = Array(array)
            }
            return self
        }
        
        func build() -> MultiPartFormData {
            let boundary = generateBoundary()
            
            var resultData = Data()
            resources.sorted{ first, second in first.key < second.key }.forEach { (name, resources) in
                resources.forEach { resource in
                    var params = resource.dispositionParameters
                    params["name"] = name
                    resultData.addLine("\(String.crlf)--\(boundary)")
                    resultData.add(header: Header.contentDisposition, value: "form-data; \(params.parametersEncoded)")
                    resource.headers.forEach {(key, value) in resultData.addHeader(name: key, value: value) }
                    resultData.append(String.crlf)
                    resultData.append(resource.data)
                }
            }
            
            if !resultData.isEmpty {
                resultData.append("\(String.crlf)--\(boundary)--")
            }
            
            return .init(boundary: boundary, data: resultData)
        }
        
        private func generateBoundary() -> String {
            "--MultiPartCoderBoundary\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        }
    }
}

private extension DataResource {
    var headers: [String: String] {
        var headers = extraHeaders
        headers[Header.contentType.rawValue] = contentType
        return headers
    }
}
