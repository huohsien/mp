//
//  CenterPinAnnotation.m
//  mp
//
//  Created by Min Tsai on 2/11/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "CenterPinAnnotation.h"
#import <AddressBook/AddressBook.h>

    
@implementation CenterPinAnnotation 
    
@synthesize image;
@synthesize coordinate;
@synthesize placemark;
@synthesize addressString;


- (void)dealloc
{
    [addressString release];
    [placemark release];
    [image release];
    [super dealloc];
}


- (NSString *)title
{
    return NSLocalizedString(@"Location", @"Location - title: Current center location");
    //return self.placemark.title;
    //return nil;
}

/*!
 @abstract Detailed text for this annotation
 
 const ABPropertyID kABPersonAddressProperty;
 const CFStringRef kABPersonAddressStreetKey;
 const CFStringRef kABPersonAddressCityKey;
 const CFStringRef kABPersonAddressStateKey;
 const CFStringRef kABPersonAddressZIPKey;
 const CFStringRef kABPersonAddressCountryKey;
 const CFStringRef kABPersonAddressCountryCodeKey;
 */

- (NSString *)subtitle
{
    // street address - return [placemark.addressDictionary valueForKey:(NSString *)kABPersonAddressStreetKey];
    //return self.placemark.title;
    
    if (self.addressString) {
        return addressString;
    }
    return nil;
}



@end
    