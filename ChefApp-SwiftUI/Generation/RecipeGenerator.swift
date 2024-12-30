//
//  RecipeGenerator.swift
//  Barback
//
//  Created by Alex Coundouriotis on 9/25/23.
//

import CoreData
import Foundation
import SwiftUI

class RecipeGenerator: ObservableObject {
    
//    @Published var createdRecipes: [Recipe] = []
    @Published var isCapReached: Bool = false
    @Published var isCreating: Bool = false
    @Published var isFinalizing: Bool = false
    @Published var isGeneratingTags: Bool = false
    @Published var isGeneratingBingImage: Bool = false
    @Published var isRegeneratingDirections: Bool = false
    @Published var isGeneratingIngredientsPreview: Bool = false
    
    func create(
        ingredients: String,
        modifiers: String?,
        expandIngredientsMagnitude: Int,
        in viewContext: NSManagedObjectContext
    ) async throws -> Recipe {
        try await create(
            ingredients: ingredients,
            modifiers: modifiers,
            expandIngredientsMagnitude: expandIngredientsMagnitude,
            dailyRecipe_isDailyRecipe: false,
            dailyRecipe_timeFrameID: nil,
            in: viewContext)
    }
    
    func create(
        ingredients: String,
        modifiers: String?,
        expandIngredientsMagnitude: Int,
        dailyRecipe_isDailyRecipe: Bool,
        dailyRecipe_timeFrameID: String?,
        in viewContext: NSManagedObjectContext
    ) async throws -> Recipe {
        // Set isCreating to false once this method completes
        defer {
            DispatchQueue.main.async {
                self.isCreating = false
            }
        }
        
        // Set isCreating to true and isCapReached to false
        await MainActor.run {
            self.isCreating = true
            self.isCapReached = false
        }
        
        // Get authToken with AuthHelper ensure
        let authToken: String
        do {
            authToken = try await AuthHelper.ensure()
        } catch {
            // TODO: Handle errors
            print("Error ensuring authToken when creating Recipe in RecipeGenerator... \(error)")
            throw GenerationError.auth
        }
        
        // Create and save and return recipe
        do {
            return try await ChefAppNetworkPersistenceManager.createSaveRecipe(
                authToken: authToken,
                ingredients: ingredients,
                modifiers: modifiers,
                expandIngredientsMagnitude: expandIngredientsMagnitude,
                dailyRecipe_isDailyRecipe: dailyRecipe_isDailyRecipe,
                dailyRecipe_timeFrameID: dailyRecipe_timeFrameID,
                in: viewContext)
        } catch NetworkingError.capReachedError {
            await MainActor.run {
                isCapReached = true
            }
            
            throw NetworkingError.capReachedError
        }
    }
    
    func finalize(
        recipe: Recipe,
        additionalInput: String?,
        in viewContext: NSManagedObjectContext
    ) async throws {
//        // Ensure is not finalizing, otherwise return
//        guard !isFinalizing else {
//            return
//        }
        
        // Set isFinalizing to false once this method completes
        defer {
            DispatchQueue.main.async {
                self.isFinalizing = false
            }
        }
        
        // Set isFinalizing to true and isCapReached to false
        DispatchQueue.main.async {
            self.isFinalizing = true
            self.isCapReached = false
        }
        
        // Get authToken with AuthHelper ensure
        let authToken: String
        do {
            authToken = try await AuthHelper.ensure()
        } catch {
            // TODO: Handle errors
            print("Error ensuring authToken when finalizing Recipe in RecipeGenerator... \(error)")
            return
        }
        
        // Finalize and save recipe
        try await ChefAppNetworkPersistenceManager.finalizeUpdateRecipe(
            authToken: authToken,
            recipe: recipe,
            additionalInput: additionalInput,
            in: viewContext)
    }
    
    func generateTags(
        recipe: Recipe,
        in viewContext: NSManagedObjectContext
    ) async throws {
        // Set isGeneratingTags to false once this method completes
        defer {
            DispatchQueue.main.async {
                self.isGeneratingTags = false
            }
        }
        
        // Set isGeneratingTags to true
        DispatchQueue.main.async {
            self.isGeneratingTags = true
        }
        
        // Get authToken with AuthHelper ensure
        let authToken: String
        do {
            authToken = try await AuthHelper.ensure()
        } catch {
            // TODO: Handle errors
            print("Error ensuring authToken when finalizing Recipe in RecipeGenerator... \(error)")
            return
        }
        
        // Generate and save tags
        try await ChefAppNetworkPersistenceManager.generateSaveTags(
            authToken: authToken,
            recipe: recipe,
            in: viewContext)
    }
    
