//
//  MPPresence.m
//  mp
//
//  Created by M Tsai on 11-12-10.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "MPPresence.h"
#import "TKLog.h"


/*!
 Presence data format indexes
 
 (msisdn,USERID,presence,domain-address,from-address, nickname ,headshot, logintime, status, abrecordid)
 */
typedef enum {
	kMPPresenceIndexMSISDN = 0,
    kMPPresenceIndexUserID = 1,
    kMPPresenceIndexPresence = 2,
    kMPPresenceIndexDomainCluster = 3,
    kMPPresenceIndexDomainServer = 4,
    kMPPresenceIndexNickname = 5,
    kMPPresenceIndexHeadshot = 6,
    kMPPresenceIndexLoginTime = 7,
    kMPPresenceIndexStatus = 8,
    kMPPresenceIndexABRecordID = 9
} MPPresenceIndex;



@implementation MPPresence

@synthesize aMSISDN;
@synthesize aUserID;
@synthesize aPresence;
@synthesize aDomainAddress;
@synthesize aFromAddress;
@synthesize aNickname;
@synthesize aHeadShot;
@synthesize aLoginTime;
@synthesize aStatusMessage;
@synthesize aRecordID;


+ (NSDateFormatter *)dateReader
{
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateReader = [dictionary objectForKey:@"MPPresenceDateReader"];
    if (!dateReader)
    {
        dateReader = [[[NSDateFormatter alloc] init] autorelease];
        [dateReader setDateFormat:@"yyyyMMddHHmm"];
        [dictionary setObject:dateReader forKey:@"MPPresenceDateReader"];
    }
    return dateReader;
}



/*!
 @abstract just encode ','='\,' and '\'='\\' so we can parse correctly
 */
- (NSString *)encodeStatus:(NSString *)rawString {
    // encode
    NSString *encodedString = [rawString stringByReplacingOccurrencesOfString:@"\\\\" withString:@"⌺b"];
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@"\\," withString:@"⌺c"];
    return encodedString;
}

/*!
 @abstract decode special characters in status
 - decode comma that we encoded for parsing
 - decode special characters from GetUserInfo
 */
- (NSString *)decodeStatus:(NSString *)rawString {
    // decode
    NSString *decodedString = [rawString stringByReplacingOccurrencesOfString:@"⌺c" withString:@","];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"⌺b" withString:@"\\"];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"\\@" withString:@"@"];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"\\>" withString:@">"];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"\\+" withString:@"+"];
    return decodedString;
}



/*!
 @abstract init presence
 
 @param raw presence string from server
 
 (msisdn,USERID,presence,domain-address,from-address, nickname ,headshot, logintime,status, abRecrodID)

 e.g.
 (0975832432,00667300,-1,,,,,,,10)@
 (0975832432,01099513,0,mplusds1.tfn.net.tw:80,10.39.106.4,Min,0,1346836540,Available,10)@
 (23432423,,,,,,,,,11)
 
 
 */
- (id) initWithPresenceString:(NSString *)presenceString {
    
    if ((self = [super init])) {
       
        // encode so we can parse correctly
        NSString *encodedString = [self encodeStatus:presenceString];
        
        NSArray *presenceInfo = [encodedString componentsSeparatedByString:@","];
        NSInteger presenceCount = [presenceInfo count];
        
        // need to at least include status
        if (presenceCount <= kMPPresenceIndexStatus) {
            DDLogWarn(@"PR-init: invalid presence encountered %@", presenceInfo);
            return nil;
        }
        
        self.aMSISDN = [presenceInfo objectAtIndex:kMPPresenceIndexMSISDN];
        self.aUserID = [presenceInfo objectAtIndex:kMPPresenceIndexUserID];
        self.aPresence = [NSNumber numberWithInteger:[[presenceInfo objectAtIndex:kMPPresenceIndexPresence] intValue]];
        self.aDomainAddress = [presenceInfo objectAtIndex:kMPPresenceIndexDomainCluster];
        self.aFromAddress = [presenceInfo objectAtIndex:kMPPresenceIndexDomainServer];
        self.aNickname = [self decodeStatus:[presenceInfo objectAtIndex:kMPPresenceIndexNickname]];
        self.aHeadShot = [NSNumber numberWithInteger:[[presenceInfo objectAtIndex:kMPPresenceIndexHeadshot] intValue]];
        self.aStatusMessage = [self decodeStatus:[presenceInfo objectAtIndex:kMPPresenceIndexStatus]];
        
        NSString *loginString = [presenceInfo objectAtIndex:kMPPresenceIndexLoginTime];

        // read in old yyyyMMddHHmm format
        //NSDateFormatter *dateReader = [MPPresence dateReader];
        //self.aLoginTime = [dateReader dateFromString:loginString]; 
        
        // read in epoch time
        self.aLoginTime = [NSDate dateWithTimeIntervalSince1970:[loginString floatValue]];
        
        // recordID optional - may not always be available
        if (presenceCount > kMPPresenceIndexABRecordID) {
            
            // only populate valid recordIDs
            // - should be last item
            //
            NSString *recordString = [presenceInfo lastObject];
            NSInteger recordInt = [recordString intValue];
            if ([recordString length] > 0 && recordInt > -1) {
                self.aRecordID = [NSNumber numberWithInt:recordInt];
            }
        
        }
        
	}
	return self;
}


- (void) dealloc {
    
    [aMSISDN release];
    [aUserID release];
    [aPresence release];
    [aDomainAddress release];
    [aFromAddress release];
    [aNickname release];
    [aHeadShot release];
    [aLoginTime release];
    [aStatusMessage release];
    [aRecordID release];
    
    [super dealloc];
}


/*!
 @abstract is contact's account deleted?
 */
- (BOOL) isContactDeleted {
    
    if ([self.aPresence intValue] == -1) {
        return YES;
    }
    return NO;
}

#pragma mark - Class Methods

/*!
 @abstact Generates array of presence objects from a complete presence string
 
 
 E.g
 (975502790,00000034,0,61.66.229.110:80,61.66.229.110,huiyi,1,201112100211,\U88dd\U5fd9\U4e2d,17)@
 (886975711112,00000036,0,61.66.229.110:80,61.66.229.110,ffff,0,201112061624,I am using M+ app,2)@
 
 (0975832432,00667300,-1,,,,,,,10)@
 (0975832432,01099513,0,mplusds1.tfn.net.tw:80,10.39.106.4,Min,0,1346836540,Available,10)@
 (23432423,,,,,,,,,11)
 
 - presence separated by @
 
 */
+ (NSArray *) getArrayFromPresence:(NSString *)presence {
    
    // Only process if we have valid presence
    //
    NSString *presenceString = nil;
    NSMutableArray *presenceArray = [[[NSMutableArray alloc] init] autorelease];
    
    NSInteger textLength = [presence length];
    if (textLength > 2) {
        
        if ([presence characterAtIndex:0] == '(' && [presence characterAtIndex:textLength-1] == ')') {
            presenceString = [presence substringWithRange:NSMakeRange(1, textLength-2)];
        }
        else {
            DDLogVerbose(@"CM-hm: ERROR - invalid presence message!! %@", presence);
            return nil;
        }
        
        NSArray *presences = [presenceString componentsSeparatedByString:@")@("];
        
        for (NSString *iPresence in presences){
            
            MPPresence *aPresence = [[MPPresence alloc] initWithPresenceString:iPresence];
            // don't insert nil!
            if (aPresence) {
                [presenceArray addObject:aPresence];
            }
            [aPresence release];
        }
        return presenceArray;
    }
    return nil;
}

@end
