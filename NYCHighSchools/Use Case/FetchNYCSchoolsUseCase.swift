//
//  FetchNYCSchoolsUseCase.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation
import Combine
import CleanArchitecture

class FetchNYCSchoolsUseCase: UseCase {
    private let repository: Repository
    
    init(repository: Repository) {
        self.repository = repository
    }
    
    func fetch<T>(url: URL, type: [T].Type) -> Future<[T], CleanError> where T : AnyObject, T : Decodable {
        return repository.fetch(url: url, forType: type)
    }
}
