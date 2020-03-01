/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Contains a simple window controller subclass that displays a list of `ImageCollection`s.
*/

import Cocoa

/**
    `GalleryWindowController` is a window controller that displays a list of 
    `ImageCollection`s. It creates and manages the connections between three split 
    panes in a `NSSplitViewController` setup as its `contentViewController`.
*/
class GalleryWindowController: NSWindowController {
    // MARK: Properties

    override var windowNibName: String {
        return "GalleryWindowController"
    }

    /// The identifier used for `NSSplitView`'s autosaving and state restoration.
    static let splitViewResorationIdentifier = "GallerySplitView"

    /**
        The controller that displays a list of available `ImageCollection`s in a 
        source list-style outline view. Shown as the sidebar of the main split view.
    */
    lazy var sidebarController: ImageCollectionListController = {
        let collectionController = ImageCollectionListController()

        /*
            Initialize the `imageCollections` to start with a collection referencing
            the system's desktop pictures.
        */
        let desktopPicturesURL = URL(fileURLWithPath: "/Library/Desktop Pictures/", isDirectory: true)
        let desktopPicturesCollection = ImageCollection(rootURL: desktopPicturesURL)
        desktopPicturesCollection.tableViewIcon = NSImage(named: "DesktopTemplate")!
        collectionController.imageCollections = [desktopPicturesCollection]

        /*
            When the selected collection changes, update the image list controller
            to visualize that collection.
        */
        collectionController.imageCollectionSelectionHandler = { [weak self] collections in
            self?.imageListController.imageCollections = collections
        }

        return collectionController
    }()

    /**
        The controller that displays a list of images from the selected `ImageCollection` 
        in a collection view. Shown as the content list of the main split view.
    */
    lazy var imageListController: ImageListController = {
        let imageListController = ImageListController()

        /*
            When the selected image changes, update our image viewer controller
            to visualize that image.
        */
        imageListController.imageSelectionHandler = { [weak self] imageFile in
            self?.imageViewerController.imageFile = imageFile
        }

        return imageListController
    }()

    /**
        The controller that displays a single `ImageFile` in an `NSImageView`. Shown
        as the primary cotnent of the main split view.
    */
    lazy var imageViewerController: ImageViewerController = ImageViewerController()

    /// The main split view controller used as the `contentViewController` of the window.
    lazy var splitViewController: NSSplitViewController = {
        // Create a split view controller to contain split view items.
        let splitViewController = NSSplitViewController()

        splitViewController.minimumThicknessForInlineSidebars = 992.0
        splitViewController.view.wantsLayer = true

        // Create a sidebar SplitViewItem. This has metrics and behaves like system standard sidebars.
        let sidebarSplitViewItem = NSSplitViewItem(sidebarWithViewController: self.sidebarController)
        splitViewController.addSplitViewItem(sidebarSplitViewItem)

        /*
            Create a content list `NSSplitViewItem`. This has metrics like system standard
            content lists. Even though it is a collection view rather than table
            view, it still follows the content list pattern.
        */
        let imageListControllerSplitViewItem = NSSplitViewItem(contentListWithViewController: self.imageListController)
        splitViewController.addSplitViewItem(imageListControllerSplitViewItem)

        // Create a standard `NSSplitViewItem`.
        let imageViewerSplitViewItem = NSSplitViewItem(viewController: self.imageViewerController)
        imageViewerSplitViewItem.minimumThickness = 300
        splitViewController.addSplitViewItem(imageViewerSplitViewItem)

        splitViewController.splitView.autosaveName = GalleryWindowController.splitViewResorationIdentifier
        splitViewController.splitView.identifier = NSUserInterfaceItemIdentifier(rawValue: GalleryWindowController.splitViewResorationIdentifier)

        return splitViewController
    }()

    // MARK: Life Cycle

    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = window else {
            fatalError("`window` is expected to be non nil by this time.")
        }

        // Hide the title, so the toolbar is placed in the titlebar region.
        window.titleVisibility = .hidden

        /*
            Make sure the `contentViewController`'s view frame size matches the
            restored window size. Setting a window's `contentViewController` will
            update the window frame size from the view frame size.
        */
        let frameSize = window.contentRect(forFrameRect: window.frame).size

        splitViewController.view.setFrameSize(frameSize)
        
        window.contentViewController = splitViewController
    }
    
    // MARK: IBActions

    @IBAction func addImageCollection(_ sender: AnyObject?) {
        sidebarController.showOpenPanelToAddImageCollection(sender)
    }
}
