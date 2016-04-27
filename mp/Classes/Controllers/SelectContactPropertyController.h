//
//  SelectContactPropertyController.h
//  mp
//
//  Created by M Tsai on 11-12-1.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

/*!
 @header SelectContactPropertyController
 
 Displays a complete list of email or sms properties for users to choose from
 
 Process:
 - gets list of properties from background contact manager
 - collates and display properties
 - submits and returns a list of properties to use
 
 Test case:
 - no property selected
 - large number of property selected
 - cancel
 - email and sms use cases
 - no phonebook contacts
 
 @copyright TernTek
 @updated 2011-11-25
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


#import <UIKit/UIKit.h>
#import "GenericTableViewController.h"
#import "SelectContactPropertyCellController.h"

/**
 Font standards
 
 */
typedef enum {
    kSelectContactPropertyTypeEmail,
    kSelectContactPropertyTypeSMS,
    kSelectContactPropertyTypeFreeSMS
} SelectContactPropertyType;



@class MPContactManager;
@class TTCollationWrapper;



@class SelectContactPropertyController;

/*!
 Delegate that can be notified when TTURLConnection is finished or has
 encountered an error.
 
 */
@protocol SelectContactPropertyControllerDelegate <NSObject>

/*!
 @abstract Called after user has completed selection
 */
- (void)SelectContactPropertyController:(SelectContactPropertyController *)controller selectedProperties:(NSArray *)properties propertyType:(SelectContactPropertyType)propertyType;
@end



@interface SelectContactPropertyController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate, SelectContactPropertyCellControllerDelegate>{
    
    id <SelectContactPropertyControllerDelegate> delegate;
    SelectContactPropertyType propertyType;
    
    NSSet *contactProperties;
    NSMutableDictionary *idToPropertyD;
    TTCollationWrapper *collation;
    NSMutableArray *filteredObjects;
    
    NSMutableDictionary *contactCellControllerD;
    
    UISearchBar *searchBar;
    UISearchDisplayController *searchController;
    BOOL searchWasActive;
}

/*! delegate called after selection is finished */
@property (nonatomic, assign) id <SelectContactPropertyControllerDelegate> delegate;

/*! the type of properties that can be selected */
@property (nonatomic, assign) SelectContactPropertyType propertyType;

/*! save properties to be shown in data model */
@property (atomic, retain) NSSet *contactProperties;

/*! save properties to be shown in data model */
@property (nonatomic, retain) NSMutableDictionary *idToPropertyD;

/*! @abstract collation object to organize contacts for table views */
@property (nonatomic, retain) TTCollationWrapper *collation;

/*! @abstract search results */
@property (nonatomic, retain) NSMutableArray *filteredObjects;


/*! store cell controller related to contacts data model */
@property (nonatomic, retain) NSMutableDictionary *contactCellControllerD;


@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UISearchDisplayController *searchController;

- (id)initWithStyle:(UITableViewStyle)style type:(SelectContactPropertyType)newType;

@end