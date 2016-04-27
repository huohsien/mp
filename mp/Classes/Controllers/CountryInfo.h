//
//  CountryInfo.h
//  mp
//
//  Created by Min Tsai on 4/15/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header CountryInfo
 
 Simple object to represent countries and their country code information
 
 @copyright TernTek
 @updated 2011-08-29
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 
 */

#import <UIKit/UIKit.h>

@interface CountryInfo : NSObject
{
    NSString *name;
    NSString *isoCode;
    NSString *phoneCountryCode;
    
}

@property(nonatomic, retain) NSString *name;

/*! ISO 2 letter country code */
@property(nonatomic, retain) NSString *isoCode;

/*! phone number country code */
@property(nonatomic, retain) NSString *phoneCountryCode;

- (id) initWithName:(NSString *)aName isoCode:(NSString *)aIsoCode phoneCountryCode:(NSString *)aPhoneCountryCode;

@end
