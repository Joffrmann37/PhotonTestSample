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
        let vm = NYCViewModelSpy(useCase: FetchNYCSchoolsUseCaseSpy(repository: NYCSchoolRepositorySpy()))
        let exp = expectation(description: "Wait for task")
        let expectedSchools = testWithExpectation(vm: vm, exp: exp)
        XCTAssertTrue(expectedSchools.count > 0)
    }
    
    func test_CouldNotReadData() {
        let vm = NYCViewModelSpy(useCase: FetchNYCSchoolsUseCaseSpy(repository: NYCSchoolRepositorySpy(shouldFail: true)))
        let exp = expectation(description: "Wait for task")
        let error = testWithExpectationOfError(vm: vm, exp: exp)
        XCTAssertEqual(error, vm.error)
    }
    
    func test_InvalidURL() {
        let vm = NYCViewModelSpy(useCase: FetchNYCSchoolsUseCaseSpy(repository: NYCSchoolRepositorySpy()), url: URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.js")!)
        let exp = expectation(description: "Wait for task")
        let error = testWithExpectationOfError(vm: vm, exp: exp)
        XCTAssertEqual(error, vm.error)
    }
    
    func test_DidGetSchoolDetails() {
        let vm = NYCViewModelSpy(useCase: FetchNYCSchoolsUseCaseSpy(repository: NYCSchoolRepositorySpy()))
        let exp = expectation(description: "Wait for task")
        let schools = testWithExpectation(vm: vm, exp: exp)
        XCTAssertEqual(schools[0].getDetails(), NYCSchoolSpy.NYCSchoolDetails(phoneNumber: "212-524-4360", schoolEmail: "admissions@theclintonschool.net", faxNumber: "212-524-4365"))
    }
    
    
    private func result(expectedResult: SchoolResult) -> SchoolResult {
        switch expectedResult {
        case .success(let array):
            return .success(array)
        case .failure(let schoolError):
            return .failure(schoolError)
        }
    }
    
    private func testWithExpectation(vm: NYCViewModelSpy, exp: XCTestExpectation, file: StaticString = #file, line: UInt = #line) -> [NYCSchool] {
        var schoolsToCompare = [NYCSchool]()
        vm.fetch()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            _ = vm.$schools.sink { schools in
                schoolsToCompare = schools
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 3)
        return schoolsToCompare
    }
    
    private func testWithExpectationOfError(vm: NYCViewModelSpy, exp: XCTestExpectation, file: StaticString = #file, line: UInt = #line) -> SchoolError {
        var finalError: SchoolError!
        vm.fetch()
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
        
        init(useCase: FetchNYCSchoolsUseCaseSpy, url: URL = URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.json")!) {
            super.init(useCase: useCase, url: url)
            self.url = url
        }
        
        func fetch() {
            (useCase as! FetchNYCSchoolsUseCaseSpy).fetchSpySchools(url: url).sink { [unowned self] completion in
                if case let .failure(error) = completion {
                    self.error = error
                }
            } receiveValue: { [weak self] schoolArr in
                guard let self = self else { return }
                self.schools = schoolArr
            }.store(in: &subscriptions)
        }        
    }
    
    class NYCSchoolSpy: NYCSchool {
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
    
    private class FetchNYCSchoolsUseCaseSpy: FetchNYCSchoolsUseCase {
        func fetchSpySchools(url: URL) -> Future<[NYCSchoolSpy], SchoolError> {
            return (repository as! NYCSchoolRepositorySpy).fetchSpySchools(url: url)
        }
    }
    
    private class NYCSchoolRepositorySpy: NYCSchoolRepository {
        let shouldFail: Bool
        
        init(shouldFail: Bool = false) {
            self.shouldFail = shouldFail
        }
        
        func fetchSpySchools(url: URL) -> Future<[NYCSchoolSpy], SchoolError> {
            if shouldFail {
                return Future<[NYCSchoolSpy], SchoolError> { [unowned self] promise in
                    URLSession(configuration: .default).dataTaskPublisher(for: url)
                        .tryMap { (data: Data, response: URLResponse) in
                            guard let httpResponse = response as? HTTPURLResponse,
                                  200...299 ~= httpResponse.statusCode
                            else {
                                throw SchoolError.serverError
                            }
                            return data
                        }
                        .decode(type: [NYCSchoolFailableSpy].self,
                                decoder: JSONDecoder())
                        .receive(on: RunLoop.main)
                        .sink { completion in
                            if case let .failure(error) = completion {
                                promise(.failure(.invalidData))
                            }
                        }
                receiveValue: {
                    promise(.success($0))
                }
                .store(in: &self.subscriptions)
                    
                }
            } else {
                return Future<[NYCSchoolSpy], SchoolError> { [unowned self] promise in
                    URLSession(configuration: .default).dataTaskPublisher(for: url)
                        .tryMap { (data: Data, response: URLResponse) in
                            guard let httpResponse = response as? HTTPURLResponse,
                                  200...299 ~= httpResponse.statusCode
                            else {
                                throw SchoolError.serverError
                            }
                            return data
                        }
                        .decode(type: [NYCSchoolSpy].self,
                                decoder: JSONDecoder())
                        .receive(on: RunLoop.main)
                        .sink { completion in
                            if case let .failure(error) = completion {
                                promise(.failure(.invalidData))
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
}
