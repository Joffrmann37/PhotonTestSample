//
//  NYCViewModel.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation
import Combine

enum FetchStrategy: Int, Codable {
    case immediate = 1, onCommand
}

class NYCViewModel: ObservableObject {
    var shouldFetchOnInit = true
    
    var useCase: FetchNYCSchoolsUseCase
    private var subscriptions = Set<AnyCancellable>()
    var url: URL = URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.json")!
    @Published var schools = [NYCSchool]()
    @Published var error: SchoolError?
    var fetchStrategy: FetchStrategy = .immediate
    
    init(useCase: FetchNYCSchoolsUseCase, url: URL = URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.json")!, fetchStrategy: FetchStrategy = .immediate) {
        self.useCase = useCase
        if fetchStrategy == .immediate {
            fetchSchools()
        }
    }
        
    private func fetchSchools() {
        useCase.fetchSchools(url: url).sink { [unowned self] completion in
            if case let .failure(error) = completion {
                self.error = error
            }
        } receiveValue: { [weak self] schoolArr in
            guard let self = self else { return }
            self.schools = schoolArr.map{ NYCSchool(dbn: $0.dbn, schoolName: $0.schoolName, overviewParagraph: $0.overviewParagraph) }
        }.store(in: &subscriptions)
    }
}