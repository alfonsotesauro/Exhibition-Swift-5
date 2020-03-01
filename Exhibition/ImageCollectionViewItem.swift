/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Contains the `ImageCollectionViewItem` class, which is a collection view item that displays an `ImageFile`'s thumbnail.
                Also contains `DoubleActionImageView`, which is an image view subclass that has a double click action.
*/

import Cocoa

/**
    The KVO context used for all `ImageCollectionViewItem` instances. This provides
    a stable address to use as the context parameter for the KVO observation methods.
*/
private var imageCollectionViewItemKVOContext = 0

/**
    `ImageCollectionViewItem` is a collection view item that displays `ImageFile`s.
    They display their selection and take into consideration the active state of 
    their containing `collectionView`. Double clicking on the item displays a 
    `StandaloneImageWindowController` with the represented `ImageFile`.
*/
class ImageCollectionViewItem: NSCollectionViewItem {
    // MARK: Properties

    var imageFile: ImageFile? {
        didSet {
            guard isViewLoaded else { return }

            updateImageViewWithImageFile(imageFile)
        }
    }

    override var isSelected: Bool {
        didSet {
            updateAppearanceFromKeyState()
        }
    }
// Alfonso Commented
    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            updateAppearanceFromKeyState()
        }
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        /*
            If the set image view is a `DoubleActionImageView`, set the `doubleAction` 
            to be the double click handler.
        */
        if let imageView = imageView as? DoubleActionImageView {
            imageView.doubleAction = #selector(ImageCollectionViewItem.handleDoubleClickInImageView(_:))
            imageView.target = self
        }

        updateImageViewWithImageFile(imageFile)

        view.layer?.cornerRadius = 2.0

        /*
            Watch for when the containing `collectionView` changes in order to 
            observe its `firstResponder`. Include the old and new `collectionView` 
            in the change dictionary to be able to unobserve the old one.
        */
        addObserver(self, forKeyPath: "collectionView", options: [.initial, .old, .new], context: &imageCollectionViewItemKVOContext)
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        // Observe the window for `keyWindow` state changes.
        if let window = view.window {
            NotificationCenter.default.addObserver(self, selector: #selector(ImageCollectionViewItem.windowDidChangeKeyState(_:)), name: NSWindow.didBecomeKeyNotification, object: window)

            NotificationCenter.default.addObserver(self, selector: #selector(ImageCollectionViewItem.windowDidChangeKeyState(_:)), name: NSWindow.didResignKeyNotification, object: window)
        }

        // Update the selection appearance now that the item is in a window
        updateAppearanceFromKeyState()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        // Stop observing the window for `keyWindow` state changes.
        if let window = view.window {
            NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification, object: window)
            NotificationCenter.default.removeObserver(self, name: NSWindow.didResignKeyNotification, object: window)
        }
    }

    deinit {
        // Stop observing for containing `collectionView` changes.
        self.removeObserver(self, forKeyPath: "collectionView", context: &imageCollectionViewItemKVOContext)


        NotificationCenter.default.removeObserver(self)
    }

    func updateImageViewWithImageFile(_ imageFile: ImageFile?) {
        if let imageFile = imageFile {
            /*
                Fetch the `ImageFile`'s image representation and update set it 
                on the image view.
            */
            imageFile.fetchThumbnailWithCompletionHandler { thumbnail in
                /*
                    Verify that the loaded image representation is from the currently
                    set `ImageFile`.
                */
                if self.imageFile == imageFile {
                    self.imageView?.image = thumbnail
                }
            }
        }
        else {
            imageView?.image = nil
        }
    }

    // MARK: Key Appearance Updating

    fileprivate func updateAppearanceFromKeyState() {
        /*
            If the containing collection view is the first responder in a window 
            that is key, then its items have a key appearance.
        */
        let hasKeyAppearance = collectionView!.isFirstResponder && (collectionView?.window?.isKeyWindow ?? false)

        /*
            If the item has key appearance, it uses the user's set selection color, 
            otherwise uses the standard inactive selection color.
        */
        let baseHighlightColor = hasKeyAppearance ? NSColor.alternateSelectedControlColor : NSColor.secondarySelectedControlColor

        let backgroundColor: CGColor

        switch highlightState {
            case .forSelection:
                backgroundColor = baseHighlightColor.withAlphaComponent(0.4).cgColor

            case .asDropTarget:
                backgroundColor = baseHighlightColor.withAlphaComponent(1.0).cgColor

            default:
                if isSelected {
                    backgroundColor = baseHighlightColor.withAlphaComponent(0.8).cgColor
                }
                else {
                    backgroundColor = NSColor.clear.cgColor
                }
            }
        
        view.layer?.backgroundColor = backgroundColor
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &imageCollectionViewItemKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if let newCollectionView = object as? NSCollectionView, newCollectionView == collectionView && keyPath == "isFirstResponder" {
            /*
                If the item's collection view changed first responder state, the 
                selection appearance may have changed.
            */
            updateAppearanceFromKeyState()
        }
        else if let newImageCollectionViewItem = object as? NSCollectionViewItem, newImageCollectionViewItem == self && keyPath == "collectionView" {
            if let oldCollectionView = change?[NSKeyValueChangeKey.oldKey] as? NSCollectionView {
                // Stop observing the containing collection view for first responder changes.
                oldCollectionView.removeObserver(self, forKeyPath: "isFirstResponder", context: &imageCollectionViewItemKVOContext)
            }

            if let newCollectionView = change?[NSKeyValueChangeKey.newKey] as? NSCollectionView {
                // Observe the containing collection view for `firstResponder` state changes.
                newCollectionView.addObserver(self, forKeyPath: "isFirstResponder", options: .new, context: &imageCollectionViewItemKVOContext)
            }
        }
    }

    @objc fileprivate func windowDidChangeKeyState(_ notification: Notification) {
        // When the window changes key state, the selection appearance may have changed.
        updateAppearanceFromKeyState()
    }

    // MARK: IBActions

    @IBAction func handleDoubleClickInImageView(_ sender: AnyObject?) {
        // On double click, show a new standalone window for the set `image`.
        if let imageFile = imageFile {
            StandaloneImageWindowController.showStandaloneImage(imageFile)
        }
    }
}

/**
     An `NSImageView` subclass with a `doubleAction` that fires on double clicks.
*/
class DoubleActionImageView: NSImageView {
    // MARK: Properties

    var doubleAction: Selector?

    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    // MARK: Event Handling

    override func mouseDown(with event: NSEvent) {
        if let doubleAction = doubleAction , event.clickCount == 2 {
            NSApp.sendAction(doubleAction, to: target, from: self)
        }
        else {
            super.mouseDown(with: event)
        }
    }
}
