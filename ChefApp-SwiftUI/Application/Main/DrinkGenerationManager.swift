////
////  DrinkGenerationManager.swift
////  Barback
////
////  Created by Alex Coundouriotis on 9/21/23.
////
//
//import Combine
//import CoreData
//import Foundation
//import SwiftUI
//
//class DrinkGenerationManager: ObservableObject {
//    
//    @Published var drinkObjectID: NSManagedObjectID?
//    
//    func create(ingredients: String, modifiers: String? = nil, expandIngredientsMagnitude: Int = 1) async throws {
//        // TODO: Comment and fix this lol, fix the ingredients and modifiers thing
//        guard let authToken = AuthHelper.get() else {
//            // TODO: Handle errors
//            print("Could not unwrap authToken when creating drink in DrinkGenerationManager!")
//            return
//        }
//        
//        DispatchQueue.main.async {
//            self.drinkObjectID = nil
//        }
//        
//        let drinkID = try await BarbackNetworkPersistenceManager.createSaveDrink(
//            authToken: authToken,
//            ingredients: ingredients,
//            modifiers: modifiers,
//            expandIngredientsMagnitude: expandIngredientsMagnitude)
//        
//        let newDrinkObjectID = try await DrinkCDClient.getDrinkPermanentID(drinkID: drinkID)
//        
//        DispatchQueue.main.async {
//            self.drinkObjectID = newDrinkObjectID
//        }
//        
//        do {
//            if let drinkID = try await DrinkCDClient.getDrinkID(drinkObjectID: newDrinkObjectID) {
//                Task {
//                    do {
//                        try await BarbackNetworkPersistenceManager.finalizeSaveDrink(
//                            authToken: authToken,
//                            drinkID: drinkID)
//                    } catch {
//                        // TODO: Handle errors
//                        print("Error finalizing saving drink in create in DrinkGenerationManager... \(error)")
//                    }
//                }
//                
//                Task {
//                    do {
//                        try await BarbackNetworkPersistenceManager.getSaveGlassColor(
//                            authToken: authToken,
//                            drinkID: Int(drinkID),
//                            to: newDrinkObjectID)
//                    }
//                }
//                
//                Task {
//                    do {
//                        try await BarbackNetworkPersistenceManager.getSaveGlass(
//                            authToken: authToken,
//                            drinkID: Int(drinkID),
//                            to: newDrinkObjectID)
//                    } catch {
//                        // TODO: Handle errors
//                        print("Error saving glass in create in DrinkGenerationManager... \(error)")
//                    }
//                }
//            } else {
//                // TODO: Handle errors
//                print("Could not unwrap drinkID from DrinkCDClient getDrinkID in create in DrinkGenerationManager!")
//            }
//        } catch {
//            // TODO: Handle errors
//            print("Error getting drink ID in create in DrinkGenerationManager... \(error)")
//        }
//    }
//    
//}
