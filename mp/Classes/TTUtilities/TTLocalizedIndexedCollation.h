//
//  TTLocalizedIndexedCollation.h
//  ContactBook
//
//  Created by M Tsai on 10-11-26.
//  Copyright 2010 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Specified the index type that this collation should use
 
 kIndexTypeNone			no index yet defined
 kIndexTypeDefault		default unmodified collation is used
 kIndexTypeHiragana		modified Japanese index should be used
 kIndexTypeZhuYin		modified Taiwan index - use zhuyin
 kIndexTypePinYin		modified CN index - use pinyin
 */


typedef enum {
	kIndexTypeNone,
	kIndexTypeDefault,
	kIndexTypeHiragana,
	kIndexTypeHiraganaRoman,
	kIndexTypeZhuYin,
	kIndexTypeZhuYinRoman,
	kIndexTypePinYin,
} IndexType;

/*!
 
 @abstract subclass of UILocalizedIndexedCollation
 
 Usage:
 - use this to override the normal behavoir apple's collation class since it is broken
 - ja: allows kanji to be sorted in hiragana index
 - zh-cn: use pinyin to sort into latin characters
 - zh-tw: use zhuyin to sort to zhuyin characters 
 
 Attributes:
 
 collationIndexArray		index to use depending on localization
 collationDictionary		dictionary to help sort objects into the right index sections
 
 Testing:
 - must work even if we change local on the fly
 
 */

@interface TTLocalizedIndexedCollation : NSObject {

	UILocalizedIndexedCollation *collation;
	IndexType indexType;
	NSArray *collationIndexArray;
	NSDictionary *collationDictionary;
	
}

@property (nonatomic, retain) UILocalizedIndexedCollation *collation;
@property (nonatomic, assign, readonly) IndexType indexType;
@property (nonatomic, retain, readonly) NSArray *collationIndexArray;
@property (nonatomic, retain, readonly) NSDictionary *collationDictionary;

// UILocalizedIndexedCollation properties and methods
//
@property(nonatomic, readonly) NSArray *sectionTitles;
@property(nonatomic, readonly) NSArray *sectionIndexTitles;

- (void) resetCache;
- (NSInteger) sectionForObject:(id)object collationStringSelector:(SEL)selector;
- (NSArray *) sortedArrayFromArray:(NSArray *)array collationStringSelector:(SEL)selector;
- (NSInteger) sectionForSectionIndexTitleAtIndex:(NSInteger)indexTitleIndex;

@end
