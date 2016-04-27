//
//  CDResource.m
//  mp
//
//  Created by Min Tsai on 1/8/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "CDResource.h"
#import "MPFoundation.h"

@interface CDResource (Private)
+ (NSArray *) resourcesForPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fetchLimit:(NSInteger)fetchLimit;
@end

@implementation CDResource

@synthesize lastDownloadAttemptDate;
@synthesize numberOfRetryAttempts;
@synthesize imageCache;

@dynamic resourceID;
@dynamic fileSmall;
@dynamic animationFiles;
@dynamic fileMedium;
@dynamic dateLastUsed;
@dynamic type;
@dynamic fileLarge;
@dynamic order;
@dynamic dateLastUpdate;
@dynamic text;
@dynamic animationDuration;
@dynamic setID;
@dynamic downloadURL;
@dynamic didDownloadUpdate;

#pragma mark - Instance Query



/*!
 @abstract Provides string representation of resource
 
 Use:
 - for debugging
  
 */
- (NSString *) description {
    
    return [NSString stringWithFormat:@"CDR: id:%@ ord:%@ set:%@ down:%@ lf:%@ tx:%@:", self.resourceID, self.order, self.setID, self.didDownloadUpdate, self.fileLarge, self.text];
    
}



/*!
 @abstract Get filename of the download URL - last part of the URL
 
 Use:
 - use as a tag to ID downloads
 
 http://xxxx/Sticker/Sticker_001.zip
 
 */
- (NSString *) downloadFilename {
 
    NSArray *urlParts = [self.downloadURL componentsSeparatedByString:@"/"];
    if ([urlParts count] > 3) {
        return [urlParts lastObject];
    }
    return nil;
}

/*!
 @abstract Gets type as RCType
  
 */
- (RCType) rcType {
    return [self.type intValue];
}


/*!
 @abstract Gets image for given image type requested
 
 @return Success return UIImage, Fail return nil
 */
- (NSString *) getImageFilenameForType:(RSImageType)imageType {
    
    NSString *fileName = nil;
    NSArray *files = nil;
    
    switch (imageType) {
        case kRSImageTypePreview:
            fileName = self.fileMedium;
            break;
            
        case kRSImageTypeLetterFull:
            fileName = self.fileLarge;
            break;
            
        case kRSImageTypeStickerStart:
            files = [self.animationFiles componentsSeparatedByString:@","];
            if ([files count] > 0) {
                fileName = [files objectAtIndex:0];
            }
            break;
            
        default:
            break;
    }
    return fileName;
}


/*!
 @abstract Gets image for given image type requested
 
 @return Success return UIImage, Fail return nil
 */
- (UIImage *) getImageForType:(RSImageType)imageType {
    
    NSString *fileName = [self getImageFilenameForType:imageType];
    
    // check if cache has image
    //
    UIImage *resourceImage = [self.imageCache objectForKey:fileName];
    if (resourceImage) {
        return resourceImage;
    }
    
    if ([fileName length] > 0) {
        TKFileManager *newFM = [[TKFileManager alloc] initWithDirectory:kRCFileCenterDirectory];
        resourceImage = [newFM getImageForFilename:fileName];  
        [newFM release];
        
        if (resourceImage) {
            // only cache small images
            CGSize imageSize = resourceImage.size;
            if (imageSize.width < 200.0) {
                if (!self.imageCache) {
                    NSCache *iCache = [[NSCache alloc] init];
                    self.imageCache = iCache;
                    [iCache release];
                }
                [self.imageCache setObject:resourceImage forKey:fileName];
            }
        }
        
        //DDLogVerbose(@"size: %f %f", testSize.width, testSize.height);
    }
    return resourceImage;
}



/*!
 @abstract Inform resource that we are trying to download it now
 
 @param isRetry Is this attempt after getting an error?
 
 @return YES if download should be attempted
 
 */
- (BOOL) shouldDownloadForRetry:(BOOL)isRetry {

    // no down if too many retries
    if (isRetry) {
        if (self.numberOfRetryAttempts > 2) {
            return NO;
        }
    }
    // no down if trying too soon again
    else {
        if (self.lastDownloadAttemptDate) {
            CGFloat timeDiff = [[NSDate date] timeIntervalSinceDate:self.lastDownloadAttemptDate];
            if (timeDiff < 120.0) {
                DDLogInfo(@"CDR: last download too close: %f", timeDiff);
                return NO;
            }
        }
    }
    
    if (isRetry) {
        self.numberOfRetryAttempts++;
    }
    self.lastDownloadAttemptDate = [NSDate date];
    return YES;
}




#pragma mark - Instance Updates

