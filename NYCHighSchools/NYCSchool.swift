//
//  NYCSchool.swift
//  NYCHighSchools
//
//  Created by Joffrey Mann on 2/7/24.
//

import Foundation

class NYCSchool: Codable, Identifiable, Equatable {
    static func == (lhs: NYCSchool, rhs: NYCSchool) -> Bool {
        return lhs.dbn == rhs.dbn
    }
    
    enum NYCKeys: String, CodingKey {
        case dbn
        case schoolName = "school_name"
        case overviewParagraph = "overview_paragraph"
    }
    
    var dbn: String
    var schoolName: String
    var overviewParagraph: String
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NYCKeys.self)
        self.dbn = try container.decode(String.self, forKey: .dbn)
        self.schoolName = try container.decode(String.self, forKey: .schoolName)
        self.overviewParagraph = try container.decode(String.self, forKey: .overviewParagraph)
    }
}
