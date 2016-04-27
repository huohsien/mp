//
//  MPResourceCenter.m
//  mp
//
//  Created by Min Tsai on 1/7/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "MPResourceCenter.h"
#import "MPFoundation.h"

#import "SynthesizeSingleton.h"
#import "CDResource.h"

NSString* const MP_RESOURCECENTER_DID_DOWNLOAD_RESOURCE_NOTIFICATION = @"MP_RESOURCECENTER_DID_DOWNLOAD_RESOURCE_NOTIFICATION";

NSString* const kRCFileCenterDirectory = @"resources";

NSString* const kRCStringTypeEmoticon = @"emoticon";
NSString* const kRCStringTypeSticker = @"sticker";
NSString* const kRCStringTypeImage = @"image";
NSString* const kRCStringTypeSound = @"sound";
NSString* const kRCStringTypeLetter = @"letter";

unichar const kRCStartChar = '(';
unichar const kRCEndChar = ')';

@implementation MPResourceCenter

@synthesize delegate;
@synthesize stickerOrderD;
@synthesize emoticonOrderD;
@synthesize letterOrderD;
@synthesize textToEmoticonD;
@synthesize textToStickerD;

@synthesize completedDownloadCount;
@synthesize resourcesPendingDownload;
@synthesize fileManger;


SYNTHESIZE_SINGLETON_FOR_CLASS(MPResourceCenter);


- (id)init {
    
    self = [super init];
    if (self) {
        
        TKFileManager *newFM = [[TKFileManager alloc] initWithDirectory:kRCFileCenterDirectory];
        newFM.delegate = self;
        self.fileManger = newFM;
        [newFM release];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearCaches)
                                                     name:UIApplicationDidEnterBackgroundNotification object:nil];
    }    
    return self;
}


-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [stickerOrderD release];
    [emoticonOrderD release];
    [textToEmoticonD release];
    [textToStickerD release];
    
    [resourcesPendingDownload release];
    [super dealloc];
}

#pragma mark - Tools

/*!
 @abstract Gets int representation for resource type
 
 @param if unknown type returns kRCTypeNone = 0
 
 Save space in CD database.
 
 */
- (RCType) rcTypeForStringType:(NSString *)stringType {
    
    
    if ([stringType isEqualToString:kRCStringTypeSticker]) {
        return kRCTypeSticker;
    }
    if ([stringType isEqualToString:kRCStringTypeEmoticon]) {
        return kRCTypeEmoticon;
    }
    if ([stringType isEqualToString:kRCStringTypeLetter]) {
        return kRCTypeLetter;
    }
    return kRCTypeNone;
}

/*!
 @abstract Clear caches that can be reloaded in the future
 
 */
- (void) clearCaches {
    
    // clear out caches that may not be accurate now
    //
    self.textToStickerD = nil;
    self.textToEmoticonD = nil;
    
}

#pragma mark - Resource Info Updates


/*!
 @abstract Takes string of sticker IDs and add to sticker order Dictionary
 
  * order example: 001,002,003...
  * assume that each sticker only belongs to one set
  * Add to sticker order D: key:stickerID value:[setID, order]
 
 */
- (void) addStickerOrderInfo:(NSString *)stickerOrder set:(NSInteger)setID {

    if (!self.stickerOrderD) {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.stickerOrderD = newD;
        [newD release];
    }
    
    NSNumber *setIDNumber = [NSNumber numberWithInteger:setID];
    NSArray *orderIDs = [stickerOrder componentsSeparatedByString:@","];
    
    int currentOrder = 0;
    for (NSString *iOrderID in orderIDs) {
        NSNumber *orderNumber = [NSNumber numberWithInt:currentOrder];
        [self.stickerOrderD setValue:[NSArray arrayWithObjects:setIDNumber, orderNumber, nil] forKey:iOrderID];
        currentOrder++;
    }
}


/*!
 @abstract Takes string of emoticon IDs and add to emoticon order Dictionary
 
 * order example: 001,002,003...
 * Add to emoticon order D: key:emoticonID value:order
 
 */