- (void) updateLastUsedAndSave {
    
    // set to current date
    self.dateLastUsed = [NSDate date];
    [AppUtility cdSaveWithIDString:@"Save resource lastUsed" quitOnFail:NO];
}


#pragma mark - Updates

/*!
 @abstract gets CDResource matching params given
 - if none found, one is created
 
 @param itemD               basic resource info dictionary
 @param type                type of resource
 @param setID               the set this resource belongs to
 @param order               order of resource to display this resource
 @param lastUpdateDate      date for this udpate
 @param save                should MO saved to CD? - NO so you can save in a batch
 
 @return
 success		CDResource
 fail			nil         - neg presence state, can't save, etc.
 
 Use:
 - used to create or update a resource from GetResourceInfo results
 
 Sticker Dict
 - item_0
 - id: 001
 - download_url: http//..
 - content_count: 6
 - content: stk_001_1.png,stk_001_2.png,..
 - previewfile: stk_001_3.png              
 - duration: 50,100,100,100,50     frame duration in ms
 - text: (sticker001)
 
 Emoticon Dict
 - id: 001
 - content_count: 2
 - content: Em_001_preview.png,Em_001.png
 - previewfile: Em_001_preview.png              
 - text: (smile)
 
 PetPhrase Dict
 - id: 1       
 - text: Are you available now?
 
 Letter Dict
 - id: 1
 - download_url: http://xxxx/Letter/Letter_001.zip
 - content_count: 2
 - content: let_001_1.png,let_001_2.png
 - previewfile: let_001_3.png              
 - text: letter_name
 
 
 */
+ (CDResource *) resourceForItemDictionary:(NSDictionary *)itemD 
                                      type:(NSNumber *)type 
                                     setID:(NSNumber *)setID 
                                     order:(NSNumber *)order
                            lastUpdateDate:(NSDate *)lastUpdateDate 
                               downloadURL:(NSString *)aDownloadURL
                                      save:(BOOL)shouldSave {
    
    if (!itemD || !type) {
        return nil;
    }
    
    
    
    NSString * newResourceID = [itemD valueForKey:@"id"];
    NSString * newText = [itemD valueForKey:@"text"];
    NSString * newDownloadURL = nil;
    
    // if download url specified, use it
    if (aDownloadURL) {
        newDownloadURL = aDownloadURL;
    }
    else {
        newDownloadURL = [itemD valueForKey:@"download_url"];
    }

    // used for preview purposes
    NSString * newFileMedium = [itemD valueForKey:@"previewfile"];
    
    // actual content file for emoticons - smaller than preview
    NSString * newFileSmall = nil;
    
    // actual content file for letters - larger than preview
    NSString * newFileLarge = nil;

    NSString * newAnimationFiles = nil;
    NSString * newAnimationDuration = nil;
    
    // get sticker info
    //
    RCType newType = [type intValue];
    if (newType == kRCTypeSticker) {
        newAnimationFiles = [itemD valueForKey:@"content"];
        newAnimationDuration = [itemD valueForKey:@"duration"];
    }
    // get emoticon info
    else if (newType == kRCTypeEmoticon) {
        NSString *content = [itemD valueForKey:@"content"];
        NSArray *files = [content componentsSeparatedByString:@","];
        if ([files count] > 1) {
            newFileSmall = [files objectAtIndex:1];
        }
    }
    // get letter info
    else if (newType == kRCTypeLetter) {
        NSString *content = [itemD valueForKey:@"content"];
        NSArray *files = [content componentsSeparatedByString:@","];
        if ([files count] > 1) {
            newFileLarge = [files objectAtIndex:1];
        }
    }
    
    // for each update assume there is a new file to download
    // - problem if update and download occurs at the same time
    //
    NSNumber * newDidDownloadUpdate = [NSNumber numberWithBool:NO];     
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDResource" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load resource if it already exists
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // include type match since resourceID may not be unique across types
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(resourceID == %@) AND (type == %@)",newResourceID, type];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    CDResource *resultResource = nil;
    
    //BOOL freshlyMade = NO;
    
    if ([results count] > 0) {
        resultResource = [results objectAtIndex:0];
    }
    // create a new contact object and return it
    //
    else {
        resultResource = [NSEntityDescription insertNewObjectForEntityForName:[entity name] 
                                                      inManagedObjectContext:managedObjectContext];
        resultResource.resourceID = newResourceID;
        resultResource.type = type;
        
    }
    if (resultResource) {
        
        resultResource.setID = setID;
        resultResource.order = order;
        resultResource.text = newText;
        resultResource.downloadURL = newDownloadURL;
        resultResource.dateLastUpdate = lastUpdateDate;
        
        resultResource.fileSmall = newFileSmall;
        resultResource.fileMedium = newFileMedium;
        resultResource.fileLarge = newFileLarge;
        
        resultResource.animationFiles = newAnimationFiles;
        resultResource.animationDuration = newAnimationDuration;
        resultResource.didDownloadUpdate = newDidDownloadUpdate;
    }
    
    // save to CD
    //
    if (shouldSave) {
        if ([AppUtility cdSaveWithIDString:@"save resourceForItemDictionary" quitOnFail:YES] != NULL) {
            return nil;
        }
    }
    return resultResource;
}



