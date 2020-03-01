/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Contains the `ImageListController` view controller subclass that displays the images in an `ImageCollection`.
*/

import Cocoa

/**
    `ImageListController` displays the `ImageFiles` in a given `ImageCollection` in 
    an `NSCollectionView. It can be given a selection handler to report when an 
    `ImageFile` is selected.
*/
class ImageListController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    // MARK: Properties

    override var nibName: String {
        return "ImageListController"
    }
    
    fileprivate static let imageCollectionViewItemIdentifier = "ImageItem"

    @IBOutlet var collectionView: NSCollectionView!

    // MARK: Image File / Collection Management

    var imageSelectionHandler: ((ImageFile?) -> Void)?

    var imageCollections = [ImageCollection]() {
        didSet {
            // Observe the new collections for changes, and unobserve the old collections.
            for collection in oldValue {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ImageCollection.imagesDidChangeNotification), object: collection)
            }

            for collection in imageCollections {
                NotificationCenter.default.addObserver(self, selector: #selector(ImageListController.imageCollectionDidChange(_:)), name: NSNotification.Name(rawValue: ImageCollection.imagesDidChangeNotification), object: collection)
            }

            guard isViewLoaded else { return }

            reloadCollectionViewAndSelectFirstItemIfNecessary()
        }
    }

    @objc func imageCollectionDidChange(_ notification: Notification) {
        reloadCollectionViewAndSelectFirstItemIfNecessary()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        // Tell the CollectionView to use the ImageCollectionViewItem nib for its items.
        let nib = NSNib(nibNamed: "ImageCollectionViewItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: ImageListController.imageCollectionViewItemIdentifier))
       
        // collectionView.register(nib, forItemWithIdentifier: ImageListController.imageCollectionViewItemIdentifier)
        
        collectionView.dataSource = self
        collectionView.delegate = self

        // Create a grid layout that is somewhat flexible for the various widths it might have.
        let gridLayout = NSCollectionViewGridLayout()
        gridLayout.minimumItemSize = NSSize(width: 100, height: 100)
        gridLayout.maximumItemSize = NSSize(width: 175, height: 175)
        gridLayout.minimumInteritemSpacing = 10
        gridLayout.margins = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        collectionView.collectionViewLayout = gridLayout

        reloadCollectionViewAndSelectFirstItemIfNecessary()

        super.viewDidLoad()
    }

    fileprivate func reloadCollectionViewAndSelectFirstItemIfNecessary() {
        collectionView.reloadData()

        // If the `collectionView` has no selection, attempt to select the first available item.
        guard collectionView.selectionIndexPaths.isEmpty else { return }
        
        // Get the collections that contain images.
        let populatedCollections = imageCollections.filter { !$0.images.isEmpty }

        // Find the first `ImageCollection` that actually has images displayed.
        guard let firstPopulatedCollection = populatedCollections.first else { return }

        /*
            Get the index path to that collection's first image -- section is the 
            index of the collection, item index is 0.
        */
        let firstPopulatedIndex = imageCollections.firstIndex(of: firstPopulatedCollection)!

        // Programmatically change the selection, and handle the changed selection.
        collectionView.selectionIndexPaths = [
            IndexPath(item: 0, section: firstPopulatedIndex)
        ]

        handleSelectionChanged()
    }


    // MARK: Collection View Data Source / Delegate

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return imageCollections.count
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageCollections[section].images.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: ImageListController.imageCollectionViewItemIdentifier), for: indexPath)

        if let imageItem = item as? ImageCollectionViewItem {
            // The section maps to the index of the `ImageCollection`.
            let imageCollection = imageCollections[(indexPath as NSIndexPath).section]

            imageItem.imageFile = imageCollection.images[(indexPath as NSIndexPath).item]
        }
    
        return item
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        handleSelectionChanged()
    }

    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        handleSelectionChanged()
    }

    fileprivate func handleSelectionChanged() {
        guard let imageSelectionHandler = imageSelectionHandler else { return }

        /*
            The collection view does not support multiple selection, so just check 
            the first index.
        */
        let selectedImage: ImageFile?

        if let selectedIndexPath = collectionView.selectionIndexPaths.first
           , (selectedIndexPath as NSIndexPath).section != -1 && (selectedIndexPath as NSIndexPath).item != -1 {
            // There is a selected index path, get the image at that path.
            selectedImage = imageCollections[(selectedIndexPath as NSIndexPath).section].images[(selectedIndexPath as NSIndexPath).item]
        }
        else {
            /*
                There is no selected index path -- the collection view supports
                empty selection, there is no selected image.
            */
            selectedImage = nil
        }

        imageSelectionHandler(selectedImage)
    }
}
