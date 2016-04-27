//
//  FriendCellController.h
//  mp
//
//  Created by M Tsai on 11-9-8.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellController.h"
#import "MPImageManager.h"


@class CDContact;
@class MPImageManager;
@class ContactCellController;


@protocol ContactCellControllerDelegate <NSObject>

/*!
 @abstract Called when contact cell needs to be refreshed.
 
 We need to tell the table to refresh the cell if something changed like the headshot.
 The table will then:
  - figure out if this controller is visible
  - if visible then refresh it
 
 */
- (void)ContactCellController:(ContactCellController *)controller refreshContact:(CDContact *)contact;


/*!
 @abstract Called when cell is tapped and chat should be initiated
 
 */
- (void)ContactCellController:(ContactCellController *)controller startChatWithContact:(CDContact *)contact;

@end


@interface ContactCellController : NSObject <CellController, MPImageManagerDelegate> {
    id <ContactCellControllerDelegate> delegate;
    CDContact *contact;
    UIViewController *parentController;
    MPImageManager *imageManager;
}

@property(nonatomic, assign) id <ContactCellControllerDelegate> delegate;

@property(nonatomic, retain) CDContact *contact;
/*! used for pushing a new VC .. but probably can do with delegate too */
@property(nonatomic, retain) UIViewController *parentController;

/*! helps access headshots for friends */
@property(nonatomic, retain) MPImageManager *imageManager;




- (id)initWithContact:(CDContact *)newContact;

@end