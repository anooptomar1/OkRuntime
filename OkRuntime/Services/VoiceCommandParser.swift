//
//  VoiceCommandParser.swift
//  OkRuntime
//
//  Created by Sarat Karumuri on 12/15/16.
//  Copyright © 2016 Gagandeep Singh. All rights reserved.
//

import Foundation

public enum actions : Int {
    case unknown
    case whereAm
    case housesForSale
    case houseBedroomFilter
    case showSchools
    case schoolFilter
    case houseSchoolFilter
    case houseStreetFilter
    case zoomToSchool
    case wrongQuery
}

public class VoiceCommandParser:NSObject {

    func parseQuery (query:String) -> actions
    {
        //   let lowercaseQuery = query.lowercased()
        if ((query.lowercased().contains("where") && query.lowercased().contains("am")) || query.lowercased().contains("where am")) {
            return actions.whereAm
        }
        if (query.lowercased().contains("houses") && query.lowercased().contains("sale")){
            return actions.housesForSale
        }
        
        if (query.lowercased().contains("houses") && query.lowercased().contains("bedroom")){
            return actions.houseBedroomFilter
        }
        
        if (query.lowercased().contains("schools") && query.lowercased().contains("area")){
            return actions.showSchools
        }
        
        if ((query.lowercased().contains("mckinley") && query.lowercased().contains("elementry")) ||
            query.lowercased().contains("mckinley elementary")) {
            return actions.schoolFilter
        }
        if (query.lowercased().contains("within") && query.lowercased().contains("school")){
            return actions.houseSchoolFilter
        }
        if (query.lowercased().contains("street") || query.lowercased().contains("avenue") || query.lowercased().contains("boulevard") || query.lowercased().contains("blvd") || query.lowercased().contains("st") || query.lowercased().contains("ave")){
            return actions.houseStreetFilter
        }
        
        return actions.wrongQuery
    }
    
}
