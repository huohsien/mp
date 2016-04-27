//
//  MPPresence.h
//  mp
//
//  Created by M Tsai on 11-12-10.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//
/*!
 @header MPPresence
 
 Represent Presence information that is passed to and from M+ servers.
 Each presence hold information for M+ contacts.
 
 Presence Format:
 (msisdn,USERID,presence,domain-address,from-address, nickname ,headshot, logintime,status, abRecrodID)
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 
 

 
 */

#import <Foundation/Foundation.h>

@interface MPPresence : NSObject {

    NSString *aMSISDN;
    NSString *aUserID;
    NSNumber *aPresence;
    NSString *aDomainAddress;
    NSString *aFromAddress;
    NSString *aNickname;
    NSNumber *aHeadShot;
    NSDate *aLoginTime;
    NSString *aStatusMessage;
    NSNumber *aRecordID;

}

@property (nonatomic, retain) NSString *aMSISDN;
@property (nonatomic, retain) NSString *aUserID;
@property (nonatomic, retain) NSNumber *aPresence;
@property (nonatomic, retain) NSString *aDomainAddress;
@property (nonatomic, retain) NSString *aFromAddress;
@property (nonatomic, retain) NSString *aNickname;
@property (nonatomic, retain) NSNumber *aHeadShot;
@property (nonatomic, retain) NSDate *aLoginTime;
@property (nonatomic, retain) NSString *aStatusMessage;
@property (nonatomic, retain) NSNumber *aRecordID;



- (id) initWithPresenceString:(NSString *)presenceString;
- (BOOL) isContactDeleted;

+ (NSArray *) getArrayFromPresence:(NSString *)presence;


@end
