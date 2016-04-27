//
//  OperatorInfoCenter.m
//  mp
//
//  Created by Min Tsai on 1/26/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "OperatorInfoCenter.h"
#import "SynthesizeSingleton.h"
#import "MPFoundation.h"
#import "MPContactManager.h"
#import "ContactProperty.h"

NSUInteger const kMPParamOperatorInfoPhoneQueryMax = 100;


NSString* const kMPQueueOperator = @"com.terntek.mp.operator";

NSString* const kMPQueueOperatorCacheFilename = @"queryOperator.cache";
NSTimeInterval const kMPQueueOperatorCacheFilenameFreshInterval = 604800.0; // Query 1/week

NSString* const MP_OPERATORINFO_UPDATE_SINGLE_NOTIFICATION = @"MP_OPERATORINFO_UPDATE_SINGLE_NOTIFICATION";
NSString* const MP_OPERATORINFO_UPDATE_ALL_NOTIFICATION = @"MP_OPERATORINFO_UPDATE_ALL_NOTIFICATION";

@interface OperatorInfoCenter (Private)
- (void)clearCache;
@end


@implementation OperatorInfoCenter

@synthesize operatorCache;
@synthesize operatorD;
@synthesize queuedRequestNumbers;
@synthesize pendingPhoneNumbers;
@synthesize operator_queue;

@synthesize imageDictionary;
@synthesize nameDictionary;
@synthesize currentCountryISOCode;
@synthesize isFileCacheFresh;


SYNTHESIZE_SINGLETON_FOR_CLASS(OperatorInfoCenter);


- (id)init {
    
    self = [super init];
    if (self) {
        
        // listen query response from PS server
        //
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processQueryOperator:) name:MP_HTTPCENTER_QUERYOPERATOR_NOTIFICATION object:nil];
        
        
        // Clear cache from memory if backgrounded
        // - reload it next time
        //
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearCache)
                                                     name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        

    }    
    return self;
}

-(void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [operatorD release];
    [super dealloc];
    
}

#pragma mark - Internal

/*!
 @abstract getter for operator data processing queue
 
 @discussion any processing of operator data should be done on this queue
 */
