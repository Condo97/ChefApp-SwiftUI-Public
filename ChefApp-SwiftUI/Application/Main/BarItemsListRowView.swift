////
////  BarItemsListRowView.swift
////  Barback
////
////  Created by Alex Coundouriotis on 9/29/23.
////
//
//import SwiftUI
//
//struct BarItemsListRowView: View {
//    
//    @Environment(\.managedObjectContext) var viewContext
//    
//    @State var item: BarItem
//    
//    var body: some View {
//        VStack {
//            HStack {
//                VStack {
//                    HStack {
//                        if let title = item.item {
//                            Text(title)
//                                .font(.custom(Constants.FontName.heavy, size: 17.0))
//                            Spacer()
//                        } else {
//                            Text("No Title")
//                                .font(.custom(Constants.FontName.heavyOblique, size: 17.0))
//                            Spacer()
//                        }
//                    }
//                    HStack {
//                        if let updateDate = item.updateDate {
//                            Text(NiceDateFormatter.dateFormatter.string(from: updateDate))
//                                .font(.custom(Constants.FontName.lightOblique, size: 10.0))
//                        } else {
//                            Text("No Date")
//                                .font(.custom(Constants.FontName.lightOblique, size: 10.0))
//                        }
//                        Spacer()
//                    }
//                }
//                Spacer()
//                Image(systemName: "chevron.right")
//            }
//        }
//    }
//    
//}
//
//#Preview {
//    Text("")
////    BarItemsListRowView()
//}