- (void) addEmoticonOrderInfo:(NSString *)emoticonOrder {
    
    if (!self.emoticonOrderD) {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.emoticonOrderD = newD;
        [newD release];
    }
    NSArray *orderIDs = [emoticonOrder componentsSeparatedByString:@","];
    
    int currentOrder = 0;
    for (NSString *iOrderID in orderIDs) {
        NSNumber *orderNumber = [NSNumber numberWithInt:currentOrder];
        [self.emoticonOrderD setValue:orderNumber forKey:iOrderID];
        currentOrder++;
    }
}

/*!
 @abstract Takes string of letter IDs and add to letter order Dictionary
 
 * order example: 001,002,003...
 * Add to letter order D: key:letterID value:order
 
 */
- (void) addLetterOrderInfo:(NSString *)letterOrder {
    
    if (!self.letterOrderD) {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.letterOrderD = newD;
        [newD release];
    }
    NSArray *orderIDs = [letterOrder componentsSeparatedByString:@","];
    
    int currentOrder = 0;
    for (NSString *iOrderID in orderIDs) {
        NSNumber *orderNumber = [NSNumber numberWithInt:currentOrder];
        [self.letterOrderD setValue:orderNumber forKey:iOrderID];
        currentOrder++;
    }
}


/*!
 @abstract Parse and Update Resource database
 
 Takes XML dictionary from GetResourceInfo and updates CoreData CDEmoticon entity
 
 - cause: 0
 - appversion: xxx
 - lastupdatetime:              epoch time of last update
 - resourcecount: 4             number of resources in this udpate
 - resource-0
    - type: sticker
    - total_set: 3              number of sets to expect
    - order_0: 001,002,..
    - order_1: 009,010,..
    - order_2: 020,021,..
    - updatecount: 2            number of resource upates
    - item_0
        - id: 001
        - download_url: http://xxxx/Sticker/Sticker_001.zip
        - content_count: 6
        - content: stk_001_1.png,stk_001_2.png,..
        - previewfile: stk_001_3.png              
        - duration: 50,100,100,100,50     frame duration in ms
        - text: (sticker001)
    - item_1
        ...
 - resource-1
    - type: emoticon
    - order: 001,002,..
    - count: 2                     items to be updated
    - download_url: http://xxx/Emoticon/emoticon.zip      zip of emoticons
    - item_0
        - id: 001
        - content_count: 2
        - content: Em_001_preview.png,Em_001.png
        - previewfile: Em_001_preview.png              
        - text: (smile)
    - item_0
        - id: 002
        - content_count: 2
        - content: Em_002_preview.png,Em_002.png
        - previewfile: Em_002_preview.png              
        - text: (vibrate)
 - resource-3
    - type: letter
    - order: 001,002,..
    - updatecount: 6            number of resource upates
    - item_0
        - id: 1
        - download_url: http://xxxx/Letter/Letter_001.zip
        - content_count: 2
        - content: let_001_1.png,let_001_2.png
        - previewfile: let_001_3.png              
        - text: letter_name
    - item_1
    ...
 
 
 1. Loop through each resource
  - Check resource type
  - read in set info and order to use later
  - update or create sticker entities: item_0, item_1
 
 
 */
