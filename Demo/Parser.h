
typedef void (^ParserCompletionBlock)(NSArray *appList);
typedef void (^ParserFailureBlock)(NSError *error);

@interface Parser : NSObject

@property (nonatomic, copy) ParserCompletionBlock completionBlock;
@property (nonatomic, copy) ParserFailureBlock failureBlock;

- (id)initWithData:(NSData *)data;
- (void)parse;

@end
