//
//  MainContainer.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 11/27/24.
//

import PDFKit
import SwiftUI

struct MainContainer: View {
    
    let loadingTikTokRecipeProgress: TikTokSourceRecipeGenerator.LoadingProgress?
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.requestReview) private var requestReview
    
    @EnvironmentObject private var premiumUpdater: PremiumUpdater
    
    @StateObject private var recipeGenerator = RecipeGenerator()
    
    @State private var recipeGenerationSpec: RecipeGenerationSpec = RecipeGenerationSpec(
        pantryItems: [],
        suggestions: [],
        input: "",
        generationAdditionalOptions: .normal) // Shows RecipeGenerationView if filled
    
    //    @State private var isShowingEntryView = false
    
    @State private var presentingPanel: Panel? = nil
    
    //    var isShowingRecipeGenerationView: Binding<Bool> {
    //        Binding(
    //            get: {
    //                recipeGenerationSpec != nil
    //            },
    //            set: { value in
    //                if !value {
    //                    recipeGenerationSpec = nil
    //                }
    //            })
    //    }
    
    var body: some View {
        // Main
        MainView(
            recipeGenerator: recipeGenerator,
            recipeGenerationSpec: recipeGenerationSpec,
            presentingPanel: $presentingPanel,
            loadingTikTokRecipeProgress: loadingTikTokRecipeProgress)
        .onOpenURL(perform: { url in
            if url.host == "recipe" || (url.host == "chitchatserver.com" && url.pathComponents[safe: 1] == "chefappdeeplink" && url.pathComponents[safe: 2] == "recipe") {
                let recipeIDString = url.lastPathComponent
                guard let recipeID = Int(recipeIDString) else {
                    // TODO: Handle Errors
                    print("Could not unwrap recipeID in MainContainer!")
                    return
                }
                
                print("recipeID: \(recipeID)")
                
                Task {
                    // Ensure authToken
                    let authToken: String
                    do {
                        authToken = try await AuthHelper.ensure()
                    } catch {
                        // TODO: Handle Errors
                        print("Error ensuring authToken in MainContainer... \(error)")
                        return
                    }
                    
                    // Get recipe
                    do {
                        let recipe = try await ChefAppNetworkPersistenceManager.getAndDuplicateAndSaveRecipe(
                            authToken: authToken,
                            recipeID: recipeID,
                            recipeGenerator: recipeGenerator,
                            in: viewContext)
                    } catch {
                        // TODO: Handle Errors
                        print("Error getting and duplicating and saving recipe in MainContainer... \(error)")
                    }
                }
            }
        })
    }
    
}

#Preview {
    
    return MainContainer(loadingTikTokRecipeProgress: nil)
        .environmentObject(PremiumUpdater())
    
}
