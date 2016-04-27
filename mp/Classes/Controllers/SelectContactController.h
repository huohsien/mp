//
//  SelectContactController.h
//  mp
//
//  Created by M Tsai on 11-12-10.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

/*!
 @header SelectContactController
 
 General tableview that shows list of friends for selection.
 
 Use:
 - Select friends to start chat or broadcast message
 - Select friends to forward message to
 - Select friends to invite to a group chat
 
 Usage:
 * contacts will be created and update using presence results
 
 @copyright TernTek
 @updated 2011-09-07
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <Foundation/Foundation.h>
#import "SelectContactCellController.h"



/*!
 @abstract The type of select views offered
 
 Basic          already selected at the top with w/ radio button (can deselect preselected contacts & can add more)
                 ~ limits selected to max broadcast limit
 
 CreateChat     no contacts pre-selected with chat, broadcast buttons at the bottom
                 ~ disables buttons when limits are reached
 
 InviteGroup    already invited at the top w/o radio button 
                 ~ can't deselected preselected, but can select more
                 ~ return only added contacts, does not include previous memebers!
 
 ReadOnly       only show the contacts provided w/o radio button - pushed view
 
 
 
 ForwardMessage only select a single contact
 
 */
typedef enum {
    kMPSelectContactTypeBasic,
	kMPSelectContactTypeCreateChat,
    kMPSelectContactTypeInviteGroup,
    kMPSelectContactTypeForwardMessage,
    kMPSelectContactTypeReadOnly
} MPSelectContactType;


@class SelectContactController;
@class MPContactManager;


@protocol SelectContactsControllerDelegate <NSObject>

@optional

// used to notify parent that this controller is done selecting contacts to chat with & pass back contacts info
//
- (void)selectContactsController:(SelectContactController *)selectContactsController chatContacts:(NSArray *)contacts;

// used to notify parent that this controller is done selecting contacts to broadcast & pass back contacts info
//
- (void)selectContactsController:(SelectContactController *)selectContactsController broadcastContacts:(NSArray *)contacts;

/*!
 @abstract Notifiy parent controller of cancel
 */
- (void)selectContactsController:(SelectContactController *)selectContactsController didCancel:(BOOL)didCancel;

@end


@interface SelectContactController : UITableViewController <SelectContactCellControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate> {

    id <SelectContactsControllerDelegate> delegate;
    
    MPSelectContactType viewType;
    NSSet *viewContacts;
    
    MPContactManager *contactManager;
    NSMutableSet *selectedUserIDs;
    NSMutableDictionary *contactCellControllerD;
    
    UISearchBar *searchBar;
    UISearchDisplayController *searchController;
    
    UIBarButtonItem *chatButtonItem;
    UIBarButtonItem *broadcastButtonItem;

}

/*! what type of select view type should be created */
@property (nonatomic, assign) MPSelectContactType viewType;

/*! object used to help determine how view id configured */
@property (nonatomic, retain) NSSet *viewContacts;

@property (nonatomic, assign) id <SelectContactsControllerDelegate> delegate;
@property (nonatomic, retain) MPContactManager *contactManager;

/*! remembers which contacts where selected in case data is reloaded - don't use to count contacts */
@property (nonatomic, retain) NSMutableSet *selectedUserIDs;


/*! store cell controller related to contacts data model */
@property (nonatomic, retain) NSMutableDictionary *contactCellControllerD;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UISearchDisplayController *searchController;

// create chat tool bar buttons
@property (nonatomic, retain) UIBarButtonItem *chatButtonItem;
@property (nonatomic, retain) UIBarButtonItem *broadcastButtonItem;

- (id)initWithTableStyle:(UITableViewStyle)style type:(MPSelectContactType)type viewContacts:(NSSet *)contacts;

@end
    
 
