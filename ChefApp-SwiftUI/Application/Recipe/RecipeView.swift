//
//  RecipeView.swift
//  Barback
//
//  Created by Alex Coundouriotis on 9/20/23.
//

import CoreData
import Foundation
import SwiftUI

struct RecipeView: View {
    
    @ObservedObject var recipeGenerator: RecipeGenerator
    @ObservedObject var recipe: Recipe
    @State var showsCloseButton: Bool = true
//    var namespace: Namespace.ID? = nil
//    var imageAnimationID: String? = nil
//    var nameAnimationID: String? = nil
//    var summaryAnimationID: String? = nil
    let onDismiss: () -> Void
    
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var premiumUpdater: PremiumUpdater
    @EnvironmentObject private var remainingUpdater: RemainingUpdater
    @EnvironmentObject private var screenIdleTimerUpdater: ScreenIdleTimerUpdater
    
    @StateObject private var tikTokSearchGenerator = TikTokSearchGenerator()
    
    @State private var editingIngredient: RecipeMeasuredIngredient?
    
    //    @State private var isDisplayingCapReachedCard: Bool = false
    
    @State private var isDisplayingRelatedVideos: Bool = false
    
    @State private var isEditingTitle: Bool = false
    @State private var isEditingIngredients: Bool = false
    
    @State private var isShowingRecipeImagePicker: Bool = false
    @State private var isShowingUltraView: Bool = false
    
    @State private var tikTokSearchResponse: TikAPISearchResponse?
    
    @State private var expandedPercentage: CGFloat = 1.0
    @State private var scrollTopOffsetSpacerMinLength: CGFloat = 0.0
    @State private var ingredientsScrollOffset: CGPoint = .zero
    
    @State private var alertShowingAllItemsMarkedForDeletion: Bool = false
    
    @State private var cardColor: Color = Colors.foreground
    
    var shouldDisplayCapReachedCard: Bool {
        !premiumUpdater.isPremium && (recipe.measuredIngredients == nil || recipe.measuredIngredients!.count == 0) && (recipe.directions == nil || recipe.directions!.count == 0) && !recipeGenerator.isCreating && !recipeGenerator.isFinalizing
    }
    
    var measurementAndIngredientOrServingsHasEdits: Bool {
        (recipe.measuredIngredients?.allObjects as? [RecipeMeasuredIngredient])?.contains(where: {
            ($0.nameAndAmountModified != nil && $0.nameAndAmountModified != $0.nameAndAmount) || $0.markedForDeletion
        }) ?? false
        ||
        recipe.estimatedServingsModified != 0 && recipe.estimatedServings != recipe.estimatedServingsModified
    }
    
    var editableEstimatedServings: Binding<Int> {
        Binding(
            get: {
                return Int(recipe.estimatedServingsModified == 0 ? recipe.estimatedServings : recipe.estimatedServingsModified)
            },
            set: { value in
                viewContext.performAndWait {
                    recipe.estimatedServingsModified = Int16(value)
                    
                    do {
                        try viewContext.save()
                    } catch {
                        // TODO: Handle Errors
                        print("Error saving viewContext in RecipeView... \(error)")
                    }
                }
            }
        )
    }
    
