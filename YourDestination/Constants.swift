//
//  Constants.swift
//  YourDestination
//
//  Created by Geek on 4/23/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import Foundation

struct Constants{
//?query=Lawson+Jebl+Akihabara+Square+Shop&location=35.701373,139.774786&key=AIzaSyCUv6toYbNQ5QD23aLS4GVmAiHy8i361Mc
    struct Destination {
        static let APIScheme = "https"
        static let APIHost = "maps.googleapis.com"
        static let APIPath = "/maps/api/place/nearbysearch/json"
    }
    
    struct GetIcon {
        static let APIScheme = "https"
        static let APIHost = "maps.googleapis.com"
        static let APIPath = "/maps/api/place/textsearch/json"
    }
    
    struct GetIconParameterKeys {
        static let APIKey = "key"
        static let location = "location"
        static let query = "query"
    }
    
    struct GetIconParameterValues{
        static let APIKey = "AIzaSyC6WcSFzYtaIflWjd-ZwFnMbU1OV_H6Yao"
    }
    
    struct DestinationParameterKeys {
        static let APIKey = "key"
        static let location = "location"
        static let sensor = "sensor"
        static let type = "type"
        static let radius = "radius"
    }
    
    struct DestinationParameterValues{
        static let APIKey = "AIzaSyC6WcSFzYtaIflWjd-ZwFnMbU1OV_H6Yao"
        static let sensor = "true"
    }
    
    enum Types: String, CaseIterable{
        case museum
        case bank
    }
    
    enum Radius: String, CaseIterable{
        case radius1 = "1000"
        case radius2 = "5000"
    }
}

