//
//  PanelView.swift
//  Barback
//
//  Created by Alex Coundouriotis on 9/21/23.
//

import CoreData
import Foundation
import SwiftUI

struct PanelView: View {
    
    @ObservedObject var recipeGenerator: RecipeGenerator
    @State var panel: Panel
    @Binding var isShowing: Bool
//    var namespace: Namespace.ID
    
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @Environment(\.requestReview) private var requestReview
    
    @EnvironmentObject private var premiumUpdater: PremiumUpdater
    @EnvironmentObject private var remainingUpdater: RemainingUpdater

    var btnBack : some View { Button(action: {
            HapticHelper.doLightHaptic()
        
            self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Text("Go Back")
                    .foregroundStyle(.black)
            }
        }
    }
    
    @StateObject private var adOrReviewCoordinator = AdOrReviewCoordinator()
    
    @State private var generationAdditionalOptions: RecipeGenerationAdditionalOptions = .normal
    
    @State private var finalizedPrompt: String = ""
    
    @State private var isAddBarItemPopupShowing: Bool = false
    
    @State private var isShowingUltraView: Bool = false
    
    @State private var recipeGenerationSpec: RecipeGenerationSpec?
    
    @GestureState private var dragOffset = CGSize.zero
    
//    @State private var finalizedPrompt: String = ""
    
    @State private var alertShowingGenerationError: Bool = false
    @State private var alertShowingCapReached: Bool = false
    
    var isShowingRecipeGenerationView: Binding<Bool> {
        Binding(
            get: {
                recipeGenerationSpec != nil
            },
            set: { value in
                if !value {
                    recipeGenerationSpec = nil
                    requestReview.callAsFunction()
                }
            })
    }
    
//    @State private var panelComponents: [PanelComponent]
//    private var panelComponentsBinding: Binding<[PanelComponent]> {
//        Binding(get: {
//            if let components = panel?.components {
//                return components
//            }
//            
//            return []
//        },
//        set: { newValue in
//            panel?.components = newValue
//        })
//    }
    