- (void) updateCDResourceWithXML:(NSDictionary *)xmlDictionary {
    
    // clear out sticker & emoticon order data
    //
    [self.stickerOrderD removeAllObjects];
    [self.emoticonOrderD removeAllObjects];
    
    int resourceCount = [[xmlDictionary valueForKey:@"resourcecounts"] intValue];
    NSString *lastUpateString = [xmlDictionary valueForKey:@"lastupdatetime"];
    CGFloat lastUpdateEpochTime = [lastUpateString floatValue];
    NSDate *lastUpdateDate = [NSDate dateWithTimeIntervalSince1970:lastUpdateEpochTime];
    
    for (int i=0; i < resourceCount; i++) {
        
        NSString *resourceKey = [NSString stringWithFormat:@"resource-%d", i+1];
        NSDictionary *resourceD = [xmlDictionary valueForKey:resourceKey];
        
        NSString *type = [resourceD valueForKey:@"type"];
        RCType rcType = [self rcTypeForStringType:type];
        NSNumber *rcTypeNumber = [NSNumber numberWithInt:rcType];
        
        // ** sticker resource **
        //
        if (rcType == kRCTypeSticker) {
        
            // save set info
            int totalSets = [[resourceD valueForKey:@"total_set"] intValue];
            for (int j=0; j < totalSets; j++) {
                NSString *orderKey = [NSString stringWithFormat:@"order-%d", j];
                NSString *orderString = [resourceD valueForKey:orderKey];
                [self addStickerOrderInfo:orderString set:j];
            }
            
            // get sticker resources items
            int itemCount = [[resourceD valueForKey:@"updatecount"] intValue];
            DDLogVerbose(@"RC: updating stickers - %d", itemCount);
            for (int k=0; k < itemCount; k++) {
                NSString *itemKey = [NSString stringWithFormat:@"item-%d", k];
                NSDictionary *itemD = [resourceD valueForKey:itemKey];
                
                NSString *idString = [itemD valueForKey:@"id"];
                
                // get order info
                NSNumber *setNumber = nil;
                NSNumber *orderNumber = nil;
                NSArray *setAndOrder = [self.stickerOrderD valueForKey:idString];
                if ([setAndOrder count] == 2) {
                    setNumber = [setAndOrder objectAtIndex:0];
                    orderNumber = [setAndOrder objectAtIndex:1];
                }
                
                // create item with this itemD, set and order info
                //
                [CDResource resourceForItemDictionary:itemD type:rcTypeNumber setID:setNumber order:orderNumber lastUpdateDate:lastUpdateDate downloadURL:nil save:NO];
            }
            
            // update all order information
            [CDResource resetOrderForRecourceType:rcType orderDictionary:self.stickerOrderD];
            
            [AppUtility cdSaveWithIDString:@"RC: save sticker udpate" quitOnFail:NO];
            
        }
        // ** emoticons **
        //
        else if (rcType == kRCTypeEmoticon) {
            
            // clear out all order info for emoticons
            //[CDResource clearOrderForRecourceType:kRCTypeEmoticon];
            
            // save order info
            NSString *orderString = [resourceD valueForKey:@"order"];
            [self addEmoticonOrderInfo:orderString];
            
            // get download URL
            //
            NSString *downloadURL = [resourceD valueForKey:@"download_url"];
            
            // get resources items
            int itemCount = [[resourceD valueForKey:@"updatecount"] intValue];
            DDLogVerbose(@"RC: updating emoticon - %d", itemCount);

            for (int k=0; k < itemCount; k++) {
                NSString *itemKey = [NSString stringWithFormat:@"item-%d", k];
                NSDictionary *itemD = [resourceD valueForKey:itemKey];
                
                
                NSString *idString = [itemD valueForKey:@"id"];
                
                // get order info
                NSNumber *orderNumber = [self.emoticonOrderD valueForKey:idString];
                
                // create item with this itemD and order info
                //
                [CDResource resourceForItemDictionary:itemD type:rcTypeNumber setID:nil order:orderNumber lastUpdateDate:lastUpdateDate downloadURL:downloadURL save:NO];
                
                // for emoticon - set downloadURL to the first item only.
                downloadURL = nil;
            }
            
            // update all order information
            [CDResource resetOrderForRecourceType:rcType orderDictionary:self.emoticonOrderD];
            
            
            [AppUtility cdSaveWithIDString:@"RC: save emoticon udpate" quitOnFail:NO];
        }
        // ** letters **
        //
        else if (rcType == kRCTypeLetter) {
            
            // save order info
            NSString *orderString = [resourceD valueForKey:@"order"];
            [self addLetterOrderInfo:orderString];
            
            // get letter resources items
            int itemCount = [[resourceD valueForKey:@"updatecount"] intValue];
            DDLogVerbose(@"RC: updating letters - %d", itemCount);
            for (int k=0; k < itemCount; k++) {
                
                NSString *itemKey = [NSString stringWithFormat:@"item-%d", k];
                NSDictionary *itemD = [resourceD valueForKey:itemKey];
                
                NSString *idString = [itemD valueForKey:@"id"];
                
                // get order info
                NSNumber *orderNumber = [self.letterOrderD valueForKey:idString];
                
                // create item with this itemD and order info
                //
                [CDResource resourceForItemDictionary:itemD type:rcTypeNumber setID:nil order:orderNumber lastUpdateDate:lastUpdateDate downloadURL:nil save:NO];
                
            }
            
            // update all order information
            [CDResource resetOrderForRecourceType:rcType orderDictionary:self.letterOrderD];
            
            [AppUtility cdSaveWithIDString:@"RC: save letter udpate" quitOnFail:NO];
        }
        
        // update image
        // update sounds
    }
    
    // save this last time - so we don't download repeatedly
    //
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingGetResourceLastUpateTime settingValue:lastUpateString];
    
    // Start downloads
    //
    BOOL shouldDownload = [[MPResourceCenter sharedMPResourceCenter] shouldStartDownload];
    
    // show download view and download progress
    //
    if (shouldDownload) {
        [[MPResourceCenter sharedMPResourceCenter] startDownloadWithDelegate:nil];
    }
    
    // resets the shared emoticon keypad
    [[AppUtility getAppDelegate] resetEmoticonKeypad];
    
    [self clearCaches];
    
}


