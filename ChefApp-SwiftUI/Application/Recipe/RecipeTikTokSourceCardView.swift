//
//  RecipeTikTokSourceCardView.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 12/20/24.
//

import SwiftUI

struct RecipeTikTokSourceCardView: View {
    
    let tikTokVideoID: String
    
    @StateObject private var tikTokGetVideoInfoGenerator = TikTokGetVideoInfoGenerator()
    
    @State private var isExpanded: Bool = false
    
    @State private var tikApiGetVideoInfoResponse: TikAPIGetVideoInfoResponse?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            Button(action: { withAnimation(.bouncy(duration: 0.5)) { isExpanded.toggle() } }) {
                HStack {
                    Text("Source TikTok")
                        .font(.heavy, 17.0)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.body, 17.0)
                }
                .padding(.horizontal)
            }
            .foregroundStyle(Colors.foregroundText)
            .padding(.bottom, 8)
            
            if isExpanded {
                TikTokGetVideoInfoCardContainer(
                    tikTokVideoID: tikTokVideoID,
                    tikTokGetVideoInfoGenerator: tikTokGetVideoInfoGenerator,
                    tikApiGetVideoInfoResponse: $tikApiGetVideoInfoResponse)
                .frame(maxHeight: 250.0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
            }
            
            Divider()
        }
    }
    
}

#Preview {
    
    RecipeTikTokSourceCardView(tikTokVideoID: "7257879974500109611")
    
}
