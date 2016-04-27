//
//  MPResourceCenter.h
//  mp
//
//  Created by M Tsai on 11-8-30.
//  Copyright 2011年 TernTek. All rights reserved.
//

/*!
 @header MPResourceCenter
 
 Helps client update new resource assets.
 - Get updated metadata for resource
 - Downloads and install new resource files
 
 
 @copyright TernTek
 @updated 2012-01-07
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <Foundation/Foundation.h>
#import "TKFileManager.h"

/*! when a resource was just downloaded - object ID of resource */
extern NSString* const MP_RESOURCECENTER_DID_DOWNLOAD_RESOURCE_NOTIFICATION;

extern NSString* const kRCFileCenterDirectory;

/**
 Resource types
 */
typedef enum {
    kRCTypeNone = 0,
	kRCTypeEmoticon = 1,
    kRCTypeSticker = 2,
    kRCTypePetPhrase = 3,
    kRCTypeLetter = 4
} RCType;


@class MPResourceCenter;
@class CDResource;

/*!
 Delegate protocol
 */
@protocol MPResourceCenterDelegate <NSObject>
/*!
 @abstract Provides progress of download
 */
- (void)MPResourceCenter:(MPResourceCenter *)resourceCenter progress:(CGFloat)progressRatio;
@end

@interface MPResourceCenter : NSObject <TKFileManagerDelegate, NSFileManagerDelegate> {
    
    id <MPResourceCenterDelegate> delegate;
    NSMutableDictionary *stickerOrderD;
    NSMutableDictionary *emoticonOrderD;
    NSMutableDictionary *letterOrderD;
    
    NSMutableDictionary *textToEmoticonD;
    NSMutableDictionary *textToStickerD;
    
    NSUInteger completedDownloadCount;
    NSMutableArray *resourcesPendingDownload;
    TKFileManager *fileManger;
    
    
}

@property (nonatomic, assign) id <MPResourceCenterDelegate> delegate;

/*! stores the set and order info for stickers for fast lookup - key:stickerID value:[setID, order]*/
@property (nonatomic, retain) NSMutableDictionary *stickerOrderD;

/*! stores order info for emoticons for fast lookup */
@property (nonatomic, retain) NSMutableDictionary *emoticonOrderD;

/*! stores order info for letter for fast lookup */
@property (nonatomic, retain) NSMutableDictionary *letterOrderD;

/*! gets emoticon given text */
@property (nonatomic, retain) NSMutableDictionary *textToEmoticonD;

/*! gets sticker given text */
@property (nonatomic, retain) NSMutableDictionary *textToStickerD;


/*! number of downloads done or failed */
@property (nonatomic, assign) NSUInteger completedDownloadCount;

/*! stores order info for emoticons for fast lookup */
@property (nonatomic, retain) NSMutableArray *resourcesPendingDownload;

/*! helps download updates and get files */
@property (nonatomic, retain) TKFileManager *fileManger;


/*!
 @abstract creates singleton object
 */
+ (MPResourceCenter *)sharedMPResourceCenter;


- (void) updateCDResourceWithXML:(NSDictionary *)xmlDictionary;
- (NSArray *) loadDefaultPetPhrases;

// download
//
- (void) installDefaultEmoticons;
- (void) clearDownloadQueue;
- (BOOL) shouldStartDownload;
- (void) downloadResource:(CDResource *)resourceToDownload force:(BOOL)force isRetry:(BOOL)isRetry addPending:(BOOL)addPending;
- (void) startDownloadWithDelegate:(id)newDelegate;

- (NSArray *) parseText:(NSString *)text;
- (NSUInteger) charCountInText:(NSString *)text;
- (CDResource *) emoticonForText:(NSString *)text;

- (CDResource *) stickerForText:(NSString *)text;
@end
