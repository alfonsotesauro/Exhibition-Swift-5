/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Contains a simple `NSWindowController` subclass to display a floating `ImageFile` preview.
*/

import Cocoa

/**
    `StandaloneImageWindowController` is a window controller that displays a floating
    `ImageFile` preview. It is required to follow its aspect ratio in windowed mode,
    but allows that strict sizing to be broken in fullscreen. Demonstrates allowing 
    specialized window sizes to be tileable.
*/
class StandaloneImageWindowController: NSWindowController, NSWindowDelegate {
    // MARK: Properties

    override var windowNibName: String {
        return "StandaloneImageWindowController"
    }

    @IBOutlet var imageView: NSImageView!

    @IBOutlet var aspectRatioConstraint: NSLayoutConstraint!
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var leadingConstraint: NSLayoutConstraint!

    /// The `ImageFile` presented by the receiver.
    var imageFile: ImageFile? {
        didSet {
            /*
                If the window is already loaded, update the image view with the 
                new set image.
            */
            if isWindowLoaded {
                updateImageViewWithImageFile(imageFile)
            }

            /*
                Update the mapping from presented `ImageFile` to presenting
                `StandaloneImageWindowController` when the `image` changes.
            */
            if let oldImage = oldValue {
                StandaloneImageWindowController.imageFileToPresentingStandaloneController[oldImage] = nil
            }

            if let newImage = imageFile {
                StandaloneImageWindowController.imageFileToPresentingStandaloneController[newImage] = self
            }
        }
    }

    // MARK: Life Cycle

    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = window else {
            fatalError("`window` is expected to be non nil by this time.")
        }

        // Hide the titlebar and title.
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // Allow the window to be dragged anywhere.
        window.isMovableByWindowBackground = true

        // Make the window dark, giving it a dark background and fullscreen titlebar
        window.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)


        /*
            Even thought the window is not fullscreen capable or allowed to have
            certain sizes when windowed, always allow it to go into a tile. Its
            constraints will be tweaked before entering fullscreen, see
            `windowWillEnterFullscreen()`.
        */
        window.collectionBehavior = [window.collectionBehavior, .fullScreenAllowsTiling]
      
        window.minFullScreenContentSize = NSSize(width: 1.0, height: 1.0)
        window.maxFullScreenContentSize = NSSize(width: 10000.0, height: 10000.0)
        
        updateImageViewWithImageFile(imageFile)
    }

    fileprivate func updateImageViewWithImageFile(_ imageFile: ImageFile?) {
        // Set the window's title to be the new `ImageFile` name, empty if the no image file.
        window?.title = imageFile?.fileNameExcludingExtension ?? ""

        if let imageFile = imageFile {
            imageFile.fetchImageWithCompletionHandler { image in
                /*
                    Verify that the loaded image representation is from the currently
                    set `ImageFile`.
                */
                if self.imageFile == imageFile {
                    self.imageView?.image = image

                    /*
                        Calculate the aspect ratio of the newly set image and update
                        the constraint from that.
                    */
                    let aspectRatio = image.size.width / image.size.height
                    self.updateAspectRatioConstraintWithAspectRatio(aspectRatio)
                }
            }
        }
        else {
            imageView.image = nil
            updateAspectRatioConstraintWithAspectRatio(1.0)
        }
    }

    /// Updates the `imageView`'s aspect ratio constraint with a new aspect ratio.
    fileprivate func updateAspectRatioConstraintWithAspectRatio(_ aspectRatio: CGFloat) {
        /*
            Deactivate the existing aspect ratio constraint and create a new one 
            with the newly calculated aspect ratio.
        */
        aspectRatioConstraint.isActive = false
        
        aspectRatioConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspectRatio)
        
        aspectRatioConstraint.identifier = "StandaloneImageWindowController.AspectRatio"
        
        aspectRatioConstraint.isActive = true
    }

    // MARK: Full Screen Notifications

    func windowWillEnterFullScreen(_ notification: Notification) {
        /*
            Lower the bottom constraint priority so that the window is not required
            to be sized tightly to the aspect ratio constrained image. When a tile,
            it typically will not follow that aspect ratio sizing.
        */
        bottomConstraint.priority = NSLayoutConstraint.Priority(rawValue: 200.0)
        leadingConstraint.priority = NSLayoutConstraint.Priority(rawValue: 200.0)

        // Show the title while in fullscreen (when the titlebar is revealed on menubar hover).
        window?.titleVisibility = .visible
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        // Reinforce the strict aspect ratio sizing of the window.
        bottomConstraint.priority = NSLayoutConstraint.Priority(rawValue: 999.0)
        leadingConstraint.priority = NSLayoutConstraint.Priority(rawValue: 999.0)

        // Rehide the title.
        window?.titleVisibility = .hidden
    }

    // MARK: ImageFile Presentation Mapping

    /**
        The mapping from presented `ImageFile` to presenting `StandaloneImageWindowController`. 
        This also keeps the presenting window controllers alive for the duration 
        of the presentation.
    */
    fileprivate static var imageFileToPresentingStandaloneController = [ImageFile: StandaloneImageWindowController]()

    /**
        Returns a `StandaloneImageWindowController` for the `ImageFile`. If a window 
        controller is already presenting that `ImageFile`, it returns the existing
        one, otherwise creates a new one.
    */
    fileprivate class func standaloneImageWindowControllerForImage(_ imageFile: ImageFile) -> StandaloneImageWindowController {
        let imageController: StandaloneImageWindowController

        if let existingImageController = StandaloneImageWindowController.imageFileToPresentingStandaloneController[imageFile] {
            // If there is an existing controller for that image, reuse it and just reshow it.
            imageController = existingImageController
        }
        else {
            /*
                Otherwise create a new one. Setting the `image` will associate it 
                with the `ImageFile` to `StandaloneImageWindowController`.
            */
            imageController = StandaloneImageWindowController()
            imageController.imageFile = imageFile
            imageController.window?.layoutIfNeeded()
            imageController.window?.center()
        }

        return imageController
    }

    /**
        Presents the `ImageFile` in a `StandaloneImageWindowController`. If one 
        already exists, it orders its window front. Otherwise it creates a new window
        controller and orders it in.
    */
    class func showStandaloneImage(_ image: ImageFile) {
        let standaloneImageController = standaloneImageWindowControllerForImage(image)

        standaloneImageController.showWindow(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let imageFile = imageFile else { return }

        /*
            When the window closes, remove the mapping from the set `image` to `self` 
            as the presentation has ended. Note that this often will result in `self`
            being deallocated.
        */
        StandaloneImageWindowController.imageFileToPresentingStandaloneController[imageFile] = nil
    }
}
