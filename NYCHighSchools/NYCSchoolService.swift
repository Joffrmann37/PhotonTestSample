//
//  NYCSchoolService.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation

enum SchoolResult: Equatable {
    case success([NYCSchool])
    case failure(SchoolError)
}

enum SchoolError: Swift.Error {
    case noData
    case invalidData
    case connectivity
}

protocol Serviceable {
    func fetchSchools(completionHandler: @escaping (SchoolResult) -> Void)
}

class NYCSchoolService: Serviceable {
    func fetchSchools(completionHandler: @escaping (SchoolResult) -> Void) {
        let task = URLSession(configuration: .default).dataTask(with: URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.json")!) { data, response, error in
            guard let data = data else {
                print("No data")
                completionHandler(.failure(.noData))
                return
            }
            do {
                let schools = try JSONDecoder().decode([NYCSchool].self, from: data)
                completionHandler(.success(schools))
            } catch {
                print(error.localizedDescription)
                completionHandler(.failure(.invalidData))
            }
        }
        task.resume()
    }
}
