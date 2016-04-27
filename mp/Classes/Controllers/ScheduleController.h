//
//  ScheduleController.h
//  mp
//
//  Created by Min Tsai on 1/17/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

/*!
 @header ScheduleController
 
 Displays pending scheduled messages.
 - messages can only be viewed or deleted.
 - no editing is allowed for now
 
 Server communication
 - send message to DS to create SM
 - DS will accept or reject
 - DS will send confirmation when SM is sent
 - client can send delete to remove SM
 
 @copyright TernTek
 @updated 2011-08-30
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


#import <UIKit/UIKit.h>
#import "GenericTableViewController.h"
#import "SelectContactController.h"
#import "ELCImagePickerController.h"
#import "ScheduleCellController.h"
#import "ComposerController.h"
#import "LetterController.h"

@interface ScheduleController : GenericTableViewController <SelectContactsControllerDelegate, UIActionSheetDelegate, ELCImagePickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ScheduleCellControllerDelegate, ComposerControllerDelegate, LetterControllerDelegate> {
    
    NSMutableArray *scheduledMessages;
    NSMutableDictionary *pendingDeleteD;
    
    NSString *pendingMessageID;
    UIBarButtonItem *editButtonItem;
}

@property (nonatomic, retain) NSMutableArray *scheduledMessages;

/*! store SM that are pending delete - key:messageID of leave message */
@property (nonatomic, retain) NSMutableDictionary *pendingDeleteD;

/*! save SM message pending delivery - wait for confirmation from DS */
@property (nonatomic, retain) NSString *pendingMessageID;

/*! Used to show and hide the edit button */
@property (nonatomic, retain) UIBarButtonItem *editButtonItem;

@end