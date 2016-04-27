//
//  ChatSettingController.h
//  mp
//
//  Created by M Tsai on 11-12-25.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectContactController.h"

/*! deletes an invite message to failed */
extern NSString* const MP_CHATSETTING_DELETE_INVITE_NOTIFICATION;


@class CDChat;
@class CDMessage;


@interface ChatSettingController : UIViewController <SelectContactsControllerDelegate, UIActionSheetDelegate> {

    CDChat *cdChat;
    BOOL pendingHiddenChatState;
    NSString *pendingInviteMessageID;
    NSArray *pendingInviteContacts;
    
    NSString *pendingDeleteMessageID;

    
}

/*! The chat which user will change settings for */
@property (nonatomic, retain) CDChat *cdChat;


/*! Requested Hidden state - handled when view appears */
@property (nonatomic, assign) BOOL pendingHiddenChatState;

/*! Message ID that we are waiting for invite confirmation from DS */
@property (nonatomic, retain) NSString *pendingInviteMessageID;

/*! Contacts that are waiting to be added to group */
@property (nonatomic, retain) NSArray *pendingInviteContacts;


/*! Message ID for leave message that we are waiting to send to DS */
@property (nonatomic, retain) NSString *pendingDeleteMessageID;


- (id)initWithCDChat:(CDChat *)newChat;

@end
