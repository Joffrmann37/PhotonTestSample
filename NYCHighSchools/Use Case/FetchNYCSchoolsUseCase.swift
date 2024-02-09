//
//  FetchNYCSchoolsUseCase.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation
import Combine

class FetchNYCSchoolsUseCase {
    let repository: NYCSchoolRepository
    
    init(repository: NYCSchoolRepository) {
        self.repository = repository
    }
    
    func fetchSchools(url: URL) -> Future<[NYCSchool], SchoolError>  {
        return repository.fetchSchools(url: url)
    }
}
