//
//  ContactProperty.m
//  mp
//
//  Created by M Tsai on 11-12-1.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "ContactProperty.h"

@implementation ContactProperty

@synthesize name;
@synthesize value;
@synthesize valueString;
@synthesize propertyID;
@synthesize isSelected;
@synthesize abRecordID;


- (void) dealloc {
    
    [propertyID release];
    [abRecordID release];
    [name release];
    [value release];
    [valueString release];
    
    [super dealloc];
}


/*!
 @abstract init with contacts who we will send broadcast to
 */
- (id)initWithName:(NSString *)newName value:(NSString *)newValue id:(NSNumber *)newID abRecordID:(NSNumber *)recordID valueString:(NSString *)newString
{
    self = [super init];
    if (self) {
        self.name = newName;
        self.value = newValue;
        self.valueString = newString;
        self.propertyID = newID;
        self.abRecordID = recordID;
        self.isSelected = NO;
    }
    return self;
}

@end
