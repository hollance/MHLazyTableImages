/*

 Based on Apple's LazyTableImages sample, version 1.2.
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2010 Apple Inc. All Rights Reserved. 
  
 */

#import "Parser.h"
#import "AppRecord.h"

// string contants found in the RSS feed
static NSString* const kIDStr     = @"id";
static NSString* const kNameStr   = @"im:name";
static NSString* const kImageStr  = @"im:image";
static NSString* const kArtistStr = @"im:artist";
static NSString* const kEntryStr  = @"entry";

@interface Parser ()
@property (nonatomic, retain) NSData* dataToParse;
@property (nonatomic, retain) NSMutableArray* workingArray;
@property (nonatomic, retain) AppRecord* workingEntry;
@property (nonatomic, retain) NSMutableString* workingPropertyString;
@property (nonatomic, retain) NSArray* elementsToParse;
@property (nonatomic, assign) BOOL storingCharacterData;
@end

@implementation Parser

@synthesize dataToParse, workingArray, workingEntry, workingPropertyString, 
            elementsToParse, storingCharacterData;

- (id)initWithData:(NSData*)data
{
	if ((self = [super init]))
	{
		self.dataToParse = data;
		self.elementsToParse = [NSArray arrayWithObjects:kIDStr, kNameStr, kImageStr, kArtistStr, nil];
	}
	return self;
}

- (void)dealloc
{
	[completionBlock release];
	[failureBlock release];
	[elementsToParse release];
	[workingPropertyString release];
	[workingEntry release];
	[workingArray release];
	[dataToParse release];
	[super dealloc];
}

- (void)setCompletionBlock:(ParserCompletionBlock)block
{
	if (completionBlock != block)
	{
		[completionBlock release];
		completionBlock = [block copy];
	}
}

- (void)setFailureBlock:(ParserFailureBlock)block
{
	if (failureBlock != block)
	{
		[failureBlock release];
		failureBlock = [block copy];
	}
}

- (void)parse
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	self.workingArray = [NSMutableArray array];
	self.workingPropertyString = [NSMutableString string];

	NSXMLParser* parser = [[NSXMLParser alloc] initWithData:dataToParse];
	[parser setDelegate:self];
	[parser parse];

	if (completionBlock != nil)
	{
		dispatch_sync(dispatch_get_main_queue(), ^
		{
			completionBlock(self.workingArray);
		});
	}

	self.workingArray = nil;
	self.workingPropertyString = nil;
	self.dataToParse = nil;

	[parser release];
	[pool release];
}

#pragma mark -
#pragma mark RSS processing

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName
									   namespaceURI:(NSString*)namespaceURI
									  qualifiedName:(NSString*)qName
										 attributes:(NSDictionary*)attributeDict
{
	if ([elementName isEqualToString:kEntryStr])
		self.workingEntry = [[[AppRecord alloc] init] autorelease];

	storingCharacterData = [elementsToParse containsObject:elementName];
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName
									 namespaceURI:(NSString*)namespaceURI
									qualifiedName:(NSString*)qName
{
	if (self.workingEntry != nil)
	{
		if (storingCharacterData)
		{
			NSString* trimmedString = [workingPropertyString
				stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

			[workingPropertyString setString:@""];  // clear for next time

			if ([elementName isEqualToString:kIDStr])
				self.workingEntry.appURLString = trimmedString;
			else if ([elementName isEqualToString:kNameStr])
				self.workingEntry.appName = trimmedString;
			else if ([elementName isEqualToString:kImageStr])
				self.workingEntry.imageURLString = trimmedString;
			else if ([elementName isEqualToString:kArtistStr])
				self.workingEntry.artist = trimmedString;
		}
		else if ([elementName isEqualToString:kEntryStr])
		{
			[self.workingArray addObject:self.workingEntry];  
			self.workingEntry = nil;
		}
	}
}

- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
	if (storingCharacterData)
		[self.workingPropertyString appendString:string];
}

- (void)parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
	if (failureBlock != nil)
	{
		dispatch_sync(dispatch_get_main_queue(), ^
		{
			failureBlock(parseError);
		});
	}
}

@end