- (dispatch_queue_t) operator_queue {
    
    // if does not exists
    // - create it
    if (operator_queue == NULL){
        operator_queue = dispatch_queue_create([kMPQueueOperator UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_retain(operator_queue);
    }
    return operator_queue;
}




/*!
 @abstract queries for operator info for all phone numbers
 
 Query all phone numbers if
  - no dictionary cache exists
  - cache file is not fresh any more
 
 @return YES If query was executed
         NO If another query is in progress
 */
- (void) queryOperatorForPhoneNumbers:(NSArray *)phoneNumbers isQueuedRequest:(BOOL)isQueuedRequest {
    
    NSAssert(dispatch_get_current_queue() == self.operator_queue, @"Must be dispatched on operatorQueue");

    // Don't request for something that is already requests or will be
    // - if single query, not a queued request and already pending and in queue
    // - then do nothing
    if ([phoneNumbers count] == 1 &&
        !isQueuedRequest &&
        ([self.pendingPhoneNumbers member:[phoneNumbers lastObject]] || [self.queuedRequestNumbers member:[phoneNumbers lastObject]]) 
        ) {
        return;
    }
    
    // create set to check if another query is in progress for this number
    // - if already pending, don't start it again
    //
    if (!self.pendingPhoneNumbers) {
        NSMutableSet *aSet = [[NSMutableSet alloc] initWithCapacity:[phoneNumbers count]];
        self.pendingPhoneNumbers = aSet;
        [aSet release];
    }
    
    NSArray *phonesToQuery = phoneNumbers;
     
    // if cache is not fresh, then do a full query instead!
    // - only fresh all if this was initiated from a query needed for the UI (count == 1)
    // - not b/c we are processing queued requests (where count will be > 1)
    //
    __block NSSet *allPhones = nil;
    if ([phoneNumbers count] == 1 &&
        ![Utility hasFileBeenModified:kMPQueueOperatorCacheFilename sinceNow:kMPQueueOperatorCacheFilenameFreshInterval]) {
        dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
        dispatch_sync(back_queue, ^{
            
            // load data from AB
            //
            MPContactManager *backCM = [AppUtility getBackgroundContactManager];
            allPhones = [backCM getABPhonePropertiesTWMobileOnly:NO];
            
        });
    }
    
    if (allPhones) {
        NSMutableArray *allPhoneArray = [[NSMutableArray alloc] initWithCapacity:[allPhones count]];
        for (ContactProperty *iProperty in allPhones) {
            [allPhoneArray addObject:iProperty.value];
        }
        phonesToQuery = [NSArray arrayWithArray:allPhoneArray];
        [allPhoneArray release];
    }
    
    // query at most kMPParamOperatorInfoPhoneQueryMax at a time
    //
    if ([phonesToQuery count] > kMPParamOperatorInfoPhoneQueryMax) {
        
        // leave max amount of numbers in querySet
        // - put the rest in queuedRequestsNumbers
        //
        NSArray *queuedNumbers = [phonesToQuery subarrayWithRange:NSMakeRange(kMPParamOperatorInfoPhoneQueryMax, 
                                                                              [phonesToQuery count] - kMPParamOperatorInfoPhoneQueryMax)];
        phonesToQuery = [phonesToQuery subarrayWithRange:NSMakeRange(0, kMPParamOperatorInfoPhoneQueryMax)];
        
        if (!self.queuedRequestNumbers) {
            NSMutableSet *qSet = [[NSMutableSet alloc] initWithCapacity:[queuedNumbers count]];
            self.queuedRequestNumbers = qSet;
            [qSet release];
        }
        
        // add remaining numbers to queued set
        [self.queuedRequestNumbers addObjectsFromArray:queuedNumbers];
        
    }
    
    // remove numbers that will be requested
    [self.queuedRequestNumbers minusSet:[NSSet setWithArray:phonesToQuery]];
    
    
    // filter out numbers that are already being queried
    // - auto released
    NSMutableSet *querySet = [[[NSMutableSet alloc] initWithArray:phonesToQuery] autorelease];
    [querySet minusSet:self.pendingPhoneNumbers];
    
    
    NSArray *phonesToRequest = [querySet allObjects];   

    // add new queries to pending
    [self.pendingPhoneNumbers unionSet:querySet];
    
    if ([phonesToRequest count] > 0) {
        // submit operator query
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            DDLogInfo(@"OIC: submit queries: %d, queued: %d", [phonesToRequest count], [self.queuedRequestNumbers count]?[self.queuedRequestNumbers count]:0);
            [[MPHTTPCenter sharedMPHTTPCenter] queryOperator:phonesToRequest];
        });
    }
    else {
        DDLogInfo(@"OIC: skip queries already pending - %d ", [phonesToRequest count]);
    }

}


/*!
 @abstract Process results of query operator from PS
 
 - if operatorD exists:             add new results to it
 - if operatorD does not exists:    create new D with new results
 
 <QueryOperator>
    <cause>0</cause>
    <operator>TWM,CHT,...</operator>
 </QueryOperator>
 
 */
