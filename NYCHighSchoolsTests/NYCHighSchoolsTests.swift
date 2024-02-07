//
//  NYCHighSchoolsTests.swift
//  NYCHighSchoolsTests
//
//  Created by Joffrey Mann on 2/7/24.
//

import XCTest
@testable import NYCHighSchools

final class NYCHighSchoolsTests: XCTestCase {
    func test_DidGetSchoolsJSON() {
        let exp = expectation(description: "Wait for task")
        let vm = NYCViewModelSpy(service: NYCSchoolService())
        var finalResult: SchoolResult!
        var schools = [NYCSchool]()
        vm.fetch { result in
            finalResult = result
            switch result {
            case .success(let array):
                schools = array
            case .failure(let schoolError):
                print(schoolError.localizedDescription)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(finalResult, .success(schools))
    }
    
    private class NYCViewModelSpy: NYCViewModel {
        func fetch(completionHandler: @escaping (SchoolResult) -> Void) {
            service.fetchSchools(completionHandler: completionHandler)
        }
    }
}
