//
//  PantryView.swift
//  Barback
//
//  Created by Alex Coundouriotis on 9/30/23.
//

import SwiftUI

struct PantryView: View {
    
//    @Binding var selectedItems: [PantryItem]
//    let multipleSelection: Bool = true
//    @Binding var isActive: Bool
//    let showsEditButton: Bool = false
//    @Binding var shouldShowEntryView: Bool
    
    @Binding var selectedItems: [PantryItem]
//    var multipleSelection: Bool = true
    var showsEditButton: Bool = false
    let onDismiss: () -> Void
    var onCreateRecipe: (() -> Void)? = nil
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var pantryItemsCategorizer: PantryItemsCategorizer = PantryItemsCategorizer()
    
    @State private var isShowingAddPantryItemView: Bool = false
    @State private var isShowingAddPantryItemCameraView: Bool = false
    
    @State private var editMode = EditMode.inactive
    
    var pantryIsEmpty: Bool {
        let fetchRequest = PantryItem.fetchRequest()
        fetchRequest.fetchLimit = 1
        do {
            return try viewContext.performAndWait { try viewContext.count(for: fetchRequest) } == 0
        } catch {
            // TODO: Handle Errors if Necessary
            print("Error counting pantry items in PantryView... \(error)")
            return false
        }
    }
    
    
    var body: some View {
        ZStack {
            ZStack {
                VStack {
                    filterSelection
                    
                    ScrollView {
                        Spacer(minLength: 28.0)
                        
                        // Refresh and Add buttons
                        if !pantryIsEmpty {
                            HStack {
                                refreshPantryCategoriesButton
                                
                                addPantryItemsButton
                            }
                            .padding([.leading, .trailing])
                        }
                        
                        // Create Recipe button
                        if !selectedItems.isEmpty {
                            if onCreateRecipe != nil {
                                Button(action: {
                                    HapticHelper.doLightHaptic()
                                    
                                    withAnimation {
                                        onCreateRecipe?()
                                    }
                                }) {
                                    ZStack {
                                        Text("Create Recipe")
                                            .font(.custom(Constants.FontName.heavy, size: 20.0))
                                        
                                        HStack {
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .imageScale(.medium)
                                        }
                                    }
                                    .foregroundStyle(Colors.elementText)
                                    .padding()
                                    .background(Colors.elementBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 14.0))
                                }
                                .buttonStyle(.plain)
                                .padding([.leading, .trailing])
                            }
                        }
                        
                        // Empty pantry items display
                        if pantryIsEmpty {
                            VStack {
                                // Empty pantry information
                                Text("Empty Pantry")
                                    .font(.heavy, 20)
                                Text("Scan your fridge or pantry to add items.")
                                    .font(.body, 17)
                                    .padding(.bottom)
                                
                                // Scan pantry button
                                Button(action: {
                                    isShowingAddPantryItemCameraView = true
                                }) {
                                    ZStack {
                                        Text("Scan Fridge or Pantry")
                                            .font(.heavy, 17)
                                        HStack {
                                            Spacer()
                                            Image(systemName: "camera")
                                                .font(.body, 17)
                                        }
                                    }
                                    .appButtonStyle()
                                }
                                
                                // Add pantry button
                                Button(action: {
                                    isShowingAddPantryItemView = true
                                }) {
                                    ZStack {
                                        Text("Add Items Manually")
                                            .font(.heavy, 17)
                                        HStack {
                                            Spacer()
                                            Image(systemName: "plus")
                                                .font(.body, 17)
                                        }
                                    }
                                    .appButtonStyle(foregroundColor: Colors.elementBackground, backgroundColor: Colors.elementText)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Pantry items
                        HStack {
                            PantryItemsContainer(
                                selectedItems: $selectedItems,
                                editMode: $editMode,
                                showsContextMenu: true,
                                selectionColor: .green)
                            //                                .fixedSize(horizontal: true, vertical: false) // TODO: Fix this so that it expands properly and stuff
                            
                            Spacer()
                        }
                        
                        Spacer(minLength: 80.0)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Colors.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    HapticHelper.doLightHaptic()
                    
                    withAnimation {
                        onDismiss()
                    }
                }) {
                    Text("Close")
                        .font(.custom(Constants.FontName.black, size: 20.0))
                        .foregroundStyle(Colors.elementBackground)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    HapticHelper.doLightHaptic()
                    
                    withAnimation {
                        if editMode == .active {
                            editMode = .inactive
                        } else {
                            editMode = .active
                        }
                    }
                }) {
                    Text(editMode == .active ? "\(Image(systemName: "checkmark")) Done" : "\(Image(systemName: "pencil.line")) Edit")
                        .font(.custom(Constants.FontName.black, size: 20.0))
                        .foregroundStyle(Colors.elementBackground)
                }
            }
        }
        .navigationTitle("Pantry")
//        .chefAppHeader(
//            showsDivider: true,
//            left: {
//                Button(action: {
//                    HapticHelper.doLightHaptic()
//                    
//                    withAnimation {
//                        onDismiss()
//                    }
//                }) {
//                    Text("Close")
//                        .font(.custom(Constants.FontName.black, size: 20.0))
//                        .foregroundStyle(Colors.elementText)
//                        .padding([.leading, .trailing])
//                        .padding(.bottom, 10)
//                }
//            },
//            right: {
//                Button(action: {
//                    HapticHelper.doLightHaptic()
//                    
//                    withAnimation {
//                        if editMode == .active {
//                            editMode = .inactive
//                        } else {
//                            editMode = .active
//                        }
//                    }
//                }) {
//                    Text(editMode == .active ? "\(Image(systemName: "checkmark")) Done" : "\(Image(systemName: "pencil.line")) Edit")
//                        .font(.custom(Constants.FontName.black, size: 20.0))
//                        .foregroundStyle(Colors.elementText)
//                        .padding([.leading, .trailing])
//                        .padding(.bottom, 10)
//                }
//            })
        .environment(\.editMode, $editMode)
//        .ignoresSafeArea()
        // Add to pantry popup
        .addToPantryPopup(isPresented: $isShowingAddPantryItemView, showCameraOnAppear: false)
        .addToPantryPopup(isPresented: $isShowingAddPantryItemCameraView, showCameraOnAppear: true)
    }
    
    var filterSelection: some View {
        HStack {
            
        }
    }
    
    var addPantryItemsButton: some View {
        Button(action: {
            HapticHelper.doLightHaptic()
            
            withAnimation {
                isShowingAddPantryItemView = true
            }
        }) {
            HStack {
                Spacer()
                Text("\(Image(systemName: "plus")) Add")
                    .font(.custom(Constants.FontName.heavy, size: 17.0))
                    .foregroundStyle(Colors.elementBackground)
                Spacer()
            }
            .padding()
            .background(Colors.foreground)
            .clipShape(RoundedRectangle(cornerRadius: 14.0))
        }
        .buttonStyle(.plain)
    }
    
    var refreshPantryCategoriesButton: some View {
        Button(action: {
            HapticHelper.doLightHaptic()
            
            Task {
                do {
                    try await pantryItemsCategorizer.categorizePantryItems(in: viewContext)
                } catch {
                    // TODO: Handle Errors
                    print("Error categorizing pantry items with PantryItemsCategorizer in PantryView... \(error)")
                }
            }
        }) {
            HStack {
                Spacer()
                
                Text("\(Image(systemName: "arrow.triangle.2.circlepath")) Re-Sort")
                    .font(.custom(Constants.FontName.body, size: 17.0))
                    .foregroundStyle(Colors.elementBackground)
                
                Spacer()
                
                if pantryItemsCategorizer.isLoading {
                    ProgressView()
                        .tint(.black)
                }
            }
            .padding()
            .background(Colors.foreground)
            .clipShape(RoundedRectangle(cornerRadius: 14.0))
            .opacity(pantryItemsCategorizer.isLoading ? 0.4 : 1.0)
            .disabled(pantryItemsCategorizer.isLoading)
        }
        .buttonStyle(.plain)
    }
    
}

#Preview {
    struct TestContentView: View {
        
        @State var selectedItems: [PantryItem] = []
        @State var pantrySelectionViewIsActive: Bool = true
        
        var body: some View {
            ZStack {
//                CircleBackgroundView.standard()
                Colors.background
                if pantrySelectionViewIsActive {
                    NavigationStack {
                        PantryView(
                            selectedItems: $selectedItems,
                            //                        multipleSelection: true,
                            showsEditButton: true,
                            onDismiss: {
                                
                            },
                            onCreateRecipe: {
                                
                            })
                    }
                    .environment(\.managedObjectContext, CDClient.mainManagedObjectContext)
                    .background(Material.thin)
                } else {
                    Button("activate", action: {
                        pantrySelectionViewIsActive = true
                    })
                }
            }
        }
        
    }
    
    return VStack {
        
    }
    .fullScreenCover(isPresented: .constant(true), content: {
        NavigationStack {
            TestContentView()
        }
    })
}
