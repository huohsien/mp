//
//  PhoneBookCellController.h
//  mp
//
//  Created by Min Tsai on 1/27/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellController.h"
#import "MPImageManager.h"

@class ContactProperty;
@class CDContact;
@class PhoneBookCellController;


@protocol PhoneBookCellControllerDelegate <NSObject>

/*!
 @abstract Called when contact cell needs to be refreshed.
 
 Refresh needed when:
 - operator info updated
 - presence info updated
 - etc.
 
 The table will then:
 - figure out if this controller is visible
 - if visible then refresh it
 
 */
- (void)PhoneBookCellController:(PhoneBookCellController *)controller refreshProperty:(ContactProperty *)property;

/*!
 @abstract Call when contact property is tapped
 - Table should push this contact's info on to navigation stack
 
 */
- (void)PhoneBookCellController:(PhoneBookCellController *)controller tappedContactProperty:(ContactProperty *)property contact:(CDContact *)contact operatorNumber:(NSNumber *)operatorNumber;

@end


@interface PhoneBookCellController : NSObject <CellController> {
    id <PhoneBookCellControllerDelegate> delegate;
    ContactProperty *phoneProperty;
    CDContact *contact;
    NSNumber *operatorNumber;

}

@property(nonatomic, assign) id <PhoneBookCellControllerDelegate> delegate;

/*! phone property that is represented by this cell */
@property(nonatomic, retain) ContactProperty *phoneProperty;

/*! the operator for this phone number */
@property(nonatomic, retain) NSNumber *operatorNumber;

/*! if also MP friend - save contact obj here */
@property(nonatomic, retain) CDContact *contact;


- (id)initWithPhoneProperty:(ContactProperty *)contactProperty associatedContact:(CDContact *)newContact;

@end