    var isShowingIngredientEditorView: Binding<Bool> {
        Binding(
            get: {
                editingIngredient != nil
            },
            set: { newValue in
                if !newValue {
                    self.editingIngredient = nil
                }
            })
    }
    
    
    var body: some View {
        ZStack {
//            let _ = Self._printChanges()
            VStack(spacing: 0.0) {
                ScrollView {
                    Spacer()
                    
                    topCard
                    
                    if recipe.dailyRecipe_isDailyRecipe {
                        dailyRecipeSaveCard
                    }
                    
                    if let tikTokVideoID = recipe.sourceTikTokVideoID {
                        RecipeTikTokSourceCardView(tikTokVideoID: tikTokVideoID)
                    }
                    
                    relatedVideosCard
                    
                    VStack {
                        if recipeGenerator.isFinalizing {
                            loadingCard
                        } else if shouldDisplayCapReachedCard {
                            CapReachedCard()
                        } else {
                            ingredients
                            
                            directions
                        }
                        
                    }
                    .padding()
                }
            }
            
            VStack {
                if showsCloseButton {
                    header
                }
                
                Spacer()
            }
        }
        .background(Colors.background)
        .clearFullScreenCover(isPresented: isShowingIngredientEditorView) {
            ZStack {
                if let editingIngredient = editingIngredient {
                    Color.clear
                        .background(Material.thin)
                    ZStack {
                        RecipeIngredientEditorView(
                            measuredIngredient: editingIngredient,
                            isShowing: isShowingIngredientEditorView)
                        .padding()
                        .background(Material.regular)
                        .clipShape(RoundedRectangle(cornerRadius: 28.0))
                        .padding()
                        .animation(.easeInOut, value: editingIngredient)
                    }
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .recipeTitleEditorPopup(isPresented: $isEditingTitle, recipe: recipe)
        .recipeImagePickerPopup(isPresented: $isShowingRecipeImagePicker, recipe: recipe)
        .ultraViewPopover(isPresented: $isShowingUltraView)
        .alert("No Ingredients", isPresented: $alertShowingAllItemsMarkedForDeletion, actions: {
            Button("Close", role: .cancel, action: {
                
            })
        }) {
            Text("All ingredients are marked for deletion. Please ensure there is at least one ingredient before updating directions.")
        }
        .onAppear {
            screenIdleTimerUpdater.keepScreenOn = true
        }
        .task {
            await finishUpdatingRecipeIfNeeded()
        }
        .task {
            // Generate bing image if recipe imageData is nil
            if recipe.imageFromAppData == nil {
                await generateBingImage()
            }
            
            // TODO: Also add an option for AI image!
        }
        .onDisappear {
            screenIdleTimerUpdater.keepScreenOn = false
        }
        
    }
    
    var header: some View {
        ZStack {
            HStack {
                Spacer()
                
                VStack {
                    Button(action: {
                        HapticHelper.doLightHaptic()
                        
                        withAnimation {
                            onDismiss()
                        }
                    }) {
                        Text(Image(systemName: "xmark"))
                            .shadow(color: Colors.elementText, radius: 1)
                            .font(.custom(Constants.FontName.black, size: 34.0))
                            .foregroundStyle(Colors.elementBackground)
                            .padding()
                        
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 100)
    }
    
    var topCard: some View {
        VStack {
            HStack {
                Spacer()
                
                // Top card
                if let name = recipe.name, let summary = recipe.summary {
                    // All necessary components in top card are loaded, so show top card
                    // Top image
                    VStack {
                        if let image = recipe.imageFromAppData {
                            Button(action: {
                                isShowingRecipeImagePicker = true
                            }) {
                                Image(uiImage: image) // TODO: Resize and set image here and stuff
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 28.0))
                                    .frame(height: 180.0)
                            }
                        }
                        
                        // Name
                        Text(name)
                            .font(.custom(Constants.FontName.black, size: 24.0))
                            .multilineTextAlignment(.center)
                            .contextMenu {
                                Button("Edit", systemImage: "square.and.pencil") {
                                    isEditingTitle = true
                                }
                            }
                        
                        // Summary
                        Text(summary)
                            .font(.custom(Constants.FontName.body, size: 14.0))
                            .multilineTextAlignment(.center)
                        
                        shareRecipeCard
                        
                        // Calories and Total Time
                        HStack {
                            Spacer()
                            
                            if recipe.estimatedTotalCalories > 0 {
                                // Calories
                                HStack {
                                    Text("Calories:")
                                        .font(.custom(Constants.FontName.black, size: 14.0))
                                        .foregroundStyle(Colors.foregroundText)
                                    
                                    Text("\(recipe.estimatedTotalCalories)")
                                        .font(.custom(Constants.FontName.black, size: 14.0))
                                        .foregroundStyle(Colors.foregroundText)
                                }
                                
                                Spacer()
                            }
                            
                            if recipe.estimatedTotalMinutes > 0 {
                                // Total Time
                                HStack {
                                    Text("Total Time:")
                                        .font(.custom(Constants.FontName.black, size: 14.0))
                                        .foregroundStyle(Colors.foregroundText)
                                    
                                    Text("\(recipe.estimatedTotalMinutes)m")
                                        .font(.custom(Constants.FontName.black, size: 14.0))
                                        .foregroundStyle(Colors.foregroundText)
                                }
                                
                                Spacer()
                            }
                            
                            HStack {
                                Button(action: {
                                    HapticHelper.doLightHaptic()
                                    Task {
                                        let authToken: String
                                        do {
                                            authToken = try await AuthHelper.ensure()
                                        } catch {
                                            // TODO: Handle Errors
                                            print("Error ensuring authToken in RecipeView... \(error)")
                                            return
                                        }
                                        
                                        // TODO: This logic needs to be fixed in the client code here and in other ChefApp apps, if the user switches from like to dislike it needs to both remove one from dislike and add one to like and the other way too
                                        do {
                                            try await ChefAppNetworkService.addOrRemoveLikeOrDislike(request: AddOrRemoveLikeOrDislikeRequest(
                                                authToken: authToken,
                                                recipeID: Int(recipe.recipeID),
                                                shouldAdd: RecipeLikeState(rawValue: Int(recipe.likeState)) != .like, // Add like if not like, otherwise remove
                                                isLike: true))
                                        } catch {
                                            // TODO: Handle Errors
                                            print("Error adding or removing dislike from Recipe on server in RecipeView... \(error)")
                                        }
                                        
                                        do {
                                            try await RecipeCDClient.updateRecipe(recipe, likeState: RecipeLikeState(rawValue: Int(recipe.likeState)) == .like ? .none : .like, in: viewContext)
                                        } catch {
                                            // TODO: Handle Errors
                                            print("Error updating Recipe likeState in RecipeView... \(error)")
                                        }
                                    }
                                }) {
                                    Image(systemName: RecipeLikeState(rawValue: Int(recipe.likeState)) == .like ? "hand.thumbsup.fill" : "hand.thumbsup")
                                        .foregroundStyle(RecipeLikeState(rawValue: Int(recipe.likeState)) == .like ? Colors.elementBackground : Colors.foregroundText)
                                }
                                
                                Button(action: {
                                    HapticHelper.doLightHaptic()
                                    Task {
                                        let authToken: String
                                        do {
                                            authToken = try await AuthHelper.ensure()
                                        } catch {
                                            // TODO: Handle Errors
                                            print("Error ensuring authToken in RecipeView... \(error)")
                                            return
                                        }
                                        
                                        do {
                                            try await ChefAppNetworkService.addOrRemoveLikeOrDislike(request: AddOrRemoveLikeOrDislikeRequest(
                                                authToken: authToken,
                                                recipeID: Int(recipe.recipeID),
                                                shouldAdd: RecipeLikeState(rawValue: Int(recipe.likeState)) != .dislike, // Add dislike if not dislike, otherwise remove
                                                isLike: false))
                                        } catch {
                                            // TODO: Handle Errors
                                            print("Error adding or removing dislike from Recipe on server in RecipeView... \(error)")
                                        }
                                        
                                        do {
                                            try await RecipeCDClient.updateRecipe(recipe, likeState: RecipeLikeState(rawValue: Int(recipe.likeState)) == .dislike ? .none : .dislike, in: viewContext)
                                        } catch {
                                            // TODO: Handle Errors
                                            print("Error updating Recipe likeState in RecipeView... \(error)")
                                        }
                                    }
                                }) {
                                    Image(systemName: RecipeLikeState(rawValue: Int(recipe.likeState)) == .dislike ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                        .foregroundStyle(RecipeLikeState(rawValue: Int(recipe.likeState)) == .dislike ? Colors.elementBackground : Colors.foregroundText)
                                }
                            }
                            .padding(.trailing)
                        }
                        .padding(.top, 8)
                        
                    }
                } else {
                    // No components in top card are loaded, so show loading
                    VStack {
                        Spacer()
                        Text("Crafting Recipe...")
                            .font(.custom(Constants.FontName.black, size: 32.0))
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.large)
                            .tint(Colors.elementBackground)
                        Spacer()
                    }
                }
                
                Spacer()
            }
            Divider()
                .foregroundStyle(Colors.elementBackground)
        }
    }
    
    var shareRecipeCard: some View {
        VStack(spacing: 0.0) {
            if let url = RecipeShareURLMaker.getShareURL(recipeID: Int(recipe.recipeID)) {
                HStack {
                    ShareLink(item: url) {
                        HStack {
                            Text("Share Recipe")
                                .font(.heavy, 17.0)
                            Image(systemName: "square.and.arrow.up")
                                .font(.body, 17.0)
                        }
                        .foregroundStyle(Colors.elementBackground)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Colors.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: 14.0))
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    var relatedVideosCard: some View {
        VStack(spacing: 0.0) {
            if let name = recipe.name,
               let summary = recipe.summary {
                Button(action: { withAnimation(.bouncy(duration: 0.5)) { isDisplayingRelatedVideos.toggle() } }) {
                    HStack {
                        Text("Related Videos")
                            .font(.heavy, 17.0)
                        Spacer()
                        Image(systemName: isDisplayingRelatedVideos ? "chevron.up" : "chevron.down")
                            .font(.body, 17.0)
                    }
                    .padding(.horizontal)
                }
                .foregroundStyle(Colors.foregroundText)
                .padding(.bottom, 8)
                
                if isDisplayingRelatedVideos {
                    TikTokSearchCardsContainer(
                        query: name + " " + summary,
                        height: 200.0,
                        maxCardWidth: 150.0,
                        tikTokSearchGenerator: tikTokSearchGenerator,
                        tikTokSearchResponse: $tikTokSearchResponse)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                }
                
                Divider()
            }
        }
    }
    
    var dailyRecipeSaveCard: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(recipe.saved ? "Un-save daily recipe?" : "Save daily recipe?")
                        .font(.custom(Constants.FontName.heavy, size: 17.0))
                    Text(recipe.saved ? "Recipe is currently saved." : "Recipe will be deleted tomorrow.")
                        .font(.custom(Constants.FontName.body, size: 12.0))
                }
                
                Spacer()
                
                Button(action: {
                    // Save or unsave daily recipe
                    Task {
                        do {
                            try await RecipeCDClient.updateRecipe(recipe, saved: !recipe.saved, in: viewContext)
                        } catch {
                            // TODO: Handle Errors
                            print("Error updating recipe dailyRecipe_isSavedToRecipes in RecipeOfTheDayView... \(error)")
                        }
                    }
                }) {
                    HStack(spacing: 6.0) {
                        Text(Image(systemName: recipe.saved ? "star.fill" : "star"))
                            .font(.body, 17.0)
                        Text(recipe.saved ? "Un-Save" : "Save")
                            .font(.custom(Constants.FontName.heavy, size: 14.0))
                    }
                        .foregroundStyle(recipe.saved ? Colors.elementBackground : Colors.elementText)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                if recipe.saved {
                                    RoundedRectangle(cornerRadius: 14.0)
                                        .stroke(Colors.elementBackground, lineWidth: 2)
                                } else {
                                    RoundedRectangle(cornerRadius: 14.0)
                                        .fill(Colors.elementBackground)
                                }
                            }
                        )
                }
            }
            .padding(.horizontal)
            
            Divider()
                .foregroundStyle(Colors.elementBackground)
        }
    }
    
    var loadingCard: some View {
        ZStack {
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Text("Creating Ingredients & Directions...")
                        .font(.custom(Constants.FontName.bodyOblique, size: 17.0))
                    ProgressView()
                        .foregroundStyle(Colors.foregroundText)
                    Spacer()
                }
                Spacer()
            }
        }
        .padding()
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 24.0))
        
    }
    
    var ingredients: some View {
        ZStack {
            // Measured Ingredients
            if let measuredIngredients = recipe.measuredIngredients?.allObjects as? [RecipeMeasuredIngredient], measuredIngredients.count > 0 {
                VStack {
                    ZStack(alignment: .top) {
                        // Insert Ingredient Button
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                HapticHelper.doLightHaptic()
                                
                                withAnimation(.bouncy) {
                                    isEditingIngredients.toggle()
                                }
                            }) {
                                Text(isEditingIngredients ? Image(systemName: "checkmark") : Image(systemName: "square.and.pencil"))
                                    .font(.custom(Constants.FontName.body, size: 20.0))
                                    .foregroundStyle(isEditingIngredients ? Colors.elementText : Colors.elementBackground)
                                    .frame(width: 48.0, height: 48.0)
                                    .background(isEditingIngredients ? Colors.elementBackground : Colors.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 14.0))
                            }
                        }
                        
                        // Edit Servings Picker
                        HStack {
                            VStack(spacing: 2.0) {
                                Text("Servings:")
                                    .font(.custom(Constants.FontName.body, size: 12.0))
                                    .foregroundStyle(Colors.foregroundText)
                                
                                Menu {
                                    Picker(
                                        selection: editableEstimatedServings,
                                        content: {
                                            ForEach(1..<100) { i in
                                                Text("\(i)")
                                                    .font(.custom(Constants.FontName.body, size: 14.0))
                                                    .tag(i)
                                            }
                                        },
                                        label: {
                                            
                                        })
                                } label: {
                                    HStack {
                                        Text("\(editableEstimatedServings.wrappedValue)")
                                            .font(.custom(Constants.FontName.body, size: 14.0))
                                        
                                        Image(systemName: "chevron.up.chevron.down")
                                            .imageScale(.medium)
                                        
                                        Spacer()
                                    }
                                    .padding([.leading, .trailing])
                                }
                                .menuOrder(.fixed)
                                .menuIndicator(.visible)
                                .foregroundStyle(Colors.elementBackground)
                                .tint(Colors.elementBackground)
                            }
                            .frame(width: 70.0, height: 48.0)
                            .background(Colors.background)
                            .clipShape(RoundedRectangle(cornerRadius: 14.0))
                            .fixedSize(horizontal: true, vertical: false)
                            
                            Spacer()
                        }
                        
                        // Ingredients Title
                        HStack {
                            Text("Ingredients")
                                .font(.custom(Constants.FontName.black, size: 20.0))
                                .foregroundStyle(Colors.foregroundText)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 1)
                    }
                    
                    Spacer(minLength: 16.0)
                    
                    VStack(spacing: isEditingIngredients ? 8.0 : 2.0) {
                        ForEach(measuredIngredients) { measuredIngredient in
                            HStack {
                                RecipeEditableIngredientView(
                                    measuredIngredient: measuredIngredient,
                                    isExpanded: $isEditingIngredients,
                                    isDisabled: $recipeGenerator.isRegeneratingDirections,
                                    onEdit: {
                                        editingIngredient = measuredIngredient
                                    })
                                Spacer()
                            }
                        }
                    }
                    //                    .padding([.leading, .trailing])
                    
                    // Add Ingredient Button
                    if isEditingIngredients {
                        Button(action: {
                            HapticHelper.doLightHaptic()
                            
                            insertAndEditNewIngredient()
                        }) {
                            HStack {
                                Spacer()
                                Text("\(Image(systemName: "plus")) Add Ingredient")
                                    .font(.custom(Constants.FontName.heavy, size: 17.0))
                                    .foregroundStyle(Colors.elementBackground)
                                Spacer()
                            }
                            .padding(8)
                            .background(Colors.background)
                            .clipShape(RoundedRectangle(cornerRadius: 24.0))
                        }
                        .animation(.bouncy, value: isEditingIngredients)
                    }
                    
                    // Regenerate Directions Button
                    HStack {
                        if measurementAndIngredientOrServingsHasEdits {
                            Button(action: {
                                HapticHelper.doMediumHaptic()
                                
                                Task {
                                    do {
                                        try await resolveIngredientsAndRegenerateDirections()
                                        
                                        HapticHelper.doSuccessHaptic()
                                    } catch {
                                        // TODO: Handle Errors
                                        print("Error resolving ingredinets and regenerating directions in RecipeView... \(error)")
                                    }
                                }
                            }) {
                                ZStack {
                                    if recipeGenerator.isRegeneratingDirections {
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                                .tint(Colors.elementText)
                                                .padding(.trailing)
                                        }
                                    }
                                    
                                    HStack {
                                        Spacer()
                                        Text("Update Instructions...")
                                            .font(.custom(Constants.FontName.heavy, size: 17.0))
                                            .foregroundStyle(Colors.elementText)
                                        Spacer()
                                    }
                                }
                            }
                            .padding(8)
                            .background(Colors.elementBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 24.0))
                            .opacity(recipeGenerator.isRegeneratingDirections ? 0.4 : 1.0)
                            .disabled(recipeGenerator.isRegeneratingDirections)
                            .padding(.top, 8)
                        }
                    }
                }
                .padding()
                .background(cardColor)
                .clipShape(RoundedRectangle(cornerRadius: 24.0))
            } else {
                // No measured ingredients are loaded, so show loading
                VStack {
                    Spacer()
                    Text("Loading Ingredients & Instructions ...")
                        .font(.custom(Constants.FontName.black, size: 32.0))
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.large)
                        .tint(Colors.elementBackground)
                    Spacer()
                }
            }
        }
        .onChange(of: ingredientsScrollOffset, perform: { offset in
            //updateExpandedPercentage(offset: offset)
            //            updateScrollTopSpacerMinLength(offset: offset)
        })
    }
    
    var directions: some View {
        VStack {
            // Directions
            if let unsortedDirections = (recipe.directions?.allObjects as? [RecipeDirection]), unsortedDirections.count > 0 {
                let directions = unsortedDirections.sorted(by: {$0.index < $1.index})
                ForEach(directions) { direction in
                    if let string = direction.string {
                        HStack {
                            Text("\(direction.index + 1)")
                                .font(.custom(Constants.FontName.black, size: 24.0))
                                .padding(.trailing, 8)
                            Text(LocalizedStringKey(string))
                                .font(.custom(Constants.FontName.body, size: 14.0))
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding()
                        .background(cardColor)
                        .clipShape(RoundedRectangle(cornerRadius: 24.0))
                    }
                }
            } else {
                if !recipeGenerator.isFinalizing {
                    Button(action: {
                        HapticHelper.doLightHaptic()
                        
                        Task {
                            await finishUpdatingRecipeIfNeeded()
                            
                            HapticHelper.doSuccessHaptic()
                        }
                    }) {
                        Text("Finish Generating...")
                            .font(.custom(Constants.FontName.heavy, size: 24.0))
                            .tint(Colors.elementBackground)
                            .background(Material.regular)
                    }
                }
            }
            
            Spacer(minLength: 240.0)
        }
    }
    
    func finishUpdatingRecipeIfNeeded() async {
        // TODO: Maybe generate image here?
        // If no measuredIngredients or directions, finalize and update remaining
        if recipe.measuredIngredients == nil || recipe.measuredIngredients!.count == 0 || recipe.directions == nil || recipe.directions!.count == 0 {
            // Finalize recipe
            do {
                try await recipeGenerator.finalize(recipe: recipe, additionalInput: "In the recipe's instructions but NOT measured ingredients, you may use **text** for bold (amounts and ingredients and emphesis) and *text* for italic (sparingly if at all), and other formats with LocalizedStringKey Swift 5.5+.", in: viewContext)
            } catch NetworkingError.capReachedError {
                //                isDisplayingCapReachedCard //- This is handled by shouldDisplayCapReachedCard
            } catch {
                // TODO: Handle errors
                print("Error finalizing recipe in RecipeView... \(error)")
            }
            
            // Update remaining
            do {
                let authToken = try await AuthHelper.ensure()
                
                do {
                    try await remainingUpdater.update(authToken: authToken)
                } catch {
                    // TODO: Handle Errors
                    print("Error updating remaining in RecipeView... \(error)")
                }
            } catch {
                // TODO: Handle Errors
                print("Error ensuring authToken in RecipeView... \(error)")
            }
        }
    }
    
    func generateBingImage() async {
        /* Bing Image */
        do {
            try await recipeGenerator.generateBingImage(recipe: recipe, in: viewContext)
        } catch {
            // TODO: Handle Errors
            print("Error generating bing image in RecipeView... \(error)")
        }
    }
    
    func insertAndEditNewIngredient() {
        // TODO: Is this good enough or does this need a better implementation lol
        let measuredIngredient: RecipeMeasuredIngredient
        do {
            measuredIngredient = try viewContext.performAndWait {
                let measuredIngredient = RecipeMeasuredIngredient(context: viewContext)
                
                measuredIngredient.recipe = recipe
                
                try viewContext.save()
                
                return measuredIngredient
            }
        } catch {
            // TODO: Handle Errors
            print("Error inserting ingredient in RecipeView... \(error)")
            return
        }
        
        editingIngredient = measuredIngredient
    }
    
    func resolveIngredientsAndRegenerateDirections() async throws {
        // Ensure all ingredients arent marekd for deletion, otherwise set showing alert to true and return TODO: Is this a good place and implementation for this?
        guard let measuredIngredients = (recipe.measuredIngredients?.allObjects as? [RecipeMeasuredIngredient]), measuredIngredients.contains(where: {!$0.markedForDeletion}) else {
            alertShowingAllItemsMarkedForDeletion = true
            return
        }
        
        // Regenerate directions and resolve updated ingredients
        try await recipeGenerator.regenerateDirectionsAndResolveUpdatedIngredients(for: recipe, additionalInput: "In the recipe's instructions but NOT measured ingredients, you may use **text** for bold (amounts and ingredients and emphesis) and *text* for italic (sparingly if at all), and other formats with LocalizedStringKey Swift 5.5+.", in: viewContext)
    }
    
    func updateExpandedPercentage(offset: CGPoint) {
        let maxOffset: CGFloat = 100.0
        
        if offset.y > maxOffset {
            expandedPercentage = 0.0
        } else if offset.y <= 0 {
            expandedPercentage = 1.0
        } else {
            expandedPercentage = 1 - offset.y / maxOffset
        }
    }
    
    
}