    private var submitButtonDisabled: Bool {
        finalizedPrompt == "" || recipeGenerator.isCreating
    }
    
//    init(recipeGenerator: RecipeGenerator, panel: Panel, namespace: Namespace.ID) {
//        self.recipeGenerator = recipeGenerator
//        self._panel = State(initialValue: panel)
//        self.namespace = namespace
//    }
    
    
    var body: some View {
        ZStack {
            VStack {
//                header
                
                ScrollView {
                    VStack {
                        // Header
                        
                        // Title Card
                        titlePanelCard
                        
                        // Panels
                        panelsStack
                            .onChange(of: panel.components) { newPanelComponents in
                                updateFinalizedPrompt()
                            }
                        
                    }
                    .padding()
                }
                
                Spacer()
                
                // Submit Button
                submitButton
                
                Spacer()
            }
//            .popup(isPresented: $isAddBarItemPopupShowing, view: {
//                GeometryReader { geometry in
//                    VStack {
//                        Spacer()
//                        HStack {
//                            Spacer()
//                            InsertBarItemView(
//                                isShowing: $isAddBarItemPopupShowing,
//                                textFieldColor: Colors.foreground,
//                                elementColor: Colors.elementColor)
//                                .padding(24.0)
//                                .background(Colors.background)
//                                .frame(width: geometry.size.width * (8 / 9))
//                                .cornerRadius(28.0)
//                            Spacer()
//                        }
//                        Spacer()
//                    }
//                }
//                .transition(.move(edge: .bottom))
//            }, customize: { popup in
//                popup
//                    .backgroundView({
//                        Color.clear
//                            .background(Material.ultraThin)
//                    })
//                    .closeOnTap(false)
//            })
        }
//        .circleBackground(
//            backgroundIndex: .constant(1),
//            colorUpdater: Colors)
//        .barbackHeader(backgroundColor: colorUpdater.elementColor, showsDivider: true, left: {
//            Button(action: {
//                withAnimation {
//                    isShowing = false
//                }
//            }) {
//                Text("Close")
//                    .font(.custom(Constants.FontName.black, size: 20.0))
//                    .foregroundStyle(Colors.elementText)
//                    .padding(.bottom, 8)
//                    .padding(.leading)
//            }
//        }, right: {
//            
//        })
//        .background(colorUpdater.elementColor)
        .toolbar {
            LogoToolbarItem()
            UltraToolbarItem(color: Colors.navigationItemColor)
        }
        .toolbarBackground(Colors.secondaryBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .fullScreenCover(isPresented: isShowingRecipeGenerationView) {
//            var _didSaveRecipe: Bool = false
//            var didSaveRecipe: Binding = Binding(
//                get: {
//                    _didSaveRecipe
//                },
//                set: { newValue in
//                    if newValue {
//                        // TODO: Should this be somewhere else, maybe an onChange for a State?
//                        isShowingRecipeGenerationView = false
//                        isShowing = false
//                    }
//                    
//                    print(newValue)
//                    
//                    _didSaveRecipe = newValue
//                })
            if let recipeGenerationSpec {
                ZStack {
                    // TODO: Is it okay to have false for useAllIngredients here, or should it be true or defined in the panel spec and optionally get user input
                    RecipeGenerationView(
                        recipeGenerator: recipeGenerator,
                        recipeGenerationSpec: recipeGenerationSpec,
                        onDismiss: { isShowingRecipeGenerationView.wrappedValue = false },
                        didSaveRecipe: { _ in
                            // Dismiss
                            isShowingRecipeGenerationView.wrappedValue = false
                            isShowing = false
                            
                            // Show ad or review
                            Task {
                                await adOrReviewCoordinator.showWithCooldown(isPremium: premiumUpdater.isPremium)
                            }
                        })
                    .background(Colors.background)
                }
            }
        }
        .capReachedErrorAlert(isPresented: $alertShowingCapReached, isShowingUltraView: $isShowingUltraView)
        .interstitialInBackground(
            interstitialID: Keys.GAD.Interstitial.panelViewGenerate,
            disabled: premiumUpdater.isPremium,
            isPresented: $adOrReviewCoordinator.isShowingInterstitial)
        .ultraViewPopover(isPresented: $isShowingUltraView)
        .onReceive(adOrReviewCoordinator.$requestedReview) { newValue in
            if newValue {
                requestReview()
            }
        }
        .alert("Error Crafting", isPresented: $alertShowingGenerationError, actions: {
            Button("Close", role: .cancel, action: {
                
            })
        }) {
            Text("There was an issue crafting your recipe. Please try again later.")
        }
        
    }
    
//    var header: some View {
//        ZStack {
//            HStack {
//                VStack {
//                    Spacer()
//                    Button(action: {
//                        withAnimation {
//                            isShowing = false
//                        }
//                    }) {
//                        Text("Close")
//                            .font(.custom(Constants.FontName.black, size: 20.0))
//                            .foregroundStyle(Colors.elementText)
//                            .padding(.bottom, 8)
//                            .padding(.leading)
//                    }
//                }
//                Spacer()
//            }
//            
//            HStack {
//                Spacer()
//                VStack {
//                    Spacer()
//                    Text("Barback")
//                        .font(.custom(Constants.FontName.black, size: 28.0))
//                        .foregroundStyle(Colors.elementText)
//                        .padding(4)
//                }
//                Spacer()
//            }
//        }
//        .frame(height: 100)
//        .background(foregroundColor)
//    }
    
    var titlePanelCard: some View {
//        ZStack {
            HStack {
//                Spacer()
                HStack {
                    Spacer()
                    Text(panel.emoji)
                        .font(.custom(Constants.FontName.black, size: 38.0))
                        .lineLimit(.max)
                        .multilineTextAlignment(.center)
                    VStack {
                        // Card
                        HStack {
                            Text(panel.title)
                                .font(.custom(Constants.FontName.black, size: 20.0))
                                .lineLimit(.max)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.5)
                            //                    Spacer()
                        }
                        HStack {
                            Text(panel.summary)
                                .font(.custom(Constants.FontName.body, size: 14.0))
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.5)
                            //                    Spacer()
                        }
                        
                    }
                    Spacer()
                }
            }
            .padding()
//        }
        .background(
            RoundedRectangle(cornerRadius: 28.0)
                .fill(Colors.foreground)
        )
//        .clipShape(RoundedRectangle(cornerRadius: 28.0))
    }
    
    var panelsStack: some View {
//        panel?.components[0].finalizedPrompt = "asdf"
        ForEach($panel.components) { $component in
            switch component.input {
            case .barSelection:
                PantrySelectionPanelComponentView(
                    panelComponent: component,
                    isAddPantryItemPopupShowing: $isAddBarItemPopupShowing,
                    finalizedPrompt: $component.finalizedPrompt)
            case .dropdown(let viewConfig):
                DropdownPanelComponentView(
                    panelComponent: component,
                    dropdownPanelComponentViewConfig: viewConfig,
                    finalizedPrompt: $component.finalizedPrompt)
            case .ingredientsInput(let viewConfig):
                IngredientsInputPanelComponentView(
                    panelComponent: component,
                    textFieldPanelComponentViewConfig: viewConfig,
                    isAddPantryItemPopupShowing: $isAddBarItemPopupShowing,
                    finalizedPrompt: $component.finalizedPrompt,
                    generationAdditionalOptions: $generationAdditionalOptions)
            case .textField(let viewConfig):
                TextFieldPanelComponentView(
                    panelComponent: component,
                    textFieldPanelComponentViewConfig: viewConfig,
                    finalizedPrompt: $component.finalizedPrompt)
            }
            Spacer(minLength: 20)
        }
    }
    
    var submitButton: some View {
        Button(action: {
            HapticHelper.doMediumHaptic()
            
            withAnimation {
                recipeGenerationSpec = RecipeGenerationSpec(
                    pantryItems: [],
                    suggestions: [],
                    input: finalizedPrompt,
                    generationAdditionalOptions: generationAdditionalOptions)
            }
        }) {
            Spacer()
            ZStack {
                Text("Create Recipe...")
                    .font(.custom(Constants.FontName.black, size: 24.0))
                    .foregroundStyle(Colors.elementText)
                HStack {
                    Spacer()
                    if !recipeGenerator.isCreating {
                        // Right chevron if not creating
                        Image(systemName: "chevron.right")
                            .font(.custom(Constants.FontName.heavy, size: 24.0))
                            .foregroundStyle(Colors.elementText)
                    } else {
                        // Progress view if creating
                        ProgressView()
                            .font(.custom(Constants.FontName.heavy, size: 24.0))
                            .tint(Colors.elementText)
                    }
                }
            }
            Spacer()
        }
        .disabled(submitButtonDisabled)
        .modifier(CardModifier(backgroundColor: Colors.elementBackground))
        .bounceable(disabled: submitButtonDisabled)
        .opacity(submitButtonDisabled ? 0.4 : 1.0)
        .padding()
    }
    
    private func updateFinalizedPrompt() {
        // TODO: I don't think that it's using the "prompt" text when creating the finalized prompt, so maybe that's something that needs to be fixed?
        
        let commaSeparator = ", "
        
        // Build completeFinalizedPrompt, ensuring that all required values' finalizedPrompts are not nil and return
        var completeFinalizedPrompt = ""
        for i in 0..<panel.components.count {
            let component = panel.components[i]
            
            // Unswrap finalizedPrompt, otherwise either return nil or continue
            guard let finalizedPrompt = component.finalizedPrompt else {
                // If required, return nil
                if component.requiredUnwrapped {
                    finalizedPrompt = ""
                    return
                }
                
                // Otherwise, continue
                continue
            }
            
            // Append to completeFinalizedPrompt
            completeFinalizedPrompt.append(finalizedPrompt)
            
            // If not the last index in panel.components, append the comma separator
            if i < panel.components.count - 1 {
                completeFinalizedPrompt.append(commaSeparator)
            }
        }
        
        finalizedPrompt = completeFinalizedPrompt
    }
    
}


