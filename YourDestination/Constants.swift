//
//  Constants.swift
//  YourDestination
//
//  Created by Geek on 4/23/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import Foundation

struct Constants{
    
    struct Destination {
        static let APIScheme = "https"
        static let APIHost = "maps.googleapis.com"
        static let APIPath = "/maps/api/place/nearbysearch/json"
    }
    
    struct DestinationParameterKeys {
        static let APIKey = "key"
        static let location = "location"
        static let sensor = "sensor"
        static let type = "type"
        static let radius = "radius"
    }
    
    struct DestinationParameterValues{
        static let APIKey = "AIzaSyCS0BOTvvFk2o-buT3NZzsvP2CNIcPUc1U"
        static let sensor = "true"
    }
    
    enum Types: String, CaseIterable{
        case mosque
        case bank
    }
    
    enum Radius: String, CaseIterable{
        case radius1 = "1000"
        case radius2 = "5000"
    }
}

