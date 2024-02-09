//
//  NYCSchoolService.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation
import Combine

enum SchoolResult: Equatable {
    case success([NYCSchool])
    case failure(SchoolError)
}

enum SchoolError: Swift.Error {
    case noData
    case invalidData
    case connectivity
    case serverError
}

class NYCSchoolRepository {
    var subscriptions = Set<AnyCancellable>()
    
    func fetchSchools(url: URL) -> Future<[NYCSchool], SchoolError> {
        return Future<[NYCSchool], SchoolError> { [unowned self] promise in
            URLSession(configuration: .default).dataTaskPublisher(for: url)
                .tryMap { (data: Data, response: URLResponse) in
                    guard let httpResponse = response as? HTTPURLResponse,
                          200...299 ~= httpResponse.statusCode
                    else {
                        throw SchoolError.serverError
                    }
                    return data
                }
                .decode(type: [NYCSchool].self,
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
