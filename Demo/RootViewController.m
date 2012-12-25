
#import "RootViewController.h"
#import "MHLazyTableImages.h"
#import "AppRecord.h"

#define CustomRowCount   8
#define CustomRowHeight  60.0f
#define AppIconHeight    48.0f

@interface RootViewController () <MHLazyTableImagesDelegate>
@end

@implementation RootViewController
{
	MHLazyTableImages *_lazyImages;
	NSArray *_entries;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]))
	{
		_lazyImages = [[MHLazyTableImages alloc] init];
		_lazyImages.placeholderImage = [UIImage imageNamed:@"Placeholder"];
		_lazyImages.delegate = self;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.tableView.rowHeight = CustomRowHeight;
	_lazyImages.tableView = self.tableView;
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	_lazyImages.tableView = nil;
}

- (void)setEntries:(NSArray *)entries
{
	_entries = entries;
	[self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger count = [_entries count];
    if (count == 0)
        return CustomRowCount;  // enough rows to fill the screen
	else
		return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([_entries count] == 0)
	{
		return (indexPath.row == 0) ? [self placeholderCell] : [self emptyCell];
	}
	else
	{
		return [self recordCellForIndexPath:indexPath];
	}
}

- (UITableViewCell *)placeholderCell
{
	static NSString *CellIdentifier = @"PlaceholderCell";

	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];   
		cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

	cell.detailTextLabel.text = @"Loading…";
	return cell;
}

- (UITableViewCell *)emptyCell
{
	static NSString *CellIdentifier = @"EmptyCell";

	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

	return cell;
}

- (UITableViewCell *)recordCellForIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"LazyTableCell";

	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}

	AppRecord *appRecord = _entries[indexPath.row];
	cell.textLabel.text = appRecord.appName;
	cell.detailTextLabel.text = appRecord.artist;

	[_lazyImages addLazyImageForCell:cell withIndexPath:indexPath];

	return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	[_lazyImages scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[_lazyImages scrollViewDidEndDecelerating:scrollView];
}

#pragma mark - MHLazyTableImagesDelegate

- (NSURL *)lazyImageURLForIndexPath:(NSIndexPath *)indexPath
{
	AppRecord *appRecord = _entries[indexPath.row];
	return [NSURL URLWithString:appRecord.imageURLString];
}

- (UIImage *)postProcessLazyImage:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath
{
    if (image.size.width != AppIconHeight && image.size.height != AppIconHeight)
 		return [self scaleImage:image toSize:CGSizeMake(AppIconHeight, AppIconHeight)];
    else
        return image;
}

- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size
{
	UIGraphicsBeginImageContextWithOptions(size, YES, 0.0f);
	CGRect imageRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
	[image drawInRect:imageRect];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

@end