extension View {
    
    func recipePopup(recipe: Binding<Recipe?>, recipeGenerator: RecipeGenerator) -> some View {
        self
            .popover(item: recipe) { unwrappedRecipe in
                RecipeView(
                    recipeGenerator: recipeGenerator,
                    recipe: unwrappedRecipe,
                    onDismiss: { recipe.wrappedValue = nil })
            }
    }
    
    func recipeFullScreenCover(recipe: Binding<Recipe?>, recipeGenerator: RecipeGenerator) -> some View {
        self
            .fullScreenCover(item: recipe) { unwrappedRecipe in
                RecipeView(
                    recipeGenerator: recipeGenerator,
                    recipe: unwrappedRecipe,
                    onDismiss: { recipe.wrappedValue = nil })
                .background(Colors.background)
//                .presentationCompactAdaptation(.fullScreenCover)
            }
    }
    
}

#Preview {
    
    let viewContext = CDClient.mainManagedObjectContext
    
    var recipe = Recipe(entity: Recipe.entity(), insertInto: viewContext)
    recipe.input = "Recipe input"
    recipe.name = "Sparkling Mint Vodka"
    recipe.summary = "A refreshing and minty cocktail with a hint of vodka and a sparkling twist!"
    recipe.estimatedTotalCalories = 100
    recipe.estimatedTotalMinutes = 60
    recipe.imageData = UIImage(named: "AppIconNoBackground")?.pngData()
    recipe.recipeID = 0
    
    recipe.dailyRecipe_isDailyRecipe = true
    recipe.dailyRecipe_timeFrameID = RecipeOfTheDayView.TimeFrames.lunch.rawValue
