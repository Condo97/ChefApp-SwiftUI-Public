//
//  AddToPantryView.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 12/15/24.
//

import SwiftUI

struct AddToPantryView: View {
    
    let showCameraOnAppear: Bool
//    let onUseManualEntry: () -> Void
    let onDismiss: () -> Void
    
    let instructionText: String = "Enter items to add to your pantry or fridge. Include produce, meats, branded items, and more."
    let instructionExampleText: String = "ex. \"Lemon, Chicken, Pasta, Tomato Paste, etc."
    
    let placeholderText: String = "Ingredient..."
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @FocusState private var automaticEntryTextFieldFocusState
    
    @StateObject private var pantryItemsParser: PantryItemsParser = PantryItemsParser()
    
    @State private var automaticEntryText: String = ""
    @State private var automaticEntryItems: [String] = []
    
    @State private var isLoading: Bool = false
    
    //    @State private var isUsingAutomaticEntry: Bool = true
    @State private var isShowingCaptureCameraView: Bool = false
    
    @State private var duplicatePantryItemNames: [String] = []
    
    @State private var alertShowingDuplicateAutomaticEntryItem: Bool = false
    @State private var alertShowingDuplicateObjectWhenInserting: Bool = false
    
    private var isAutoSubmitButtonEnabled: Bool {
        !automaticEntryText.isEmpty || !automaticEntryItems.isEmpty
    }
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Title
                Text("Add to Pantry")
                    .font(.custom(Constants.FontName.black, size: 24.0))
                    .padding(.bottom, 8)
                    .padding(.horizontal)
                
