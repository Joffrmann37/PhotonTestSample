//
//  NYCSchoolService.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation
import Combine

enum SchoolError: Int, Swift.Error {
    case badRequest = 400
    case forbidden = 403
    case notFound = 404
    case serverError = 500
    case notAcceptable = 406
}

public class NYCSchoolRepository {
    var subscriptions = Set<AnyCancellable>()
    
    func fetchSchools<T>(url: URL, forType type: [T].Type) -> Future<[T], CleanError> where T : NYCSchool {
        fetch(url: url, forType: type)
    }
}

extension NYCSchoolRepository: Repository {
    public func fetch<T>(url: URL, forType type: [T].Type) -> Future<[T], CleanError> where T : Decodable {
        return Future<[T], CleanError> { [unowned self] promise in
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
                    if case let .failure(error) = completion, let error = error as? CleanError {
                        promise(.failure(error))
                    }
                }
        receiveValue: {
            promise(.success($0))
        }
        .store(in: &self.subscriptions)
            
        }
    }
}
