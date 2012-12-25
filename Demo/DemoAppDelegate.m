
#import "DemoAppDelegate.h"
#import "RootViewController.h"
#import "Parser.h"
#import "MHImageCache.h"

static NSString *const TopPaidAppsFeed = @"http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=75/xml";

@implementation DemoAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[self.window makeKeyAndVisible];
	[self downloadRecords];
	return YES;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	[[MHImageCache sharedInstance] flushMemory];
}

- (void)downloadRecords
{
	NSURL *url = [NSURL URLWithString:TopPaidAppsFeed];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];

	[NSURLConnection sendAsynchronousRequest:request
		queue:[NSOperationQueue mainQueue]
		completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
		{
			NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
		
			if (error != nil)
			{
				[self handleError:error];
			}
			else if ([httpResponse statusCode] != 200)
			{
				NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Unexpected response from server" };

				NSError *error = [NSError
					errorWithDomain:NSCocoaErrorDomain
					code:kCFFTPErrorUnexpectedStatusCode
					userInfo:userInfo];

				[self handleError:error];
			}
			else  // success!
			{
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
				{
					Parser *parser = [[Parser alloc] initWithData:data];

					parser.completionBlock = ^(NSArray *appList)
					{
						[self.rootViewController setEntries:appList];
					};

					parser.failureBlock = ^(NSError *error)
					{
						[self handleError:error];
					};

					[parser parse];
				});
			}
		}];
}

- (void)handleError:(NSError *)error
{
	UIAlertView *alertView = [[UIAlertView alloc]
		initWithTitle:@"Cannot Show Top Paid Apps"
		message:[error localizedDescription]
		delegate:nil
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil];

	[alertView show];
}

@end
