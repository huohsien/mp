//
//  SuggestCellController.h
//  mp
//
//  Created by Min Tsai on 2/19/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//


/*!
 @header SuggestCellController
 
 Represents contacts suggestions and allows user to block or unblock each contact.
 
 @copyright TernTek
 @updated 2011-11-25
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <UIKit/UIKit.h>
#import "CellController.h"
#import "MPImageManager.h"

@class CDContact;

@class SuggestCellController;

@protocol SuggestCellControllerDelegate <NSObject>


/*!
 @abstract Called when contact cell needs to be refreshed.
 
 We need to tell the table to refresh the cell if something changed like the headshot.
 The table will then:
 - figure out if this controller is visible
 - if visible then refresh it
 
 */
- (void)SuggestCellController:(SuggestCellController *)controller refreshContact:(CDContact *)contact;


/*!
 @abstract Called when cell was tapped
 - table hide the options of the last selected cell if it is visible
 - save this indexpath
 
 */
- (void)SuggestCellController:(SuggestCellController *)controller didTapIndexPath:(NSIndexPath *)indexPath;

/*!
 @abstract Called when cell is refreshed
 */
- (void)SuggestCellController:(SuggestCellController *)controller refreshedContact:(CDContact *)contact;


/*!
 @abstract Called if contact is blocked or added
 
 */
- (void)SuggestCellController:(SuggestCellController *)controller didChangeStateForContact:(CDContact *)contact;


/*!
 @abstract Notify tableview that a contact should be blocked
 */
- (void)SuggestCellController:(SuggestCellController *)controller blockContact:(CDContact *)contact;

/*!
 @abstract Notify tableview that a contact should be added as a friend
 */
- (void)SuggestCellController:(SuggestCellController *)controller addContact:(CDContact *)contact;

@end



@interface SuggestCellController : NSObject <CellController, MPImageManagerDelegate> {
    id <SuggestCellControllerDelegate> delegate;
    
    CDContact *contact; 
    MPImageManager *imageManager;
    

    
}
@property(nonatomic, assign) id <SuggestCellControllerDelegate> delegate;
@property(nonatomic, retain) CDContact *contact;

/*! helps access headshots for friends */
@property(nonatomic, retain) MPImageManager *imageManager;



- (id)initWithObject:(id)newObject;
- (void)tableView:(UITableView *)tableView showOptionsAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)tableView:(UITableView *)tableView hideOptionsAtIndexPath:(NSIndexPath *)indexPath showResult:(BOOL)showResult;
@end