/*!
 @abstract Sets the order information for a given resource type
 
 @param type The type of resource to udpate
 @param orderDictionary Key: resourceID Value: orderInfo of that resource - if order == nil, then no order
 
 Use:
 - since we will update now, so we should clear out old order info and set new order info for all resource items
 
 */
+ (void) resetOrderForRecourceType:(RCType)type orderDictionary:(NSDictionary *)orderDictionary {
    
    // get all resources for this type
    //
    NSNumber *typeNumber = [NSNumber numberWithInt:type];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(type == %@)",typeNumber];
    NSArray *resources = [CDResource resourcesForPredicate:pred sortDescriptors:nil fetchLimit:-1];
    
    // set all of them to order = -1
    //
    for (CDResource *iResource in resources) {
        
        // get order info
        id orderObject = [orderDictionary valueForKey:iResource.resourceID];
        if ([orderObject isKindOfClass:[NSNumber class]]) {
            iResource.order = orderObject;
        }
        else if ([orderObject isKindOfClass:[NSArray class]]) {
            if ([orderObject count] == 2) {
                NSNumber *setNumber = [orderObject objectAtIndex:0];
                NSNumber *orderNumber = [orderObject objectAtIndex:1];
                iResource.setID = setNumber;
                iResource.order = orderNumber;
            }
        }
        // no order - so excluded and will not be available for use
        else {
            iResource.order = [NSNumber numberWithInt:-1];
        }
    }
    // save manually - [AppUtility cdSaveWithIDString:@"R-co: clearing resource order" quitOnFail:NO];
}

#pragma mark - Queries


/*!
 @abstract gets resources that meets predicate requirements
 
 @param fetchLimit limits the number of fetches returned -1 means no limit
 
 @return success - array of resources, fail - nil no resource found
 
 */
+ (NSArray *) resourcesForPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fetchLimit:(NSInteger)fetchLimit {
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDResource" 
											  inManagedObjectContext:managedObjectContext];
	
	// load resource if it already exists
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    [fetchRequest setEntity:entity];
    
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
    if (sortDescriptors) {
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    if (fetchLimit > 0) {
        [fetchRequest setFetchLimit:fetchLimit];
    }
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    return results;
}

/*!
 @abstract gets sticker given it's text code
 
 @return success - sticker resource, fail - nil
 
 */
+ (CDResource *) stickerForText:(NSString *)stickerText {
    if ([stickerText length] > 0) {
        NSNumber *typeNumber = [NSNumber numberWithInt:kRCTypeSticker];
        NSString *nextText = [NSString stringWithFormat:@"%@a", stickerText];
        
        // include type match since resourceID may not be unique across types
        // - also make sure url is available
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(text >= %@) AND (text < %@) AND (type == %@)",
                             stickerText,
                             nextText,
                             typeNumber];
                
        NSArray *results = [CDResource resourcesForPredicate:pred sortDescriptors:nil fetchLimit:1];
        if ([results count] > 0) {
            return [results objectAtIndex:0];
        }
        DDLogVerbose(@"CDR: no sticker found - %@ - %@", pred, results);
    }
    return nil;
}


/*!
 @abstract gets resources that still need to downloaded
 
 @return success - array of resources that needs download, fail - nil no downloads needed
 
 */
+ (NSArray *) resourcesNotDownloadedYet {
    
    // include type match since resourceID may not be unique across types
    // - also make sure url is available
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(didDownloadUpdate == %@) AND (downloadURL > %@)",[NSNumber numberWithBool:NO], @"h"];
    
    // download in order
    //
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
    [sortDescriptor release];
    
    return [CDResource resourcesForPredicate:pred sortDescriptors:sortDescriptors fetchLimit:-1];
}


/*!
 @abstract gets resources for a given type and set
 
 @param type        type of resource to query for
 @param setID       which set to query.  -1 == get all sets
 @param onlyRecent  get only the most recently used resources
 
 */