- (void) processQueryOperator:(NSNotification *)notification {
        
    // notification received in main queue
    // - switch to operator queue
    //
    dispatch_async(self.operator_queue, ^{
        
        NSDictionary *responseD = [notification object];
        
        // extract phone number queried
        NSString *phonesString = [responseD valueForKey:kTTXMLIDTag];
        NSArray *phonesQueried = [phonesString componentsSeparatedByString:@"@"];
        NSUInteger phonesCount = [phonesQueried count];
        
        
        // parse results and save to dictionary
        //
        if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
            
            NSString *operatorString = [responseD valueForKey:@"operator"];
            NSArray *operators = [operatorString componentsSeparatedByString:@","];
            

            
            NSMutableArray *operatorNumbers = [[NSMutableArray alloc] initWithCapacity:[operators count]];
            for (NSString *iOperator in operators){
                [operatorNumbers addObject:[NSNumber numberWithInt:[iOperator intValue]]];
            }
            
            NSDictionary *newOperatorD = nil;
            // only update if number of phones and operators match
            //
            DDLogInfo(@"OIC: results op: %d phone: %d", [operatorNumbers count], phonesCount);
            if ([operatorNumbers count] == phonesCount) {
                newOperatorD = [NSDictionary dictionaryWithObjects:operatorNumbers forKeys:phonesQueried];
            }
            else {
                DDLogWarn(@"OIC: results number %d does not match query phone numbers %d - %@", [operatorNumbers count], phonesCount, phonesQueried);
            }
            [operatorNumbers release]; 
            // if new results exists
            NSInteger resultCount = [newOperatorD count];
            if (resultCount > 0) {
                
                // if query DB exists add result to it
                //
                if (self.operatorD) {
                    [self.operatorD setValuesForKeysWithDictionary:newOperatorD];
                }
                // if query DB does not exists, create a new one
                else {
                    self.operatorD = [NSMutableDictionary dictionaryWithDictionary:newOperatorD];
                }
                // save dictionary to file
                //
                NSString *filePath = [Utility documentFilePath:kMPQueueOperatorCacheFilename];
                [self.operatorD writeToFile:filePath atomically:YES];
                
                // send out result notification
                // - if one result, send single update
                //
                if ([newOperatorD count] == 1) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:MP_OPERATORINFO_UPDATE_SINGLE_NOTIFICATION object:newOperatorD];
                    });
                }
                // - if multiple results, send update all
                //
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        self.isFileCacheFresh = YES;
                        // clear old cache
                        [self.operatorCache removeAllObjects];
                        [[NSNotificationCenter defaultCenter] postNotificationName:MP_OPERATORINFO_UPDATE_ALL_NOTIFICATION object:nil];
                    });
                }
            }
            
        }
        // did not succeed!
        else {
            DDLogWarn(@"OI: WARN query operator got failed response!");
        }
        
        // remove pending queries
        // - if failed, then we can query again
        //
        if (phonesQueried) {
            NSSet *responsePhones = [NSSet setWithArray:phonesQueried];
            [self.pendingPhoneNumbers minusSet:responsePhones];
        }
        
        
        // if queued numbers are present, send another request
        //
        if ([self.queuedRequestNumbers count] > 0) {
            [self queryOperatorForPhoneNumbers:[self.queuedRequestNumbers allObjects] isQueuedRequest:YES];
        }
        
    }); // end dispatch
}



#pragma mark - External


/*!
 @abstract Check if operator info is available
 
 - only TW users can get this info
 - only request from main queue!
 
 */
- (BOOL) isOperatorInfoAvailable {
    
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"isOperatorInfoAvailable must be dispatched on mainQueue");
    
    // this section only gets run once per session 
    // - check phone country code: more reliable than region settings
    // 
    if (!self.currentCountryISOCode) {
        self.currentCountryISOCode = [[MPHTTPCenter sharedMPHTTPCenter] getCountryCode];
        
        if ([Utility hasFileBeenModified:kMPQueueOperatorCacheFilename sinceNow:kMPQueueOperatorCacheFilenameFreshInterval]) {
            self.isFileCacheFresh = YES;
        }
        else {
            self.isFileCacheFresh = NO;
        }
    }
    
    if ([self.currentCountryISOCode isEqualToString:@"886"]) {
        return YES;
    }
    return NO;
    
    
    
    // this section only gets run once per session - check phone region settings
    /*if (!self.currentCountryISOCode) {
        self.currentCountryISOCode = [Utility currentLocalCountryCode];
        
        if ([Utility hasFileBeenModified:kMPQueueOperatorCacheFilename sinceNow:kMPQueueOperatorCacheFilenameFreshInterval]) {
            self.isFileCacheFresh = YES;
        }
        else {
            self.isFileCacheFresh = NO;
        }
    }
    
    if ([self.currentCountryISOCode hasPrefix:@"TW"]) {
        return YES;
    }
    return NO;*/
}

/*!
 @abstract clear cache
 
 Use:
 - clear cache when session ends, so next time we get fresh data

 */
