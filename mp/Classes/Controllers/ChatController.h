//
//  ChatController.h
//  mp
//
//  Created by M Tsai on 11-9-26.
//  Copyright 2011年 TernTek. All rights reserved.
//

/*!
 @header ChatController

 
 == Broadcast Messages ==
 
 This VC also creates ComposerControllers for broadcast messages.
 - Msg is composed and returned by delegate
 - Send out broadcast msg - state created & not related to a particular chat
   ~ 
 - Wait for "Sent" confirmation
 - If successful
   ~ change state to sent
 - If not successful
   ~ 
 
 == Delete Chats ==
 
 Deleting chats works in the following way:
  1 - p2p chats gets deleted right away
  2 - group chats delete
    ~ send a Leave message to all group participants
    ~ waits notifacation for returning sent message, then deletes the chat
    ~ waits notification for timeout or network failure to cancel delete
    ~ pending deletes are stored in pendingDeleteD dictionary
 
 
 @copyright TernTek
 @updated 2011-08-30
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


#import <UIKit/UIKit.h>
#import "TKRefreshTableViewController.h"
#import "SelectContactController.h"
#import "ChatCellController.h"
#import "ComposerController.h"
#import "ELCImagePickerController.h"
#import "LetterController.h"
#import "LocationShareController.h"
#import "HiddenController.h"
#import "ChatDialogController.h"

@interface ChatController : TKRefreshTableViewController <SelectContactsControllerDelegate, UIActionSheetDelegate, ChatCellControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ELCImagePickerControllerDelegate, ComposerControllerDelegate, LetterControllerDelegate, LocationShareControllerDelegate, HiddenControllerDelegate, ChatDialogControllerDelegate> {

    NSMutableArray *chats;
    
    NSMutableArray *hiddenChats;
    NSMutableArray *regularChats;
    
    NSMutableDictionary *pendingDeleteD;
    NSString *pendingMessageID;
    
    NSArray *broadcastContacts;
    SelectContactController *selectController;
    
    CDChat *pendingHiddenChat;
    BOOL shouldPushPendingChat;
    
    UIBarButtonItem *editButtonItem;
    
    NSMutableSet *pendingMessageToUpdate;
    NSTimer *uiUpdateTimer;
}

@property (nonatomic, retain) NSMutableArray *chats;

@property (nonatomic, retain) NSMutableArray *hiddenChats;
@property (nonatomic, retain) NSMutableArray *regularChats;

/*! store chats that are pending delete - key:messageID of leave message */
@property (nonatomic, retain) NSMutableDictionary *pendingDeleteD;

/*! temp store to save selected contacts for broadcast messages */
@property (nonatomic, retain) NSArray *broadcastContacts;

/*! select contact VC, keep reference so we can present modally above it */
@property (nonatomic, retain) SelectContactController *selectController;

/*! save Broadcast messageID pending delivery - wait for confirmation from DS */
@property (nonatomic, retain) NSString *pendingMessageID;


/*! Hidden chat that should be shown after unlocking PIN */
@property (nonatomic, retain) CDChat *pendingHiddenChat;

/*! Should we push the pending chat? */
@property (nonatomic, assign) BOOL shouldPushPendingChat;

/*! Used to show and hide the edit button */
@property (nonatomic, retain) UIBarButtonItem *editButtonItem;

/*! Store messages to update when uiUpdateTimer fires */
@property (nonatomic, retain) NSMutableSet *pendingMessageToUpdate;

/*! Start timer to throttle ui updates */
@property (nonatomic, retain) NSTimer *uiUpdateTimer;


@end
