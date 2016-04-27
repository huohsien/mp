//
//  TTLocalizedIndexedCollation.m
//  ContactBook
//
//  Created by M Tsai on 10-11-26.
//  Copyright 2010 TernTek. All rights reserved.
//

#import "TTLocalizedIndexedCollation.h"
#import "TKLog.h"
#import "AppUtility.h"

@implementation TTLocalizedIndexedCollation

@synthesize collation;
@synthesize indexType;
@synthesize collationIndexArray;
@synthesize collationDictionary;


- (void) dealloc {
    
    [collation release];
    [collationIndexArray release];
    [collationDictionary release];
    
    [super dealloc];
}


/**
 Init 
 
 */
- (id) init {
	self = [super init];
	if (self) {
		self.collation = [UILocalizedIndexedCollation currentCollation];
	}
	return self;
}


#pragma mark -
#pragma mark Property Methods

/**
 Resets cache values
 
 Usage:
 - called when a new index is created and collation values should be reread again
 
 */
- (void) resetCache {
	
	[collationIndexArray release];
	collationIndexArray = nil;
	
	[collationDictionary release];
	collationDictionary = nil;
	
	indexType = kIndexTypeNone;
	
}


/**
 Gets a suitable default index type using the system locale info
 
 For default index and t9 cache are:
 * TW:		Zhuyin+Roman
 * JA:		Kana+Roman
 * Else:	Pinyin
 
 Use:
 - to get a default setting for "index" setting when one is not set yet
 
 */
-(IndexType) recommendedIndexType {
    
	// default use PinYin
    IndexType recommendIndex = kIndexTypePinYin;
    
	NSLocale *currentLocale = [NSLocale currentLocale];
	NSString *preferredLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
	NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
	DDLogVerbose(@"TTLIC: lan:%@ count:%@ LID:%@ ", preferredLanguage, countryCode, [currentLocale localeIdentifier]);
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	// don't use cache
	[defaults synchronize];
	//BOOL isLatinIndexOn = [[defaults stringForKey:kUserDefaultLatinIndexKey] boolValue];
	
	// if Japanese language
	if ([preferredLanguage isEqualToString:@"ja"]) {
		recommendIndex = kIndexTypeHiraganaRoman;
	}
	// if Traditional ZH and Taiwan
	else if ([preferredLanguage isEqualToString:@"zh-Hant"]) {
		if ([countryCode isEqualToString:@"TW"]) {
			recommendIndex = kIndexTypeZhuYinRoman;
		}
		else {
			recommendIndex = kIndexTypePinYin;
		}
	}
	// if Simplified ZH
	else if ([preferredLanguage isEqualToString:@"zh-Hans"]) {
		recommendIndex = kIndexTypePinYin;
	}
	return recommendIndex;
}

/**
 Check user's phone settings to determine index should be used
 - cache results for performance
 
 */
- (IndexType) indexType {
	
	// caches results	
	if (indexType != kIndexTypeNone) {
		return indexType;
	}
	
    indexType = [self recommendedIndexType];

	return indexType;
}


/**
 Get collation index array
 - uses cache for performance
 
 Logic:
 - check language and determine which dictionary to return
 - generate dictionary and return it
 
 */
