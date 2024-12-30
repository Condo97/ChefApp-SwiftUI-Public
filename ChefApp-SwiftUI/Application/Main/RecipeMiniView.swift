//
//  RecipeMiniView.swift
//  Barback
//
//  Created by Alex Coundouriotis on 9/18/23.
//

import Foundation
import SwiftUI

struct RecipeMiniView: View {
    
    var title: String
    var summary: String?
    var image: UIImage?
    var date: Date
    let isFromTikTok: Bool
    
    static func from(recipe: Recipe) -> RecipeMiniView? {
        guard let title = recipe.name else {
            // TODO: Handle errors
            return nil
        }
        
        let summary = recipe.summary
        let date = recipe.updateDate ?? Date.distantPast
        let image = recipe.imageFromAppData
        let isFromTikTok = recipe.sourceTikTokVideoID != nil
        
        return RecipeMiniView(
            title: title,
            summary: summary,
            image: image,
            date: date,
            isFromTikTok: isFromTikTok)
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack {
                ZStack {
                    Group {
                        if let image = image {
                            Image(uiImage: image) // TODO: Fix image size and modifiers
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                        } else {
                            ZStack {
                                Colors.background
                                ProgressView()
                                    .tint(Colors.foregroundText)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14.0))
                    .frame(width: 48.0, height: 48.0)
                }
                
                HStack {
                    RoundedRectangle(cornerRadius: 14.0)
                        .frame(width: 2)
                        .foregroundStyle(Colors.background)
                        .padding(.leading)
                        .padding(.top, 8)
                }
            }
            Spacer(minLength: 15)
            VStack {
                VStack {
                    HStack(alignment: .top) {
                        Text(title)
                            .font(.custom(Constants.FontName.black, size: 17.0))
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Text(NiceDateFormatter.dateFormatter.string(from: date))
                            .font(.custom(Constants.FontName.body, size: 12.0))
                    }
                    if let description = summary {
                        Spacer()
                        HStack {
                            Text(description)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.custom(Constants.FontName.body, size: 14.0))
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        Spacer()
                    }
                    if isFromTikTok {
                        HStack {
                            Image(Constants.Images.tikTokLogo)
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text("From TikTok")
                                .font(.heavy, 12)
                                .italic()
                                .opacity(0.6)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
}

struct RecipeMiniView_PreviewProvider: PreviewProvider {
    
    static var previews: some View {
        ZStack {
            RecipeMiniView(
                title: "Title",
                summary: "Description",
                image: UIImage(named: "HighballTest")!,
                date: Date(),
                isFromTikTok: true)
        }
        .environmentObject(PremiumUpdater())
        .environmentObject(ProductUpdater())
        .environmentObject(RemainingUpdater())
    }
    
}
