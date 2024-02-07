//
//  NYCViewModel.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation

class NYCViewModel: ObservableObject, Equatable {
    static func == (lhs: NYCViewModel, rhs: NYCViewModel) -> Bool {
        lhs.schools == rhs.schools
    }
    
    var service: Serviceable
    @Published var schools = [NYCSchool]()
    var error: SchoolError?
    
    init(service: Serviceable) {
        self.service = service
        fetchSchools()
    }
    
    func fetchSchools() {
        service.fetchSchools(url: URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.json")!) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let array):
                    self.schools = array
                case .failure(let schoolError):
                    self.error = schoolError
                }
            }
        }
    }
}