- (void)clearCache {
    
    [self.operatorCache removeAllObjects];
    self.currentCountryISOCode = nil;

    dispatch_sync(self.operator_queue, ^{        
        [self.pendingPhoneNumbers removeAllObjects];
        self.operatorD = nil;
    });

}



-(UIImage *) backImageForOperatorNumber:(NSNumber *)opNumber {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        self.imageDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"std_icon_telecom_blue.png", 
                                [NSNumber numberWithInt:kOIOperatorCHTMobile],
                                @"std_icon_telecom_blue.png", 
                                [NSNumber numberWithInt:kOIOperatorCHTFixed],
                                @"std_icon_telecom_orange.png", 
                                [NSNumber numberWithInt:kOIOperatorTWM],
                                @"std_icon_telecom_orange.png", 
                                [NSNumber numberWithInt:kOIOperatorTFN],
                                @"std_icon_telecom_red.png", 
                                [NSNumber numberWithInt:kOIOperatorFET],
                                @"std_icon_telecom_red.png", 
                                [NSNumber numberWithInt:kOIOperatorSPARQ],
                                @"std_icon_telecom_green2.png", 
                                [NSNumber numberWithInt:kOIOperatorAPTMobile],
                                @"std_icon_telecom_green2.png", 
                                [NSNumber numberWithInt:kOIOperatorAPTFixed],
                                @"std_icon_telecom_bluegreen.png", 
                                [NSNumber numberWithInt:kOIOperatorVIBO],
                                @"std_icon_telecom_purple.png", 
                                [NSNumber numberWithInt:kOIOperatorOTHER],
                                nil];
    });
    
    UIImage *backImage = [Utility resizableImage:[UIImage imageNamed:[self.imageDictionary objectForKey:opNumber]] leftCapWidth:17.0 topCapHeight:13.0];
    
    return backImage;
}


/*-(UIImage *) backImageForOperatorNumber:(NSNumber *)opNumber {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        self.imageDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                           [Utility resizableImage:[UIImage imageNamed:@"std_icon_telecom_blue.png"] leftCapWidth:17.0 topCapHeight:13.0], 
                           [NSNumber numberWithInt:kOIOperatorCHTMobile],
                           [Utility resizableImage:[UIImage imageNamed:@"std_icon_telecom_blue.png"] leftCapWidth:17.0 topCapHeight:13.0], 
                           [NSNumber numberWithInt:kOIOperatorCHTFixed],
                           [Utility resizableImage:[UIImage imageNamed:@"std_icon_telecom_green.png"] leftCapWidth:17.0 topCapHeight:13.0], 
                           [NSNumber numberWithInt:kOIOperatorTWM],
                           [Utility resizableImage:[UIImage imageNamed:@"std_icon_telecom_green.png"] leftCapWidth:17.0 topCapHeight:13.0], 
                           [NSNumber numberWithInt:kOIOperatorTFN],
                           [Utility resizableImage:[UIImage imageNamed:@"std_icon_telecom_red.png"] leftCapWidth:17.0 topCapHeight:13.0], 
                           [NSNumber numberWithInt:kOIOperatorFET],
                           [Utility resizableImage:[UIImage imageNamed:@"std_icon_telecom_red.png"] leftCapWidth:17.0 topCapHeight:13.0], 
                           [NSNumber numberWithInt:kOIOperatorSPARQ],
                           [Utility resizableImage:[UIImage imageNamed:@"std_icon_telecom_orange.png"] leftCapWidth:17.0 topCapHeight:13.0], 
                           [NSNumber numberWithInt:kOIOperatorAPTMobile],
                           [Utility resizableImage:[UIImage imageNamed:@"std_icon_telecom_orange.png"] leftCapWidth:17.0 topCapHeight:13.0], 
                           [NSNumber numberWithInt:kOIOperatorAPTFixed],
                           [Utility resizableImage:[UIImage imageNamed:@"std_icon_telecom_bluegreen.png"] leftCapWidth:17.0 topCapHeight:13.0], 
                           [NSNumber numberWithInt:kOIOperatorVIBO],
                           [Utility resizableImage:[UIImage imageNamed:@"std_icon_telecom_purple.png"] leftCapWidth:17.0 topCapHeight:13.0], 
                           [NSNumber numberWithInt:kOIOperatorOTHER],
                           nil];
    });
    return [self.imageDictionary objectForKey:opNumber];
}*/

