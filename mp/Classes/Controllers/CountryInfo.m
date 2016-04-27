//
//  CountryInfo.m
//  mp
//
//  Created by Min Tsai on 4/15/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "CountryInfo.h"

@implementation CountryInfo

@synthesize name;
@synthesize isoCode;
@synthesize phoneCountryCode;

/*!
 @abstract init presence
 
 @param raw presence string from server
 
 (msisdn,USERID,presence,domain-address,from-address, nickname ,headshot, logintime,status, abRecrodID)
 
 */
- (id) initWithName:(NSString *)aName isoCode:(NSString *)aIsoCode phoneCountryCode:(NSString *)aPhoneCountryCode {
    
    if ((self = [super init])) {
        
        self.name = aName;
        self.isoCode = aIsoCode;
        self.phoneCountryCode = aPhoneCountryCode;
        
	}
	return self;
}

- (void) dealloc {
    
    [name release];
    [isoCode release];
    [phoneCountryCode release];
    
    [super dealloc];
}

@end