- (NSArray *) collationIndexArray {
	
	if (collationIndexArray != nil) {
		return collationIndexArray;
	}

	// default alphbet
	NSArray *indexArray;
	
	IndexType iType = self.indexType;
	
	// generate hiragana index
	//
	if (iType == kIndexTypeHiraganaRoman) {
		indexArray = [[NSArray alloc] initWithObjects:
					  @"あ",@"い",@"う",@"え",@"お",
					  @"か",@"き",@"く",@"け",@"こ",
					  @"さ",@"し",@"す",@"せ",@"そ",
					  @"た",@"ち",@"つ",@"て",@"と",
					  @"な",@"に",@"ぬ",@"ね",@"の",
					  @"は",@"ひ",@"ふ",@"へ",@"ほ",
					  @"ま",@"み",@"む",@"め",@"も",
					  @"や",@"ゆ",@"よ",
					  @"ら",@"り",@"る",@"れ",@"ろ",
					  @"わ",
					  @"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",
					  @"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",
					  @"#",nil];

	}
	else if (iType == kIndexTypeHiragana) {
		indexArray = [[NSArray alloc] initWithObjects:
					  @"あ",@"い",@"う",@"え",@"お",
					  @"か",@"き",@"く",@"け",@"こ",
					  @"さ",@"し",@"す",@"せ",@"そ",
					  @"た",@"ち",@"つ",@"て",@"と",
					  @"な",@"に",@"ぬ",@"ね",@"の",
					  @"は",@"ひ",@"ふ",@"へ",@"ほ",
					  @"ま",@"み",@"む",@"め",@"も",
					  @"や",@"ゆ",@"よ",
					  @"ら",@"り",@"る",@"れ",@"ろ",
					  @"わ",
					  @"#",
					  nil];
		
	}
	// generate zhuyin index
	//
	else if (iType == kIndexTypeZhuYin) {
		indexArray = [[NSArray alloc] initWithObjects:
					  @"ㄅ",@"ㄆ",@"ㄇ",@"ㄈ",@"ㄉ",@"ㄊ",@"ㄋ",@"ㄌ",@"ㄍ",@"ㄎ",
					  @"ㄏ",@"ㄐ",@"ㄑ",@"ㄒ",@"ㄓ",@"ㄔ",@"ㄕ",@"ㄖ",@"ㄗ",@"ㄘ",
					  @"ㄙ",@"ㄚ",@"ㄛ",@"ㄜ",@"ㄝ",@"ㄞ",@"ㄟ",@"ㄠ",@"ㄡ",@"ㄢ",
					  @"ㄣ",@"ㄤ",@"ㄥ",@"ㄦ",@"ㄧ",@"ㄨ",@"ㄩ",
					  @"#",
					  nil];
	}
	else if (iType == kIndexTypeZhuYinRoman) {
		indexArray = [[NSArray alloc] initWithObjects:
					  @"ㄅ",@"ㄆ",@"ㄇ",@"ㄈ",@"ㄉ",@"ㄊ",@"ㄋ",@"ㄌ",@"ㄍ",@"ㄎ",
					  @"ㄏ",@"ㄐ",@"ㄑ",@"ㄒ",@"ㄓ",@"ㄔ",@"ㄕ",@"ㄖ",@"ㄗ",@"ㄘ",
					  @"ㄙ",@"ㄚ",@"ㄛ",@"ㄜ",@"ㄝ",@"ㄞ",@"ㄟ",@"ㄠ",@"ㄡ",@"ㄢ",
					  @"ㄣ",@"ㄤ",@"ㄥ",@"ㄦ",@"ㄧ",@"ㄨ",@"ㄩ",
					  @"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",
					  @"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",
					  @"#",
					  nil];
	}
	// use roman characters for pinyin
	//
	else if (iType == kIndexTypePinYin) {
		indexArray = [[NSArray alloc] initWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",
				  @"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",nil];	
	}
	// default collation titles
	else {
		indexArray = [[NSArray alloc] initWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",
					  @"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",nil];	
		
		/*indexArray = [self.collation sectionTitles];
		[indexArray retain];  // want to keep it*/
	}
	collationIndexArray = indexArray;	
	return collationIndexArray;
}

#define kJaDictionary		@"ja_index_dictionary_1_0"
#define kZhuYinDictionary	@"zhuyin_index_dictionary_1_0"
#define kPinYinDictionary	@"pinyin_index_dictionary_1_0"

/**
 Getter for collationDictionary
 - uses cache for performance
 
 */
- (NSDictionary *) collationDictionary {
	
	if (collationDictionary != nil) {
		return collationDictionary;
	}
	
	// default dictionary
	NSDictionary *dictionary = nil;
	
	IndexType iType = self.indexType;
	NSString *languageFilename;
    
	// generate hiragana index
	//
	if (iType == kIndexTypeHiragana || iType == kIndexTypeHiraganaRoman) {
        languageFilename = kJaDictionary;
	}
	// generate zhuyin index
	//
	else if (iType == kIndexTypeZhuYin || iType == kIndexTypeZhuYinRoman) {
        languageFilename = kZhuYinDictionary;
	}
	// use roman characters for pinyin
	//
	else if (iType == kIndexTypePinYin) {
        languageFilename = kPinYinDictionary;
	}
	// default collation titles - use pinyin
	else {
		// use pinyin for now... instead of default collation from iOS
        languageFilename = kPinYinDictionary;
	}
	
    // check if thread dictionary has a cached copy
    dictionary = [[AppUtility getAppDelegate] sharedCacheObjectForKey:languageFilename]; 
    
    // if not cached, load from file
    //
    if (!dictionary) {
        NSString *path = [[NSBundle mainBundle] pathForResource:languageFilename ofType:@""];
        dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
        
        
        // store cache
        [[AppUtility getAppDelegate] sharedCacheSetObject:dictionary forKey:languageFilename];
    }
    
	// if got a dictionary
	if (dictionary != collationDictionary) {
        [dictionary retain];
		[collationDictionary release];
		collationDictionary = dictionary;
	}
	return collationDictionary;
}



