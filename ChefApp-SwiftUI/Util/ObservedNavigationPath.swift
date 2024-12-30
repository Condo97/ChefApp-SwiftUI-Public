//
//  ObservedNavigationPath.swift
//  Barback
//
//  Created by Alex Coundouriotis on 9/23/23.
//

import Foundation
import SwiftUI

class ObservedNavigationPath: ObservableObject {
    
    @Published var navigationPath: NavigationPath = NavigationPath()
    
    func clear() {
        navigationPath.removeLast(navigationPath.count)
    }
    
}
