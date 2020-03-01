/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Contains the `ImageViewerController` view controller class, which displays an `ImageFile.`
*/

import Cocoa


/**
    `ImageViewerController` displays an `ImageFile` in a scrollable `NSImageView`. It shows
    shows the title of the set image file in a `NSTextField` label.
*/
class ImageViewerController: NSViewController {
    // MARK: Properties

    override var nibName : String {
        return "ImageViewerController"
    }
    
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var titleField: NSTextField!
    @IBOutlet var bottomOverlayView: NSVisualEffectView!

    var imageFile: ImageFile? {
        didSet {
            guard isViewLoaded else { return }

            updateImageViewWithImageFile(imageFile)
        }
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        /*
            Turn on translatesAutoresizingMaskIntoConstraints, Interface Builder
            turns this off for all views in a nib. The `NSScrollView` and `NSClipView` 
            expect to be able to control their documentView via modifying its `frame`.
        */
        imageView.translatesAutoresizingMaskIntoConstraints = true

        /*
            Turn off the automatic content insets on the image's scroll view. The
            bottom overlay view will be included in the content insets, which will
            be manually added in.
        */
        scrollView.automaticallyAdjustsContentInsets = false

        updateImageViewWithImageFile(imageFile)
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        // Update the content insets now that the image viewer is in a window.
        updateScrollViewContentInsets()
    }

    /**
        Updates the `scrollView`'s `contentInsets` based on the containing window's
        `contentLayoutRect` and the size of the bottom bar that covers the bottom 
        of the scroll view.
    */
    fileprivate func updateScrollViewContentInsets() {
        // Verify the view is loaded and in a window.
        guard isViewLoaded else { return }
        guard let window = view.window else { return }

        let contentLayoutRect = window.contentLayoutRect

        /*
            Convert the `contentLayoutRect` to the coordinate space of and clipped 
            to the bounds of the image view's scroll view.
        */
        let scrollViewContentLayoutRect = scrollView.convert(contentLayoutRect, from: nil).intersection(scrollView.bounds)

        let minYContentLayoutRectInset = scrollViewContentLayoutRect.minY - scrollView.bounds.minY
        let maxYContentLayoutRectInset = scrollView.bounds.maxY - scrollViewContentLayoutRect.maxY

        /*
            Get the rect of the bottom bar in the coordinate space of and clipped 
            to the bounds of the image view's scroll view.
        */
        let scrollViewBottomBarRect = scrollView.convert(bottomOverlayView.bounds, from: bottomOverlayView).intersection(scrollView.bounds)

        /*
            Calculate the contentInsets based on the `contentLayoutRect` and the
            bottom bar. The top inset is purely based on the `contentLayoutRect`'s
            inset. The bottom inset is the maximum of the inset from the 
            `contentLayoutRect` and the bottom bar.
        */
        let topEdgeInset = scrollView.isFlipped ? minYContentLayoutRectInset : maxYContentLayoutRectInset

        let bottomEdgeInset = max((scrollView.isFlipped ? maxYContentLayoutRectInset : minYContentLayoutRectInset), scrollViewBottomBarRect.height)
        
        scrollView.contentInsets = NSEdgeInsets(top: topEdgeInset, left: 0, bottom: bottomEdgeInset, right: 0)
    }

    func updateImageViewWithImageFile(_ imageFile: ImageFile?) {
        if let imageFile = imageFile {
            /*
                Fetch the `ImageFile`'s image representation and update set it on
                the image view.
            */
            imageFile.fetchImageWithCompletionHandler { image in
                /*
                    Verify that the loaded image representation is from the currently
                    set `ImageFile`.
                */                
                guard self.imageFile == imageFile else { return }

                self.imageView.image = image

                /*
                    Size the ImageView to match the new image size, and zoom
                    to fit the entire new image.
                */
                self.imageView.frame = NSRect(origin: NSPoint.zero, size: image.size)
                self.scrollView.magnify(toFit: self.imageView.frame)
            }
        }
        else {
            imageView.image = nil
        }

        /*
            Update the title field using the image name, using an empty string if
            there is none.
        */
        titleField.stringValue = imageFile?.fileNameExcludingExtension ?? ""
    }
}
