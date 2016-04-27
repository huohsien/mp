//
//  SelectCellController.h
//  mp
//
//  Created by M Tsai on 11-11-26.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

/*!
 @header SelectCellController
 
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

@class CDContact;
@class SelectCellController;

@protocol SelectCellControllerDelegate <NSObject>

// used to notify tableview that a contact was tapped.  Allows tableview react such as enable or disable buttons.
//
- (void)selectCellController:(SelectCellController *)selectCellController tappedObject:(id)tappedObject;

@end


/*!
 
 contact        contact that this cell represents
 isSelected     is this particular contact selected
 
 */

@interface SelectCellController : NSObject <CellController> {
    id <SelectCellControllerDelegate> delegate;
    id cellObject;  
    RowPosition rowPosition;
}

@property(nonatomic, assign) id <SelectCellControllerDelegate> delegate;
@property(nonatomic, retain) id cellObject;
@property (nonatomic, assign) RowPosition rowPosition;


- (id)initWithObject:(id)newObject;

@end