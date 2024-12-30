//
//  RecipeSwipeView.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 12/7/24.
//

import SwiftUI

struct RecipeSwipeView: View {
    
//    let recipeSwipeCardsViewModel: RecipeSwipeCardsView.Model
//    @ObservedObject var recipeGenerator: RecipeGenerator
    @ObservedObject var recipeSwipeCardsViewModel: RecipeSwipeCardsView.Model// = RecipeSwipeCardsView.Model(cards: [])
    let isLoading: Bool
    let onSwipe: (_ recipe: Recipe, _ swipeDirection: RecipeSwipeCardView.SwipeDirection) -> Void
    let onDetailViewSave: (Recipe) -> Void
//    let onUndo: (_ recipe: Recipe, _ previousSwipeDirection: RecipeSwipeCardView.SwipeDirection) -> Void
    let onClose: () -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var premiumUpdater: PremiumUpdater
    
//    @Namespace private var namespace
    
    
    @State private var presentingRecipe: Recipe?
    
    @State private var isShowingUltraView: Bool = false
    
    @State private var swipedCardsIterator: Int = 0 // This is for the tap animation
    
//    var imageAnimationID: String { "recipeImage\(swipedCardsIterator)" }
//    var nameAnimationID: String { "recipeName\(swipedCardsIterator)" }
//    var summaryAnimationID: String { "recipeSummary\(swipedCardsIterator)" }
    
//    private var isLoading: Bool {
//        recipeGenerator.isCreating
//    }
    
    var body: some View {
        Group {
            if !(recipeSwipeCardsViewModel.unswipedCards.isEmpty && isLoading) {
                RecipeSwipeCardsView(
                    model: recipeSwipeCardsViewModel,
                    onTap: { card in
                        withAnimation {
                            self.presentingRecipe = card.recipe
                        }
                    },
                    onSwipe: { card, direction in
                        // Call onSwipe if recipe can be unwrapped
                        if let recipe = card.recipe {
                            onSwipe(recipe, direction)
                        }
                    },
                    onSwipeComplete: {
                        // Increment swipedCardsIterator
                        DispatchQueue.main.async {
                            self.swipedCardsIterator += 1
                        }
                    },
                    onClose: onClose)
            } else {
                VStack {
                    VStack {
                        Text("Loading Recipes")
                            .font(.heavy, 20.0)
                        ProgressView()
                        
                        if !premiumUpdater.isPremium {
                            Text("Upgrade for Faster Queue")
                                .font(.heavy, 14.0)
                            Button(action: { isShowingUltraView = true }) {
                                Text("Upgrade")
                                    .appButtonStyle()
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Colors.background)
        .ultraViewPopover(isPresented: $isShowingUltraView)
        .saveRecipePopup(
            recipe: $presentingRecipe,
            didSaveRecipe: { recipe in
                onDetailViewSave(recipe)
                recipeSwipeCardsViewModel.removeTopCard()
            })
    }
    
}

#Preview {
    
    let cards = (try! CDClient.mainManagedObjectContext.fetch(Recipe.fetchRequest())).map({ RecipeSwipeCardView.Model(
        recipe: $0,
        imageURL: AppGroupLoader(appGroupIdentifier: Constants.Additional.appGroupID).fileURL(for: $0.imageAppGroupLocation!),
        name: $0.name,
        summary: $0.summary
    ) })
    
    @State var recipeGenerator = RecipeGenerator()
    
    return RecipeSwipeView(
//        recipeSwipeCardsViewModel: RecipeSwipeCardsView.Model(cards: cards),
//        recipeGenerator: recipeGenerator,
        recipeSwipeCardsViewModel: RecipeSwipeCardsView.Model(cards: cards),
        isLoading: false,
        onSwipe: { recipe, swipeDirection in
            
        },
        onDetailViewSave: { recipe in
            
        },
//        onUndo: { recipe, previousSwipeDirection in
//            
//        },
        onClose: {
            
        })
    .task {
        try! await recipeGenerator.create(ingredients: "", modifiers: "", expandIngredientsMagnitude: 0, in: CDClient.mainManagedObjectContext)
        try! await recipeGenerator.create(ingredients: "", modifiers: "", expandIngredientsMagnitude: 0, in: CDClient.mainManagedObjectContext)
        try! await recipeGenerator.create(ingredients: "", modifiers: "", expandIngredientsMagnitude: 0, in: CDClient.mainManagedObjectContext)
        try! await recipeGenerator.create(ingredients: "", modifiers: "", expandIngredientsMagnitude: 0, in: CDClient.mainManagedObjectContext)
        try! await recipeGenerator.create(ingredients: "", modifiers: "", expandIngredientsMagnitude: 0, in: CDClient.mainManagedObjectContext)
    }
    .environment(\.managedObjectContext, CDClient.mainManagedObjectContext)
    .environmentObject(PremiumUpdater())
    .environmentObject(ProductUpdater())
    .environmentObject(RemainingUpdater())
    .environmentObject(ScreenIdleTimerUpdater())
    
}
