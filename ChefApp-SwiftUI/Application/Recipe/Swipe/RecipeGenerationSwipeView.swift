//
//  RecipeOfTheDayGenerationSwipeView.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 12/7/24.
//

import SwiftUI

struct RecipeGenerationSwipeView: View {
    
    @ObservedObject var recipeGenerator: RecipeGenerator
    @ObservedObject var recipeSwipeCardsViewModel: RecipeSwipeCardsView.Model
    @ObservedObject var recipeGenerationSpec: RecipeGenerationSpec
    let onSwipe: (_ recipe: Recipe, _ swipeDirection: RecipeSwipeCardView.SwipeDirection) -> Void
    let onDetailViewSave: (Recipe) -> Void
    let onUndo: (_ recipe: Recipe, _ previousSwipeDirection: RecipeSwipeCardView.SwipeDirection) -> Void
    let onClose: () -> Void
    
    private let demoPantryItems: String = "Salt, pepper, olive oil, butter, garlic, onion, tomato, chicken, flour, sugar, eggs, milk, cheese, basil, oregano, paprika, cumin, ginger, soy sauce, honey, lemon, beef, pork, rice, pasta, potatoes, carrots, celery, mushrooms, spinach, cilantro, parsley, vinegar, baking powder, baking soda, vanilla extract, cinnamon, nutmeg, canola oil, chicken broth, beef broth, bell peppers, zucchini, corn, beans, shrimp, tofu, yogurt, maple syrup, tahini, mustard, cilantro"
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var premiumUpdater: PremiumUpdater
    
    @State private var isShowingAllPantryItems: Bool = false
    @State private var isShowingEntry: Bool = false
    
    @State private var isGeneratingNext: Bool = false
    
    private var maxAutoGenerate: Int {
        (premiumUpdater.isPremium ? Constants.Generation.premiumAutomaticRecipeGenerationLimit : Constants.Generation.freeAutomaticRecipeGenerationLimit)
        +
        2
    }
    
    private var allPantryItems: [PantryItem]? {
        do {
            return try viewContext.performAndWait { try viewContext.fetch(PantryItem.fetchRequest()) }
        } catch {
            // TODO: Handle Errors
            print("Error fetching pantry items in RecipeGenerationSwipeView... \(error)")
            return nil
        }
    }
    
    private var parsedInput: String {
        // TODO: Should I add anything else to the input string if selectedPantryItems is not empty?
        // Create parsedInput starting with input
        var parsedInput = recipeGenerationSpec.input
        
        // If selectedPantryItems is not empty add generationAdditionalOptions additional string and selectedPantryItems separated by commas
        if !recipeGenerationSpec.pantryItems.isEmpty {
            parsedInput += recipeGenerationSpec.generationAdditionalOptions == .boostCreativity ? "\nIngredients: " : (recipeGenerationSpec.generationAdditionalOptions == .useOnlyGivenIngredients ? "\nSelect From: " : "\nChoose from Ingredients: ")
            parsedInput += "\n\n"
        }
        
        // If pantryItems is empty or generationAdditionalOptions is useAllGivenIngredients add all pantry items, otherwise add pantry items
        if recipeGenerationSpec.pantryItems.isEmpty {
            do {
                if let allPantryItems,
                   !allPantryItems.isEmpty {
                    parsedInput += allPantryItems.shuffled().compactMap({$0.name}).joined(separator: ", ")
                } else {
                    // Append demo text TODO: Make sure this cannot be shown unless user enters ingredients, or handle in a better way
                    parsedInput += demoPantryItems.split(separator: ", ").shuffled().joined(separator: ", ")//"<No ingredients, the user is demoing the recipe creation ability.> Imagine there are common ingredients included here."
                }
            } catch {
                // TODO: Handle Errors
                print("Error getting all pantry items for parsedInput in RecipeGenerationSwipeView... \(error)")
            }
        } else {
            parsedInput += recipeGenerationSpec.pantryItems.shuffled().compactMap({$0.name}).joined(separator: ", ") // TODO: Should there be anything else if the name cannot be unwrapped? Since that is the only attribute besides category it's most likely always going to be filled, right, or at least it's expected behaviour to be filled, so it's probably fine to just compactmap filtering with just the name
        }
        
        return parsedInput
    }
    
    private var parsedInputDifferentThanNewRecipes: String {
        let allCards = recipeSwipeCardsViewModel.swipedCards + recipeSwipeCardsViewModel.unswipedCards
        return parsedInput + (allCards.count > 0 ? "\nDIFFERENT THAN RECIPE: " + allCards.compactMap({$0.name != nil && $0.summary != nil ? "\($0.name!), \($0.summary!)" : nil}).joined(separator: "\nAND DIFFERENT THAN: ") : "")
    }
    
    private var parsedModifiers: String? {
        // Right now if selectedSuggestions is empty nil, otherwise just the selectedSuggestions separated by commas
        recipeGenerationSpec.suggestions.isEmpty ? nil : recipeGenerationSpec.suggestions.joined(separator: ", ")
    }
    
