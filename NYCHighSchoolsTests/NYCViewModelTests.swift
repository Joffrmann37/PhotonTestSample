//
//  NYCViewModelTests.swift
//  NYCHighSchoolsTests
//
//  Created by Joffrey Mann on 2/7/24.
//

import XCTest
@testable import NYCHighSchools

final class NYCViewModelTests: XCTestCase {
    func test_DidGetSchoolsJSON() {
        let vm = NYCViewModelSpy(service: NYCSchoolServiceSpy())
        var finalResult: SchoolResult!
        var schools = [NYCSchool]()
        let exp = expectation(description: "Wait for task")
        testWithExpectation(vm: vm, exp: exp) { result in
            if case .success(let array) = result {
                schools = array
            }
            finalResult = result
            exp.fulfill()
        }
        XCTAssertEqual(finalResult, result(expectedResult: .success(schools)))
    }
    
    func test_CouldNotReadData() {
        let vm = NYCViewModelSpy(service: NYCSchoolServiceSpy(shouldFail: true))
        var finalResult: SchoolResult!
        var error: SchoolError!
        let exp = expectation(description: "Wait for task")
        testWithExpectation(vm: vm, exp: exp) { result in
            if case .failure(let err) = result {
                error = err
            }
            finalResult = result
            exp.fulfill()
        }
        XCTAssertEqual(finalResult, result(expectedResult: .failure(error)))
    }
    
    func test_InvalidURL() {
        let vm = NYCViewModelSpy(service: NYCSchoolServiceSpy(), url: URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.js")!)
        var finalResult: SchoolResult!
        var error: SchoolError!
        let exp = expectation(description: "Wait for task")
        testWithExpectation(vm: vm, exp: exp) { result in
            if case .failure(let err) = result {
                error = err
            }
            finalResult = result
            exp.fulfill()
        }
        XCTAssertEqual(finalResult, result(expectedResult: .failure(error)))
    }
    
    func test_DidGetSchoolDetails() {
        let vm = NYCViewModelSpy(service: NYCSchoolServiceSpy())
        var details: NYCSchool.NYCSchoolDetails!
        let exp = expectation(description: "Wait for task")
        testWithExpectation(vm: vm, exp: exp) { result in
            if case .success(let array) = result {
                details = array[0].getDetails()
            }
            exp.fulfill()
        }
        XCTAssertEqual(details, NYCSchoolSpy.NYCSchoolDetails(phoneNumber: "212-524-4360", schoolEmail: "admissions@theclintonschool.net", faxNumber: "212-524-4365"))
    }
    
    
    private func result(expectedResult: SchoolResult) -> SchoolResult {
        switch expectedResult {
        case .success(let array):
            return .success(array)
        case .failure(let schoolError):
            return .failure(schoolError)
        }
    }
    
    private func testWithExpectation(vm: NYCViewModelSpy, exp: XCTestExpectation, completionHandler: @escaping (SchoolResult) -> Void, file: StaticString = #file, line: UInt = #line) {
        vm.fetch { result in
            completionHandler(result)
        }
        wait(for: [exp], timeout: 3)
    }
    
    private class NYCViewModelSpy: NYCViewModel {
        let url: URL
        
        init(service: Serviceable, url: URL = URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.json")!) {
            self.url = url
            super.init(service: service)
            self.service = service
        }
        
        func fetch(completionHandler: @escaping (SchoolResult) -> Void) {
            service.fetchSchools(url: url, completionHandler: completionHandler)
        }
    }
    
    internal class NYCSchoolSpy: NYCSchool {
        var website: String
                
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: NYCKeys.self)
            self.website = try container.decode(String.self, forKey: NYCKeys.website)
            try super.init(from: decoder)
        }
    }
    
    private class NYCSchoolFailableSpy: NYCSchoolSpy {
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: NYCKeys.self)
            try super.init(from: decoder)
            self.website = try container.decode(String.self, forKey: NYCKeys.faxNumber)
        }
    }
    
    private class NYCSchoolServiceSpy: Serviceable {
        let shouldFail: Bool
        
        init(shouldFail: Bool = false) {
            self.shouldFail = shouldFail
        }
        
        func fetchSchools(url: URL, completionHandler: @escaping (NYCHighSchools.SchoolResult) -> Void) {
            let task = URLSession(configuration: .default).dataTask(with: url) { [weak self] data, response, error in
                guard let self = self, let data = data else {
                    print("No data")
                    completionHandler(.failure(.noData))
                    return
                }
                do {
                    var schools: [NYCSchoolSpy]!
                    
                    if shouldFail {
                        schools = try JSONDecoder().decode([NYCSchoolFailableSpy].self, from: data)
                    } else {
                        schools = try JSONDecoder().decode([NYCSchoolSpy].self, from: data)
                    }
                    completionHandler(.success(schools))
                } catch {
                    print(error.localizedDescription)
                    completionHandler(.failure(.invalidData))
                }
            }
            task.resume()
        }
    }
}
