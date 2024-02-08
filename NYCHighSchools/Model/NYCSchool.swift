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
        case phoneNumber = "phone_number"
        case schoolEmail = "school_email"
        case faxNumber = "fax_number"
        case website
    }
    
    var dbn: String
    var schoolName: String
    var overviewParagraph: String
    private var phoneNumber: String
    private var schoolEmail: String?
    private var faxNumber: String?
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NYCKeys.self)
        self.dbn = try container.decode(String.self, forKey: .dbn)
        self.schoolName = try container.decode(String.self, forKey: .schoolName)
        self.overviewParagraph = try container.decode(String.self, forKey: .overviewParagraph)
        self.phoneNumber = try container.decode(String.self, forKey: NYCKeys.phoneNumber)
        self.schoolEmail = try container.decodeIfPresent(String.self, forKey: NYCKeys.schoolEmail)
        self.faxNumber = try container.decodeIfPresent(String.self, forKey: NYCKeys.faxNumber)
    }
    
    internal class NYCSchoolDetails: Equatable {
        static func == (lhs: NYCSchool.NYCSchoolDetails, rhs: NYCSchool.NYCSchoolDetails) -> Bool {
            return lhs.phoneNumber == rhs.phoneNumber
        }
        
        let phoneNumber: String
        let schoolEmail: String
        let faxNumber: String
        
        init(phoneNumber: String, schoolEmail: String, faxNumber: String) {
            self.phoneNumber = phoneNumber
            self.schoolEmail = schoolEmail
            self.faxNumber = faxNumber
        }
    }
    
    
    func getDetails() -> NYCSchoolDetails {
        return NYCSchoolDetails(phoneNumber: phoneNumber, schoolEmail: schoolEmail ?? "N/A", faxNumber: faxNumber ?? "N/A")
    }
}
