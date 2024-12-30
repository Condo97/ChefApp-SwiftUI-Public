//
//  SheetView.swift
//  Barback
//
//  Created by Alex Coundouriotis on 9/20/23.
//

import Foundation
import SwiftUI

struct SheetView: View {
    
    @ObservedObject var recipeGenerator: RecipeGenerator
    @Binding var selectedPantryItems: [PantryItem]
    @Binding var inputFieldText: String
    @Binding var isShowingEntryView: Bool
    @Binding var selectedSuggestions: [String]
    @State var showsCraftText: Bool = false
    var textFieldPlaceholders: [String]
    let onGenerate: () -> Void
    
//    private let coordinator = GADInterstitialCoordinator()
    
//    var timer = Timer.publish(every: 8.0, on: .main, in: .common).autoconnect()
    
    @Environment(\.colorScheme) private var colorScheme
    
    @Namespace private var namespace
    
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var textFieldPlaceholderIndex: Int = 0
    
    @State private var craftButtonBackgroundMatchedGeometryEffectID = "craftButtonBackground"
    @State private var craftButtonTextMatchedGeometryEffectID = "craftButtonText"
    @State private var craftButtonArrowMatchedGeometryEffectID = "craftButtonArrow"
    
    @State private var previousSuggestions: [String] = []
    
    @State private var yOffset: CGFloat = 0.0
    
    private var submitButtonDisabled: Bool {
        recipeGenerator.isCreating || (inputFieldText.isEmpty && selectedPantryItems.isEmpty && selectedSuggestions.isEmpty)
    }
    
//    @State private var buttonWidth: CGFloat = 0.0
    
