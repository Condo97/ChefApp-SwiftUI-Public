//
//  EntryView.swift
//  Barback
//
//  Created by Alex Coundouriotis on 9/20/23.
//

import Foundation
import PopupView
import SwiftUI

struct EntryView: View {
    
    @State var generateMessage: String
    @Binding var selectedPantryItems: [PantryItem]
    @Binding var generationAdditionalOptions: RecipeGenerationAdditionalOptions
    @Binding var selectedSuggestions: [String]
    let showsTitle: Bool
    var onDismiss: () -> Void
    
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \PantryItem.updateDate, ascending: false)], animation: .default) private var pantryItems: FetchedResults<PantryItem>
    
//    @State private var isDisplayingBrowseSuggestions: Bool = false
    @State private var isDisplayingAdvancedOptions: Bool = false
    
    @State private var isShowingPantrySelectionView: Bool = false
    
    
    var body: some View {
        
        ZStack {
            VStack {
                //                ScrollView {
                ScrollView {
                    VStack {
                        HStack {
                            VStack(spacing: 0.0) {
                                if showsTitle {
                                    title
                                        .padding(.top)
                                        .padding([.leading, .trailing])
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                message
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top)
                                    .padding([.leading, .trailing])
                                
                                browseSuggestions
                                    .padding(.top)
                                
                                advancedOptions
                                    .padding(.top)
                            }
                        }
                        
                        //                        // Selected pantry items
                        //                        if !selectedPantryItems.isEmpty {
                        //                            selectedPantryItemsDisplay
                        //                        }
                        
                        //                        if !isDisplayingAdvancedOptions {
                        VStack(spacing: 0.0) {
                            Divider()
                            
                            // Add from pantry
                            addFromPantry
                            
                            Spacer(minLength: 80.0)
                        }
                        //                        }
                    }
                    
                    //                }
                    //                     , customize: { popup in
                    //                popup
                    //                    .backgroundView({
                    //                        Color.clear
                    //                            .background(Material.ultraThin)
                    //                    })
                    //            })
                    .onTapGesture {
                        KeyboardDismisser.dismiss()
                    }
                }
            }
            
//            VStack {
//                header
//                
//                Spacer()
//            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Colors.background, for: .navigationBar)
        .toolbar {
//            LogoToolbarItem(foregroundColor: Colors.elementBackground)
            ToolbarItem(placement: .principal) {
                Text("Create Recipes")
                    .font(.damion, 32)
                    .foregroundStyle(Colors.elementBackground)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    onDismiss()
                }) {
                    Text("Close")
                        .font(.heavy, 17)
                        .foregroundStyle(Colors.elementBackground)
                }
            }
        }
    }
        
