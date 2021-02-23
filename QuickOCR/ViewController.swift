//
//  ViewController.swift
//  QuickOCR
//
//  Created by Zheng on 2/23/21.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var dropView: DropView!
    @IBOutlet weak var imageView: NSImageView!
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    var currentCachingProcess: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.alphaValue = 0
        dropView.layer?.cornerRadius = 6
        
        dropView.returnImageURL = { [weak self] (imageURL, nsImage) in
            guard let self = self else { return }
            
            if let url = imageURL {
                self.handleFileURLObject(url)
            } else if let image = nsImage {
                self.processImage(image: image)
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if let currentWindow = self.view.window {
            
            currentWindow.setFrame(NSRect(x: currentWindow.frame.origin.x, y: currentWindow.frame.origin.y, width: 400,height: 200), display: true)
        }
    }
    
    override var representedObject: Any? {
        didSet {
            
        }
    }
    
    func handleFileURLObject(_ url: URL) {
        if let image = NSImage(contentsOfFile: url.path) {
                processImage(image: image)
        }
    }
    func processImage(image: NSImage) {
        var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        if let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) {
            imageView.image = image
            search(in: imageRef)
            resize()
        }
    }
    
    func resize(customSize: NSSize? = nil, animate: Bool = true) {
        var windowFrame = view.window?.frame ?? NSRect(x: 0, y: 0, width: 100, height: 100)
        
        let oldWidth = windowFrame.size.width
        
        var newWidth = oldWidth
        var newHeight = CGFloat(400)
        if let custom = customSize {
            newWidth = custom.width
            newHeight = custom.height
        }
        
        windowFrame.size = NSMakeSize(newWidth, newHeight)
        view.window?.setFrame(windowFrame, display: true, animate: animate)
    }
}

class DropView: NSView {
    
    var hasFilePath = false
    let expectedExt = ["jpg", "png"]
    
    var returnImageURL: ((URL?, NSImage?) -> Void)?
    
    var inactiveColor = NSColor(calibratedRed: 0.3, green: 0.3, blue: 0.3, alpha: 0.3)
    var activeColor = NSColor(calibratedRed: 0, green: 0, blue: 0.8, alpha: 0.3)
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.wantsLayer = true
        self.layer?.backgroundColor = inactiveColor.cgColor
        
        registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if checkExtension(sender) == true {
            self.layer?.backgroundColor = activeColor.cgColor
            return .copy
        } else {
            return NSDragOperation()
        }
    }
    
    fileprivate func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        guard let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = board[0] as? String
        else { return false }

        let suffix = URL(fileURLWithPath: path).pathExtension
        
        for ext in self.expectedExt {
            if ext.lowercased() == suffix {
                return true
            }
        }
        return false
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        if hasFilePath {
            self.layer?.backgroundColor = NSColor.clear.cgColor
        } else {
            self.layer?.backgroundColor = inactiveColor.cgColor
        }
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        if hasFilePath {
            self.layer?.backgroundColor = NSColor.clear.cgColor
        } else {
            self.layer?.backgroundColor = inactiveColor.cgColor
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        guard let pasteboardObjects = sender.draggingPasteboard.readObjects(forClasses: [NSImage.self, NSColor.self, NSString.self, NSURL.self], options: nil), pasteboardObjects.count > 0 else {
            return false
        }
        
        pasteboardObjects.forEach { (object) in
            if let image = object as? NSImage {
                print("Image dropped")
                returnImageURL?(nil, image)
                hasFilePath = true
            }
            
            if let url = object as? NSURL {
                print("URL dropped")
                returnImageURL?(url as URL, nil)
                hasFilePath = true
            }
        }
        return true
    }
}
