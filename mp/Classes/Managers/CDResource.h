//
//  CDResource.h
//  mp
//
//  Created by Min Tsai on 1/8/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MPResourceCenter.h"

/**
 Resource Image Type
 
 Describes the type of image requested
 - used for external request, so other don't need to know fileSmall, Medium or Large
 - add other types as needed
 
 Preview        Usually for selection views: emoticon keypad, letter selection (ResourceButton)
 LetterFull     Large letter image
 
 */
typedef enum {
    kRSImageTypePreview = 0,
    kRSImageTypeLetterFull = 1,
    kRSImageTypeStickerStart = 2
} RSImageType;


@interface CDResource : NSManagedObject {
    
    NSDate *lastDownloadAttemptDate;
    NSUInteger numberOfRetryAttempts;
    NSCache *imageCache;
    
}

@property (nonatomic, retain) NSDate *lastDownloadAttemptDate;
@property (nonatomic, assign) NSUInteger numberOfRetryAttempts;

/*! cache for quick access to old images */
@property (nonatomic, retain) NSCache *imageCache;

@property (nonatomic, retain) NSString * resourceID;
@property (nonatomic, retain) NSString * fileSmall;
@property (nonatomic, retain) NSString * animationFiles;
@property (nonatomic, retain) NSString * fileMedium;
@property (nonatomic, retain) NSDate * dateLastUsed;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * fileLarge;

/*! order = -1 is not used */
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSDate * dateLastUpdate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * animationDuration;
@property (nonatomic, retain) NSNumber * setID;
@property (nonatomic, retain) NSString * downloadURL;
@property (nonatomic, retain) NSNumber * didDownloadUpdate;


+ (CDResource *) resourceForItemDictionary:(NSDictionary *)itemD 
                                      type:(NSNumber *)type 
                                     setID:(NSNumber *)setID 
                                     order:(NSNumber *)order
                            lastUpdateDate:(NSDate *)lastUpdateDate 
                               downloadURL:(NSString *)aDownloadURL
                                      save:(BOOL)shouldSave;
+ (void) resetOrderForRecourceType:(RCType)type orderDictionary:(NSDictionary *)orderDictionary;

+ (CDResource *) stickerForText:(NSString *)stickerText;
+ (NSArray *) resourcesNotDownloadedYet;
+ (NSArray *) resourcesForType:(RCType)type setID:(int)setID onlyRecent:(BOOL)onlyRecent;
+ (void) deleteAllResources;
+ (void) resetStickerDownload;

- (NSString *) downloadFilename;
- (RCType) rcType;

- (NSString *) getImageFilenameForType:(RSImageType)imageType;
- (UIImage *) getImageForType:(RSImageType)imageType;

- (BOOL) shouldDownloadForRetry:(BOOL)isRetry;
- (void) updateLastUsedAndSave;

@end
