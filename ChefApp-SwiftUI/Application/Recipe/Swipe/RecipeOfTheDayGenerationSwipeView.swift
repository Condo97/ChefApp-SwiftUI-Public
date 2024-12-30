//
//  RecipeOfTheDayGenerationSwipeView.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 12/7/24.
//

import SwiftUI

struct RecipeOfTheDayGenerationSwipeView: View {
    
    let recipeOfTheDayGenerationSpec: RecipeOfTheDayContainer.RecipeOfTheDayGenerationSpec
    let dailyRecipes: FetchedResults<Recipe>
    let onDismiss: () -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var recipeOfTheDayGenerator = RecipeOfTheDayGenerator()
    @StateObject private var recipeSwipeCardsViewModel = RecipeSwipeCardsView.Model(cards: [])
    
    @State private var recipeToOverwriteDailyRecipeWith: Recipe?
    //    @State private var alertShowingOverwriteRecipe: Bool = false
    
    var alertShowingOverwriteRecipe: Binding<Bool> {
        Binding(
            get: {
                recipeToOverwriteDailyRecipeWith != nil
            },
            set: { value in
                if !value {
                    recipeToOverwriteDailyRecipeWith = nil
                }
            })
    }
    
    var body: some View {
        RecipeGenerationSwipeView(
            recipeGenerator: recipeOfTheDayGenerator,
            recipeSwipeCardsViewModel: recipeSwipeCardsViewModel,
            recipeGenerationSpec: recipeOfTheDayGenerationSpec.recipeGenerationSpec,
            onSwipe: { recipe, direction in
                HapticHelper.doLightHaptic()
                
                if direction == .right {
                    saveOrLoadSaveAlert(recipe: recipe)
                }
            },
            onDetailViewSave: saveOrLoadSaveAlert,
            onUndo: { recipe, previousSwipeDirection in
                // There should be nothing here becuase it dismisses on swipe right and there is no CoreData modification to be done 
            },
            onClose: onDismiss)
        .alert("Save \(recipeOfTheDayGenerationSpec.recipeGenerationTimeFrame.displayString.uppercased())?", isPresented: alertShowingOverwriteRecipe, actions: {
            Button("Save") {
                if let recipeToOverwriteDailyRecipeWith {
                    saveRecipe(recipe: recipeToOverwriteDailyRecipeWith)
                }
                onDismiss()
            }
            Button("Cancel", role: .cancel) {
                withAnimation {
                    let _ = recipeSwipeCardsViewModel.undo()
                }
            }
        }) {
            Text("This will overwrite your current \(recipeOfTheDayGenerationSpec.recipeGenerationTimeFrame.displayString.lowercased())")
        }
    }
    
    func saveOrLoadSaveAlert(recipe: Recipe) {
        // Right now it is always overwriting a recipe so always show the alert
        recipeToOverwriteDailyRecipeWith = recipe
    }
    
    func saveRecipe(recipe: Recipe) {
        Task {
            // Delete or save and update current recipe of the day for time frame
            let existingRecipesForTimeFrame = dailyRecipes.filter({ $0.dailyRecipe_timeFrameID == recipeOfTheDayGenerationSpec.recipeGenerationTimeFrame.rawValue })
            for existingRecipeForTimeFrame in existingRecipesForTimeFrame {
                await recipeOfTheDayGenerator.deleteOrSaveAndUpdateRecipe(existingRecipeForTimeFrame, in: viewContext)
            }
            
            // Set to recipe of the day for the time frame
            do {
                try await RecipeCDClient.updateRecipe(recipe, dailyRecipe_isDailyRecipe: true, in: viewContext)
            } catch {
                // TODO: Handle Errors
                print("Error updating recipe dailyRecipe_isDailyRecipe in RecipeOfTheDayContainer, continuing... \(error)")
            }
            do {
                try await RecipeCDClient.updateRecipe(recipe, dailyRecipe_timeFrameID: recipeOfTheDayGenerationSpec.recipeGenerationTimeFrame.rawValue, in: viewContext)
            } catch {
                // TODO: Handle Errors
                print("Error updating recipe dailyRecipe_timeFrameID in RecipeOfTheDayContainer, continuing... \(error)")
            }
        }
    }
}

//#Preview {
//    RecipeOfTheDayGenerationSwipeView()
//}
