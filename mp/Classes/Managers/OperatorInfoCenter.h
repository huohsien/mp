//
//  OperatorInfoCenter.h
//  mp
//
//  Created by Min Tsai on 1/26/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header OperatorInfoCenter
 
 Queries and caches operator info from PS
 
 Data Model:
 - operatorCache
    ~ is accessed by main thread and queried first
 
 - operatorD
    ~ dictionary is stored in memory for fast queries
    ~ file is read in whenever dictionary does not exists
 
 - remote query
    ~ if operatorD does not have answer, then perform a remote query
    ~ results are store to file, operatorD and operatorCache

 - operatorD file is completely refreshed every 7 days
 
 - after each session
    ~ cache and D are cleared
 
 @copyright TernTek
 @updated 2012-01-07
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <Foundation/Foundation.h>

/*! Got a single phone number result - notif = dictionary: key - phone number, value - operator nsnumber */
extern NSString* const MP_OPERATORINFO_UPDATE_SINGLE_NOTIFICATION;

/*! Got a multiple result update, so clear everything and request new info again - notif = nil */
extern NSString* const MP_OPERATORINFO_UPDATE_ALL_NOTIFICATION;


/**
 Telecom groupings
 
 Query:     Info not available, query started
 None:      No operator info available - for foreign users
 
 (1) 中華 (CHT 3G, CHT 2G)
 (2) 中華市話 (CHT 市話)
 (3) 台灣大 (TWM 3G, TWM 2G, 泛亞, 東信)
 (4) 台灣固網 (台灣固網)
 (5) 遠傳 (FET 3G, FET 2G, 和信)
 (6) 速博 (Sparq)
 (7) 亞太行動
 (8) 亞太固網
 (9) 威寶
 (10)其他
*/ 
typedef enum {
    kOIOperatorQuery = -2,
    kOIOperatorNone = -1,
    kOIOperatorCHTMobile = 1,
    kOIOperatorCHTFixed = 2,
    kOIOperatorTWM = 3,
    kOIOperatorTFN = 4,
    kOIOperatorFET = 5,
    kOIOperatorSPARQ = 6,
    kOIOperatorAPTMobile = 7,
    kOIOperatorAPTFixed = 8,
    kOIOperatorVIBO = 9,
    kOIOperatorOTHER = 10

} OIOperator;


@class OperatorInfoCenter;

/*!
 Delegate protocol
 */
@protocol OperatorInfoCenterDelegate <NSObject>
/*!
 @abstract Provides progress of download
 */
- (void)OperatorInfoCenter:(OperatorInfoCenter *)operatorInfoCenter;
@end

@interface OperatorInfoCenter : NSObject {
    
    //id <MPResourceCenterDelegate> delegate;
    
    NSString *currentCountryISOCode;
    BOOL isFileCacheFresh;
    
    NSCache *operatorCache;
    NSMutableDictionary *operatorD;
    
    NSMutableSet *queuedRequestNumbers;
    NSMutableSet *pendingPhoneNumbers;
    
    dispatch_queue_t operator_queue;
    
    NSDictionary *imageDictionary;
    NSDictionary *nameDictionary;
    
}

//@property (nonatomic, assign) id <MPResourceCenterDelegate> delegate;

/*! cached region information - used to check if operator info is available */
@property (nonatomic, retain) NSString *currentCountryISOCode;

/*! checks if file cache is fresh - done once every session */
@property (nonatomic, assign) BOOL isFileCacheFresh;


/*! cache for operatorD */
@property (nonatomic, retain) NSCache *operatorCache;

/*! gets operator ID given phone number - key:phonenumber value:operatorID*/
@property (nonatomic, retain) NSMutableDictionary *operatorD;


/*! phone numbers that are waiting to be queried - since users has too many numbers to query */
@property (atomic, retain) NSMutableSet *queuedRequestNumbers;

/*! phone numbers for a query that we are waiting for results to return for */
@property (atomic, retain) NSMutableSet *pendingPhoneNumbers;

/*! Queue: for processing operator responses */
@property (readonly, assign) dispatch_queue_t operator_queue;


/*! dictionary of image names for operators */
@property (nonatomic, retain) NSDictionary *imageDictionary;

/*! dictionary of telecom names for operators */
@property (nonatomic, retain) NSDictionary *nameDictionary;

/*!
 @abstract creates singleton object
 */
+ (OperatorInfoCenter *)sharedOperatorInfoCenter;

- (UIImage *) backImageForOperatorNumber:(NSNumber *)opNumber;
- (NSString *) nameForOperatorNumber:(NSNumber *)opNumber;
- (NSNumber *) requestOperatorForPhoneNumber:(NSString *)phoneNumber;
- (BOOL) isOperatorInfoAvailable;
- (void) clearCache;
@end
