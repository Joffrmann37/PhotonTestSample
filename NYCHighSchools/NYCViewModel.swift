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
    
    let service: Serviceable
    @Published var schools = [NYCSchool]()
    var error: SchoolError?
    
    init(service: Serviceable) {
        self.service = service
        fetchSchools()
    }
    
    func fetchSchools() {
        service.fetchSchools { result in
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
