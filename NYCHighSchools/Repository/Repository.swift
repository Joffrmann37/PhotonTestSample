//
//  NYCSchoolService.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation
import Combine

public enum CleanError: Int, Swift.Error {
    case badRequest = 400
    case forbidden = 403
    case notFound = 404
    case serverError = 500
    case notAcceptable = 406
}

public protocol Repository {
    func fetch<T: Decodable>(url: URL, forType type: [T].Type) -> Future<[T], CleanError>
}