-(NSString *) nameForOperatorNumber:(NSNumber *)opNumber {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        self.nameDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                               NSLocalizedString(@"CHT", @"Operator - CHT"), [NSNumber numberWithInt:kOIOperatorCHTMobile],
                               NSLocalizedString(@"CHT_Fix", @"Operator - CHT"), [NSNumber numberWithInt:kOIOperatorCHTFixed],
                               NSLocalizedString(@"TWM", @"Operator - CHT"), [NSNumber numberWithInt:kOIOperatorTWM],
                               NSLocalizedString(@"TWM_Fix", @"Operator - CHT"), [NSNumber numberWithInt:kOIOperatorTFN],
                               NSLocalizedString(@"FET", @"Operator - CHT"), [NSNumber numberWithInt:kOIOperatorFET],
                               NSLocalizedString(@"Sparq", @"Operator - CHT"), [NSNumber numberWithInt:kOIOperatorSPARQ],
                               NSLocalizedString(@"MBT", @"Operator - CHT"), [NSNumber numberWithInt:kOIOperatorAPTMobile],
                               NSLocalizedString(@"MBT_Fix", @"Operator - CHT"), [NSNumber numberWithInt:kOIOperatorAPTFixed],
                               NSLocalizedString(@"Vibo", @"Operator - CHT"), [NSNumber numberWithInt:kOIOperatorVIBO],
                               NSLocalizedString(@"Other", @"Operator - CHT"), [NSNumber numberWithInt:kOIOperatorOTHER],
                               nil];
    });
    return [self.nameDictionary objectForKey:opNumber];
}



/*!
 @abstract Requests operator info for this phone number
 
 - if cache is not fresh, a network query is started 
   ~ complete phonebook query with all numbers will be initiated
 
 Update Single Result:
 - are returned via notifications
 - requester observer notification
   ~ once notification is received, then remove observer and update results
 
 Update All Results:
 - if a full phone book refresh is requested from the PS
 - send a update all notif
 - UI should clear all old results and allow UI elements to query individually again to get new results
    ~e.g. data model cleared and reload table should be performed.
 
 @return nil if failure, operator number if cache is available
 
 
 Results values: deprecated
 - kOIOperatorNone If no info is available for this number
 - kOIOperatorQuery - if no data is readily available, so query for it
    ~ Should not get this result
 
 
 
 */
- (NSNumber *) requestOperatorForPhoneNumber:(NSString *)phoneNumber {
    
    if (!self.operatorCache) {
        NSCache *newCache = [[NSCache alloc] init];
        self.operatorCache = newCache;
        [newCache release];
    }
    
    __block NSNumber *resultNumber = [self.operatorCache objectForKey:phoneNumber];
    
    // if cache return answer
    if (resultNumber) {
        return resultNumber;
    }
    
    // only TW users will get this information
    //        
    if ([self isOperatorInfoAvailable]) {
        // check in dictionary for cache value
        dispatch_sync(self.operator_queue, ^{
            
            // if DB does not exist, then load it from file if it is fresh
            if (!self.operatorD) {
                // try to read in file
                NSString *cacheFile = [Utility documentFilePath:kMPQueueOperatorCacheFilename];
                self.operatorD = [NSMutableDictionary dictionaryWithContentsOfFile:cacheFile];
            }
            resultNumber = [self.operatorD valueForKey:phoneNumber];
        });
    }
    
    // if no dictionary or no results or not fresh, start a query
    //
    if (!resultNumber || self.isFileCacheFresh == NO) {
        dispatch_async(self.operator_queue, ^{
            [self queryOperatorForPhoneNumbers:[NSArray arrayWithObject:phoneNumber] isQueuedRequest:NO];
        });
    }
    
    // save cache result
    if (resultNumber) {
        [self.operatorCache setObject:resultNumber forKey:phoneNumber];
    }
    
    return resultNumber;
    
}





@end
