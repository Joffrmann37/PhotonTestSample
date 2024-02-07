//
//  DetailView.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import SwiftUI

struct DetailView: View {
    var school: NYCSchool
    
    var body: some View {
        NavigationView {
            Text(school.overviewParagraph)
        }
        .navigationTitle(school.schoolName)
    }
}