    // TODO: Look up Form and Section
    
    
    var body: some View {
        ZStack {
//            let _ = Self._printChanges()
            VStack {
                ZStack {
                    if isShowingEntryView {
                        VStack(spacing: 0.0) {
                            pantryItemList
                            
                            HStack {
                                inputField
                                
                                submitButton
                            }
                            
                            if !selectedSuggestions.isEmpty {
                                suggestionsList
                                    .padding([.leading, .trailing])
                                    .padding(.bottom, 4)
                            }
                        }
                        .background(Colors.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: 20.0))
                    } else {
                        showInputFieldButton
                    }
                }
            }
        }
    }
    
    var pantryItemList: some View {
        ScrollView(.horizontal) {
            HStack {
                Spacer()
                ForEach(selectedPantryItems.reversed()) { selectedPantryItem in
                    if let selectedPantryItemName = selectedPantryItem.name {
                        Button(action: {
                            HapticHelper.doLightHaptic()
                            
                            selectedPantryItems.removeAll(where: {$0 == selectedPantryItem})
                        }) {
                            Text(selectedPantryItemName)
                                .font(.custom(Constants.FontName.body, size: 12.0))
                            Text(Image(systemName: "xmark"))
                                .font(.custom(Constants.FontName.body, size: 12.0))
                        }
                        .padding(8)
                        .foregroundStyle(Colors.elementBackground)
                        .background(Colors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14.0))
                        .padding(.top, 4)
                    }
                }
            }
        }
        .scrollIndicators(.never)
    }
    
    var inputField: some View {
        TextField("", text: $inputFieldText, axis: .vertical)
            .textFieldTickerTint(colorScheme == .light ? Colors.elementBackground : Colors.foregroundText)
            .keyboardDismissingTextFieldToolbar("Done", color: Colors.elementBackground)
            .font(.custom(Constants.FontName.medium, size: 17.0))
            .placeholder(when: inputFieldText.isEmpty) {
                Text(textFieldPlaceholders[textFieldPlaceholderIndex])
                    .font(.custom(Constants.FontName.body, size: 17.0))
                    .foregroundStyle(Colors.foregroundText)
                    .opacity(0.4)
            }
            .focused($isTextFieldFocused)
            .padding()
    }
    
    var showInputFieldButton: some View {
        Button(action: {
            // Do light haptic
            HapticHelper.doLightHaptic()
            
            // Show entry view
            withAnimation {
                isShowingEntryView = true
            }
        }) {
            ZStack {
                Spacer()
                Text("Create Recipe")
                    .font(.custom("copperplate-bold", size: 24.0))
                    .foregroundStyle(Colors.elementText)
                    .matchedGeometryEffect(id: craftButtonTextMatchedGeometryEffectID, in: namespace)
                
                HStack {
                    Spacer()
                    
                    Text(recipeGenerator.isCreating ? "" : "\(Image(systemName: "arrow.right"))")
                        .font(.custom("copperplate-bold", size: 17.0))
                        .foregroundStyle(Colors.elementText)
                        .matchedGeometryEffect(id: craftButtonArrowMatchedGeometryEffectID, in: namespace)
                    
                    if recipeGenerator.isCreating {
                        ProgressView()
                            .tint(Colors.elementText)
                    }
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14.0)
                    .fill(Colors.elementBackground)
                    .matchedGeometryEffect(id: craftButtonBackgroundMatchedGeometryEffectID, in: namespace))
            .clipShape(RoundedRectangle(cornerRadius: 20.0))
        }
        .bounceable()
    }
    
    var suggestionsList: some View {
        SingleAxisGeometryReader(axis: .horizontal) { geo in
            HStack {
                FlexibleView(availableWidth: geo.magnitude, data: selectedSuggestions, spacing: 8.0, alignment: .leading, content: { suggestion in
                    Text(suggestion)
                        .font(.custom(Constants.FontName.medium, size: 12.0))
                        .foregroundStyle(Colors.foregroundText)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Colors.foreground)
                        .clipShape(Capsule())
                        .padding(.top, -6)
                    
                })
                
                Spacer()
            }
        }
    }
    
    var submitButton: some View {
        ZStack {
            KeyboardDismissingButton(action: {
                HapticHelper.doLightHaptic()
                
                // TODO: Do enable/disable stuff, for action generate
                Task {
                    do {
                        // Present drink generation view to start generating drink
                        withAnimation {
                            onGenerate()
                        }
                        
//                        // Create drink
//                        try await drinkGenerator.create(input: textFieldText)
                    } catch {
                        // TODO: Handle errors
                        print("Could not create using generationManager in SheetView body... \(error)")
                    }
                }
            }) {
                VStack {
                    ZStack {
                        HStack(spacing: 8.0) {
                            // TODO: Make this hug the bottom as the user keeps typing in text
                            
                            if showsCraftText {
                                Text("Create")
                                    .font(.custom("copperplate-bold", size: 19.0))
                                    .foregroundStyle(Colors.elementText)
                                    .matchedGeometryEffect(id: craftButtonTextMatchedGeometryEffectID, in: namespace)
                            }
                            
                            ZStack {
                                Text(recipeGenerator.isCreating ? "" : "\(Image(systemName: "arrow.up"))")
                                    .font(.custom("copperplate-bold", size: 17.0))
                                    .foregroundStyle(Colors.elementText)
                                    .matchedGeometryEffect(id: craftButtonArrowMatchedGeometryEffectID, in: namespace)
                                
                                if recipeGenerator.isCreating {
                                    ProgressView()
                                        .tint(Colors.elementText)
                                }
                            }
                        }
//                        Text("Craft \(Image(systemName: submitButtonImageName))")
////                            .resizable()
//                            .padding(8)
//                            .font(.custom("copperplate-bold", size: 17.0))
//                            .foregroundStyle(Colors.elementText)
                        
//                        if drinkGenerator.isCreating {
//                            ProgressView()
//                        }
                    }
                    .padding(8)
                }
            }
            .background(
                ZStack {
                    if showsCraftText {
                        RoundedRectangle(cornerRadius: 24.0)
                            .matchedGeometryEffect(id: craftButtonBackgroundMatchedGeometryEffectID, in: namespace)
                    } else {
                        RoundedRectangle(cornerRadius: 24.0)
                            .matchedGeometryEffect(id: craftButtonBackgroundMatchedGeometryEffectID, in: namespace)
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .foregroundStyle(Colors.elementBackground)
            )
            .disabled(submitButtonDisabled)
            .opacity(submitButtonDisabled ? 0.4 : 1.0)
            .bounceable(disabled: submitButtonDisabled)
        }
//        .frame(width: 32.0, height: 32.0)
        .aspectRatio(contentMode: .fill)
        .padding([.trailing], 8)
        .onDisappear {
            // Dismiss entry view TODO: Is this a good place to do this?
            isShowingEntryView = false
        }
    }
    
}

#Preview {
    
    struct ContentView: View {
        
        @State var inputFieldText = "Input Field Text"
        @State var suggestionButtonPressed: Bool = false
        @State var selectedSuggestions: [String] = []
        
        private let textFieldPlaceholders = [
            "Test 1",
            "Test 2",
            "Tee hee :)"
        ]
        
        private let suggestions = [
            "Suggestion 1",
            "Another suggestion",
            "a third suggestion!"
        ]
        
        @State private var selectedSuggestionIndex: Int = 0
        
        var body: some View {
            VStack {
                Button(action: {
                    HapticHelper.doLightHaptic()
                    
                    if selectedSuggestionIndex >= suggestions.count {
                        selectedSuggestions.removeAll()
                        selectedSuggestionIndex = 0
                    } else {
                        selectedSuggestions.append(suggestions[selectedSuggestionIndex])
                        
                        selectedSuggestionIndex += 1
                    }
                }) {
                    Text("Change Suggestion Text")
                        .foregroundStyle(.blue)
                }
                
                SheetView(
                    recipeGenerator: RecipeGenerator(),
                    selectedPantryItems: .constant([]),
                    inputFieldText: $inputFieldText,
                    isShowingEntryView: .constant(true),
                    selectedSuggestions: $selectedSuggestions,
                    textFieldPlaceholders: textFieldPlaceholders,
                    onGenerate: {
                        
                    })
                .padding()
                .background(Colors.background)
                //            .cornerRadius(28.0)
            }
        }
    }
    
    return ContentView()
}
