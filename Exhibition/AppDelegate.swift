/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application delegate. Creates and holds onto the main window controller.
*/


import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: Properties
    
    let galleryWindowController = GalleryWindowController()
    
    // MARK: Life Cycle
    
    override func awakeFromNib() {
        galleryWindowController.showWindow(nil)
    }
}