    private var isLoadingRecipe: Bool {
        recipeGenerator.isCreating || recipeGenerator.isGeneratingBingImage
    }
    
    var body: some View {
        VStack {
            RecipeSwipeView(
//                recipeGenerator: recipeGenerator,
                recipeSwipeCardsViewModel: recipeSwipeCardsViewModel,
                isLoading: isLoadingRecipe,
                onSwipe: onSwipe,
                onDetailViewSave: onDetailViewSave,
                onClose: onClose)
            
            Text("swipe right to save")
                .font(.body, 14)
                .foregroundStyle(Colors.foregroundText)
                .opacity(0.6)
            
            HStack {
                Button(action: {
                    withAnimation {
                        if let lastSwipedCard = recipeSwipeCardsViewModel.undo() {
                            if let recipe = lastSwipedCard.recipe { // TODO: Research and analyze use cases to see if this is a good way to handle this
                                onUndo(recipe, lastSwipedCard.swipeDirection)
                            }
                        }
                    }
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .padding()
                        .foregroundStyle(Color(.systemBlue))
                        .background(Colors.foreground)
                        .clipShape(Circle())
                        .font(.body, 24.0)
                }
                .disabled(recipeSwipeCardsViewModel.swipedCards.isEmpty)
                .opacity(recipeSwipeCardsViewModel.swipedCards.isEmpty ? 0.2 : 1.0)
                Button(action: {
                    if let topCard = recipeSwipeCardsViewModel.unswipedCards.reversed().first,
                       let recipe = topCard.recipe {
                        recipeSwipeCardsViewModel.updateTopCardSwipeDirection(.left)
                        recipeSwipeCardsViewModel.removeTopCard()
                        onSwipe(recipe, .left)
                    }
                }) {
                    Image(systemName: "xmark")
                        .padding()
                        .foregroundStyle(Color(.systemRed))
                        .background(Colors.foreground)
                        .clipShape(Circle())
                        .font(.body, 40.0)
                }
                
                Button(action: {
                    if let topCard = recipeSwipeCardsViewModel.unswipedCards.reversed().first,
                       let recipe = topCard.recipe {
                        recipeSwipeCardsViewModel.updateTopCardSwipeDirection(.right)
                        recipeSwipeCardsViewModel.removeTopCard()
                        onSwipe(recipe, .right)
                    }
                }) {
                    Image(systemName: "checkmark")
                        .padding()
                        .foregroundStyle(Color(.systemGreen))
                        .background(Colors.foreground)
                        .clipShape(Circle())
                        .font(.body, 40.0)
                }
                Button(action: {
                    isShowingAllPantryItems = true
                }) {
                    Image(systemName: "list.bullet")
                        .padding()
                        .foregroundStyle(Color(.systemYellow))
                        .background(Colors.foreground)
                        .clipShape(Circle())
                        .font(.body, 24.0)
                }
            }
            
            Button(action: {
                isShowingEntry = true
            }) {
                // TODO: Entry Mini View
                HStack {
                    Spacer()
                    
                    VStack {
                        if !recipeGenerationSpec.pantryItems.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(recipeGenerationSpec.pantryItems) { pantryItem in
                                        if let name = pantryItem.name {
                                            Text(name)
                                                .font(.custom(Constants.FontName.body, size: 12.0))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(Colors.background)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        } else {
                            if allPantryItems == nil || allPantryItems!.isEmpty {
                                Text("Using Demo Ingredients")
                                    .font(.heavy, 12)
                            } else {
                                Text("Using all ingredients")
                                    .font(.custom(Constants.FontName.heavy, size: 12.0))
                            }
                        }
                        
                        Group {
                            if recipeGenerationSpec.input.isEmpty {
                                Text("*Tap to Add Prompt*")
                                    .opacity(0.6)
                            } else {
                                Text(recipeGenerationSpec.input)
                            }
                        }
                        .font(.custom(Constants.FontName.body, size: 14.0))
                        
                        if recipeGenerationSpec.suggestions.count > 0 {
                            Text(recipeGenerationSpec.suggestions.joined(separator: ", "))
                                .font(.custom(Constants.FontName.heavy, size: 10.0))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up")
                }
                .padding()
                .foregroundStyle(Colors.foregroundText)
                .frame(maxWidth: .infinity)
                .background(Colors.foreground)
                .clipShape(RoundedRectangle(cornerRadius: 14.0))
                .padding(.horizontal)
            }
        }
        .background(Colors.background)
        .sheet(isPresented: $isShowingEntry) {
            NavigationStack {
                VStack {
                    EntryView(
                        generateMessage: "Tap a suggestion or ingredients to create.",
                        selectedPantryItems: $recipeGenerationSpec.pantryItems,
                        generationAdditionalOptions: $recipeGenerationSpec.generationAdditionalOptions,
                        selectedSuggestions: $recipeGenerationSpec.suggestions,
                        showsTitle: false,
                        onDismiss: { isShowingEntry = false })
                    SheetView(
                        recipeGenerator: RecipeGenerator(),
                        selectedPantryItems: $recipeGenerationSpec.pantryItems,
                        inputFieldText: $recipeGenerationSpec.input,
                        isShowingEntryView: $isShowingEntry,
                        selectedSuggestions: $recipeGenerationSpec.suggestions,
                        showsCraftText: true,
                        textFieldPlaceholders: ["Enter Prompt..."],
                        onGenerate: {
                            // Reset swipe cards view model to clear recipe models
                            recipeSwipeCardsViewModel.reset()
                            isShowingEntry = false
                        })
                    .padding(.horizontal)
                }
                .background(Colors.background)
            }
        }
        .fullScreenCover(isPresented: $isShowingAllPantryItems) {
            NavigationStack {
                PantryView(
                    selectedItems: $recipeGenerationSpec.pantryItems,
                    showsEditButton: true,
                    onDismiss: {
                        isShowingAllPantryItems = false
                    })
                .background(Colors.background)
            }
        }
        .onReceive(recipeSwipeCardsViewModel.$unswipedCards) { newValue in
            if newValue.count < maxAutoGenerate {
                // Request generation
                Task {
                    // Generate if is not generating next TODO: Test if this needs to be faster and if so add a count to the amount of recipes that can be generating at once
                    if !isGeneratingNext {
                        do {
                            try await generateNext()
                        } catch {
                            // TODO: Handle errors
                            print("Could not generate next recipe in RecipeOfTheDayGenerationSwipeView... \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func generateNext() async throws {
        defer { DispatchQueue.main.async { self.isGeneratingNext = false } }
        await MainActor.run { isGeneratingNext = true }
        
        // If recipeID can be unwrapped from creating a recipe with recipeGenerator, get recipe ingredients preview, update remaining, and generateNext
        let recipe = try await recipeGenerator.create(
            ingredients: parsedInputDifferentThanNewRecipes,
            modifiers: parsedModifiers,
            expandIngredientsMagnitude: recipeGenerationSpec.generationAdditionalOptions.rawValue, // TODO: This should also be some string value on the server instead of expandIngredientsMagnitude as the advanced options could have more functionality this way :)
            in: viewContext)
        
//        // Set isLoadingRecipe to false and generate next if it is auto generating
//        if /*recipeGenerator.createdRecipes.count*/ recipeSwipeCardsViewModel.unswipedCards.count < maxAutoGenerate {
//            try await generateNext()
//        }
        
        // Generate bing image
        try await recipeGenerator.generateBingImage(
            recipe: recipe,
            in: viewContext)
        
        // Set isGeneratingNext to false to ensure the next one can be updated since the recipe is already generated, though this function should really just return the recipe and its caller should append the recipe
        await MainActor.run { isGeneratingNext = false }
        
        // Add to unswiped cards
        withAnimation {
            self.recipeSwipeCardsViewModel.unswipedCards.append(RecipeSwipeCardView.Model(
                recipe: recipe,
                imageURL: recipe.imageAppGroupLocation == nil ? nil : AppGroupLoader(appGroupIdentifier: Constants.Additional.appGroupID).fileURL(for: recipe.imageAppGroupLocation!),
                name: recipe.name,
                summary: recipe.summary))
        }
        
//        if let imageAppGroupLocation = recipe.imageAppGroupLocation {
//            recipeSwipeCardsViewModel.unswipedCards[.imageURL = AppGroupLoader(appGroupIdentifier: Constants.Additional.appGroupID).fileURL(for: imageAppGroupLocation)//recipeSwipeCardsViewModel.unswipedCards[i].recipe?.imageFromAppData
//        }
        
        // Update model with image TODO: Check this
//        for i in 0..<recipeSwipeCardsViewModel.unswipedCards.count {
//            if recipeSwipeCardsViewModel.unswipedCards[i].imageURL == nil {
//                if let recipe = recipeSwipeCardsViewModel.unswipedCards[i].recipe,
//                   let imageAppGroupLocation = recipe.imageAppGroupLocation {
//                    recipeSwipeCardsViewModel.unswipedCards[i].imageURL = AppGroupLoader(appGroupIdentifier: Constants.Additional.appGroupID).fileURL(for: imageAppGroupLocation)//recipeSwipeCardsViewModel.unswipedCards[i].recipe?.imageFromAppData
//                }
//            }
//        }
    }
    
}

#Preview {
    RecipeGenerationSwipeView(
        recipeGenerator: RecipeGenerator(),
        recipeSwipeCardsViewModel: RecipeSwipeCardsView.Model(cards: []),
        recipeGenerationSpec: RecipeGenerationSpec(
            pantryItems: [],
            suggestions: [],
            input: "",
            generationAdditionalOptions: .normal),
        onSwipe: { recipe, direction in
            
        },
        onDetailViewSave: { recipe in
            
        },
        onUndo: { recipe, previousSwipeDirection in
            
        },
        onClose: {
            
        })
    .environment(\.managedObjectContext, CDClient.mainManagedObjectContext)
    .environmentObject(PremiumUpdater())
    .environmentObject(ProductUpdater())
    .environmentObject(RemainingUpdater())
    .environmentObject(ScreenIdleTimerUpdater())
}
