//
//  RecipeMeasuredIngredientCDClient.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 6/18/24.
//

import CoreData
import Foundation

class RecipeMeasuredIngredientCDClient {
    
    /***
     Append  Measured Ingredient
     
     Appends and saves a measured ingredient for a recipe
     */
    
    static func appendMeasuredIngredient(ingredientAndMeasurement: String, to recipe: Recipe, in managedContext: NSManagedObjectContext) async throws {
        try await managedContext.perform {
            let recipeMeasuredIngredient = RecipeMeasuredIngredient(context: managedContext)
            
            recipeMeasuredIngredient.nameAndAmount = ingredientAndMeasurement
//            recipeMeasuredIngredient.nameAndAmountModified = ingredientAndMeasurement // TODO: Should I be setting this here?
            recipeMeasuredIngredient.recipe = recipe
            
            try managedContext.save()
        }
    }
    
    static func appendMeasuredIngredients(ingredientsAndMeasurements: [String], to recipe: Recipe, in managedContext: NSManagedObjectContext) async throws {
        try await managedContext.perform {
            for ingredientAndMeasurement in ingredientsAndMeasurements {
                let recipeMeasuredIngredient = RecipeMeasuredIngredient(context: managedContext)
                
                recipeMeasuredIngredient.nameAndAmount = ingredientAndMeasurement
//                recipeMeasuredIngredient.nameAndAmountModified = ingredientAndMeasurement // TODO: Should I be setting this here?
                recipeMeasuredIngredient.recipe = recipe
            }
            
            try managedContext.save()
        }
    }
    
    /***
     Count Recipe Measured Ingredients
     
     Counts all measured ingredients for a recipe
     */
    
    static func count(for recipe: Recipe, in managedContext: NSManagedObjectContext) async throws -> Int? {
        await managedContext.perform {
            recipe.measuredIngredients?.count ?? 0
        }
    }
    
    /***
     Delete All Maesured Ingredients
     
     Deletes all measured ingredients for a recipe
     */
    
    static func deleteAllMeasuredIngredients(for recipe: Recipe, in managedContext: NSManagedObjectContext) async throws {
        let fetchRequest = RecipeMeasuredIngredient.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(RecipeMeasuredIngredient.recipe), recipe)
        
        try await CDClient.delete(fetchRequest: fetchRequest, in: managedContext)
    }
    
    /***
     Delete Measured Ingredients Marked For Deletion
     
     Deletes all measured ingredients marked for deletion
     */
    static func deleteMeasuredIngredientsMarkedForDeletion(for recipe: Recipe, in managedContext: NSManagedObjectContext) async throws {
        let fetchRequest = RecipeMeasuredIngredient.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "%K = %@ AND %K = %d", #keyPath(RecipeMeasuredIngredient.recipe), recipe, #keyPath(RecipeMeasuredIngredient.markedForDeletion), true)
        
        try await CDClient.delete(fetchRequest: fetchRequest, in: managedContext)
    }
    
    /***
     Resolve Measured Ingredients
     
     Sets all ingredients with nameAndAmountModified not nil or empty nameAndAmount to nameAndAmountModified and nameAndAmountModified to nil
     */
    
    static func resolveMeasuredIngredients(for recipe: Recipe, in managedContext: NSManagedObjectContext) async throws {
        try await managedContext.perform {
            let fetchRequest = RecipeMeasuredIngredient.fetchRequest()
            
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(RecipeMeasuredIngredient.recipe), recipe)
            
            for result in try managedContext.fetch(fetchRequest) {
                if result.nameAndAmountModified != nil && !result.nameAndAmountModified!.isEmpty {
                    result.nameAndAmount = result.nameAndAmountModified!
                    result.nameAndAmountModified = nil
                }
            }
            
            try managedContext.save()
        }
    }
    
}