    func generateBingImage(
        recipe: Recipe,
        in viewContext: NSManagedObjectContext
    ) async throws {
        // Set isGeneratingBingImage to false once this method completes
        defer {
            DispatchQueue.main.async {
                self.isGeneratingBingImage = false
            }
        }
        
        // Set isGeneratingBingImage to true
        DispatchQueue.main.async {
            self.isGeneratingBingImage = true
        }
        
        // Get authToken with AuthHelper ensure
        let authToken: String
        do {
            authToken = try await AuthHelper.ensure()
        } catch {
            // TODO: Handle errors
            print("Error ensuring authToken when finalizing Recipe in RecipeGenerator... \(error)")
            return
        }
        
        // Generate save first bing image
        try await ChefAppNetworkPersistenceManager.generateSaveFirstBingImage(
            recipe: recipe,
            in: viewContext)
        
        // Save image URL to server
        do {
            try await ChefAppNetworkPersistenceManager.saveRecipeImageURL(
                authToken: authToken,
                recipe: recipe,
                in: viewContext)
        } catch {
            // TODO: Handle Errors
            print("Error saving recipe image URL to server RecipeGenerator, continuing... \(error)")
        }
    }
    
    func regenerateDirectionsAndResolveUpdatedIngredients(
        for recipe: Recipe,
        additionalInput: String,
        in managedContext: NSManagedObjectContext
    ) async throws {
//        // Ensure is not regenerating already, otherwise return
//        guard !isRegeneratingDirections else {
//            return
//        }
        
        // Set isRegeneratingDirections to false once this method completes
        defer {
            DispatchQueue.main.async {
                self.isRegeneratingDirections = false
            }
        }
        
        // Set isRegeneratingDirections to true
        DispatchQueue.main.async {
            self.isRegeneratingDirections = true
        }
        
        // Get authToken with AuthHelper ensure
        let authToken: String
        do {
            authToken = try await AuthHelper.ensure()
        } catch {
            // TODO: Handle errors
            print("Error ensuring authToken when regenerating directions in RecipeGenerator... \(error)")
            return
        }
        
        // Get and save regenerated directions
        try await ChefAppNetworkPersistenceManager.regenerateSaveMeasuredIngredientsAndDirectionsAndResolveUpdatedIngredients(authToken: authToken, recipe: recipe, additionalInput: additionalInput, in: managedContext)
    }
    
//    func getRecipeIngredientsPreview(RecipeID: Int64) async throws {
//        // Ensure is not generating Recipe ingredients preview already, otherwise return
//        guard !isGeneratingIngredientsPreview else {
//            return
//        }
//        
//        // Set isGeneratingIngredientsPreview to false once this method completes
//        defer {
//            DispatchQueue.main.async {
//                self.isGeneratingIngredientsPreview = false
//            }
//        }
//        
//        // Set isGeneratingIngredientsPreview to true
//        DispatchQueue.main.async {
//            self.isGeneratingIngredientsPreview = true
//        }
//        
//        // Get authToken with AuthHelper ensure
//        let authToken: String
//        do {
//            authToken = try await AuthHelper.ensure()
//        } catch {
//            // TODO: Handle errors
//            print("Error ensuring authToken when getting Recipe ingredients preview in RecipeGenerator... \(error)")
//            return
//        }
//        
//        // Get permanent Recipe object id
//        let RecipeObjectID = try await RecipeCDClient.getRecipePermanentID(RecipeID: RecipeID)
//        
//        // Get and save Recipe ingredients preview
//        try await ChefAppNetworkPersistenceManager.getSaveRecipeIngredientsPreview(
//            authToken: authToken,
//            RecipeID: Int(RecipeID),
//            to: RecipeObjectID)
//    }
    
//    func updateGlass(RecipeID: Int64) async throws {
//        // Ensure is not generating glass already, otherwise return
//        guard !isUpdatingGlass else {
//            return
//        }
//        
//        // Set isUpdatingGlass to false once this method completes
//        defer {
//            DispatchQueue.main.async {
//                self.isUpdatingGlass = false
//            }
//        }
//        
//        // Set isUpdatingGlass to true
//        DispatchQueue.main.async {
//            self.isUpdatingGlass = true
//        }
//        
//        // Get authToken with AuthHelper ensure
//        let authToken: String
//        do {
//            authToken = try await AuthHelper.ensure()
//        } catch {
//            // TODO: Handle errors
//            print("Error ensuring authToken when updating glass in RecipeGenerator... \(error)")
//            return
//        }
//        
//        // Get permanent Recipe object id
//        let RecipeObjectID = try await RecipeCDClient.getRecipePermanentID(RecipeID: RecipeID)
//        
//        // Get and save glass color
//        try await BarbackNetworkPersistenceManager.getSaveGlassColor(
//            authToken: authToken,
//            RecipeID: Int(RecipeID),
//            to: RecipeObjectID)
//        
//        // Get and save glass
//        try await BarbackNetworkPersistenceManager.getSaveGlass(
//            authToken: authToken,
//            RecipeID: Int(RecipeID),
//            to: RecipeObjectID)
//    }
    
}
