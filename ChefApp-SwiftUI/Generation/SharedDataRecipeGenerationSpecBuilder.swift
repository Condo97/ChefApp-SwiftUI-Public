//
//  ImportedRecipeGenerator.swift
//  ChefApp-SwiftUI
//
//  Created by Alex Coundouriotis on 12/20/24.
//

import Foundation
import PDFKit

class SharedDataRecipeGenerationSpecBuilder: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var recipeGenerationSpec: RecipeGenerationSpec?
    
    func buildRecipeGenerationSpec(from sharedData: SharedData) async {
        // Defer setting isLoadingExtensionAttachment to false
        defer {
            DispatchQueue.main.async { self.isLoading = false }
        }
        
        // Set isLoadingExtensionAttachment to true
        await MainActor.run {
            isLoading = true
        }
        
        // Get text from attachment
        guard let text = await getText(from: sharedData) else {
            // TODO: Handle Errors
            print("Could not unwrap text from sharedData in MainContainer!")
            return
        }
        
        // Process Recipe with this as the input and show the creator page
        await MainActor.run {
            recipeGenerationSpec = RecipeGenerationSpec(
                pantryItems: [],
                suggestions: [],
                input: text,
                generationAdditionalOptions: .normal)
        }
    }
    
    func getText(from sharedData: SharedData) async -> String? {
        if let urlString = sharedData.url,
           let url = URL(string: urlString) {
            do {
                if let receivedText = try await WebpageTextReader.getWebpageText(externalURL: url) {
                    return receivedText
                }
                
                // TODO: Prompt GPT with text
            } catch {
                // TODO: Handle Errors
                print("Error reading webpage text in WriteSmith_SwiftUIApp... \(error)")
            }
        }
        
        if let text = sharedData.text {
            return text
        }
        
        if let pdfAppGroupFilepath = sharedData.pdfAppGroupFilepath {
            if let pdfData = AppGroupLoader(appGroupIdentifier: Constants.Additional.appGroupID)
                .loadData(from: pdfAppGroupFilepath),
               let pdfDocument = PDFDocument(data: pdfData) {
                return PDFReader.readPDF(from: pdfDocument)
            }
        }
        
        return nil
    }
    
    
}
