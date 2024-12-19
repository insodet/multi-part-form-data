import XCTest
@testable import MultiPartFormDataCoder

final class MultiPartFormDataCoderTests: XCTestCase {
    
    struct Test: Codable, Equatable {
        let name: String
        let mine: Double
    }
    
    func testMultipartGenerationWithJsonAndTxtFile() throws {
        let object = Test(name: "xyz", mine: 100.3)
            let resource = try JsonResource(object)
        let formData = MultiPartFormData
            .builder()
            .add(resource: resource, named: "myObject")
            .add(resource: DataFileResource(filename: "test.txt", data: "xyz".data(using: .utf8)!), named: "file")
            .build()
        let expectationString =
        """
        \r
        --\(formData.boundary)\r
        Content-Disposition : form-data; filename="test.txt"; name="file"\r
        Content-Type : text/plain\r
        \r
        xyz\r
        --\(formData.boundary)\r
        Content-Disposition : form-data; name="myObject"\r
        Content-Type : application/json\r
        \r
        \(String(data: resource.data, encoding: .utf8)!)\r
        --\(formData.boundary)--
        """
        XCTAssertEqual(String(data: formData.data, encoding: .utf8), expectationString)
    }
    
    func testMultipartArrayOfFiles() throws {
        let firstURL = Bundle.module.url(forResource: "test1", withExtension: "png")!
        let secondURL = Bundle.module.url(forResource: "test2", withExtension: "png")!
        let formData = MultiPartFormData
            .builder()
            .add(contentsOf: [UrlFileResource(url: firstURL), UrlFileResource(url: secondURL)], named: "image")
            .build()
        var expected = Data()
        expected.append(
            """
            \r
            --\(formData.boundary)\r
            Content-Disposition : form-data; filename="test1.png"; name="image"\r
            Content-Type : image/png\r
            \r
            
            """.data(using: .utf8)!
        )
        expected.append(try Data(contentsOf: firstURL))
        expected.append(
            """
            \r
            --\(formData.boundary)\r
            Content-Disposition : form-data; filename="test2.png"; name="image"\r
            Content-Type : image/png\r
            \r
            
            """.data(using: .utf8)!
        )
        expected.append(try Data(contentsOf: secondURL))
        expected.append(
            """
            \r
            --\(formData.boundary)--
            """.data(using: .utf8)!
        )
        XCTAssertEqual(formData.data, expected)
    }
    
    func testBoundaryReadingFromContentType() throws {
        let data = MultiPartFormData.builder().build()
        XCTAssertEqual(data.contentType.boundaryFromContentTypeHeader, data.boundary)
        XCTAssertEqual(data.contentType.uppercased().boundaryFromContentTypeHeader, data.boundary.uppercased())
    }
    
    func testMultipartDataReading() throws {
        let data =
        """
        \r
        --GeneratedBondary\r
        Content-Disposition : form-data; filename="test.txt"; name="file"\r
        Content-TYPE : text/plain\r
        \r
        xyz\r
        --GeneratedBondary\r
        Content-Disposition : form-data; name="myObject"\r
        content-type : application/json\r
        Content-length : 120\r
        \r
        {"mine":100.3,"name":"xyz"}\r
        --GeneratedBondary--
        """.data(using: .utf8)!
        let reader = MultiPartFormDataParser(boundary: "GeneratedBondary", data: data)
        let (name,part) = reader.readPart()!
        XCTAssertEqual(part.dispositionParameters, ["filename":"test.txt"])
        XCTAssertEqual(name, "file")
        XCTAssertEqual(part.contentType, "text/plain")
        XCTAssertEqual(String(data: part.data, encoding: .utf8), "xyz")
        XCTAssertEqual(part.extraHeaders, [:])
        
        let (secondPartName, secondPart) = reader.readPart()!
        XCTAssertEqual(secondPart.dispositionParameters, [:])
        XCTAssertEqual(secondPartName, "myObject")
        XCTAssertEqual(secondPart.contentType, "application/json")
        XCTAssertEqual(try JSONDecoder().decode(Test.self, from: secondPart.data), Test(name: "xyz", mine: 100.3))
        XCTAssertEqual(secondPart.extraHeaders, ["Content-length":"120"])
    }
    
    func testMultipartDataReadingWithArray() throws {
        let data =
        """
        \r
        --GeneratedBondary\r
        Content-Disposition : form-data; filename="test1.txt"; name="file"\r
        Content-TYPE : text/plain\r
        \r
        xyz\r
        --GeneratedBondary\r
        Content-Disposition : form-data; filename="test2.txt"; name="file"\r
        Content-TYPE : text/plain\r
        Content-length : 12\r
        \r
        zyxel\r
        --GeneratedBondary\r
        Content-Disposition : form-data; name="myObject"\r
        content-type : application/json\r
        Content-length : 120\r
        \r
        {"mine":100.3,"name":"xyz"}\r
        --GeneratedBondary--
        """.data(using: .utf8)!
        let reader = MultiPartFormDataReader(boundary: "GeneratedBondary", data: data)
        let files = reader.arrayParameter(named: "file")
        XCTAssertEqual(files.count, 2)
        XCTAssertEqual(files.first?.dispositionParameters, ["filename":"test1.txt"])
        XCTAssertEqual(files.first?.contentType, "text/plain")
        XCTAssertEqual(String(data: files.first!.data, encoding: .utf8), "xyz")
        XCTAssertEqual(files.first?.extraHeaders, [:])
        
        XCTAssertEqual(files.last?.dispositionParameters, ["filename":"test2.txt"])
        XCTAssertEqual(files.last?.contentType, "text/plain")
        XCTAssertEqual(String(data: files.last!.data, encoding: .utf8), "zyxel")
        XCTAssertEqual(files.last?.extraHeaders, ["Content-length":"12"])
        
        let myObject = reader.singleParameter(named: "myObject")
        XCTAssertEqual(myObject?.dispositionParameters, [:])
        XCTAssertEqual(myObject?.contentType, "application/json")
        XCTAssertEqual(try JSONDecoder().decode(Test.self, from: myObject!.data), Test(name: "xyz", mine: 100.3))
        XCTAssertEqual(myObject?.extraHeaders, ["Content-length":"120"])
    }
    
    func testMultipartDataConvertedValue() throws {
        let data =
        """
        \r
        --GeneratedBondary\r
        Content-Disposition : form-data; name="myObject"\r
        content-type : application/json\r
        Content-length : 120\r
        \r
        {"mine":100.3,"name":"xyz"}\r
        --GeneratedBondary--
        """.data(using: .utf8)!
        let reader = MultiPartFormDataReader(boundary: "GeneratedBondary", data: data)
        
        XCTAssertEqual(reader.convertedParameter(named: "myObject", converter: { try? JSONDecoder().decode(Test.self, from: $0.data) }), Test(name: "xyz", mine: 100.3))
    }
}