#pragma mark - Pet Phrase



/*!
 @abstract Create default petphrase is non is found
 
 @return returns an array of these petphrases
 
 PetPhrase Dict
 - id: 1       
 - text: Are you available now?
 
 */
- (NSArray *) loadDefaultPetPhrases {
    
    // copy it over file bundle
    NSString *path = [[NSBundle mainBundle] pathForResource:@"pet_phrase" ofType:@"plist"];
    NSArray *phrases = [[NSArray alloc] initWithContentsOfFile:path];

    NSMutableArray *phraseResources = [[[NSMutableArray alloc] init] autorelease];
    
    // create petphrase resources
    int i = 0;
    NSNumber *setID = [NSNumber numberWithInt:0];
    NSNumber *rcTypeNumber = [NSNumber numberWithInt:kRCTypePetPhrase];
    for (NSString *iPhrase in phrases) {
        
        NSNumber *order = [NSNumber numberWithInt:i];
    
        NSDictionary *phraseD = [NSDictionary dictionaryWithObjectsAndKeys:[order stringValue], @"id", iPhrase, @"text", nil];
        
        CDResource *newPhrase = [CDResource resourceForItemDictionary:phraseD type:rcTypeNumber setID:setID order:order lastUpdateDate:nil downloadURL:nil save:NO];
        
        if (newPhrase) {
            [phraseResources addObject:newPhrase];
        }
        i++;
    }
    [AppUtility cdSaveWithIDString:@"save default pet phrase" quitOnFail:NO];
    [phrases release];
    return phraseResources;
}





#pragma mark - Resource Download


/*!
 @abstract Install default emoticons in case they are not available over the network
 
 */
- (void) installDefaultEmoticons {
    // install default emoticons
    // emoticon_default_(mdpi|xhdpi).zip
    //
    CGFloat scale = [[UIScreen mainScreen] scale];
    NSString *resolution = @"mdpi";
    if (scale == 2.0) {
        resolution = @"xhdpi";
    }
    NSString *fileName = [NSString stringWithFormat:@"emoticon_default_%@", resolution];
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"zip"];
    
    [self.fileManger downloadFilename:@"emoticon_default.zip" url:[fileURL absoluteString] isPost:NO];
}


/*!
 @abstract Clear out download queue
 
 Use:
 - don't leave downloads pending between sessions, otherwise we will probably queue up too many!
 
 */
- (void) clearDownloadQueue {
    
    if (self.fileManger) {
        [self.fileManger clearDownloadQueue];
    }
}

/*!
 @abstract Checks if we have any pending downloads
 
 @return YES if we should start downloading
 
 Note:
 - caches resources that need to be download
 
 Use:
 - check at every time we enter foreground
 
 */