                // Text field
                TextField(placeholderText, text: $automaticEntryText)
                    .textFieldTickerTint(colorScheme == .light ? Colors.elementBackground : Colors.foregroundText)
                    .keyboardDismissingTextFieldToolbar("Done", color: Colors.elementBackground)
                    .focused($automaticEntryTextFieldFocusState)
                    .font(.custom(Constants.FontName.body, size: 17.0))
                    .foregroundColor(Colors.foregroundText)
                    .padding()
                    .background(Colors.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: 20.0))
                    .padding(.horizontal)
                    .onSubmit {
                        // Set textField to focused to bring up keyboard
                        UIView.performWithoutAnimation {
                            automaticEntryTextFieldFocusState = true
                        }
                        
                        // Parse automatic entry text
                        parseAutomaticEntryText()
                    }
                
                if !automaticEntryText.isEmpty {
                    Button(action: {
                        // Parse automatic entry text
                        parseAutomaticEntryText()
                    }) {
                        ZStack {
                            Text("Add")
                                .font(.heavy, 20.0)
                            Image(systemName: "return")
                                .font(.body, 20.0)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .foregroundStyle(Colors.elementText)
                        .padding()
                    }
                    .foregroundColor(Colors.foregroundText)
                    .background(Colors.elementBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20.0))
                    .padding(.horizontal)
                }
                
                automaticEntryView
                    .padding(.horizontal)
                
                //                submitButtonView
                
                // New Pantry Items
                VStack(spacing: 0.0) {
                    // Empty list preview
                    if automaticEntryItems.isEmpty && !pantryItemsParser.isLoadingGetPantryItemsFromImage {
                        // List preview
                        addToPantryViewListItem {
                            Text("Pantry items will appear here.")
                                .font(.body, 14.0)
                                .foregroundStyle(Colors.foregroundText)
                                .opacity(0.6)
                        }
                    }
                    
                    if pantryItemsParser.isLoadingGetPantryItemsFromImage {
                        addToPantryViewListItem {
                            Text("Loading Scan...") // TODO: Pretty sure this is the only use case for this text to display but if there are more use cases it is necessary to change this text
                                .font(.body, 17)
                            Spacer()
                            ProgressView()
                        }
                    }
                    ForEach(automaticEntryItems.reversed(), id: \.self) { item in
                        addToPantryViewListItem {
                            Text(item)
                                .font(.body, 17)
                            Spacer()
                            Button(action: {
                                automaticEntryItems.removeAll(where: {$0 == item})
                            }) {
                                Image(systemName: "xmark")
                            }
                            .font(.body, 14.0)
                            .foregroundStyle(Color(.systemRed))
                        }
                    }
                }
            }
        }
        .background(Colors.background)
        .overlay {
            if pantryItemsParser.isLoadingParseSavePantryItems {
                ZStack {
                    Colors.background
                        .opacity(0.6)
                    VStack {
                        Text("Saving Pantry")
                            .font(.heavy, 20)
                        ProgressView()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Colors.background, for: .navigationBar)
        .toolbar {
            LogoToolbarItem(foregroundColor: Colors.elementBackground)
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    // Dismiss
                    onDismiss()
                }) {
                    Text("Cancel")
                        .font(.body, 17.0)
                        .foregroundStyle(Colors.elementBackground)
                }
                .disabled(isLoading)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    Task {
                        // Save and dismiss
                        await savePantryItems()
                        await MainActor.run { onDismiss() }
                    }
                }) {
                    Text("Save")
                        .font(.heavy, 17.0)
                        .foregroundStyle(Colors.elementBackground)
                }
                .disabled(isLoading)
            }
        }
        .onAppear {
            if showCameraOnAppear {
                isShowingCaptureCameraView = true
            }
        }
        .alert("Duplicate Entry", isPresented: $alertShowingDuplicateAutomaticEntryItem, actions: {
            Button("Done", role: .cancel, action: {
                
            })
        }) {
            Text("This item is already in your list to add to pantry.")
        }
        .alert("Duplicate Item", isPresented: $alertShowingDuplicateObjectWhenInserting, actions: {
            Button("Done", role: .cancel, action: onDismiss)
        }) {
            Text("Duplicate pantry items found and won't be added:\n" + duplicatePantryItemNames.joined(separator: ", "))
        }
        .fullScreenCover(isPresented: $isShowingCaptureCameraView) {
            ZStack {
                CaptureCameraViewControllerRepresentable(
                    reset: .constant(false),
                    onAttach: { image, cropFrame, unmodifiedImage in
                        Task {
                            do {
                                // Get pantryItemStrings from image and add them to automaticEntryItems
                                let pantryItemStrings = try await pantryItemsParser.parseGetPantryItemsFromImage(image: image, input: nil).map({$0.name})
                                
                                automaticEntryItems.append(contentsOf: pantryItemStrings)
                            } catch {
                                // TODO: Handle Errors
                                print("Error getting pantry item text from image in InsertPantryItemView... \(error)")
                            }
                        }
                        
                        withAnimation {
                            isShowingCaptureCameraView = false
                        }
                    })
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                HapticHelper.doLightHaptic()
                                
                                isShowingCaptureCameraView = false
                            }
                        }) {
                            ZStack {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .frame(width: 30.0, height: 30.0)
                                    .foregroundStyle(Colors.elementText)
                                
                                Image(systemName: "xmark")
                                    .resizable()
                                    .frame(width: 28.0, height: 28.0)
                                    .foregroundStyle(Colors.elementBackground)
                            }
                            .padding(.top)
                            .padding()
                            .padding()
                        }
                    }
                    Spacer()
                }
            }
            .ignoresSafeArea()
        }
    }
    
    var automaticEntryView: some View {
        VStack {
            // Instructions
            Text(instructionText)
                .font(.custom(Constants.FontName.light, size: 14.0))
                .multilineTextAlignment(.center)
                .opacity(0.4)
            Text(instructionExampleText)
                .font(.custom(Constants.FontName.lightOblique, size: 14.0))
                .multilineTextAlignment(.center)
                .opacity(0.4)
            
            // Add with Camera Button
            Button(action: {
                HapticHelper.doLightHaptic()
                
                isShowingCaptureCameraView = true
            }) {
                ZStack {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .imageScale(.medium)
                    }
                    HStack {
                        Spacer()
                        Image(systemName: "camera")
                            .font(.body, 20.0)
                        Text("Scan to Add")
                            .font(.custom(Constants.FontName.heavy, size: 20.0))
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14.0)
                        .stroke(Colors.elementBackground)
                    RoundedRectangle(cornerRadius: 14.0)
                        .fill(Colors.foreground)
                }
            )
            .foregroundStyle(Colors.elementBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14.0))
            .padding(.top, 8)
            
            // Add with Camera Description
            HStack {
                Text("Take a picture of your pantry, fridge, receipt items, and more. AI will automatically find and add items.")
                    .font(.custom(Constants.FontName.light, size: 14.0))
                    .multilineTextAlignment(.center)
                    .opacity(0.4)
                Spacer()
            }
        }
    }
    
    func addToPantryViewListItem<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(spacing: 0.0) {
            HStack {
                content()
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(Colors.foregroundText)
            .padding()
            .background(Colors.foreground)
            
            Divider()
        }
    }
    
    func parseAutomaticEntryText() {
        // Loop through automaticEntryText split by comma separator
        for item in automaticEntryText.split(separator: ", ") {
            // Ensure automaticEntryText is not in automaticEntryItems, otherwise return
            guard !automaticEntryItems.contains(String(item)) else {
                alertShowingDuplicateAutomaticEntryItem = true
                return
            }
            
            // Take automaticEntryText and add it to automaticEnteredItems
            automaticEntryItems.append(String(item))
        }
        
        // Set automaticEntryText to blank
        automaticEntryText = ""
    }
    
    func savePantryItems() async {
        defer { DispatchQueue.main.async { self.isLoading = false } }
        await MainActor.run { isLoading = true }
        
        // Save pantry items
        do {
            try await pantryItemsParser.parseSavePantryItems(
                input: automaticEntryItems.joined(separator: ", ") + "\n" + automaticEntryText,
                in: viewContext)
            
            // Do success haptic
            HapticHelper.doSuccessHaptic()
        } catch PantryItemPersistenceError.duplicatePantryItemNames(let duplicatePantryItemNames) {
            // Do warning haptic
            HapticHelper.doWarningHaptic()
            
            // Set instance dupliactePantryItemsNames to dupliactePantryItemNames from error
            self.duplicatePantryItemNames = duplicatePantryItemNames
            alertShowingDuplicateObjectWhenInserting = true
        } catch {
            // TODO: Handle errors
            print("Error parsing and saving bar items in body in InsertPantryItemView... \(error)")
        }
    }
    
}

extension View {
    
    func addToPantryPopup(isPresented: Binding<Bool>, showCameraOnAppear: Bool) -> some View {
        self
            .fullScreenCover(isPresented: isPresented) {
                NavigationStack {
                    AddToPantryView(
                        showCameraOnAppear: showCameraOnAppear,
                        onDismiss: { isPresented.wrappedValue = false })
                }
            }
    }
    
}

#Preview {
    
    NavigationStack {
        AddToPantryView(
            showCameraOnAppear: false,
//            onUseManualEntry: {
//                
//            },
            onDismiss: {
                
            }
        )
    }
    
}
