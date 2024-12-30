//
//  EasyPantryUpdateContainer.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 11/29/24.
//

import SwiftUI

struct EasyPantryUpdateContainer: View {
    
    let onClose: () -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var constantsUpdater: ConstantsUpdater
    
    @State private var selectedItems: [PantryItem] = []
    
//    private var selectedOlderThanDay: Binding<Int> {
//        Binding(
//            get: {
//                constantsHelper.easyPantryUpdateContainerOlderThanDays
//            },
//            set: { value in
//                ConstantsHelper.easyPantryUpdateContainerOlderThanDays = value
//            })
//    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Remove Old Items...")
                    .font(.custom(Constants.FontName.heavy, size: 24.0))
                    .padding(.horizontal)
                HStack {
                    Text("Showing items older than")
                        .font(.custom(Constants.FontName.body, size: 14.0))
                    Menu(content: {
                        ForEach(0...11, id: \.self) { index in
                            Button(action: {
                                // Reset selectedItems
                                selectedItems = []
                                
                                // Set older than days
                                constantsUpdater.easyPantryUpdateContainerOlderThanDays = index
                            }) {
                                Text("\(index) days")
//                                    .tag(index)
//                                    .font(.largeTitle)
                            }
                        }
                    }) {
                        HStack {
                            Text("\(constantsUpdater.easyPantryUpdateContainerOlderThanDays) days")
                                .font(.custom(Constants.FontName.heavy, size: 14.0))
                                .underline()
                            
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .foregroundStyle(Colors.elementBackground)
                    }
                }
                .padding(.horizontal)
                
                EasyPantryUpdateView(
                    olderThanDays: constantsUpdater.easyPantryUpdateContainerOlderThanDays,
                    onClose: onClose,
                    selectedItems: $selectedItems,
                    beforeDaysAgoDateSectionedPantryItems: SectionedFetchRequest<String?, PantryItem>(
                        sectionIdentifier: \.daysAgoString,
                        sortDescriptors: [
                            NSSortDescriptor(keyPath: \PantryItem.updateDate, ascending: true),
                            NSSortDescriptor(keyPath: \PantryItem.name, ascending: true)
                        ],
                        predicate: NSPredicate(format: "%K <= %@", #keyPath(PantryItem.updateDate), Calendar.current.date(byAdding: .day, value: -constantsUpdater.easyPantryUpdateContainerOlderThanDays, to: Date())! as NSDate),
                        animation: .default))
                
                Spacer()
            }
            .padding()
        }
        .background(Colors.background)
    }
}

extension View {
    
    func easyPantryUpdateContainerPopup(isPresented: Binding<Bool>) -> some View {
        self
            .fullScreenCover(isPresented: isPresented) {
                NavigationStack {
                    EasyPantryUpdateContainer(onClose: {
                        isPresented.wrappedValue = false
                    })
                }
            }
    }
    
}

#Preview {
    
    NavigationStack {
        EasyPantryUpdateContainer(onClose: {
            
        })
    }
    .environment(\.managedObjectContext, CDClient.mainManagedObjectContext)
    .environmentObject(ConstantsUpdater())
    
}