- (BOOL) shouldStartDownload {
   
    // reset pending downloads
    if (!self.resourcesPendingDownload) {
        NSMutableArray *newArray = [[NSMutableArray alloc] init];
        self.resourcesPendingDownload = newArray;
        [newArray release];
    }
    else {
        [self.resourcesPendingDownload removeAllObjects];
    }
    
    // if no routing, then don't download
    if (![[AppUtility getSocketCenter] isNetworkReachable]) {
        return NO;
    }
    
    // cache download targets
    //
    NSArray *results = [CDResource resourcesNotDownloadedYet];
    if ([results count] > 0) {
        
        
        [self.resourcesPendingDownload addObjectsFromArray:results];
        self.completedDownloadCount = 0;
        
        return YES;
    }
    
    return NO;
} 


/*!
 @abstract Adds "_2x" to download URL for retina display devices
 
 http://61.66.229.106:8080/ResourceDownload/sticker/sticker_65_xhdpi.zip
 
 Changes to
 
 http://61.66.229.106:8080/ResourceDownload/sticker/sticker_65_xhdpi_2x.zip
 ~ this zip file contains @2x.png files
 
 */
- (NSString *)getRetinaURLIfNeeded:(NSString *)originalURL {
    CGFloat scale = [[UIScreen mainScreen] scale];
    if (scale == 2.0) {
        return [originalURL stringByReplacingOccurrencesOfString:@"dpi.zip" withString:@"dpi_2x.zip"];
    }
    else {
        return originalURL;
    }
}


/*!
 @abstract Starts downloading resources
 
 Just fill up download queue on FM.  The FM will then download one file at a time.
 
 */
- (void) downloadResourcePrivate:(CDResource *)resourceToDownload {
    
        [self.fileManger downloadFilename:[resourceToDownload downloadFilename] url:[self getRetinaURLIfNeeded:resourceToDownload.downloadURL] isPost:NO];
}

/*!
 @abstract Start single resource download
 
 */
- (void) downloadResource:(CDResource *)resourceToDownload force:(BOOL)force isRetry:(BOOL)isRetry addPending:(BOOL)addPending {
    
    BOOL shouldDownload = [resourceToDownload shouldDownloadForRetry:isRetry];
    
    if (force) {
        shouldDownload = YES;
    }
    
    BOOL isPendingDownload = NO;
    if ([self.resourcesPendingDownload indexOfObject:resourceToDownload] != NSNotFound) {
        isPendingDownload = YES;
    }
    
    // if we should download or the resource is not in download queue
    // 
    if (shouldDownload || !isPendingDownload) {
        DDLogVerbose(@"RC: downloading: %@", resourceToDownload.text);
        
        if (addPending) {
            if (!self.resourcesPendingDownload) {
                NSMutableArray *newArray = [[NSMutableArray alloc] init];
                self.resourcesPendingDownload = newArray;
                [newArray release];
            }
            // register download
            [self.resourcesPendingDownload addObject:resourceToDownload];
        }
        
        [self downloadResourcePrivate:resourceToDownload];
    }
    else {
        DDLogVerbose(@"RC: skip downloading: %@", resourceToDownload.text);
    }
} 

/*!
 @abstract Starts downloading all resources that still not available yet
 
 Just fill up download queue on FM.  The FM will then download one file at a time.
 
 */
- (void) startDownloadWithDelegate:(id)newDelegate {
    
    DDLogVerbose(@"RC: start down: %d", [self.resourcesPendingDownload count]);
    
    self.delegate = newDelegate;
    for (CDResource *iResource in self.resourcesPendingDownload) {
        
        // keep record of download
        //
        [self downloadResource:iResource force:YES isRetry:NO addPending:NO];
        //[self downloadResourcePrivate:iResource];
    }
} 


#pragma mark - Sticker Resources


/*!
 @abstract Creates cache dictionary of resources for fast lookup
 */
- (void)reloadTextToStickerDictionary {
    if (self.textToStickerD) {
        [self.textToStickerD removeAllObjects];
    }
    else {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.textToStickerD = newD;
        [newD release];
    }
    
    NSArray *resources = [CDResource resourcesForType:kRCTypeSticker setID:-1 onlyRecent:NO];
    for (CDResource *iResource in resources) {
        if ([iResource.text length] > 0) {
            [self.textToStickerD setValue:iResource forKey:iResource.text];
        }
    }
}

