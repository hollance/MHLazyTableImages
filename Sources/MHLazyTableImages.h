/*!
 * \file MHLazyTableImages.h
 *
 * Copyright (c) 2010-2011 Matthijs Hollemans
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

/*!
 * UITableViewCell subclasses should implement this protocol in order to be
 * notified when an image has been lazily loaded.
 */
@protocol MHLazyTableImageCell <NSObject>

/*!
 * Invoked when the image has finished loading.
 *
 * @param image the UIImage or nil if the image failed to load
 */
- (void)didLoadLazyImage:(UIImage*)image;

@end

/*!
 * By default, UITableViewCell puts lazily loaded images into its imageView.
 */
@interface UITableViewCell (MHLazyTableImages) <MHLazyTableImageCell>
@end

/*!
 * Your view controller should implement this protocol in order to connect your
 * data model to the lazy image loading system.
 */
@protocol MHLazyTableImagesDelegate <NSObject>

/*! Returns the URL for the row at the specified index-path. */
- (NSURL*)lazyImageURLForIndexPath:(NSIndexPath*)indexPath;

@optional

/*!
 * Implement this to perform post-processing on the image, such as scaling it
 * to the desired dimensions. This will insert the altered image into the cache
 * and remove the original.
 */
- (UIImage*)postProcessLazyImage:(UIImage*)image forIndexPath:(NSIndexPath*)indexPath;

@end

/*!
 * Allows for efficient downloading of images in a UITableView with many rows.
 * Downloading the image for a row will be deferred until the row scrolls into
 * view and then the image will be downloaded asynchronously.
 *
 * To use, create an instance of MHLazyTableImages in your view controller and
 * set the view controller as its delegate. When the view is loaded, connect 
 * the table view.
 *
 * Your view controller must also implement the UIScrollViewDelegate methods 
 * -scrollViewDidEndDragging:willDecelerate: and -scrollViewDidEndDecelerating:
 * and forward these calls to MHLazyTableImages.
 *
 * You should also set a placeholder image.
 *
 * Finally, simply call -addLazyImageForCell:withIndexPath: in your table view
 * data source's -tableView:cellForRowAtIndexPath: method. This will use the
 * cached image if available, or start an asynchronous download if not.
 *
 * If an image fails to load and the cell is configured again for that row 
 * (because the user scrolls back to it) then we try to load the image again.
 *
 * The downloaded images are stored in MHImageCache. This cache can be flushed
 * to make room for new images when available memory becomes low.
 *
 * \note There currently is no way to cancel the downloading of an image. That 
 * might be useful when you're changing a row while its image is still loading.
 * If the index-paths get out of sync with the table, then images might end up
 * in the wrong rows.
 */
@interface MHLazyTableImages : NSObject
{
}

/*! The delegate object. */
@property (nonatomic, assign) id<MHLazyTableImagesDelegate> delegate;

/*! Weak reference to the table view on whose behalf we are working. */
@property (nonatomic, assign) UITableView* tableView;

/*! Temporary image that is shown while the real image is loading. */
@property (nonatomic, retain) UIImage* placeholderImage;

/*!
 * Adds a lazily-loaded image to a table view cell.
 */
- (void)addLazyImageForCell:(id<MHLazyTableImageCell>)cell withIndexPath:(NSIndexPath*)indexPath;

/*!
 * You should call this method from your UIScrollView delegate.
 */
- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate;

/*!
 * You should call this method from your UIScrollView delegate.
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView;

@end
