//
//  ContentView.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var vm = NYCViewModel(useCase: FetchNYCSchoolsUseCase(repository: NYCSchoolRepository()))
    
    var body: some View {
        NavigationView {
                List {
                    ForEach($vm.schools) { school in
                        let name = school.wrappedValue.schoolName
                        let dbn = school.wrappedValue.dbn
                        NavigationLink(destination: DetailView(school: school.wrappedValue)) {
                            VStack(spacing: 10, content: {
                                Text(name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(dbn)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            })
                        }
                        .navigationBarTitle("NYC Schools")
                    }
                }
            .navigationBarTitle("NYC Schools List")
        }
        .onAppear {
            vm.fetchSchools()
        }
    }
}

#Preview {
    ContentView()
}
