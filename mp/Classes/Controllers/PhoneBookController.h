//
//  PhoneBookController.h
//  mp
//
//  Created by Min Tsai on 1/26/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header PhoneBookController
 
 Displays of list of telephone numbers
 
 Process:
 - gets list of phone numbers from background contact manager
 - collates and display properties
 - submits and returns a list of properties to use
 
 Test case:
 - no property selected
 - large number of property selected
 - cancel
 - email and sms use cases
 - no phonebook contacts
 
 Phone to Contact matching:
 Since M+ registered phone number includes country code, they don't match exactly with 
 the number in the user's phone book.  So we only try to match the last 6 digits.  This
 should be enough to ensure we find the right contact for a phone number.  6 digits
 was chosen since this is probably the shortest mobile number possible.  
 
 @copyright TernTek
 @updated 2011-11-25
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


#import <UIKit/UIKit.h>
#import "GenericTableViewController.h"
#import "PhoneBookCellController.h"



@class MPContactManager;
@class TTCollationWrapper;



@interface PhoneBookController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate, PhoneBookCellControllerDelegate>{
        
    NSSet *contactProperties;
    NSMutableDictionary *idToPropertyD;
    TTCollationWrapper *collation;
    NSMutableArray *filteredObjects;
    
    NSMutableDictionary *contactCellControllerD;
    NSMutableDictionary *phoneToContactD;
    
    UISearchBar *searchBar;
    UISearchDisplayController *searchController;
    BOOL searchWasActive;
}


/*! Phone properties data model */
@property (atomic, retain) NSSet *contactProperties;

/*! converts ID to property */
@property (nonatomic, retain) NSMutableDictionary *idToPropertyD;

/*! @abstract collation object to organize contacts for table views */
@property (nonatomic, retain) TTCollationWrapper *collation;

/*! @abstract search results data model */
@property (nonatomic, retain) NSMutableArray *filteredObjects;


/*! store cell controller related to contacts data model */
@property (nonatomic, retain) NSMutableDictionary *contactCellControllerD;

/*! 
 D to get associated contact for a phone number
 - key: last 6 digit of phone number 
 - value: CDContact 
 */
@property (nonatomic, retain) NSMutableDictionary *phoneToContactD;


@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UISearchDisplayController *searchController;


@end