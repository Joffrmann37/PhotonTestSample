//
//  NYCViewModel.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation
import Combine

class NYCViewModel: ObservableObject {
    private let useCase: UseCase
    private var subscriptions = Set<AnyCancellable>()
    var url: URL = URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.json")!
    @Published var schools = [NYCSchool]()
    @Published var error: CleanError?
    
    init(useCase: UseCase, url: URL = URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.json")!) {
        self.useCase = useCase
        self.url = url
    }
        
    func fetchSchools<T>(type: [T].Type = [NYCSchool].self) where T: NYCSchool {
        useCase.fetch(url: url, type: type).sink { [unowned self] completion in
            if case let .failure(error) = completion {
                self.error = error
            }
        } receiveValue: { [weak self] schoolArr in
            guard let self = self else { return }
            self.schools = schoolArr
        }.store(in: &subscriptions)
    }
}
