////
////  BarSelectionEditView.swift
////  Barback
////
////  Created by Alex Coundouriotis on 9/29/23.
////
//
//import SwiftUI
//
//struct BarSelectionEditView: View {
//    
//    @Binding var isShowing: Bool
//    @Binding var elementColor: Color
//    
//    enum FilterStates: String, CaseIterable {
//        case all = "All"
//        case bases = "Base Alcohols"
//        case mixers = "Mixers"
//    }
//    
//    @Namespace var namespace
//    @Environment(\.managedObjectContext) var viewContext
//    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \BarItem.item, ascending: false)], animation: .default) private var allBarItems: FetchedResults<BarItem>
//    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \BarItem.item, ascending: false)], predicate: NSPredicate(format: "%K = %d", #keyPath(BarItem.isAlcohol), true), animation: .default) private var baseBarItems: FetchedResults<BarItem>
//    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \BarItem.item, ascending: false)], predicate: NSPredicate(format: "%K = %d", #keyPath(BarItem.isAlcohol), false), animation: .default) private var mixerBarItems: FetchedResults<BarItem>
//    
//    @State var selectedFilterState: FilterStates = .all
//    @State var editingItem: BarItem?
//    
//    @State var shouldDeleteItem: BarItem?
//    
//    @State var isShowingInsertBarItemView: Bool = false
//    @State var isShowingEditBarItemView: Bool = false
//    @State private var alertShowingDeleteItem: Bool = false
//    
//    var body: some View {
//        ZStack {
//            VStack {
////                header
//                
//                filters
//                
//                //                ScrollView {
//                //                    VStack {
//                List(selectedFilterState == .all ? allBarItems : selectedFilterState == .bases ? baseBarItems : mixerBarItems) { item in
//                    
//                    ZStack {
//                        BarItemsListRowView(item: item)
//                            .background(Colors.foreground)
//                            .onTapGesture {
//                                if item != editingItem {
//                                    withAnimation {
//                                        editingItem = item
//                                        isShowingEditBarItemView = true
//                                    }
//                                } else {
//                                    withAnimation {
//                                        editingItem = nil
//                                        isShowingEditBarItemView = false
//                                    }
//                                }
//                            }
//                            .swipeActions(content: {
//                                Button(action: {
//                                    shouldDeleteItem = item
//                                    alertShowingDeleteItem = true
//                                }) {
//                                    Text("Delete")
//                                }
//                                .tint(Color(uiColor: .systemRed))
//                            })
//                    }
//                }
//                .listStyle(.insetGrouped)
//                //                    }
//                //                    .padding()
//                //                }
//                .background(Colors.background)
//            }
//        }
//        .overlay {
//            if isShowingInsertBarItemView {
//                Color.clear
//                    .background(Material.thin)
//                    .transition(.opacity)
//                GeometryReader { geometry in
//                    VStack {
//                        Spacer()
//                        HStack {
//                            Spacer()
//                            InsertBarItemView(
//                                isShowing: $isShowingInsertBarItemView,
//                                textFieldColor: Colors.foreground,
//                                elementColor: $elementColor)
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
//            }
//        }
//        .overlay {
//            if isShowingEditBarItemView {
//                Color.clear
//                    .background(Material.thin)
//                    .transition(.opacity)
//                GeometryReader { geometry in
//                    VStack {
//                        Spacer()
//                        HStack {
//                            Spacer()
//                            if let editingItem = editingItem {
//                                EditBarItemView(
//                                    item: editingItem,
//                                    isActive: $isShowingEditBarItemView,
//                                    elementColor: $elementColor)
//                                    .padding(24.0)
//                                    .background(Colors.foreground)
//                                    .frame(width: geometry.size.width * (8 / 9))
//                                    .clipShape(RoundedRectangle(cornerRadius: 28.0))
//                            }
//                            Spacer()
//                        }
//                        Spacer()
//                    }
//                }
//                .transition(.move(edge: .bottom))
//            }
//        }
//        .alert("Delete Item", isPresented: $alertShowingDeleteItem, actions: {
//            if let shouldDeleteItem = shouldDeleteItem {
//                Button("Back", role: .cancel, action: {
//                    self.shouldDeleteItem = nil
//                })
//            
//                Button("Delete", role: .destructive, action: {
//                    viewContext.delete(shouldDeleteItem)
//                    
//                    do {
//                        try viewContext.save()
//                        
//                        self.shouldDeleteItem = nil
//                    } catch {
//                        // TODO: Handle errors
//                        print("Error saving viewContext in BarSelectionEditView... \(error)")
//                    }
//                })
//            } else {
//                Button("Done", role: .cancel, action: {
//                    
//                })
//            }
//        }) {
//            if shouldDeleteItem != nil {
//                Text("Are you sure you want to delete this item?")
//            } else {
//                Text("This item cannot be deleted.")
//            }
//        }
//        .barbackHeader(
//            backgroundColor: elementColor,
//            showsDivider: true,
//            left: {
//                Button(action: {
//                    isShowing = false
//                }) {
//                    Text("Close")
//                        .font(.custom(Constants.FontName.heavy, size: 20.0))
//                        .foregroundStyle(Colors.elementText)
//                        .padding(.leading)
//                        .padding(.bottom, 10)
//                }
//            },
//            right: {
//                Button(action: {
//                    withAnimation {
//                        isShowingInsertBarItemView = true
//                    }
//                }) {
//                    Text(Image(systemName: "plus"))
//                        .font(.custom(Constants.FontName.heavy, size: 20.0))
//                        .foregroundStyle(Colors.elementText)
//                        .padding(.trailing)
//                        .padding(.bottom, 10)
//                }
//            })
//        .ignoresSafeArea()
//    }
//    
////    var header: some View {
////        ZStack {
////            HStack {
////                VStack {
////                    Spacer()
////                    Button(action: {
////                        isShowing = false
////                    }) {
////                        Text("Close")
////                            .font(.custom(Constants.FontName.heavy, size: 20.0))
////                            .foregroundStyle(Colors.elementText)
////                            .padding(.leading)
////                            .padding(.bottom, 10)
////                    }
////                }
////                Spacer()
////            }
////            
////            HStack {
////                Spacer()
////                VStack {
////                    Spacer()
////                    Text("Barback")
////                        .font(.custom(Constants.FontName.appname, size: 34.0))
////                        .foregroundStyle(Colors.elementText)
////                        .padding(4)
////                }
////                Spacer()
////            }
////            
////            HStack {
////                Spacer()
////                VStack {
////                    Spacer()
////                    Button(action: {
////                        withAnimation {
////                            isShowingInsertBarItemView = true
////                        }
////                    }) {
////                        Text(Image(systemName: "plus"))
////                            .font(.custom(Constants.FontName.heavy, size: 20.0))
////                            .foregroundStyle(Colors.elementText)
////                            .padding(.trailing)
////                            .padding(.bottom, 10)
////                    }
////                }
////            }
////        }
////        .frame(height: 100)
//////        .background(elementColor)
////    }
//    
//    var filters: some View {
//        HStack {
//            ForEach(FilterStates.allCases, id: \.self) { filterState in
////                        Spacer()
//                Button(action: {
//                    withAnimation {
//                        selectedFilterState = filterState
//                    }
//                }) {
//                    VStack {
//                        Text(filterState.rawValue)
//                            .font(.custom(selectedFilterState == filterState ? Constants.FontName.black : Constants.FontName.body, size: 17.0))
//                            .frame(minWidth: 40.0)
//                        if filterState == selectedFilterState {
//                            RoundedRectangle(cornerRadius: 17.0)
//                                .matchedGeometryEffect(id: "littleUnderline", in: namespace)
//                                .frame(maxHeight: 2)
//                        } else {
//                            Spacer()
//                        }
//                    }
//                }
////                        Spacer()
//            }
//            .padding([.leading, .top, .trailing])
//            .fixedSize(horizontal: true, vertical: true)
//        }
//    }
//    
//    func getItemsToSort(filterState: FilterStates) -> FetchedResults<BarItem> {
//        switch filterState {
//        case .all: allBarItems
//        case .bases: baseBarItems
//        case .mixers: mixerBarItems
//        }
//    }
//    
//}
//
//#Preview {
//    BarSelectionEditView(
//        isShowing: .constant(true),
//        elementColor: .constant(Colors.element))
//        .environment(\.managedObjectContext, CDClient.mainManagedObjectContext)
//        .background(Colors.background)
//        .presentationCompactAdaptation(.fullScreenCover)
//}