//    var header: some View {
//        VStack {
//            Spacer()
//            if onDismiss != nil {
//                KeyboardDismissingButton(action: {
//                    HapticHelper.doLightHaptic()
//                    
//                    withAnimation(.easeInOut(duration: 0.2)) {
//                        onDismiss?()
//                    }
//                }) {
//                    Text(Image(systemName: "xmark"))
//                        .font(.custom(Constants.FontName.heavy, size: 28.0))
//                        .foregroundStyle(Colors.elementBackground)
//                        .padding([.leading, .trailing])
//                    //                                        .padding([.bottom], 10.0)
//                }
//            }
//        }
//        .frame(height: 100.0)
//        .ignoresSafeArea()
//    }
    
    var title: some View {
        HStack {
            Text("Create Recipe...")
//                .font(.custom(Constants.FontName.black, size: 34.0))
                .font(.custom(Constants.FontName.damion, size: 42.0))
            //                                    .padding([.bottom], 10.0)
            Spacer()
        }
    }
    
    var message: some View {
        HStack {
            Text(generateMessage)
                .font(.custom(Constants.FontName.body, size: 17.0))
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }
    
    var browseSuggestions: some View {
        VStack {
//            KeyboardDismissingButton(action: {
//                isDisplayingBrowseSuggestions.toggle()
//            }) {
//                Text(isDisplayingBrowseSuggestions ? "Hide Suggestions" : "Browse Suggestions...")
//                    .font(.custom(Constants.FontName.heavy, size: 14.0))
//                    .padding([.leading, .trailing], 16)
//                    .padding([.top, .bottom], 8)
//                    .background(Colors.foreground)
//                    .tint(elementColor)
//                    .clipShape(RoundedRectangle(cornerRadius: 14.0))
//                Spacer()
//            }
//            .padding()
            
//            if isDisplayingBrowseSuggestions {
//                VStack {
//                    HStack {
//                        Text("Tap to add to prompt...")
//                            .font(.custom(Constants.FontName.bodyOblique, size: 14.0))
//                            .foregroundStyle(Colors.foregroundText)
//                        Spacer()
//                    }
//                }
//                .padding([.leading, .trailing])
                
                ScrollView(.horizontal) {
                    VStack {
                        HStack {
                            ForEach(SuggestionsModel.topSuggestions, id: \.self) { suggestion in
                                Button(action: {
                                    HapticHelper.doLightHaptic()
                                    
                                    // Remove suggestion from selectedSuggestions if it's in there otherwise add it
                                    if selectedSuggestions.contains(suggestion) {
                                        withAnimation(.bouncy(duration: 0.5)) {
                                            selectedSuggestions.removeAll(where: {$0 == suggestion})
                                        }
                                    } else {
                                        withAnimation(.bouncy(duration: 0.5)) {
                                            selectedSuggestions.append(suggestion)
                                        }
                                    }
                                }) {
                                    Text(suggestion)
                                        .font(.custom(Constants.FontName.medium, size: 14.0))
                                }
                                .padding(8)
                                .foregroundStyle(Colors.foregroundText)
                                .background(selectedSuggestions.contains(suggestion) ? Color(uiColor: .systemGreen).opacity(0.4) : .clear)
                                .background(Colors.foreground)
                                .clipShape(RoundedRectangle(cornerRadius: 14.0))
                            }
                            
                            Spacer()
                        }
                        .padding([.leading, .trailing])
                        
                        HStack {
                            ForEach(SuggestionsModel.bottomSuggestions, id: \.self) { suggestion in
                                Button(action: {
                                    HapticHelper.doLightHaptic()
                                    
                                    // Remove suggestion from selectedSuggestions if it's in there otherwise add it
                                    if selectedSuggestions.contains(suggestion) {
                                        withAnimation(.bouncy(duration: 0.5)) {
                                            selectedSuggestions.removeAll(where: {$0 == suggestion})
                                        }
                                    } else {
                                        withAnimation(.bouncy(duration: 0.5)) {
                                            selectedSuggestions.append(suggestion)
                                        }
                                    }
                                }) {
                                    Text(suggestion)
                                        .font(.custom(Constants.FontName.medium, size: 14.0))
                                }
                                .padding(8)
                                .foregroundStyle(Colors.foregroundText)
                                .background(selectedSuggestions.contains(suggestion) ? Color(uiColor: .systemGreen).opacity(0.4) : .clear)
                                .background(Colors.foreground)
                                .clipShape(RoundedRectangle(cornerRadius: 14.0))
                            }
                            
                            Spacer()
                        }
                        .padding([.leading, .trailing])
                    }
                }
                .scrollIndicators(.never)
                
//            }
        }
    }
    
    var advancedOptions: some View {
        PantryRecipeGenerationAdvancedOptionsView(
            isDisplayingAdvancedOptions: $isDisplayingAdvancedOptions,
            generationAdditionalOptions: $generationAdditionalOptions)
    }
    
//    var selectedPantryItemsDisplay: some View {
//        VStack(alignment: .leading, spacing: 8.0) {
//            Text("Selected Ingredients:")
//                .font(.custom(Constants.FontName.body, size: 17.0))
//                .foregroundStyle(Colors.foregroundText)
//                .padding([.leading, .trailing])
//            
//            ScrollView(.horizontal) {
//                HStack {
//                    ForEach(selectedPantryItems) { selectedPantryItem in
//                        if let name = selectedPantryItem.name {
//                            Button(action: {
//                                selectedPantryItems.removeAll(where: {$0 == selectedPantryItem})
//                            }) {
//                                Text(name)
//                                    .font(.custom(Constants.FontName.body, size: 17.0))
//                                    .foregroundStyle(Colors.foregroundText)
//                                    .padding([.top, .bottom], 8)
//                                    .padding([.leading, .trailing])
//                                    .background(Color(uiColor: .systemGreen).opacity(0.4))
//                                    .clipShape(RoundedRectangle(cornerRadius: 14.0))
//                            }
//                        }
//                    }
//                }
//                .padding([.leading, .trailing])
//            }
//        }
//    }
    
    var addFromPantry: some View {
        VStack {
            HStack {
                Text("Tap to add ingredients from your pantry...")
                    .font(.custom(Constants.FontName.bodyOblique, size: 14.0))
                    .foregroundStyle(Colors.foregroundText)
                    .padding([.leading, .trailing])
                
                Spacer()
            }
            .padding([.top, .bottom], 8)
            
            HStack {
                PantrySelectionView(
                    selectedPantryItems: $selectedPantryItems,
                    showsAdvancedOptions: false,
                    generationAdditionalOptions: $generationAdditionalOptions)
                
//                Spacer()
            }
        }
    }
    
}


#Preview {
    
    ZStack {
        Spacer()
    }
    .overlay {
        EntryView(
            generateMessage: "AI Chef here, tell me what you want to recipe or get inspired from suggestions. 😊",
            selectedPantryItems: .constant([]),
            generationAdditionalOptions: .constant(.normal),
            selectedSuggestions: .constant([]),
            showsTitle: true,
            onDismiss: {
                
            }
        )
        .background(Colors.background)
        .environment(\.managedObjectContext, CDClient.mainManagedObjectContext)
        .environmentObject(PremiumUpdater())
        .environmentObject(ProductUpdater())
        .environmentObject(RemainingUpdater())
    }
    
    
}

