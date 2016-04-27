//
//  ContactProperty.h
//  mp
//
//  Created by M Tsai on 11-12-1.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContactProperty : NSObject {
    NSNumber *propertyID;
    NSNumber *abRecordID;
    NSString *name;
    NSString *value;
    NSString *valueString;
    BOOL isSelected;
}

/*! id used for collation purposes */
@property (retain) NSNumber *propertyID;


/*! addressbook native record ID for contact - used to find related AB or M+ contact */
@property (retain) NSNumber *abRecordID;

/*! phonebook name of this contact */
@property (retain) NSString *name;

/*! value of this property */
@property (retain) NSString *value;

/*! original formatted value string */
@property (retain) NSString *valueString;


/*! is this cell selected by user */
@property(nonatomic, assign) BOOL isSelected;


- (id)initWithName:(NSString *)newName value:(NSString *)newValue id:(NSNumber *)newID abRecordID:(NSNumber *)recordID valueString:(NSString *)newString;

@end
