//
//  BlockedCellController.h
//  mp
//
//  Created by M Tsai on 11-12-5.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//


/*!
 @header BlockedCellController
 
 A generic cell controller that allows us display options and tell the table view
 which option the user selected.  Should work for any object.
 
 Each row will print out the description: of the object.  So define this method if 
 a special format is needed.
 
 @copyright TernTek
 @updated 2011-11-25
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>
#import "CellController.h"
#import "MPImageManager.h"

@class CDContact;

@class BlockedCellController;

@protocol BlockedCellControllerDelegate <NSObject>

/*!
 @abstract Notify tableview that a contact should be unblocked
 */
- (void)blockedCellController:(BlockedCellController *)blockedCellController unblockContact:(CDContact *)contact;

/*!
 @abstract Notify tableview to refresh row - usually headshot was updated
 */
- (void)blockedCellController:(BlockedCellController *)blockedCellController refreshContact:(CDContact *)contact;


@end


/*!
 
 contact        contact that this cell represents
 isSelected     is this particular contact selected
 
 */

@interface BlockedCellController : NSObject <CellController, MPImageManagerDelegate> {
    id <BlockedCellControllerDelegate> delegate;
    CDContact *contact;  
    MPImageManager *imageManager;
}
@property(nonatomic, assign) id <BlockedCellControllerDelegate> delegate;
@property(nonatomic, retain) CDContact *contact;

/*! helps access headshots for friends */
@property(nonatomic, retain) MPImageManager *imageManager;

- (id)initWithObject:(id)newObject;

@end