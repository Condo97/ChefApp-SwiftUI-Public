//
//  RecipeOfTheDayGenerator.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 11/30/24.
//

import CoreData
import Foundation
import SwiftUI

class RecipeOfTheDayGenerator: RecipeGenerator {
    
    @Published var isLoadingPreGeneration: Bool = false
    
    var isLoading: Bool {
        isLoadingPreGeneration || (isCreating && !isFinalizing && !isGeneratingBingImage && !isGeneratingTags)
    }
    
    func reloadDailyRecipe(dailyRecipes: any Collection<Recipe>, pantryItems: any Collection<PantryItem>, recipe: Recipe, timeFrame: RecipeOfTheDayView.TimeFrames, in managedContext: NSManagedObjectContext) async {
        guard !isLoading else { return }
        defer { DispatchQueue.main.async { self.isLoadingPreGeneration = false } }
        await MainActor.run { isLoadingPreGeneration = true }
        
        // Get name of previous recipe so that the new one can be different than it
        let previousRecipeName = recipe.name ?? ""
        
        // Delete or save and update recipe
        await deleteOrSaveAndUpdateRecipe(recipe, in: managedContext)
        
        // Generate new daily recipe
        do {
            try await generateDailyRecipe(dailyRecipes: dailyRecipes, pantryItems: pantryItems, timeFrame: timeFrame, additionalModifiers: "\n\nMake it different than \(previousRecipeName).", in: managedContext)
        } catch {
            // TODO: Handle Errors if Necessary
            print("Error generating daily recipe in reload process in RecipeOfTheDayContainer, continuing... \(error)")
        }
    }
    
    func processDailyRecipes(dailyRecipes: any Collection<Recipe>, pantryItems: any Collection<PantryItem>, in managedContext: NSManagedObjectContext) async {
        guard !isLoading else { return }
        defer { DispatchQueue.main.async { self.isLoadingPreGeneration = false } }
        await MainActor.run { isLoadingPreGeneration = true }
        
//                guard let currentTimeFrame = RecipeOfTheDayView.TimeFrames.timeFrame(for: Date()) else {
//                    // TODO: Handle Errors
//                    print("Could not unwrap currentTimeFrame in RecipeOfTheDayContainer!")
//                    return
//                }
        
        // Scrub yesterday and previous days' recipes that are not saved and save ones that should be
        for dailyRecipe in dailyRecipes {
            if let creationDate = dailyRecipe.creationDate {
                if !Calendar.current.isDateInToday(creationDate) {
                    // Delete or save and update recipe because not today
                    await deleteOrSaveAndUpdateRecipe(dailyRecipe, in: managedContext)
                }
            } else {
                // Delete or save and update recipe because no creationDate TODO: Should this just outright delete it?
                await deleteOrSaveAndUpdateRecipe(dailyRecipe, in: managedContext)
            }
        }
        
        // Generate new daily breakfast, lunch, and dinner recipes as necessary
        do {
            try await generateDailyRecipe(dailyRecipes: dailyRecipes, pantryItems: pantryItems.shuffled(), timeFrame: .breakfast, additionalModifiers: nil, in: managedContext)
        } catch {
            // TODO: Handle Errors if Necessary
            print("Error generating daily breakfast recipe in RecipeOfTheDayContainer, continuing... \(error)")
        }
        do {
            try await generateDailyRecipe(dailyRecipes: dailyRecipes, pantryItems: pantryItems.shuffled(), timeFrame: .lunch, additionalModifiers: nil, in: managedContext)
        } catch {
            // TODO: Handle Errors if Necessary
            print("Error generating daily breakfast recipe in RecipeOfTheDayContainer, continuing... \(error)")
        }
        do {
            try await generateDailyRecipe(dailyRecipes: dailyRecipes, pantryItems: pantryItems.shuffled(), timeFrame: .dinner, additionalModifiers: nil, in: managedContext)
        } catch {
            // TODO: Handle Errors if Necessary
            print("Error generating daily breakfast recipe in RecipeOfTheDayContainer, continuing... \(error)")
        }
    }
    
    func deleteOrSaveAndUpdateRecipe(_ recipe: Recipe, in managedContext: NSManagedObjectContext) async {
        if recipe.saved {
            // Save by setting isDailyRecipe and isSavedToRecipes to false
            do {
                try await RecipeCDClient.updateRecipe(recipe, dailyRecipe_isDailyRecipe: false, in: managedContext)
            } catch {
                // TODO: Handle Errors
                print("Error updating recipe isDailyRecipe in RecipeOfTheDayContainer... \(error)")
            }
        } else {
            // Delete
            do {
                try await RecipeCDClient.deleteRecipe(recipe, in: managedContext)
            } catch {
                // TODO: Handle Errors
                print("Error deleting recipe in RecipeOfTheDayContainer, continuing... \(error)")
            }
        }
    }
    
    func generateDailyRecipe(dailyRecipes: any Collection<Recipe>, pantryItems: any Collection<PantryItem>, timeFrame: RecipeOfTheDayView.TimeFrames, additionalModifiers: String?, in managedContext: NSManagedObjectContext) async throws {
        // Set isLoadingPreGeneration to false since pre-generation loading is complete
        await MainActor.run { isLoadingPreGeneration = false }
        
        // Create if no dailyRecipe for timeFrame
        if !dailyRecipes.contains(where: {
            //            guard let dailyRecipeTimeFrame = RecipeOfTheDayView.TimeFrames.timeFrame(for: $0.creationDate ?? Date()) else {
            //                // TODO: Delete recipe? Handle this
            //                return false
            //            }
            guard let dailyRecipeTimeFrameID = $0.dailyRecipe_timeFrameID,
                  let dailyRecipeTimeFrame = RecipeOfTheDayView.TimeFrames(rawValue: dailyRecipeTimeFrameID) else {
                // TODO: Delete recipe? Handle this
                print("Could not unwrap timeFrameID or timeFrame in RecipeOfTheDayContainer!")
                return false
            }
            
            return timeFrame == dailyRecipeTimeFrame
        }) {
            // Generate daily recipe and image for current time frame
            do {
                let recipe = try await create(
                    ingredients: pantryItems.compactMap(\.name).joined(separator: ", "),
                    modifiers: "Select from this list and create a delicious \(timeFrame.displayString)." + (additionalModifiers ?? ""),
                    expandIngredientsMagnitude: 0,
                    dailyRecipe_isDailyRecipe: true,
                    dailyRecipe_timeFrameID: timeFrame.rawValue,
                    in: managedContext)
                
                try await generateBingImage(
                    recipe: recipe,
                    in: managedContext)
            } catch {
                // TODO: Handle Errors
                print("Error creating recipe in RecipeOfTheDayContainer... \(error)")
            }
        } else {
            throw RecipeOfTheDayError.recipeOfTheDayExistsForTimeframe
        }
    }
    
}
