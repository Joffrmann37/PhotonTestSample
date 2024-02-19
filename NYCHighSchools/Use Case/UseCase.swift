//
//  FetchNYCSchoolsUseCase.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation
import Combine

public protocol UseCase {
    func fetch<T: Decodable>(url: URL, type: [T].Type) -> Future<[T], CleanError> where T: AnyObject
}
