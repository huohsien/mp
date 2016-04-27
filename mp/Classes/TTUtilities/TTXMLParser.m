//
//  TTXMLParser.m
//  mp
//
//  Created by M Tsai on 11-8-30.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "TTXMLParser.h"
#import "TKLog.h"


NSString* const kTTXMLRootElementName = @"kRootElementName";
NSString* const kTTXMLTypeTag = @"kTTXMLTypeTag";
NSString* const kTTXMLIDTag = @"kTTXMLIDTag";

@implementation TTXMLParser

@synthesize delegate;

@synthesize parseData;
@synthesize xmlParser;
@synthesize xmlDictionary;
@synthesize xmlDictionaries;

@synthesize parentKeys;
@synthesize currentKey;
@synthesize currentStringValue;

@synthesize typeTag;
@synthesize idTag;
@synthesize urlString;

- (void) dealloc {
    
    self.xmlParser.delegate = nil;
    
    [parseData release];
    [xmlParser release];
    [xmlDictionary release];
    [xmlDictionaries release];
    
    [parentKeys release];
    [currentKey release];
    [currentStringValue release];
    [typeTag release];
    [idTag release];
    [urlString release];
    [super dealloc];
}

/*! 
 @abstract Initialize the TTURLConnection by setting up request
 @discussion Creates a URL Request object with the specified URL string.
 
 @param urlString target URL to connect to
 @param typeTag identifies type of query requested
 @param idTag identifies which object made request & who should handle it
 
 */
- (id) initWithData:(NSData *)xmlData typeTag:(NSString *)newType idTag:(NSString *)newID
{
	self = [super init];
	if (self != nil)
	{

        self.parseData = xmlData;
        
        NSXMLParser *newParser = [[NSXMLParser alloc] initWithData:xmlData];
        [newParser setDelegate:self];
        [newParser setShouldResolveExternalEntities:YES];
        self.xmlParser = newParser;
        [newParser release];
        
        NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
        self.xmlDictionary = newDictionary;
        [newDictionary release];
        
        [self.xmlDictionary setValue:newType forKey:kTTXMLTypeTag];
        [self.xmlDictionary setValue:newID forKey:kTTXMLIDTag];
        
        NSMutableArray *newArray = [[NSMutableArray alloc] init];
        self.xmlDictionaries = newArray;
        [newArray release];
        
        NSMutableArray *newArrayP = [[NSMutableArray alloc] init];
        self.parentKeys = newArrayP;
        [newArrayP release];
        
	}
	return self;
}

/*!
 @abstract start the parsing process
 */
- (void) parse {
    [self.xmlParser parse];
}

#pragma mark - Delegate Methods

/*! 
 @abstract Delegate called when a new element is encountered
 
 @discussion This method should prepare new values to be added to the dictionary
 
 */ 
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    // if the dictionary is empty, then this must be the root element
    //
    if (![self.xmlDictionary valueForKey:kTTXMLRootElementName]){
        [self.xmlDictionary setValue:elementName forKey:kTTXMLRootElementName];
        [self.xmlDictionaries addObject:self.xmlDictionary];
    }
    // start a new element and reset the value
    //
    else {
        
        // if child element encountered
        // - store parent key and create a new dictionary
        //
        if ([self.currentKey length] > 0) { //&& [self.currentStringValue length] == 0) {
            [self.parentKeys addObject:self.currentKey];
            NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
            [self.xmlDictionaries addObject:newDictionary];
            [newDictionary release];
            
            self.currentKey = elementName;
            self.currentStringValue = nil;
        }
        // element in the same level - same dictionary
        else {
            self.currentKey = elementName;
            self.currentStringValue = nil;
        }
    }
}

/*! 
 @abstract Delegate called when new value characters are found.
 
 @discussion Store new characters in current value until the end of the element is reached
 
 */
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!self.currentStringValue) {
        NSMutableString *newString = [[NSMutableString alloc] initWithCapacity:50];
        self.currentStringValue = newString;
        [newString release];
    }
    [self.currentStringValue appendString:string];
}



/*! 
 @abstract Delegate called when an element is terminated
 
 @discussion Add new element to the return dictionary.
 
 */
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    // if the root termination is encountered, then we are done
    // - send result XML dictionary to delegate
    //
    if ( [elementName isEqualToString:[self.xmlDictionary valueForKey:kTTXMLRootElementName] ] ) {
        
        if ([self.delegate respondsToSelector:@selector(TTXMLParser:finishParsingWithDictionary:)]) {
            [self.delegate TTXMLParser:self finishParsingWithDictionary:self.xmlDictionary];
        }
        
        // delegate no longer needed
        //
        parser.delegate = nil;
        self.delegate = nil;
    }
    // for regular elements
    //
    else if ([elementName isEqualToString:self.currentKey] && self.currentStringValue){
        // decode percent escaped text
        //
        NSString *decodedText = [self.currentStringValue stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[self.xmlDictionaries lastObject] setValue:decodedText forKey:self.currentKey];
    }
    // for the end of a level - dictionary
    // - add dictionary to the parent dictionary using parent key
    // - remove from dictionary array
    //
    else if ([self.parentKeys count] > 0 && [elementName isEqualToString:[self.parentKeys lastObject]]){
        NSMutableDictionary *finishedD = [[self.xmlDictionaries lastObject] retain];
        [self.xmlDictionaries removeLastObject];
        [[self.xmlDictionaries lastObject] setValue:finishedD forKey:[self.parentKeys lastObject]];
        [self.parentKeys removeLastObject];
        [finishedD release];
    }
    self.currentKey = nil;
    self.currentStringValue = nil;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    NSString *dataString = [[NSString alloc] initWithData:self.parseData encoding:NSUTF8StringEncoding];
    DDLogError(@"TXP-error: %@, len:%d, tag: %@, data:%@, url:%@", 
               [parseError localizedDescription], 
               [self.parseData length], 
               self.typeTag, 
               dataString, 
               self.urlString);
    
    [dataString release];
    
    if ([self.delegate respondsToSelector:@selector(TTXMLParser:parseErrorOccurred:)]){
        [self.delegate TTXMLParser:self parseErrorOccurred:parseError];
    }
}

@end
