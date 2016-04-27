//
//  BlockedController.h
//  mp
//
//  Created by M Tsai on 11-12-5.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//


/*!
 @header BlockedController
 
 Allow users to unblock contacts that were previously blocked. 
 
 @copyright TernTek
 @updated 2011-11-25
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>
#import "GenericTableViewController.h"
#import "BlockedCellController.h"

@class CDContact;

@interface BlockedController : GenericTableViewController <BlockedCellControllerDelegate> {
    
    NSMutableArray *blockedContacts;
    CDContact *unblockCandidate;
    
}

/*! list of predefined status to display to user */
@property (nonatomic, retain) NSMutableArray *blockedContacts;

/*! save pending status update value here */
@property (nonatomic, retain) CDContact *unblockCandidate;

@end