#Preview {
//    @Namespace var namespace
    
    return PanelView(
        recipeGenerator: RecipeGenerator(),
        panel: Panel(
            emoji: "😊",
            title: "This is a Title",
            summary: "This is the description for the title",
            prompt: "Prompt",
            components: [
                PanelComponent(
                    input: .textField(TextFieldPanelComponentViewConfig(
                        placeholder: "Text Field Panel Component Placeholder")),
                    title: "Text Field Panel Title",
                    detailTitle: "Test Detail Title",
                    detailText: "Test Detail Text",
                    promptPrefix: "Text Field Panel Component Prompt Prefix",
                    required: true),
                PanelComponent(
                    input: .dropdown(DropdownPanelComponentViewConfig(
                        items: [
                            "First item",
                            "Second item"
                        ])),
                    title: "Dropdown Panel Title",
                    detailTitle: "Test Detail Title",
                    detailText: "Test Detail Text",
                    promptPrefix: "Dropdown Panel Prompt Prefix",
                    required: true),
                PanelComponent(
                    input: .barSelection,
                    title: "Bar Selection Component Title",
                    promptPrefix: "Bar Selection Component Prompt Prefix",
                    required: true)
        ]),
        isShowing: .constant(true))
        .environment(\.managedObjectContext, CDClient.mainManagedObjectContext)
        .environmentObject(PremiumUpdater())
        .environmentObject(ProductUpdater())
        .environmentObject(RemainingUpdater())
        .background(Colors.background)
}
