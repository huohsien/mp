//
//  TTRefreshTableViewController.h
//  ContactBook
//
//  Created by M Tsai on 11-3-22.
//  Copyright 2011 TernTek. All rights reserved.
//

/**
 TableViewController that also manages a pull-down (reload) mechanism for this table
 
 orginal code from:
 http://www.cocoanetics.com/2009/12/how-to-make-a-pull-to-reload-tableview-just-like-tweetie-2/
 
 
 To Use:
 - subclass this class
 - override "reloadTableViewDataSource" so that it performs the action you want
 - call "dataSourceDidFinishLoadingNewData" when action performed is complete

 Attribute:
 reloadDelayTimer		timer to add a delay to sending reload message to TV Controller
 
 */
#import <UIKit/UIKit.h>
#import "HiddenChatView.h"
#import "GenericTableViewController.h"


@interface TKRefreshTableViewController : GenericTableViewController <HiddenChatViewDelegate>
{
	HiddenChatView *refreshHeaderView;
	
	BOOL checkForRefresh;
	BOOL reloading;
	BOOL insetOnReload;
    BOOL isLocked;
    
	NSTimer *reloadDelayTimer;
	
	/*SoundEffect *psst1Sound;
	SoundEffect *psst2Sound;
	SoundEffect *popSound;*/
}

/*! is HC currently locked - should only modify inset if unlocked */
@property (nonatomic, assign) BOOL isLocked;

/*! should inset be modified to fix header titles position */
@property (nonatomic, assign) BOOL insetOnReload;

@property (nonatomic, retain) NSTimer *reloadDelayTimer;
@property (nonatomic, retain) HiddenChatView *refreshHeaderView;

- (void) dataSourceDidFinishLoadingNewDataAnimated:(BOOL)animated;
- (void) showReloadAnimationAnimated:(BOOL)animated;
- (void) lockHiddenChat;

@end