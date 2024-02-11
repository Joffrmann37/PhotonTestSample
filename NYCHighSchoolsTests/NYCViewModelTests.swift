//
//  NYCViewModelTests.swift
//  NYCHighSchoolsTests
//
//  Created by Joffrey Mann on 2/7/24.
//

import XCTest
@testable import NYCHighSchools
import Combine

final class NYCViewModelTests: XCTestCase {
    func test_DidGetSchoolsJSON() {
        let vm = NYCViewModelSpy(useCase: FetchNYCSchoolsUseCase(repository: NYCSchoolRepositorySpy()))
        let exp = expectation(description: "Wait for task")
        let expectedSchools = testWithExpectation(vm: vm, exp: exp)
        XCTAssertTrue(expectedSchools.count > 0)
    }
    
    func test_CouldNotReadData() {
        let vm = NYCViewModelSpy(useCase: FetchNYCSchoolsUseCase(repository: NYCSchoolRepositorySpy()))
        let exp = expectation(description: "Wait for task")
        let error = testWithExpectationOfError(vm: vm, type: [NYCSchoolInvalidSpy].self, exp: exp)
        XCTAssertEqual(error, vm.error)
    }
    
    func test_InvalidURL() {
        let vm = NYCViewModelSpy(useCase: FetchNYCSchoolsUseCase(repository: NYCSchoolRepositorySpy()), url: URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.js")!)
        let exp = expectation(description: "Wait for task")
        let error = testWithExpectationOfError(vm: vm, type: [NYCSchoolSpy].self, exp: exp)
        XCTAssertEqual(error, vm.error)
    }
    
    func test_DidGetSchoolDetails() {
        let vm = NYCViewModelSpy(useCase: FetchNYCSchoolsUseCase(repository: NYCSchoolRepositorySpy()))
        let exp = expectation(description: "Wait for task")
        let schools = testWithExpectation(vm: vm, exp: exp)
        XCTAssertEqual(schools[0].getDetails(), NYCSchoolSpy.NYCSchoolDetails(phoneNumber: "212-524-4360", schoolEmail: "admissions@theclintonschool.net", faxNumber: "212-524-4365"))
    }
    
    private func testWithExpectation(vm: NYCViewModelSpy, exp: XCTestExpectation, file: StaticString = #file, line: UInt = #line) -> [NYCSchool] {
        var schoolsToCompare = [NYCSchool]()
        vm.fetchSchools()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            _ = vm.$schools.sink { schools in
                schoolsToCompare = schools
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 3)
        return schoolsToCompare
    }
    
    private func testWithExpectationOfError<T>(vm: NYCViewModelSpy, type: [T].Type, exp: XCTestExpectation, file: StaticString = #file, line: UInt = #line) -> SchoolError where T: NYCSchool {
        var finalError: SchoolError!
        vm.fetchSchools(type: type)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            _ = vm.$error.sink { error in
                guard let error = error else { return }
                finalError = error
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 3)
        return finalError
    }
    
    private class NYCViewModelSpy: NYCViewModel {
        private var subscriptions = Set<AnyCancellable>()
        
        override init(useCase: FetchNYCSchoolsUseCase, url: URL = URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.json")!) {
            super.init(useCase: useCase, url: url)
            self.useCase = useCase
            self.url = url
        }
        
        override func fetchSchools<T>(type: [T].Type = [NYCSchool].self) where T : NYCSchool {
            return useCase.fetchSchools(url: url, type: type).sink { [unowned self] completion in
                if case let .failure(error) = completion {
                    self.error = error
                }
            } receiveValue: { [weak self] schoolArr in
                guard let self = self else { return }
                self.schools = schoolArr
            }.store(in: &subscriptions)
        }
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
    
    private class NYCSchoolRepositorySpy: Serviceable {
        var subscriptions = Set<AnyCancellable>()
        
        func fetch<T: Decodable>(url: URL, forType type: [T].Type) -> Future<[T], SchoolError> {
            return Future<[T], SchoolError> { [unowned self] promise in
                URLSession(configuration: .default).dataTaskPublisher(for: url)
                    .tryMap { (data: Data, response: URLResponse) in
                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
                            throw SchoolError(rawValue: httpResponse.statusCode)!
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
