//
//  AnimatedGifView.swift
//  Barback
//
//  Created by Alex Coundouriotis on 10/8/23.
//

import Foundation
import SwiftUI

struct AnimatedGifView: UIViewRepresentable {
    
    @State var imageName: String = "giftGif"

    func makeUIView(context: Context) -> UIImageView {
        let image = UIImage.gifImageWithName(imageName)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = .gifImageWithName(imageName)
    }
    
}
