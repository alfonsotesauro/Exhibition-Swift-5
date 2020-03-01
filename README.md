# Exhibition: An Adaptive OS X App

The Exhibition sample demonstrates techniques for making windows more adaptive. You’ll see how to use the NSSplitViewController class to create system-standard adaptive sidebars. The sample also shows how to use the NSCollectionView class API introduced in OS X 10.11 to create more flexible layouts using constraint priorities and the automatic detaching behavior of the NSStackView class.

## Model

The ImageCollection class represents a directory at a given URL. On initialization, it asynchronously creates ImageFiles to represent the images files in that directory. ImageFiles lazily and asynchronously provides thumbnails and images for the represented image file URL. 

## View Controllers

ImageCollectionListController controls the view used as a sidebar in the main Exhibition window, and displays a list of the directories in an NSOutlineView, represented by ImageCollections, the user has added to the app. By default its populated with the system 'Desktop Pictures' directory. 

The ImageListController displays the images in an ImageCollection in an NSCollectionView. The containing GalleryWindowController sets the visualized ImageCollection based on the selection in the ImageCollectionListController.

The ImageViewerController displays a single ImageFile in a scrollable NSImageView. Again, the containing GalleryWindowController sets the visualized ImageFile based on the selection in the ImageListController.

The ImageToolsViewController is added as a child of the ImageViewerController and displays a list of "tool" controls that associated with the image. These controls are laid out using an NSStackView that allows the tools to fill the tool area with equal sizing when there is enough space, and automatically detaches the views when space runs out.

## Window Controllers

The GalleryWindowController controls the main window used in Exhibition. It has an NSSplitViewController as its content, which displays an ImageCollectionListController, ImageListController, and ImageViewerController as children. A sidebar style NSSplitViewItem is created for the ImageCollectionListController to get the autocollapse and overlay behavior. Similarly, a content list style NSSplitViewItem is created for the ImageListController to get standard sizing behavior.

The StandaloneImageWindowController displays a single ImageFile and is restricted to be sized according to that image's aspect ratio. Its window is not a primary fullscreen window, but is tilable. On entering split fullscreen, it loses its aspect ratio restriction and letterboxes the image.

## Requirements

### Build

Xcode 8.0, macOS 10.12 SDK

### Runtime

macOS 10.12 

Copyright (C) 2016 Apple Inc. All rights reserved.
