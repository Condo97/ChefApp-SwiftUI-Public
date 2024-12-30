//
//  MainView.swift
//  Barback
//
//  Created by Alex Coundouriotis on 9/16/23.
//

import SwiftUI
import CoreData
import Combine

class MainViewModel: ObservableObject {
    
    @Published var panels: [Panel]?
    
    init() {
        // Setup create panels
        setupCreatePanels()
    }
    
    private func setupCreatePanels() {
        // If panelsJSON can be unwrapped and panels can be completely fetched from the file system, set the createPanelsData to the createPanels from the file system
        if let panelsJSON = CreatePanelsJSONPersistenceManager.get() {
            do {
                if let parsedCreatePanelsData = try PanelParser.parsePanelsGettingImagesFromFiles(fromJson: panelsJSON) {
                    DispatchQueue.main.async {
                        self.panels = parsedCreatePanelsData
                    }
                }
            } catch {
                // TODO: Handle errors
                print("Error parsing panels getting images from files... \(error)")
            }
        }
        
        // Update create panels fetching images from network
        Task {
            await updateCreatePanelsFetchingImagesFromNetwork()
        }
    }
    
    private func updateCreatePanelsFetchingImagesFromNetwork() async {
        do {
            // Get create save panels from PantrybackNetworkPersistenceManager
            try await ChefAppNetworkPersistenceManager.getSaveCreatePanels()
            
            if let panelsJSON = CreatePanelsJSONPersistenceManager.get() {
                do {
                    let parsedCreatePanelsData = try await PanelParser.parsePanelsUpdatingSavedImagesFromNetwork(fromJson: panelsJSON)
                    
                    DispatchQueue.main.async {
                        self.panels = parsedCreatePanelsData
                    }
                } catch {
                    print("Could not parse panel after getting and saving create panels in init in MainViewModel... \(error)")
                }
            }
        } catch {
            print("Could not get create save panels from network in init in MainViewModel... \(error)")
        }
    }
    
}

struct MainView: View {
    
    @ObservedObject var recipeGenerator: RecipeGenerator
    @ObservedObject var recipeGenerationSpec: RecipeGenerationSpec
    //    @Binding var isShowingEntryView: Bool
    @Binding var presentingPanel: Panel?
    let loadingTikTokRecipeProgress: TikTokSourceRecipeGenerator.LoadingProgress?
    
    @Environment(\.managedObjectContext) var viewContext
    @Namespace var panelNamespace
    