+ (NSArray *) resourcesForType:(RCType)type setID:(int)setID onlyRecent:(BOOL)onlyRecent {
    
    NSNumber *typeNumber = [NSNumber numberWithInt:type];
    NSNumber *setNumber = [NSNumber numberWithInt:setID];
    
    NSPredicate *pred = nil;
    NSArray *sortDescriptors = nil;
    
    // recent should only fetch one page worth of resources
    // - default, don't limit
    NSInteger fetchLimit = -1;

    // only for recent page
    if (onlyRecent) {

        NSDate *last3Months = [NSDate dateWithTimeIntervalSinceNow:-7776000];
        
        if (type == kRCTypeEmoticon) {
            pred = [NSPredicate predicateWithFormat:@"(type == %@) AND (order > -1) AND (dateLastUsed > %@)",typeNumber, last3Months];
            fetchLimit = 21;
        }
        else if (type == kRCTypeSticker) {
            pred = [NSPredicate predicateWithFormat:@"(type == %@) AND (setID == %@) AND (order > -1) AND (dateLastUsed > %@)",typeNumber, setNumber, last3Months];
            fetchLimit = 8;
        }
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateLastUsed" ascending:NO];
        sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
        [sortDescriptor release];
    }
    // get all resources
    else {
        // if set specified and sticker
        if (type == kRCTypeSticker && setID > -1) {
            pred = [NSPredicate predicateWithFormat:@"(type == %@) AND (setID == %@) AND (order > -1)",typeNumber, setNumber];
        }
        else if (type == kRCTypeEmoticon || 
                 type == kRCTypeSticker  || 
                 type == kRCTypePetPhrase ||
                 type == kRCTypeLetter ) {
            pred = [NSPredicate predicateWithFormat:@"(type == %@) AND (order > -1)",typeNumber];
        }
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
        sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
        [sortDescriptor release];
    }
    
    return [CDResource resourcesForPredicate:pred sortDescriptors:sortDescriptors fetchLimit:fetchLimit];
}

+ (void) deleteAllResources {
    
    NSArray *all = [CDResource resourcesForPredicate:nil sortDescriptors:nil fetchLimit:-1];
    for (CDResource *iResource in all) {
        [AppUtility cdDeleteManagedObject:iResource];
    }
    [AppUtility cdSaveWithIDString:@"Delete all resources" quitOnFail:NO];
    
}


/*!
 @abstract Sets download to NO for stickers
 
 For testing sticker incomplete download
 
 */
+ (void) resetStickerDownload {
    
    // only stickers 
    //NSArray *stickers = [CDResource resourcesForType:kRCTypeSticker setID:-1 onlyRecent:NO];
    
    // all resources
    NSArray *stickers = [CDResource resourcesForPredicate:nil sortDescriptors:nil fetchLimit:-1];
    
    TKFileManager *newFM = [[TKFileManager alloc] initWithDirectory:kRCFileCenterDirectory];

    for (CDResource *iSticker in stickers) {
        // delete file
        //
        NSString *deleteName = [iSticker.fileMedium stringByReplacingOccurrencesOfString:@"." withString:@"@2x."];
        [newFM deleteFilename:deleteName deletePreivew:NO];
        [newFM deleteFilename:iSticker.fileMedium deletePreivew:NO];

        NSString *deleteSmallName = [iSticker.fileSmall stringByReplacingOccurrencesOfString:@"." withString:@"@2x."];
        [newFM deleteFilename:deleteSmallName deletePreivew:NO];
        [newFM deleteFilename:iSticker.fileSmall deletePreivew:NO];
        
        NSString *deleteLargeName = [iSticker.fileLarge stringByReplacingOccurrencesOfString:@"." withString:@"@2x."];
        [newFM deleteFilename:deleteLargeName deletePreivew:NO];
        [newFM deleteFilename:iSticker.fileLarge deletePreivew:NO];
        
        NSArray *aFiles = [iSticker.animationFiles componentsSeparatedByString:@","];
        
        for (NSString *iFile in aFiles) {
            deleteName = [iFile stringByReplacingOccurrencesOfString:@"." withString:@"@2x."];
            [newFM deleteFilename:deleteName deletePreivew:NO];
            [newFM deleteFilename:iFile deletePreivew:NO];
        }
        
        //CGSize testSize = resourceImage.size;
        //DDLogVerbose(@"size: %f %f", testSize.width, testSize.height);
        
        // set download to no
        //iSticker.didDownloadUpdate = [NSNumber numberWithBool:NO];
        
    }
    [AppUtility cdSaveWithIDString:@"Delete sticker files and reset download" quitOnFail:NO];
    [newFM release];
}


@end
