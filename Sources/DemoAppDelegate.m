
#import "DemoAppDelegate.h"
#import "RootViewController.h"
#import "ASIHTTPRequest.h"
#import "Parser.h"
#import "MHImageCache.h"

static NSString* const TopPaidAppsFeed = @"http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=75/xml";

@implementation DemoAppDelegate

@synthesize window, navigationController, rootViewController;

- (void)handleError:(NSError*)error
{
	UIAlertView* alertView = [[UIAlertView alloc]
		initWithTitle:@"Cannot Show Top Paid Apps"
		message:[error localizedDescription]
		delegate:nil
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil];

	[alertView show];
	[alertView release];
}

- (void)downloadRecords
{
	__block __typeof__(self) blockSelf = self;
	__block ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:TopPaidAppsFeed]];
	[request addRequestHeader:@"Content-Type" value:@"text/xml"];

	[request setCompletionBlock:^
	{
		if ([request responseStatusCode] != 200)
		{
			NSDictionary* userInfo = [NSDictionary
				dictionaryWithObject:@"Unexpected response from server"
				forKey:NSLocalizedDescriptionKey];

			NSError* error = [NSError
				errorWithDomain:NSCocoaErrorDomain
				code:kCFFTPErrorUnexpectedStatusCode
				userInfo:userInfo];

			[blockSelf handleError:error];		
			return;
		}

		Parser* parser = [[Parser alloc] initWithData:[request responseData]];

		[parser setCompletionBlock:^(NSArray* appList)
		{
			blockSelf.rootViewController.entries = appList;
			[blockSelf.rootViewController.tableView reloadData];    
		}];

		[parser setFailureBlock:^(NSError* error)
		{
			[blockSelf handleError:error];
		}];

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
		{
			[parser parse];
		});

		[parser release];
	}];

	[request setFailedBlock:^
	{
		[blockSelf handleError:[request error]];
	}];

	[request startAsynchronous];
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	self.window.rootViewController = navigationController;
	[self.window makeKeyAndVisible];

	[self downloadRecords];
	return YES;
}

- (void)dealloc
{
	[rootViewController release];
	[navigationController release];
	[window release];
	[super dealloc];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application
{
	[[MHImageCache sharedInstance] flushMemory];
}

@end