    // Fetch requests for pantry items and recipes
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PantryItem.updateDate, ascending: false)],
        animation: .default
    ) private var pantryItems: FetchedResults<PantryItem>
    
    // State objects and variables for various functionalities
    @StateObject private var mainViewModel = MainViewModel()
    @StateObject private var keyboardResponder = KeyboardResponder()
    
    @EnvironmentObject private var constantsUpdater: ConstantsUpdater
    @EnvironmentObject private var premiumUpdater: PremiumUpdater
    @EnvironmentObject private var productUpdater: ProductUpdater
    @EnvironmentObject private var remainingUpdater: RemainingUpdater
    
    @State private var isDisplayingSheetView = true
    @State private var isDisplayingHeader = true
    
    @State private var isShowingAddPantryItemDirectlyToCameraPopup = false
    @State private var isShowingAddPantryItemPopup = false
    @State private var isShowingEasyPantryUpdateContainer: Bool = false
    
    //    @State private var generationItemsSelected: [PantryItem] = []
    //    @State private var generationInput: String = ""
    //    @State private var generationSuggestionsSelected: [String] = []
    //    @State private var generationAdditionalOptions: RecipeGenerationAdditionalOptions = .normal
    
    @State private var isShowingPanelView: Bool = false
    @State private var canPresentPanel: Bool = true
    
    @State private var isShowingAllPantryItemsView: Bool = false
    @State private var presentingRecipe: Recipe? = nil
    
    @State private var isShowingSettingsView: Bool = false
    @State private var isShowingSwipeCardsEntryView: Bool = false
    @State private var isShowingUltraView: Bool = false
    //    @State private var recipeObjectIDShouldPopToRootAlsoDeprecateThisLol: Bool = false
    
    private var isShowingRecipeView: Binding<Bool> {
        Binding(
            get: {
                presentingRecipe != nil
            },
            set: { newValue in
                if !newValue {
                    presentingRecipe = nil
                }
            }
        )
    }
    
    private var shouldShowSheetCraftText: Bool {
        true
    }
    
    var body: some View {
        //        ZStack {
        //            NavigationStack {
        ZStack {
            let _ = Self._printChanges()
            ScrollView(.vertical) {
                VStack(spacing: 0.0) {
                    // Is Loading TikTok Source Recipe Insert
                    if let loadingTikTokRecipeProgress {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Loading TikTok Recipe...")
                                    .font(.heavy, 20)
                                Group {
                                    switch loadingTikTokRecipeProgress {
                                    case .preparing:
                                        Text("Preparing TikTok data...")
                                    case .transcribingVideo:
                                        Text("Transcribing video...")
                                    case .generatingRecipe:
                                        Text("Generating recipe...")
                                    }
                                }
                                .font(.body, 14)
                                .italic()
                                .opacity(0.6)
                            }
                            Spacer()
                            ProgressView()
                        }
                        .foregroundStyle(Colors.foregroundText)
                        .padding()
                        .background(Colors.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: 14.0))
                        .padding(.top)
                        .padding(.horizontal)
                    }
                    
                    //                            Spacer(minLength: 28)
                    //                                todayTitle
                    //                                craftTitle
                    //                                craftDisplay
                    recipeOfTheDay
                        .padding(.vertical)
                    //                                Spacer(minLength: 24.0)
                    //                                pantryTitle
                    //                                horizontalPantryDisplay
                    //                            Spacer(minLength: 16.0)
                    
                    //                                pantryTitle
                    
                    HStack {
                        quickCameraAddToPantryButton
                        showPantryButton
                    }
                    .padding([.leading, .trailing])
                    //                                .fixedSize(horizontal: false, vertical: true)
                    
                    if pantryItems.contains(where: {
                        if let updateDate = $0.updateDate {
                            return updateDate <= Calendar.current.date(byAdding: .day, value: -constantsUpdater.easyPantryUpdateContainerOlderThanDays, to: Date())!
                        }
                        
                        return false
                    }) {
                        easyPantryUpdateButton
                    }
                    
                    Spacer(minLength: 24.0)
                    recipesTitle
                        .padding(.bottom, 8)
                    RecipesView(onSelect: { presentingRecipe = $0 })
                        .sheet(isPresented: isShowingRecipeView) {
                            if let presentingRecipe = presentingRecipe {
                                RecipeView(
                                    recipeGenerator: recipeGenerator,
                                    recipe: presentingRecipe,
                                    onDismiss: { isShowingRecipeView.wrappedValue = false }
                                )
                                .background(Colors.background)
                                .presentationCompactAdaptation(.fullScreenCover)
                            }
                        }
                    Spacer(minLength: 214.0)
                }
            }
            .background(Colors.background)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    HapticHelper.doLightHaptic()
                    
                    isShowingSettingsView = true
                }) {
                    Image(systemName: "gear")
                        .font(.custom(Constants.FontName.heavy, size: 17.0))
                        .foregroundStyle(Colors.elementBackground)
                }
            }
            LogoToolbarItem(foregroundColor: Colors.elementBackground)
            if !premiumUpdater.isPremium {
                UltraToolbarItem(color: Colors.elementBackground)
            }
        }
        .toolbar(isDisplayingHeader ? .visible : .hidden)
        .toolbarBackground(Colors.background, for: .navigationBar)
        //                .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $isShowingPanelView) {
            if let panel = presentingPanel {
                PanelView(
                    recipeGenerator: recipeGenerator,
                    panel: panel,
                    isShowing: $isShowingPanelView
                )
                .background(Colors.background)
            }
        }
        .navigationDestination(isPresented: $isShowingSettingsView) {
            SettingsView(
                premiumUpdater: premiumUpdater,
                isShowing: $isShowingSettingsView
            )
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                // Do light haptic
                HapticHelper.doLightHaptic()
                
                // Show entry view
                withAnimation {
                    isShowingSwipeCardsEntryView = true
                }
            }) {
                ZStack {
                    Spacer()
                    Text("Create Recipe")
                        .font(.custom("copperplate-bold", size: 24.0))
                        .foregroundStyle(Colors.elementText)
                    
                    HStack {
                        Spacer()
                        
                        Text(recipeGenerator.isCreating ? "" : "\(Image(systemName: "arrow.right"))")
                            .font(.custom("copperplate-bold", size: 17.0))
                            .foregroundStyle(Colors.elementText)
                        
                        if recipeGenerator.isCreating {
                            ProgressView()
                                .tint(Colors.elementText)
                        }
                    }
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14.0)
                    .fill(Colors.elementBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20.0))
            .bounceable()
            .padding()
            .background(Material.regular)
        }
        .background(Colors.background)
        // Add to pantry popup
        .addToPantryPopup(isPresented: $isShowingAddPantryItemDirectlyToCameraPopup, showCameraOnAppear: true)
        .addToPantryPopup(isPresented: $isShowingAddPantryItemPopup, showCameraOnAppear: false)
        // EasyPantryUpdateContainer popup
        .easyPantryUpdateContainerPopup(isPresented: $isShowingEasyPantryUpdateContainer)
        // Sheet for all pantry items view
        .fullScreenCover(isPresented: $isShowingAllPantryItemsView) {
            NavigationStack {
                PantryContainer(
                    showsEditButton: true,
                    onDismiss: {
                        isShowingAllPantryItemsView = false
                    },
                    onCreateRecipe: { selectedItems in
                        // Set recipeGenerationSpec pantryItems to selectedItems
                        self.recipeGenerationSpec.pantryItems = selectedItems
                        
                        DispatchQueue.main.async {
                            self.isShowingAllPantryItemsView = false
                        }
                        
                        //                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.59) {
                        //                            self.isShowingEntryView = true
                        //                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.59) {
                            self.isShowingSwipeCardsEntryView = true
                        }
                    })
                .background(Colors.background)
            }
        }
        // Create recipe swipe cards
        .fullScreenCover(isPresented: $isShowingSwipeCardsEntryView) {
            NavigationStack {
                RecipeSaveGenerationSwipeContainer(
                    //                    recipeGenerator: recipeGenerator,
                    recipeGenerationSpec: recipeGenerationSpec,
                    onClose: {
                        isShowingSwipeCardsEntryView = false
                    })
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    LogoToolbarItem(foregroundColor: Colors.elementBackground)
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            isShowingSwipeCardsEntryView = false
                        }) {
                            Text("Close")
                                .font(.heavy, 17)
                                .foregroundStyle(Colors.elementBackground)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Components
    
    private var todayTitle: some View {
        HStack {
            Text("Today")
                .font(.custom(Constants.FontName.heavy, size: 20.0))
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var craftTitle: some View {
        HStack {
            Text("Craft")
                .font(.custom(Constants.FontName.black, size: 24.0))
                .foregroundStyle(Colors.foregroundText)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var craftDisplay: some View {
        ScrollView(.horizontal) {
            let columns = Array(repeating: GridItem(.fixed(140)), count: 2)
            LazyHGrid(rows: columns) {
                if let panels = mainViewModel.panels {
                    ForEach(panels) { panel in
                        Button(action: {
                            HapticHelper.doLightHaptic()
                            
                            if canPresentPanel {
                                withAnimation(.spring(duration: 0.2)) {
                                    presentingPanel = panel
                                    isShowingPanelView = true
                                }
                            }
                        }) {
                            PanelMiniView(
                                panel: panel,
                                textStyle: Colors.foregroundText,
                                background: Colors.foreground,
                                namespace: panelNamespace
                            )
                            .background(Colors.foreground)
                            .clipShape(RoundedRectangle(cornerRadius: 28.0))
                        }
                        .tint(Colors.foregroundText)
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.never)
    }
    
    private var recipeOfTheDay: some View {
        RecipeOfTheDayContainer(
            onSelect: { recipe in
                presentingRecipe = recipe
            },
            onOpenAddToPantry: {
                isShowingAddPantryItemPopup = true
            })
    }
    
    private var pantryTitle: some View {
        HStack {
            Text("Pantry")
                .font(.custom(Constants.FontName.heavy, size: 20.0))
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var quickCameraAddToPantryButton: some View {
        Button(action: {
            HapticHelper.doLightHaptic()
            
            withAnimation(.bouncy(duration: 0.5)) {
                isShowingAddPantryItemDirectlyToCameraPopup = true
            }
        }) {
            ZStack {
                Text(Image(systemName: "camera"))
                    .font(.custom(Constants.FontName.body, fixedSize: 28.0))
                    .foregroundStyle(Colors.foregroundText)
                    .padding(8)
                //                    .offset(x: -1, y: -1)
                    .frame(maxHeight: .infinity)
                    .background(RoundedRectangle(cornerRadius: 14.0)
                        .fill(Colors.foreground)
                        .aspectRatio(1, contentMode: .fill))
                //                .clipShape(RoundedRectangle(cornerRadius: 14.0))
                
                Image(systemName: "plus")
                    .foregroundStyle(Colors.foreground)
                    .fontWeight(.black)
                    .scaleEffect(x: 1.2, y: 1.2)
                    .offset(x: 15, y: 10)
                
                Image(systemName: "plus")
                    .foregroundStyle(Colors.elementBackground)
                    .fontWeight(.black)
                    .offset(x: 15, y: 10)
            }
        }
    }
    
    private var showPantryButton: some View {
        Button(action: {
            HapticHelper.doLightHaptic()
            
            withAnimation {
                isShowingAllPantryItemsView = true
            }
        }) {
            ZStack {
                HStack {
                    Spacer()
                    Text("\(Image(systemName: "list.bullet")) View Pantry")
                        .font(.custom(Constants.FontName.heavy, size: 20.0))
                    Spacer()
                }
                
                //                HStack {
                //                    Spacer()
                //
                //                    Image(systemName: "chevron.right")
                //                        .imageScale(.medium)
                //                }
            }
            .foregroundStyle(Colors.foregroundText)
            .padding()
            .background(Colors.foreground)
            .clipShape(RoundedRectangle(cornerRadius: 14.0))
        }
    }
    
    private var easyPantryUpdateButton: some View {
        Button(action: {
            isShowingEasyPantryUpdateContainer = true
        }) {
            HStack {
                Image(systemName: "exclamationmark")
                    .foregroundStyle(Colors.elementBackground)
                    .font(.custom(Constants.FontName.heavy, size: 17.0))
                    .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Update Pantry")
                        .font(.custom(Constants.FontName.heavy, size: 17.0))
                    Text("Easily remove old items...")
                        .font(.custom(Constants.FontName.body, size: 14.0))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(Colors.foregroundText)
            .padding()
            .background(Colors.foreground)
            .clipShape(RoundedRectangle(cornerRadius: 14.0))
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
    
    private var recipesTitle: some View {
        HStack {
            Text("Recipes")
                .font(.custom(Constants.FontName.heavy, size: 20.0))
            Spacer()
        }
        .padding(.horizontal)
    }
    
    //    // Overlay for introduction view
    //    private var introOverlay: some View {
    //        Group {
    //#if !DEBUG // TODO: Remove this!
    //            if introNotComplete.wrappedValue {
    //                IntroViewSimple()
    //            }
    //#endif
    //        }
    //    }
}

#Preview {
    MainView(
        recipeGenerator: RecipeGenerator(),
        recipeGenerationSpec: RecipeGenerationSpec(
            pantryItems: [],
            suggestions: [],
            input: "",
            generationAdditionalOptions: .normal),
        //        isShowingEntryView: .constant(false),
        presentingPanel: .constant(nil),
        loadingTikTokRecipeProgress: nil
    )
    .environment(\.managedObjectContext, CDClient.mainManagedObjectContext)
    .environmentObject(ConstantsUpdater())
    .environmentObject(PremiumUpdater())
    .environmentObject(ProductUpdater())
    .environmentObject(RemainingUpdater())
}

