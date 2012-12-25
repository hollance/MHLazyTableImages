# MHLazyTableImages

This is a rewrite of Apple's LazyTableImages sample project, which allows for efficient downloading of images in a table view with many rows.

The lazy image loading has been refactored into a class of its own, `MHLazyTableImages`, which makes it very easy to use. The class `MHImageCache` is used to cache the images. The code has also been changed to use blocks and NSURLConnection.

## License

The MHLazyTableImages and MHImageCache source code is copyright 2010-2012 Matthijs Hollemans and is licensed under the terms of the MIT license.

Portions of this source code are based on Apple's LazyTableImages sample, version 1.2.

Any source files without a license header are considered to be public domain.
