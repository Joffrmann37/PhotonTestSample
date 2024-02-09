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
            VStack (spacing: 20, content: {
                Text("Phone number: \(school.getDetails().phoneNumber)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("E-mail: \(school.getDetails().schoolEmail)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Fax number: \(school.getDetails().faxNumber)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(school.overviewParagraph)
            }).padding(.top, -200)
        }
        .navigationTitle(school.schoolName)
    }
}
