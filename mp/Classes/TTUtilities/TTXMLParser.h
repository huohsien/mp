//
//  TTXMLParser.h
//  mp
//
//  Created by M Tsai on 11-8-30.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>

/*! defines the return dictionary key for the root element name */
extern NSString* const kTTXMLRootElementName;
extern NSString* const kTTXMLTypeTag;
extern NSString* const kTTXMLIDTag;

/*!
 @header TTXMLParser
 
 TTXMLParser uses NSXMLParser and creates a NSDictionary that contains the elements
 and values of the parsed XML file.
 
 The root element's name is stored as a key: "rootElementName".  The primary elements'
 values can be accessed by setting the dictionary key to the name of the element.  
 Sub levels are stored in dictionaries.
 
 See the example below:
 
 <authentication>
    <cause>0</cause>
    <domain>61.66.229.110:80</domain>
    <akey>1020345</ akey >
    <text>您目前還有10封免費簡訊額度….</text>
    <parent>
        <child>abc</child>
    </parent>
 </authentication>
 
 Dictionary:
  - rootElementName: authentication
  - cause: 0
  - domain: 61.55.229.110:80
  - akey: 1020345
  - text: 您目前還有1...
  - parent: 
            - child: abc
 
 
 This class is only designed to handle small XML files.  Large XML files will consume large
 amounts of memory, so a custom delegate for NSXMLParser (possibly writing data to file).
 
 @copyright TernTek
 @updated 2011-08-30
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


@class TTXMLParser;

/*!
 Delegate that can be notified when TTURLConnection is finished or has
 encountered an error.
 
 */
@protocol TTXMLParserDelegate <NSObject>


/*!
 @abstract Called when data has completed loading and is ready to use.
 
 */
- (void)TTXMLParser:(TTXMLParser *)parser finishParsingWithDictionary:(NSDictionary *)dictionary;

/*!
 @abstract Called when error encountered
 */
- (void)TTXMLParser:(TTXMLParser *)parser parseErrorOccurred:(NSError *)parseError;

@end



@interface TTXMLParser : NSObject <NSXMLParserDelegate> {
    
    id <TTXMLParserDelegate> delegate;
    
    NSData *parseData;
    
    NSXMLParser *xmlParser;
    NSMutableDictionary *xmlDictionary;
    NSMutableArray *xmlDictionaries;
    
    NSMutableArray *parentKeys;
    NSString *currentKey;
    NSMutableString *currentStringValue;
    
    NSString *typeTag;
    NSString *idTag;
    NSString *urlString;
}

/*! delegate that gets called when parsing is complete */
@property (nonatomic, assign) id <TTXMLParserDelegate> delegate;

/*! input data to be parsed */
@property (nonatomic, retain) NSData *parseData;


/*! xmlParser is a SAX parser used to read the XML file. */
@property (nonatomic, retain) NSXMLParser *xmlParser;

/*! xmlDictionary is the results dictionary where XML values are stored */
@property (nonatomic, retain) NSMutableDictionary *xmlDictionary;

/*! array of xml dictionaries - push more dictionaries to handle multi level XML */
@property (nonatomic, retain) NSMutableArray *xmlDictionaries;


/*! keys of parent dictionary */
@property (nonatomic, retain) NSMutableArray *parentKeys;

/*! currentKey whose value is being read in */
@property (nonatomic, retain) NSString *currentKey;

/*! currentValue that is still being read in by parser */
@property (nonatomic, retain) NSMutableString *currentStringValue;

/*! tag to identify what type of query this is & how we should handle the results */
@property (nonatomic, retain) NSString *typeTag;

/*! tag to identify who requested and who should handle this query */
@property (nonatomic, retain) NSString *idTag;

/*! for debugging - print out show did the error */
@property (nonatomic, retain) NSString *urlString;


/*! 
 @abstract Initialize the TTURLConnection by setting up request
 @discussion Creates a URL Request object with the specified URL string.
 
 @param urlString target URL to connect to
 */
- (id) initWithData:(NSData *)xmlData typeTag:(NSString *)newType idTag:(NSString *)newID;

/*!
 @abstract start the parsing process
 */
- (void) parse;


@end