/*!
 @abstract Gets emoticon resource for text code
 
 Use:
 - helps determine if we should delete the entire string
 */
- (CDResource *)stickerForText:(NSString *)text {
    if (!self.textToStickerD) {
        [self reloadTextToStickerDictionary];
    }
    return [self.textToStickerD valueForKey:text];
}


#pragma mark - Parse Text

/*!
 @abstract Creates cache dictionary of resources for fast lookup
 */
- (void)reloadTextToEmoticonDictionary {
    if (self.textToEmoticonD) {
        [self.textToEmoticonD removeAllObjects];
    }
    else {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.textToEmoticonD = newD;
        [newD release];
    }
    
    NSArray *resources = [CDResource resourcesForType:kRCTypeEmoticon setID:0 onlyRecent:NO];
    for (CDResource *iResource in resources) {
        if ([iResource.text length] > 0) {
            [self.textToEmoticonD setValue:iResource forKey:iResource.text];
        }
    }
}
    
/*!
 @abstract Gets emoticon resource for text code
 
 Use:
 - helps determine if we should delete the entire string
 */
- (CDResource *)emoticonForText:(NSString *)text {
    if (!self.textToEmoticonD) {
        [self reloadTextToEmoticonDictionary];
    }
    return [self.textToEmoticonD valueForKey:text];
}


/*!
 @abstract lookup text code to see if it matches an emoticon 
 */
- (UIImage *)imageForResourceText:(NSString *)resourceText {
    
    CDResource *thisResource = [self emoticonForText:resourceText];
    if (thisResource) {
        return [self.fileManger getImageForFilename:thisResource.fileSmall];
    }
    return nil;
}


/*!
 @abstract Parse text and provides an array of results for UI to use
 
 Just fill up download queue on FM.  The FM will then download one file at a time.
 
 No emoticon
 - return string in array
 
 Has emoticon
 - return array of text and images
 
 Is sticker
 - return Animation resource in array
 
 */
