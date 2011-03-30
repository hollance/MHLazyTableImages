/*!
 * \file MHImageCache.m
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

#import "MHImageCache.h"
#import "ASIHTTPRequest.h"

@implementation UIImageView (MHImageCache)

- (void)mh_loadImageFromURL:(NSURL*)url
{
	__block __typeof__(self) blockSelf = self;
	[[MHImageCache sharedInstance] imageFromURL:url usingBlock:^(UIImage* theImage)
	{
		if (theImage != nil)
			blockSelf.image = theImage;
	}];
}

@end

@implementation MHImageCache

+ sharedInstance 
{ 
	static MHImageCache* instance = nil; 
	if (instance == nil) 
	{
		instance = [[self alloc] init]; 
	}
	return instance; 
}

- (void)dealloc
{
	[images release];
	[loadingImages release];
	[cacheDirectory release];
	[super dealloc];
}

- (NSMutableDictionary*)images
{
	if (images == nil)
	{
		images = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
	}
	return images;
}

- (NSMutableDictionary*)loadingImages
{
	if (loadingImages == nil)
	{
		loadingImages = [[NSMutableDictionary dictionaryWithCapacity:5] retain];
	}
	return loadingImages;
}

- (NSString*)cacheDirectory
{
	if (cacheDirectory == nil)
	{
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
		NSString* libraryDirectory = [paths objectAtIndex:0];

		cacheDirectory = [[[libraryDirectory
			stringByAppendingPathComponent:@"Private Documents"]
			stringByAppendingPathComponent:@"Image Cache"] retain];

		NSFileManager* fileManager = [NSFileManager defaultManager];
		if (![fileManager fileExistsAtPath:cacheDirectory])
		{
			NSError* error = nil;
			if (![fileManager createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:&error])
				NSLog(@"Error creating directory: %@", [error description]);
		}
	}
	return cacheDirectory;
}

- (NSString*)keyForURL:(NSURL*)url
{
	return [NSString stringWithFormat:@"%lu-%@", [url hash], [url lastPathComponent]];
}

- (void)notifyBlocksForKey:(NSString*)key
{
	NSMutableArray* blocks = [self.loadingImages objectForKey:key];

	for (MHImageCacheBlock block in blocks)
	{
		// It is possible for the block to replace the image with another one;
		// for example, it may do post-processing and put the processed image
		// back into the cache under the same key. Because the image may be
		// changed out from under us, we must look it up anew on every loop.
		block([self.images objectForKey:key]);
	}

	[self.loadingImages removeObjectForKey:key];
}

- (void)imageFromURL:(NSURL*)url usingBlock:(MHImageCacheBlock)block
{
	[self imageFromURL:url cacheInFile:YES usingBlock:block];
}

- (void)imageFromURL:(NSURL*)url cacheInFile:(BOOL)cacheInFile usingBlock:(MHImageCacheBlock)block
{
	NSString* key = [self keyForURL:url];

	// 1) If we have the image in memory, use it.

	UIImage* image = [self.images objectForKey:key];
	if (image != nil)
	{
		block(image);
		return;
	}

	// 2) If we have the file locally stored, then load into memory and use it.

	NSString* path = nil;
	if (cacheInFile)
	{
		path = [self.cacheDirectory stringByAppendingPathComponent:key];
		image = [UIImage imageWithContentsOfFile:path];
		if (image != nil)
		{
			[self.images setObject:image forKey:key];
			block(image);
			return;
		}
	}

	// 3) If a download for this image is already pending, then add the block 
	//    to the list of blocks that will be invoked when the download is done.

	block = [[block copy] autorelease];  // move to heap!

	NSMutableArray* array = [self.loadingImages objectForKey:key];
	if (array != nil)
	{
		[array addObject:block];
		return;
	}

	// 4) Download the image, store it in a local file (if allowed), and use it.

	array = [NSMutableArray arrayWithCapacity:3];
	[array addObject:block];
	[self.loadingImages setObject:array forKey:key];

	__block __typeof__(self) blockSelf = self;
	__block ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:url];

	[request setCompletionBlock:^
	{
		UIImage* image = nil;
		if ([request responseStatusCode] == 200)
		{
			NSData* data = [request responseData];
			image = [[UIImage alloc] initWithData:data];
			if (image != nil)
			{
				if (cacheInFile)
					[data writeToFile:path atomically:NO];

				[blockSelf.images setObject:image forKey:key];
				[image release];
			}
		}
		[blockSelf notifyBlocksForKey:key];
	}];

	[request setFailedBlock:^
	{
		[blockSelf notifyBlocksForKey:key];
	}];

	[request startAsynchronous];
}

- (UIImage*)cachedImageWithURL:(NSURL*)url
{
	return [self.images objectForKey:[self keyForURL:url]];
}

- (void)cacheImage:(UIImage*)image withURL:(NSURL*)url
{
	[self.images setObject:image forKey:[self keyForURL:url]];
}

- (void)flushMemory
{
	[images removeAllObjects];
}

@end
