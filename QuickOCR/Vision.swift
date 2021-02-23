//
//  Vision.swift
//  QuickOCR
//
//  Created by Zheng on 2/23/21.
//

import Cocoa
import Vision


extension ViewController {
    func search(in cgImage: CGImage) {
        
        
        let thisProcessIdentifier = UUID()
        currentCachingProcess = thisProcessIdentifier
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            let request = VNRecognizeTextRequest { request, error in
                self.handleCachedText(request: request, error: error, thisProcessIdentifier: thisProcessIdentifier)
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en_GB"]
            
            
            let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            do {
                try imageRequestHandler.perform([request])
            } catch let error {
                self.currentCachingProcess = nil
                print("Error: \(error)")
            }
        }

    }
    
    func handleCachedText(request: VNRequest?, error: Error?, thisProcessIdentifier: UUID) {
        print("done")
        
        guard thisProcessIdentifier == currentCachingProcess else { return }
        
        currentCachingProcess = nil
        
        guard let results = request?.results, results.count > 0 else {
            print("no results")
            return
        }
        
        
        var string = ""
        for result in results {
            if let observation = result as? VNRecognizedTextObservation {
                for text in observation.topCandidates(1) {
                    string.append(text.string + "\n")
                }
            }
        }
        
        DispatchQueue.main.async {
            
            self.textView.string = string
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                
                self.scrollView.animator().alphaValue = 1
            }
        }
        
    }
}
