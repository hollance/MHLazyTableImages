
@class RootViewController;

@interface DemoAppDelegate : NSObject <UIApplicationDelegate>
{
}

@property (nonatomic, retain) IBOutlet UIWindow* window;
@property (nonatomic, retain) IBOutlet UINavigationController* navigationController;
@property (nonatomic, retain) IBOutlet RootViewController* rootViewController;

@end