- (NSArray *) parseText:(NSString *)text {
    NSMutableArray *retArray = [[[NSMutableArray alloc] init] autorelease];
    
    // trim white space
    // 
    NSString *newText = [Utility trimWhiteSpace:text];
        
    // look for ( and ) to find emoticons and stickers
    NSCharacterSet *bracketSet = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"%C%C", kRCStartChar, kRCEndChar]];
    
    if (newText == nil) {
        DDLogVerbose(@"RC: nil text sent to parseText:%@", text);
        return nil;
    }
    NSScanner *scanner = [NSScanner scannerWithString:newText];
    [scanner setCharactersToBeSkipped:nil]; // don't skip any chars, otherwise scanner will not proceed when encountering newline
    
    // marks last '(' found
    NSInteger startCharIndex = -1;
    
    // marks last ')' found
    NSInteger endCharIndex = -1;
    // saves end index in case revert needed
    NSInteger tmpEndIndex = -1; 
    
    // marks last text start
    NSInteger textCharIndex = -2;  // -2 never set, -1 not set
    
    
    unichar atChar = 0;
    
    NSUInteger currentIndex = 0;
    NSUInteger scanIteration = 0;
    
    while ([scanner isAtEnd] == NO) {
        
        [scanner scanUpToCharactersFromSet:bracketSet intoString:NULL];
        currentIndex = [scanner scanLocation];
        
        // if scanned to the end - means we just scanned text and no bracket found
        if ([scanner isAtEnd]) {
            atChar = 0;
        }
        else {
            atChar = [newText characterAtIndex:[scanner scanLocation]];
        }
        
        // found resource start "("
        //
        if (atChar == kRCStartChar) {
            // save start index
            startCharIndex = currentIndex;
            
            // end char was found before & there is actual text in between
            if (endCharIndex > -1 && 
                startCharIndex > endCharIndex+1) {
                textCharIndex = endCharIndex +1;
            }
            // if start char is not at the start
            else if (startCharIndex > 0 && 
                     endCharIndex == -1 && 
                     textCharIndex == -2) {
                textCharIndex = 0;
            }
        }
        // found resource end!
        //
        else if (atChar == kRCEndChar) {
            tmpEndIndex = endCharIndex;
            endCharIndex = currentIndex;
            
            // previous start char was found - with at least one char
            //
            if (startCharIndex > -1 && 
                endCharIndex > startCharIndex +1) {
                
                // test if it is a resource
                NSString *resourceText = [newText substringWithRange:NSMakeRange(startCharIndex, endCharIndex-startCharIndex+1)];
                UIImage *resourceImage = [self imageForResourceText:resourceText];
                if (resourceImage) {
                    
                    // if previous text exits
                    if (textCharIndex > -1) {
                        [retArray addObject:[newText substringWithRange:NSMakeRange(textCharIndex, startCharIndex-textCharIndex)]];
                    }
                    // save resource
                    [retArray addObject:resourceImage];
                    
                    // reset for next resource
                    textCharIndex = -1;
                    startCharIndex = -1;
            
                }
                // not a resource - just text
                else {
                    // set this as regular text
                    if (textCharIndex == -1) {
                        textCharIndex = startCharIndex;
                    }
                    startCharIndex = -1;
                    endCharIndex = tmpEndIndex;
                }
            }
            // just a random end char without a start char before it
            else {
                startCharIndex = -1;
                endCharIndex = tmpEndIndex;
            }
        }
        // if at the end of text
        else if (atChar == 0) {
            // add last text if it exists
            if (textCharIndex > -1 && currentIndex > textCharIndex) {
                [retArray addObject:[newText substringFromIndex:textCharIndex]];
            }
            // add text starting from last emoticon to the end
            else if (endCharIndex > -1 && endCharIndex+1 < [newText length]) {
                [retArray addObject:[newText substringFromIndex:endCharIndex+1]];
            }
            // if all regular text
            else if ((textCharIndex == -2 || textCharIndex == 0) && [retArray count] == 0){
                [retArray addObject:newText];
            }
            break;
        }
        
        NSUInteger previousIndex = currentIndex;
        
        NSString *atCharString = [NSString stringWithFormat:@"%C", atChar];
        [scanner scanString:atCharString intoString:NULL]; // skip over bracket char
        currentIndex = [scanner scanLocation];
        
        // scanning character fails
        // - e.g. (ﾟ (+half width katakana - causes problem and scanner can't can the ( character
        if (currentIndex == previousIndex && currentIndex < [newText length]-1) {
            [scanner setScanLocation:currentIndex+1];
            currentIndex = [scanner scanLocation];
        }
        
        scanIteration++;
        
        // if bracket is at the end
        // - or if for some reason there are too many iterations - just in case
        if ([scanner isAtEnd] || scanIteration > kMPParamChatMessageLengthMax+100 ) {
            
            // add last text if it exists
            if (textCharIndex > -1 && currentIndex > textCharIndex) {
                [retArray addObject:[newText substringFromIndex:textCharIndex]];
            }
            // add text starting from last emoticon to the end
            else if (endCharIndex > -1 && endCharIndex+1 < [newText length]) {
                [retArray addObject:[newText substringFromIndex:endCharIndex+1]];
            }
            // if all regular text
            else if ((textCharIndex == -2 || textCharIndex == 0) && [retArray count] == 0){
                [retArray addObject:newText];
            }
            break;
        }
        
    }
    return retArray;
}



/*!
 @abstract Counts the amount of characters in text.
 - 1 emoticon equals one text
 
 @return Number of characters in text
 
 */
- (NSUInteger) charCountInText:(NSString *)text {
    
    NSArray *msgElements = [[MPResourceCenter sharedMPResourceCenter] parseText:text];
    
    // clear out values
    NSUInteger charCount = 0;
    
    for (id arrayItem in msgElements) {
        
        if ([arrayItem isKindOfClass:[NSString class]]) {
            charCount += [arrayItem length];
        }
        else if ([arrayItem isKindOfClass:[UIImage class]]) {
            charCount ++;
        }
    
    }
    return charCount;
}



#pragma mark - TKFileManager Delegate


/*!
 @abstract Adds @2x modifer to all png files
 
 */
