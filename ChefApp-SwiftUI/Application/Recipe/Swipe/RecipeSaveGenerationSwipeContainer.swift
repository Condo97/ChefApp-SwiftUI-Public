//
//  RecipeSaveGenerationSwipeContainer.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 12/12/24.
//

import SwiftUI

struct RecipeSaveGenerationSwipeContainer: View {
    
    let recipeGenerationSpec: RecipeGenerationSpec
    let onClose: () -> Void
    
    @Environment(\.requestReview) private var requestReview
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var constantsUpdater: ConstantsUpdater
    @EnvironmentObject private var premiumUpdater: PremiumUpdater
    
    @StateObject private var adOrReviewCoordinator = AdOrReviewCoordinator()
    
    var body: some View {
        RecipeGenerationSwipeContainer(
//                    recipeGenerator: recipeGenerator,
            recipeGenerationSpec: recipeGenerationSpec,
            onSwipe: { recipe, swipeDirection in
                if swipeDirection == .right {
                    // Save to Recipes
                    Task {
                        do {
                            try await RecipeCDClient.updateRecipe(recipe, saved: true, in: viewContext)
                        } catch {
                            // TODO: Handle Errors
                            print("Error updating recipe in MainView... \(error)")
                        }
                    }
                    
                    // Show ad or review if premium
                    Task {
                        await adOrReviewCoordinator.showWithCooldown(isPremium: premiumUpdater.isPremium)
                    }
                }
            },
            onDetailViewSave: { recipe in
                // Save to Recipes
                Task {
                    do {
                        try await RecipeCDClient.updateRecipe(recipe, saved: true, in: viewContext)
                    } catch {
                        // TODO: Handle Errors
                        print("Error updating recipe in MainView... \(error)")
                    }
                }
                
                // Show ad or review if premium
                Task {
                    await adOrReviewCoordinator.showWithCooldown(isPremium: premiumUpdater.isPremium)
                }
            },
            onUndo: { recipe, previousSwipeDirection in
                if previousSwipeDirection == .right {
                    // Remove from saved if saved
                    Task {
                        do {
                            try await RecipeCDClient.updateRecipe(recipe, saved: false, in: viewContext)
                        } catch {
                            // TODO: Handle Errors
                            print("Error updating recipe in MainnView... \(error)")
                        }
                    }
                }
            },
            onClose: onClose)
        // Interstitial to be shown on generate
        .interstitialInBackground(
            interstitialID: Keys.GAD.Interstitial.mainContainerGenerate,
            disabled: premiumUpdater.isPremium,
            isPresented: $adOrReviewCoordinator.isShowingInterstitial)
        // Show ad on appear if not premium
        .task {
            // Show ad or review immediately if premium and not fewer than one launch
            if constantsUpdater.launchCount >= 2 {
                await adOrReviewCoordinator.showAdImmediately(isPremium: premiumUpdater.isPremium)
            }
        }
        // Show review on change of requestedReview
        .onReceive(adOrReviewCoordinator.$requestedReview) { newValue in
            if newValue {
                requestReview()
            }
        }
    }
}

//#Preview {
//
//    RecipeSaveGenerationSwipeContainer()
//    
//}