/**
 Getter methods for sectionTitles
 
 //Returns the list of section titles for the table view. (read-only)
 @property(nonatomic, readonly) NSArray *sectionTitles
 
 */
- (NSArray *) sectionTitles {
	return self.collationIndexArray;
}

/**
 Getter methods for sectionIndexTitles
 
 //Returns the list of section-index titles for the table view (read-only)
 @property(nonatomic, readonly) NSArray *sectionIndexTitles
 
 */
- (NSArray *) sectionIndexTitles {
	return self.collationIndexArray;
}


#pragma mark -
#pragma mark Collation Methods


/**
 Returns an integer identifying the section in which a model object belongs.
 
 Usage:
 - determines which section this object should be placed
 */

- (NSInteger)sectionForObject:(id)object collationStringSelector:(SEL)selector {
						  
	//DDLogVerbose(@"TTLIC: start SFO");
	//IndexType iType = self.indexType;
	
	// if default use collation default behavoir
	// avoid this for now until Apple fixes this
	/*if (iType == kIndexTypeDefault) {
		return [self.collation sectionForObject:object collationStringSelector:selector];
	}*/
	
	// otherwise use custom dictionary to get the right index
	//
	NSInteger indexCount = [self.collationIndexArray count];
	// default to last index
	NSInteger resultSection = indexCount-1;
	
	NSString *sortString = [object performSelector:selector];
	// if sort string exists
	// - use dictionary to get section index
	//
	if ([sortString length] > 0) {
		NSString *firstChar = [sortString substringToIndex:1];
		//DDLogVerbose(@"TTLIC: before dict search");
		
		NSNumber *resNumber = [self.collationDictionary objectForKey:firstChar];
		
		//DDLogVerbose(@"TTLIC: char:%@ index:%@", firstChar, resNumber);
		
		// if dictionary entry was found
		// - otherwise: a number of an unknown (Han) character
		if (resNumber != nil) {
			
			// if results overflow the index size
			// - probably Zhuyin or Ja with Latin Index setting turned off
			if ([resNumber intValue] < indexCount) {
				resultSection = [resNumber intValue];
			}
		}
		// check phonetic name to sort: primiarly done for Ja users
		// NOTE: hard codes selector, so only Person objects can be sorted!!!
		else {
			/* phonetic not available in M+
             sortString = [object performSelector:@selector(propertyPhoneticName)];
			firstChar = [sortString substringToIndex:1];
			resNumber = [self.collationDictionary objectForKey:firstChar];
			if (resNumber != nil && [resNumber intValue] < indexCount) {
				resultSection = [resNumber intValue];
			}*/
		}
	}
	
	// if all else fails, return max index number - nothing matches so put at the end
	//DDLogVerbose(@"TTLIC: using custom index %@ - returning max #", sortString);
	return resultSection;
}

/**
 Sort array of objects depending on selector
 
 Just used the sort provided by default collation object
 */
- (NSArray *)sortedArrayFromArray:(NSArray *)array collationStringSelector:(SEL)selector {
	return [self.collation sortedArrayFromArray:array collationStringSelector:selector];
}

/**
 sectionForSectionIndexTitleAtIndex:
 Returns the section that the table view should scroll to for the given index title.
 
 Usage:
 - helps map the index number to the section that the table should scroll to
 */

- (NSInteger)sectionForSectionIndexTitleAtIndex:(NSInteger)indexTitleIndex {
	//IndexType iType = self.indexType;
	
	return indexTitleIndex;
	
	// if default use collation default behavoir
	/*if (iType == kIndexTypeDefault) {
		return [self.collation sectionForSectionIndexTitleAtIndex:indexTitleIndex];
	}
	// otherwise the index used here are one to one
	// - do we need to cap it to prevent crash?
	else {
		return indexTitleIndex;
	}*/
}



@end
