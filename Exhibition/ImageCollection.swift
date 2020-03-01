/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Contains the `ImageCollection` class, which is a collection of `ImageFile`s.
*/

import Cocoa

/**
    `ImageCollection` represents a directory on the file system that contains images.
    It creates and vends `ImageFile`s for each of those image files in the directory.
*/
class ImageCollection {
    // MARK: Notifications

    static let imagesDidChangeNotification = "ImageCollectionImagesDidChangeNotification"

    // MARK: Properties

    /// The name of the `ImageCollection`. Defaults to the referenced directory name.
    var name: String

    /**
        The `ImageFiles` contained in the collection. Populated asynchronously 
        and posts an `imagesDidChangeNotification` on updates.
    */
    fileprivate(set) var images = [ImageFile]()

    /// The directory URL referenced by the collection.
    fileprivate(set) var rootURL: URL

    /// Private mapping from URL to `ImageFile` used when updating with the referenced directory.
    fileprivate var imagesByURL = [URL: ImageFile]()

    /**
        Private backing for the table view icon. When the backing is nil, `tableViewIcon`
        returns the default collection image.
    */
    fileprivate var _tableViewIcon: NSImage?

    /**
        The image used as the icon in table view representations. Returns a standard
        icon by default. Setting nil will return to the default, never returns nil.
    */
    var tableViewIcon: NSImage {
        get {
            return _tableViewIcon ?? NSImage(named: "FolderTemplate")!
        }

        set(newTableViewIcon) {
            _tableViewIcon = newTableViewIcon
        }
    }

    // MARK: Initalizers

    init(rootURL: URL) {
        self.rootURL = rootURL

        name = rootURL.lastPathComponent 
        
        refreshOnBackgroundThread()
    }

    // MARK: Image List Manipulation

    fileprivate func addImageFile(_ imageFile: ImageFile) {
        insertImageFile(imageFile, atIndex: images.count)
    }

    fileprivate func insertImageFile(_ imageFile: ImageFile, atIndex index: Int) {
        images.insert(imageFile, at: index)

        imagesByURL[imageFile.URL as URL] = imageFile
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: ImageCollection.imagesDidChangeNotification), object: self)
    }

    fileprivate func removeImageFileAtIndex(_ index: Int) {
        let imageFile = images[index]

        removeImageFile(imageFile)
    }

    fileprivate func removeImageFile(_ imageFile: ImageFile) {
        images.remove(at: images.index(of: imageFile)!)
        
        imagesByURL.removeValue(forKey: imageFile.URL as URL)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: ImageCollection.imagesDidChangeNotification), object: self)
    }

    // MARK: ImageFile Fetching

    /// The operation queue all `ImageFile`s use to load their thumbnails.
    fileprivate static var imageFileFetchingQueue: OperationQueue = {
        let queue = OperationQueue()
       
        queue.name = "ImageCollection Image Fetching Queue"
        
        return queue
    }()

    func refreshOnBackgroundThread() {
        ImageCollection.imageFileFetchingQueue.addOperation(refreshImageFiles)
    }

    fileprivate func refreshImageFiles() {
        let resourceValueKeys = [
            URLResourceKey.isRegularFileKey, 
            URLResourceKey.typeIdentifierKey, 
            URLResourceKey.contentModificationDateKey
        ]
    
        let options: FileManager.DirectoryEnumerationOptions = [.skipsSubdirectoryDescendants, .skipsPackageDescendants]
        
        // Create an enumerator to enumerate all of the immediate files in the referenced directory.
        guard let directoryEnumerator = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: resourceValueKeys, options: options, errorHandler: { url, error in
            print("`directoryEnumerator` error: \(error).")
            return true
        }) else { return }
            
        var addedURLs = [URL]()
        var filesToRemove = images
        var filesChanged = [ImageFile]()
        
        for case let url as URL in directoryEnumerator {
            do {
                let resourceValues = try (url as NSURL).resourceValues(forKeys: resourceValueKeys)
                
                // Verify the URL is a file and not a directory or symlink.
                guard let isRegularFileResourceValue = resourceValues[URLResourceKey.isRegularFileKey] as? NSNumber else { continue }

                guard isRegularFileResourceValue.boolValue else { continue }
                
                // Verify the URL is an image.
                guard let fileType = resourceValues[URLResourceKey.typeIdentifierKey] as? String else { continue }
                guard UTTypeConformsTo(fileType as CFString, "public.image" as CFString) else { continue }
                
                // Verify that it has a modification date.
                guard let modificationDate = resourceValues[URLResourceKey.contentModificationDateKey] as? Date else { continue }
                
                if let existingFile = imagesByURL[url] {
                    // This URL is in the collection, check if it needs updating.
                    if modificationDate.compare(existingFile.dateLastUpdated as Date) == .orderedDescending {
                        filesChanged.append(existingFile)
                    }
                
                    let existingFileIndex = filesToRemove.index(of: existingFile)!
                    filesToRemove.remove(at: existingFileIndex)
                }
                else {
                    // This URL is new, put it in our the list of added URLs
                    addedURLs.append(url)
                }
            } 
            catch {
                print("Unexpected error occured: \(error).")
            }
        }


        for imageFile in filesToRemove {
            removeImageFile(imageFile)
        }

        // Regenerate all changed files.
        for imageFile in filesChanged {
            removeImageFile(imageFile)

            addedURLs += [imageFile.URL]
        }

        // Update the image on the main queue.
        OperationQueue.main.addOperation {
            for URL in addedURLs {
                let imageFile = ImageFile(URL: URL)
                
                self.addImageFile(imageFile)
            }
        }
    }
}

// `ImageCollections`s are equivalent if their URLs are equivalent.
extension ImageCollection: Hashable {
    var hashValue: Int {
        return rootURL.hashValue
    }
}

func ==(lhs: ImageCollection, rhs: ImageCollection) -> Bool {
    return lhs.rootURL == rhs.rootURL
}
