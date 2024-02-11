//
//  FetchNYCSchoolsUseCase.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation
import Combine

class FetchNYCSchoolsUseCase {
    let repository: Serviceable
    
    init(repository: Serviceable) {
        self.repository = repository
    }
    
    func fetchSchools<T: Decodable>(url: URL, type: [T].Type = [NYCSchool].self) -> Future<[T], SchoolError> where T: NYCSchool  {
        return repository.fetch(url: url, forType: type)
    }
}
