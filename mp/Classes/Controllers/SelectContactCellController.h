//
//  SelectContactCellController.h
//  mp
//
//  Created by M Tsai on 11-12-10.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellController.h"
#import "MPImageManager.h"


@class CDContact;
@class SelectContactCellController;

/*!

 
 */
@protocol SelectContactCellControllerDelegate <NSObject>

/*!
 @abstract Called after user has completed selection
 */
- (void)SelectContactCellController:(SelectContactCellController *)controller didSelect:(BOOL)selected;
@end


@interface SelectContactCellController : NSObject <CellController, MPImageManagerDelegate> {
    id <SelectContactCellControllerDelegate> delegate;
    CDContact *contact;
    BOOL isSelected;
    MPImageManager *imageManager;
    
    BOOL enableSelection;

}

@property(nonatomic, assign) id <SelectContactCellControllerDelegate> delegate;
@property(nonatomic, retain) CDContact *contact;

/*! current select status of this controller */
@property(nonatomic, assign) BOOL isSelected;

/*! is this controller selectable */
@property(nonatomic, assign) BOOL enableSelection;


/*! helps access headshots for friends */
@property(nonatomic, retain) MPImageManager *imageManager;

- (id)initWithContact:(CDContact *)newContact enableSelection:(BOOL)enable;

@end