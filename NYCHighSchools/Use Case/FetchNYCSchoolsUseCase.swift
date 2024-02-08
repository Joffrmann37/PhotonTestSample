//
//  FetchNYCSchoolsUseCase.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation

class FetchNYCSchoolsUseCase {
    let repository: NYCSchoolRepository
    
    init(repository: NYCSchoolRepository) {
        self.repository = repository
    }
    
    func fetchSchools(url: URL, completionHandler: @escaping (SchoolResult) -> Void) {
        repository.fetchSchools(url: url, completionHandler: completionHandler)
    }
}
