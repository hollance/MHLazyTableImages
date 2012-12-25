
#import "Parser.h"
#import "AppRecord.h"

// string contants found in the RSS feed
static NSString *const IDElement     = @"id";
static NSString *const NameElement   = @"im:name";
static NSString *const ImageElement  = @"im:image";
static NSString *const ArtistElement = @"im:artist";
static NSString *const EntryElement  = @"entry";

@interface Parser () <NSXMLParserDelegate>
@property (nonatomic, strong) NSData *dataToParse;
@property (nonatomic, strong) NSMutableArray *workingArray;
@property (nonatomic, strong) AppRecord *workingEntry;
@property (nonatomic, strong) NSMutableString *workingPropertyString;
@property (nonatomic, strong) NSArray *elementsToParse;
@property (nonatomic, assign) BOOL storingCharacterData;
@end

@implementation Parser

- (id)initWithData:(NSData *)data
{
	if ((self = [super init]))
	{
		self.dataToParse = data;
		self.elementsToParse = @[IDElement, NameElement, ImageElement, ArtistElement];
	}
	return self;
}

- (void)parse
{
	@autoreleasepool
	{
		self.workingArray = [NSMutableArray array];
		self.workingPropertyString = [NSMutableString string];

		NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.dataToParse];
		[parser setDelegate:self];
		[parser parse];

		if (self.completionBlock != nil)
		{
			dispatch_sync(dispatch_get_main_queue(), ^
			{
				self.completionBlock(self.workingArray);
			});
		}

		self.workingArray = nil;
		self.workingPropertyString = nil;
		self.dataToParse = nil;
	}
}

#pragma mark - RSS Processing

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
									    namespaceURI:(NSString *)namespaceURI
									   qualifiedName:(NSString *)qName
										  attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:EntryElement])
		self.workingEntry = [[AppRecord alloc] init];

	self.storingCharacterData = [self.elementsToParse containsObject:elementName];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
									  namespaceURI:(NSString *)namespaceURI
									 qualifiedName:(NSString *)qName
{
	if (self.workingEntry != nil)
	{
		if (self.storingCharacterData)
		{
			NSString *trimmedString = [self.workingPropertyString
				stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

			[self.workingPropertyString setString:@""];  // clear for next time

			if ([elementName isEqualToString:IDElement])
				self.workingEntry.appURLString = trimmedString;
			else if ([elementName isEqualToString:NameElement])
				self.workingEntry.appName = trimmedString;
			else if ([elementName isEqualToString:ImageElement])
				self.workingEntry.imageURLString = trimmedString;
			else if ([elementName isEqualToString:ArtistElement])
				self.workingEntry.artist = trimmedString;
		}
		else if ([elementName isEqualToString:EntryElement])
		{
			[self.workingArray addObject:self.workingEntry];  
			self.workingEntry = nil;
		}
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (self.storingCharacterData)
		[self.workingPropertyString appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	if (self.failureBlock != nil)
	{
		dispatch_sync(dispatch_get_main_queue(), ^
		{
			self.failureBlock(parseError);
		});
	}
}

@end