- (void) add2xModifierToResourceFiles {
    
    // set listing of files
    //
    NSError *error = nil;
    NSString *resourceDirectory = [Utility documentFilePath:kRCFileCenterDirectory];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourceDirectory error:&error];
    if (error) {
        DDLogVerbose(@"RC: ERROR listing directory %@", [error localizedDescription]);
        return;
    }
    
    NSMutableSet *filesToRename = [[NSMutableSet alloc] init];
    
    // check if files are PNG and do not have @2x
    for (NSString *iFile in files) {
        if ([iFile hasSuffix:@".png"] && [iFile rangeOfString:@"2x"].location == NSNotFound) {
            [filesToRename addObject:iFile];
        }
    }
    [[NSFileManager defaultManager] setDelegate:self];
    for (NSString *iRename in filesToRename) {
        
        NSString *newName = [iRename stringByReplacingOccurrencesOfString:@".png" withString:@"@2x.png"];
        NSString *oldPath = [NSString stringWithFormat:@"%@/%@", resourceDirectory, iRename];
        NSString *newPath = [NSString stringWithFormat:@"%@/%@", resourceDirectory, newName];
        [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error];
        if (error) {
            DDLogVerbose(@"RC: ERROR moving file %@", [error localizedDescription]);
        }
    }
    [filesToRename release];
    [[NSFileManager defaultManager] setDelegate:nil];
}


/*!
 @abstract Updates download progress
 
 */
- (void) updateDownloadProgress {
    
    if ([self.delegate respondsToSelector:@selector(MPResourceCenter:progress:)]) {
        
        CGFloat progress = (CGFloat)self.completedDownloadCount/(CGFloat)[self.resourcesPendingDownload count];
        
        [self.delegate MPResourceCenter:self progress:progress];
        
        // - deprecated, we download @2x files directly now
        //
        // when download is complete update file names if needed
        //
        /*if (progress == 1.0 && [[UIScreen mainScreen] scale] == 2.0) {
            [self add2xModifierToResourceFiles];
        }*/
    }
}

/*!
 @abstract Called when data has completed loading and is ready to use.
 
 - just finished download original file
 - mark resource as downloaded
 - dequeue this resource for download
 
 */
- (void)TKFileManager:(TKFileManager *)fileManager finishLoadingWithData:(NSData *)data filename:(NSString *)filename{
    
    CDResource *doneResource = nil;
    for (CDResource *iResource in self.resourcesPendingDownload) {
        NSString *iFilename = [iResource downloadFilename];
        if ([iFilename isEqualToString:filename]) {
            doneResource = iResource;
            break;
        }
    }
    
    if (doneResource) {
        doneResource.didDownloadUpdate = [NSNumber numberWithBool:YES];
        self.completedDownloadCount++;
        [self updateDownloadProgress];
        
        [AppUtility cdSaveWithIDString:@"RC: save did download update" quitOnFail:NO];
        //[self.resourcesPendingDownload removeObject:doneResource];
        DDLogVerbose(@"down success: %@ - %@ - %d", filename, doneResource.text, [data length]);
        
        // post notification so keypad scrollview can update
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_RESOURCECENTER_DID_DOWNLOAD_RESOURCE_NOTIFICATION object:[doneResource objectID]];
    }
   
}

/*! 
 @abstract Got error and passes filename as an ID tag
 */
- (void)TKFileManager:(TKFileManager *)fileManager didFailWithError:(NSError *)error filename:(NSString *)filename {
    
    DDLogWarn(@"RC: failed download %@", filename);
    CDResource *errorResource = nil;
    for (CDResource *iResource in self.resourcesPendingDownload) {
        if ([[iResource downloadFilename] isEqualToString:filename]) {
            errorResource = iResource;
            break;
        }
    }
    self.completedDownloadCount++;
    [self updateDownloadProgress];

    if (errorResource) {
        //[self.resourcesPendingDownload removeObject:errorResource];
    }
}


#pragma mark - NSFileManager

/*!
 @abstract allow overwrite of files
 */
- (BOOL)fileManager:(NSFileManager *)fm shouldProceedAfterError:(NSError *)error movingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    return YES;
}


@end