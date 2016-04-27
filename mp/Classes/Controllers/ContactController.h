//
//  FriendController.h
//  mp
//
//  Created by M Tsai on 11-9-8.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactCellController.h"
#import "MPImageManager.h"
#import "HiddenController.h"


@class MPContactManager;
@class CDChat;


@interface ContactController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate, ContactCellControllerDelegate, MPImageManagerDelegate, HiddenControllerDelegate>{

    
    MPContactManager *contactManager;
    NSMutableDictionary *contactCellControllerD;
    
    UISearchBar *searchBar;
    UISearchDisplayController *searchController;
    MPImageManager *imageManager;
    
    CDChat *pendingHiddenChat;
    BOOL shouldPushPendingChat;
    
}

@property (nonatomic, retain) MPContactManager *contactManager;

/*! store cell controller related to contacts data model */
@property (nonatomic, retain) NSMutableDictionary *contactCellControllerD;


@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UISearchDisplayController *searchController;


/*! help download my headshot */
@property (nonatomic, retain) MPImageManager *imageManager;

/*! Hidden chat that should be shown after unlocking PIN */
@property (nonatomic, retain) CDChat *pendingHiddenChat;

/*! Should we push the pending chat when view appears - helps hide tabbar */
@property (nonatomic, assign) BOOL shouldPushPendingChat;

@end
