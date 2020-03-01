/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Contains the `ImageFile` class, which represents an image at a given URL.
*/

import Cocoa

/**
    `ImageFile` represents an image on disk. It can create thumbnail and full image representations.
*/
class ImageFile {
    // MARK: Notifications

    static let thumbnailDidLoadNotification = "ImageFileThumbnailDidLoadNotification"
    static let imageDidLoadNotification = "ImageFileImageDidLoadNotification"

    // MARK: Properties

    /// The date the ImageFile was last updated from its URL source.
    fileprivate(set) var dateLastUpdated = Date()

    /// The url the receiver references.
    fileprivate(set) var URL: Foundation.URL

    /// The filename of the receiver, with the extension.
    var fileName: String? {
        return URL.lastPathComponent
    }

    /// The filename of the receiver, without the extension. Suitable for presentation names.
    var fileNameExcludingExtension: String? {
        let lastPathComponent = URL.lastPathComponent
        return (lastPathComponent as NSString).deletingPathExtension
    }

    /// The operation queue all `ImageFile`s use to load their thumbnails.
    fileprivate static var thumbnailLoadingOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        
        queue.name = "ImageFile Thumbnail Loading Queue"
        
        return queue
    }()
    
    /// The operation queue all `ImageFile`s use to load their images.
    fileprivate static var imageLoadingOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        
        queue.name = "ImageFile Image Loading Queue"
        
        return queue
    }()
    
    
    /// The image source representing the image at the set `url`.
    fileprivate lazy var imageSource: CGImageSource? = {
        let imageSource = CGImageSourceCreateWithURL(self.URL.absoluteURL as CFURL, nil)
        
        if let imageSource = imageSource {
            // Verify the image source has a valid uniform type identifier.
            guard CGImageSourceGetType(imageSource) != nil else { return nil }
        }
        
        return imageSource
    }()

    /// The private cache for the loaded thumbnail.
    fileprivate var _thumbnail: NSImage?
    
    /// The cache for the loaded image.
    fileprivate var _image: NSImage?
    
    // MARK: Initializer

    init(URL: Foundation.URL) {
        self.URL = URL
    }

    // MARK: Image Loading

    /**
        Fetch the thumbnail with a callback closure. If the thumbnail has already
        been loaded, the completionHandler is invoked immediately with the cached
        thumbnail.
    */
    func fetchThumbnailWithCompletionHandler(_ completionHandler: @escaping (NSImage) -> Void) {
        if let thumbnail = _thumbnail {
            // If the thumbnail is already loaded, invoke the `completionHandler` with it immediately.
            completionHandler(thumbnail)
        }
        else {
            // Otherwise, load the thumbnail and callback once it has loaded.
            ImageFile.thumbnailLoadingOperationQueue.addOperation {
                guard let imageSource = self.imageSource else { return }

                /*
                    Create a thumbnail from the image source. If the file doesn't 
                    come with a thumbnail, ask CG to create one, with a maximum 
                    size of 160 pts.
                */
                let thumbnailOptions = [
                    String(kCGImageSourceCreateThumbnailFromImageIfAbsent): true,
                    String(kCGImageSourceThumbnailMaxPixelSize): 160
                ] as [String : Any]
                
                guard let thumbnailRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions as CFDictionary?) else { return }

                let thumbnailImage = NSImage(cgImage: thumbnailRef, size: NSSize.zero)

                /*
                    Update the `_thumbnail` cache on the main thread and send 
                    notification that it has loaded.
                */
                OperationQueue.main.addOperation {
                    self._thumbnail = thumbnailImage

                    NotificationCenter.default.post(name: Notification.Name(rawValue: ImageFile.thumbnailDidLoadNotification), object: self)

                    completionHandler(thumbnailImage)
                }
            }
        }
    }

    /**
        Fetch the image with a callback closure. If the image has already been
        loaded, the `completionHandler` is invoked immediately with the cached image.
    */
    func fetchImageWithCompletionHandler(_ completionHandler: @escaping (NSImage) -> Void) {
        if let image = _image {
            // If the image is already loaded, invoke the completionHandler with it immediately.
            completionHandler(image)
        }
        else {
            // Otherwise, load the image and callback once it has loaded.
            ImageFile.thumbnailLoadingOperationQueue.addOperation() {
                guard let imageSource = self.imageSource else { return }

                // Create a full image from the image source.
                guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else { return }

                let image = NSImage(cgImage: imageRef, size: NSZeroSize)

                // Update the `_image` cache on the main thread and send notification that it has loaded.
                OperationQueue.main.addOperation {
                    self._image = image
                    NotificationCenter.default.post(name: Notification.Name(rawValue: ImageFile.imageDidLoadNotification), object: self)
                    completionHandler(image)
                }
            }
        }
    }
}

// `ImagesFile`s are equivalent if their URLs are equivalent.
extension ImageFile: Hashable {
    var hashValue: Int {
        return URL.hashValue
    }
}

extension ImageFile: Equatable { }

func ==(lhs: ImageFile, rhs: ImageFile) -> Bool {
    return lhs.URL == rhs.URL
}
