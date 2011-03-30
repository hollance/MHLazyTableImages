/*!
 * \file MHImageCache.h
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
 * Category on UIImageView that adds caching capability.
 */
@interface UIImageView (MHImageCache)

/*!
 * Obtains an image from the cache (if possible) or otherwise downloads it
 * and sets it on the view. The view is not automatically resized.
 */
- (void)mh_loadImageFromURL:(NSURL*)url;

@end

/*! 
 * The block type for the MHImageCache callback.
 *
 * @param image a UIImage object or nil in case of an error
 */
typedef void (^MHImageCacheBlock)(UIImage* image);

/*!
 * A simple image cache. There are two levels of caching: 1) in memory, 2) on 
 * the local file system (in app/Library/Private Documents/Image Cache).
 *
 * \note There currently is no method to flush the file cache.
 *
 * \warning This class is not thread-safe. You should use it from the main 
 * thread only.
 */
@interface MHImageCache : NSObject
{
	/*! The images that are loaded into memory. */
	NSMutableDictionary* images;

	/*! The images that are currently being downloaded. */
	NSMutableDictionary* loadingImages;

	/*! The directory where we will cache image files. */
	NSString* cacheDirectory;
}

/*!
 * MHImageCache is a singleton; always access it using \c +sharedInstance.
 */
+ sharedInstance;

/*!
 * Obtains an image from the cache. If the image is not cached yet, it will be
 * downloaded asynchronously and stored on the local file system.
 */
- (void)imageFromURL:(NSURL*)url usingBlock:(MHImageCacheBlock)block;

/*!
 * Obtains an image from the cache. If the image is not cached yet, it will be
 * downloaded asynchronously.
 *
 * \note Multiple parallel calls to this method for the same URL will only 
 * download the image once.
 *
 * @param url the URL to download the image from
 * @param cacheInFile if NO, the downloaded image will not be stored on the
 *        local file system (it will only be cached in memory)
 * @param block the callback with the UIImage object; this is always called on
 *        the main thread
 */
- (void)imageFromURL:(NSURL*)url cacheInFile:(BOOL)cacheInFile usingBlock:(MHImageCacheBlock)block;

/*!
 * Returns the image for the specified URL or nil if this image has not been
 * cached yet.
 */
- (UIImage*)cachedImageWithURL:(NSURL*)url;

/*!
 * Inserts a UIImage into the cache.
 *
 * @param image the UIImage to insert into the cache
 * @param url the key that the image is stored under; if there already was an
 *        image with that key it will be replaced
 */
- (void)cacheImage:(UIImage*)image withURL:(NSURL*)url;

/*!
 * Removes all images from the memory cache. Useful when the app receives a low
 * memory warning.
 *
 * \note Does not remove any cached files.
 */
- (void)flushMemory;

@end
