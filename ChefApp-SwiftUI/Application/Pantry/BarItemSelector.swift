//
//  PantryItemSelector.swift
//  Barback
//
//  Created by Alex Coundouriotis on 10/10/23.
//

import Foundation
import SwiftUI

protocol PantryItemSelector {
    
    var selectedItems: Binding<[PantryItem]> { get set }
    var deselectedItems: Binding<[PantryItem]> { get set }
    
}
