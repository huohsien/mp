//
//  FriendSuggestionController.h
//  mp
//
//  Created by Min Tsai on 2/19/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//


/*!
 @header FriendSuggestionController
 
 Allow users add or block friend suggestions 
 
 @copyright TernTek
 @updated 2011-11-25
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>
#import "GenericTableViewController.h"
#import "SuggestCellController.h"

@class CDContact;

@interface FriendSuggestionController : GenericTableViewController <SuggestCellControllerDelegate> {
    
    NSMutableArray *suggestedContacts;
    NSIndexPath *lastTappedIndexPath;
    
    NSString *selectedContactID;
    NSTimer *deleteRowTimer;
    
    BOOL isReloadPending;
}

/*! list of predefined status to display to user */
@property (nonatomic, retain) NSMutableArray *suggestedContacts;

/*! location of last cell that was tapped - should hide it's options if another cell was tapped */
@property (nonatomic, retain) NSIndexPath *lastTappedIndexPath;

/*! Keep track of selected contact incase table is refreshed */
@property (nonatomic, retain) NSString *selectedContactID;

/*! Execute delayed action to delete a row */
@property (nonatomic, retain) NSTimer *deleteRowTimer;

/*! Flag that we have a reload that is pending */
@property (nonatomic, assign) BOOL isReloadPending;

@end