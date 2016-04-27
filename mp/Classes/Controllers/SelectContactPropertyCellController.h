//
//  SelectContactPropertyCellController.h
//  mp
//
//  Created by M Tsai on 11-12-2.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellController.h"

@class ContactProperty;
@class SelectContactPropertyCellController;

/*!
 Delegate that can be notified when TTURLConnection is finished or has
 encountered an error.
 
 */
@protocol SelectContactPropertyCellControllerDelegate <NSObject>

/*!
 @abstract Called after user has completed selection
 */
- (void)SelectContactPropertyCellController:(SelectContactPropertyCellController *)controller didSelect:(BOOL)selected;
@end


@interface SelectContactPropertyCellController : NSObject <CellController> {
    id <SelectContactPropertyCellControllerDelegate> delegate;
    ContactProperty *property;
}

@property(nonatomic, assign) id <SelectContactPropertyCellControllerDelegate> delegate;

/*! property that this cell represents */
@property(nonatomic, retain) ContactProperty *property;


- (id)initWithContactProperty:(ContactProperty *)newProperty;

@end