//    recipe.dailyRecipe_isSavedToRecipes = false
    
    var recipeMeasuredIngredient1 = RecipeMeasuredIngredient(entity: RecipeMeasuredIngredient.entity(), insertInto: viewContext)
    recipeMeasuredIngredient1.nameAndAmount = "ingredient and measurement"
    recipeMeasuredIngredient1.recipe = recipe
    
    var recipeMeasuredIngredient2 = RecipeMeasuredIngredient(entity: RecipeMeasuredIngredient.entity(), insertInto: viewContext)
    recipeMeasuredIngredient2.nameAndAmount = "another ingredient 2 1/4 cup"
    recipeMeasuredIngredient2.recipe = recipe
    
    var recipeMeasuredIngredient3 = RecipeMeasuredIngredient(entity: RecipeMeasuredIngredient.entity(), insertInto: viewContext)
    recipeMeasuredIngredient3.nameAndAmount = "3 3/5 cup wow another ingredient"
    recipeMeasuredIngredient3.recipe = recipe
    
    var recipeDirection1 = RecipeDirection(entity: RecipeDirection.entity(), insertInto: viewContext)
    recipeDirection1.index = 1
    recipeDirection1.string = "First direction"
    recipeDirection1.recipe = recipe
    
    var recipeDirection2 = RecipeDirection(entity: RecipeDirection.entity(), insertInto: viewContext)
    recipeDirection2.index = 2
    recipeDirection2.string = "Second direction"
    recipeDirection2.recipe = recipe
    
    var recipeDirection3 = RecipeDirection(entity: RecipeDirection.entity(), insertInto: viewContext)
    recipeDirection3.index = 3
    recipeDirection3.string = "Third direction"
    recipeDirection3.recipe = recipe
    
    var recipeDirection4 = RecipeDirection(entity: RecipeDirection.entity(), insertInto: viewContext)
    recipeDirection4.index = 4
    recipeDirection4.string = "Fourth direction"
    recipeDirection4.recipe = recipe
    
    var recipeDirection5 = RecipeDirection(entity: RecipeDirection.entity(), insertInto: viewContext)
    recipeDirection5.index = 5
    recipeDirection5.string = "fifth direction"
    recipeDirection5.recipe = recipe
    
    var recipeDirection6 = RecipeDirection(entity: RecipeDirection.entity(), insertInto: viewContext)
    recipeDirection6.index = 6
    recipeDirection6.string = "Sixth direction"
    recipeDirection6.recipe = recipe
    
    var recipeDirection7 = RecipeDirection(entity: RecipeDirection.entity(), insertInto: viewContext)
    recipeDirection7.index = 7
    recipeDirection7.string = "Seventh direction"
    recipeDirection7.recipe = recipe
    
    var recipeDirection8 = RecipeDirection(entity: RecipeDirection.entity(), insertInto: viewContext)
    recipeDirection8.index = 8
    recipeDirection8.string = "Eigth direction"
    recipeDirection8.recipe = recipe
    
    try! viewContext.save()
    
    return RecipeView(
        recipeGenerator: RecipeGenerator(),
        recipe: recipe,
        onDismiss: {
            
        })
    .environment(\.managedObjectContext, CDClient.mainManagedObjectContext)
    .environmentObject(PremiumUpdater())
    .environmentObject(ProductUpdater())
    .environmentObject(RemainingUpdater())
    .environmentObject(ScreenIdleTimerUpdater())
    .background(Colors.background)
}
