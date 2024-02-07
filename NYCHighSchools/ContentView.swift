//
//  ContentView.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var vm = NYCViewModel(service: NYCSchoolService())
    
    var body: some View {
        NavigationView {
                List {
                    ForEach($vm.schools) { school in
                        let name = school.wrappedValue.schoolName
                        let dbn = school.wrappedValue.dbn
                        NavigationLink(destination: DetailView(school: school.wrappedValue)) {
                            VStack(spacing: 10, content: {
                                Text(name)
                                Text(dbn)
                            })
                        }
                        .navigationBarTitle("NYC Schools")
                    }
                }
            .navigationBarTitle("NYC Schools List")
        }
    }
}

#Preview {
    ContentView()
}
