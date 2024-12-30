//
//  Keys.swift
//  PantryPal
//
//  Created by Alex Coundouriotis on 7/1/23.
//

import CryptoSwift
import Foundation

struct Keys {
    
    struct AppsFlyer {
        static let appKey: String
        static let devKey: String
    }
    
    static var BING_API_KEY: String
    
    struct GAD {
        
        struct Interstitial {
            
            static let mainContainerGenerate: String
            static let panelViewGenerate: String
            
        }
        
        static let ADMOB_APP_ID: String
        
        static let BANNER_AD_MAIN_UNIT_ID: String
        static let INTERSTITIAL_AD_MAIN_UNIT_ID: String
    }
    
}
