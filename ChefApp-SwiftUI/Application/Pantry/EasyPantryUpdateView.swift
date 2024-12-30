//
//  EasyPantryUpdateView.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 11/29/24.
//

import SwiftUI

struct EasyPantryUpdateView: View {
    
    // TODO: When submitted, update updateDate
    
    let olderThanDays: Int
    let onClose: () -> Void
    @Binding var selectedItems: [PantryItem]
    @SectionedFetchRequest var beforeDaysAgoDateSectionedPantryItems: SectionedFetchResults<String?, PantryItem>
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var allSelected: Bool {
        selectedItems.count == beforeDaysAgoDateSectionedPantryItems.reduce(0) { $0 + $1.count } // This sums up the items in each section
    }
    
    var body: some View {
        VStack {
            Button(action: { // TODO: Move this to PantryItemsView so that it will show in all its uses
                if allSelected {
                    // If all selected remove all from selected items
                    selectedItems = []
                } else {
                    // If not selected select all
                    selectedItems = beforeDaysAgoDateSectionedPantryItems.flatMap { section in
                        section.compactMap { pantryItem in
                            pantryItem as PantryItem
                        }
                    }
                }
            }) {
                HStack {
                    Text(allSelected ? "Deselect All" : "Select All")
                        .font(.heavy, 17)
                    Spacer()
                    Image(systemName: allSelected ? "checkmark.circle.fill" : "checkmark.circle")
                }
                .foregroundStyle(Colors.elementBackground)
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Colors.elementText)
                .clipShape(RoundedRectangle(cornerRadius: 14.0))
            }
            
            if beforeDaysAgoDateSectionedPantryItems.isEmpty {
                Text("No Items")
                    .font(.custom(Constants.FontName.body, size: 17.0))
                    .foregroundStyle(Colors.foregroundText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Colors.foreground.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 14.0))
            } else {
                PantryItemsView(
                    selectedItems: $selectedItems,
                    editMode: .constant(.inactive),
                    sectionedPantryItems: _beforeDaysAgoDateSectionedPantryItems,
                    showsContextMenu: false,
                    selectionColor: .red)
            }
        }
        .toolbarBackground(Colors.elementBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image(Constants.ImageName.navBarLogoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Colors.elementText)
                    .frame(maxHeight: 38.0)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    onClose()
                }) {
                    Text("Close")
                        .font(.custom(Constants.FontName.body, size: 17.0))
                        .foregroundStyle(Colors.elementText)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    Task {
                        for selectedItem in selectedItems {
                            do {
                                try await PantryItemCDClient.deletePantryItem(selectedItem, in: viewContext)
                            } catch {
                                // TODO: Handle Errors
                                print("Error deleting pantry item in EasyPantryUpdateContainer, continuing... \(error)")
                            }
                        }
                        
                        for pantryItemElement in beforeDaysAgoDateSectionedPantryItems {
                            for pantryItem in pantryItemElement {
                                // Set each item's updateDate to one day before the olderThanDays in reference to the current date TODO: Should this be in reference to the ingredient's date? No, because if the item is like 5 days old and olderThanDays is 3, it will set it to 2 days old so that the next day it will show up in the easy pantry update view
                                let newUpdateDate = Calendar.current.date(
                                    byAdding: .day,
                                    value: olderThanDays <= 0 ? 0 : -olderThanDays + 1, // Make sure the olderThanDays result is not less than zero
                                    to: Date()) ?? Date()
                                
                                try await PantryItemCDClient.updatePantryItem(pantryItem, updateDate: newUpdateDate, in: viewContext)
                            }
                        }
                    }
                    
                    onClose()
                }) {
                    Text("Save")
                        .font(.custom(Constants.FontName.heavy, size: 17.0))
                        .foregroundStyle(Colors.elementText)
                }
            }
        }
    }
    
}

#Preview {
    
    NavigationStack {
        EasyPantryUpdateView(
            olderThanDays: 3,
            onClose: {
                
            },
            selectedItems: .constant([]),
            beforeDaysAgoDateSectionedPantryItems: SectionedFetchRequest<String?, PantryItem>(
                sectionIdentifier: \.daysAgoString,
                sortDescriptors: [
                    NSSortDescriptor(keyPath: \PantryItem.updateDate, ascending: true),
                    NSSortDescriptor(keyPath: \PantryItem.name, ascending: true)
                ],
                predicate: NSPredicate(format: "%K <= %@", #keyPath(PantryItem.updateDate), Calendar.current.date(byAdding: .day, value: -3, to: Date())! as NSDate),
                animation: .default))
    }
    .environment(\.managedObjectContext, CDClient.mainManagedObjectContext)
    
}
