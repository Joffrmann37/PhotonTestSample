//
//  NYCViewModelTests.swift
//  NYCHighSchoolsTests
//
//  Created by Joffrey Mann on 2/7/24.
//

import XCTest
@testable import NYCHighSchools
import Combine
import CleanArchitecture

final class NYCViewModelTests: XCTestCase {
    func test_DidGetSchoolsJSON() {
        let vm = NYCViewModel(useCase: FetchNYCSchoolsUseCase(repository: NYCSchoolRepositorySpy()))
        let exp = expectation(description: "Wait for task")
        let expectedSchools = testWithExpectation(vm: vm, exp: exp)
        XCTAssertTrue(expectedSchools.count > 0)
    }
    
    func test_CouldNotReadData() {
        let vm = NYCViewModel(useCase: FetchNYCSchoolsUseCase(repository: NYCSchoolRepositorySpy()))
        let exp = expectation(description: "Wait for task")
        let error = testWithExpectationOfError(vm: vm, type: [NYCSchoolInvalidSpy].self, exp: exp)
        XCTAssertEqual(error, vm.error)
    }
    
    func test_InvalidURL() {
        let vm = NYCViewModel(useCase: FetchNYCSchoolsUseCase(repository: NYCSchoolRepositorySpy()), url: URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.js")!)
        let exp = expectation(description: "Wait for task")
        let error = testWithExpectationOfError(vm: vm, type: [NYCSchoolSpy].self, exp: exp)
        XCTAssertEqual(error, vm.error)
    }
    
    func test_DidGetSchoolDetails() {
        let vm = NYCViewModel(useCase: FetchNYCSchoolsUseCase(repository: NYCSchoolRepositorySpy()))
        let exp = expectation(description: "Wait for task")
        let schools = testWithExpectation(vm: vm, exp: exp)
        XCTAssertEqual(schools[0].getDetails(), NYCSchoolSpy.NYCSchoolDetails(phoneNumber: "212-524-4360", schoolEmail: "admissions@theclintonschool.net", faxNumber: "212-524-4365"))
    }
    
    private func testWithExpectation(vm: NYCViewModel, exp: XCTestExpectation, file: StaticString = #file, line: UInt = #line) -> [NYCSchool] {
        var schoolsToCompare = [NYCSchool]()
        vm.fetchSchools()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            _ = vm.$schools.sink { schools in
                schoolsToCompare = schools
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 5)
        return schoolsToCompare
    }
    
    private func testWithExpectationOfError<T>(vm: NYCViewModel, type: [T].Type, exp: XCTestExpectation, file: StaticString = #file, line: UInt = #line) -> CleanError where T: NYCSchool {
        var finalError: CleanError!
        vm.fetchSchools(type: type)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            _ = vm.$error.sink { error in
                guard let error = error else { return }
                finalError = error
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 5)
        return finalError
    }
    
    private class NYCSchoolSpy: NYCSchool {
        var website: String = ""
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: NYCKeys.self)
            try super.init(from: decoder)
            self.website = try container.decode(String.self, forKey: NYCKeys.website)
        }
    }
    
    private class NYCSchoolInvalidSpy: NYCSchool {
        var website: String = ""
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: NYCKeys.self)
            try super.init(from: decoder)
            self.website = try container.decode(String.self, forKey: NYCKeys.faxNumber)
        }
    }
    
    private class NYCSchoolRepositorySpy: Repository {
        var subscriptions = Set<AnyCancellable>()
        
        func fetch<T>(url: URL, forType type: [T].Type) -> Future<[T], CleanError> where T : Decodable {
            return Future<[T], CleanError> { [unowned self] promise in
                URLSession(configuration: .default).dataTaskPublisher(for: url)
                    .tryMap { (data: Data, response: URLResponse) in
                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
                            throw CleanError(rawValue: httpResponse.statusCode)!
                        }
                        return data
                    }
                    .decode(type: type,
                            decoder: JSONDecoder())
                    .receive(on: RunLoop.main)
                    .sink { completion in
                        if case let .failure(error) = completion {
                            promise(.failure(.badRequest))
                        }
                    }
            receiveValue: {
                promise(.success($0))
            }
            .store(in: &self.subscriptions)
                
            }
        }
    }
}
