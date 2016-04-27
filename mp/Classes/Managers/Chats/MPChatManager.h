//
//  MPChatManager.h
//  mp
//
//  Created by M Tsai on 11-9-20.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

// when new message comes in
extern NSString* const MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION;

// when updates to message status comes in
extern NSString* const MP_CHATMANAGER_UPDATE_MESSAGE_NOTIFICATION;

// when multimsg processing is complete
extern NSString* const MP_CHATMANAGER_NEW_MULTIMSG_NOTIFICATION;

/*! Sent when typing message is received - object is cdChat object ID */
extern NSString* const MP_CHATMANAGER_TYPING_NOW_NOTIFICATION;



// when new schedule message confirmation is received
extern NSString* const MP_CHATMANAGER_NEW_SCHEDULED_NOTIFICATION;

// when schedule is accepted by DS - sent received and new message state saved
extern NSString* const MP_CHATMANAGER_UPDATE_SCHEDULE_NOTIFICATION;


/*! when badge count update was requested - notify HC to udpate badge as well */
extern NSString* const MP_CHATMANAGER_UPDATE_BADGECOUNT_NOTIFICATION;


@class MPMessage, CDMessage, CDChat;

@interface MPChatManager : NSObject {
    NSInteger totalUnreadMessagesCache;
    NSTimer *playInAppTimer;
    
    NSManagedObjectID *currentDisplayedChatID;
    NSTimer *updateBadgeTimer;
    
    BOOL disableMessageProcessing;
    
    // testing
    BOOL isEchoTestOn;
    NSString *echoMessageID;
    
    // batch processing
    BOOL isBatchProcessingOn;
    NSMutableArray *batchNewMessages;
    NSMutableArray *batchUpdatedMessageIDs;
}

/*! should echo test continue to run */
@property (nonatomic, assign) BOOL isEchoTestOn;

/*! last message echo message ID - check if we get sent reply for it */
@property (nonatomic, retain) NSString *echoMessageID;


/*! cache the number of unread message, so no need to recount if there was no change recently */
@property (assign) NSInteger totalUnreadMessagesCache;

/*! Delay timer to play audio and vibrate when new messages arrives */
@property (nonatomic, retain) NSTimer *playInAppTimer;

/*! Chat ID that is currently viewed by user - helps count unread chats while in chat dialog */
@property (nonatomic, retain) NSManagedObjectID *currentDisplayedChatID;

/*! Throttle expensive badge updates */
@property (nonatomic, retain) NSTimer *updateBadgeTimer;

/*! Shuts down message processing during account delete process */
@property (nonatomic, assign) BOOL disableMessageProcessing;

// batch processing
/*! Should we batch save and notify together for new messages */
@property (nonatomic, assign) BOOL isBatchProcessingOn;


/*! New message object IDs that are batched together */
@property (nonatomic, retain) NSMutableArray *batchNewMessages;

/*! Message object IDs for messages with state changes that are batched together */
@property (nonatomic, retain) NSMutableArray *batchUpdatedMessageIDs;


/*!
 @abstract creates singleton object
 */
+ (MPChatManager *)sharedMPChatManager;


- (void) runEchoTest;
- (void) handleMessage:(MPMessage *)newMessage;
- (void) sendCDMessage:(CDMessage *)cdMessage requireSentConfirmation:(BOOL)requireSentConfirmation enableAcceptRejectConfirmation:(BOOL)enabledAcceptRejectConfirmation;
- (void) sendCDMessage:(CDMessage *)cdMessage;
- (void) sendTypingNowMessageForChat:(CDChat *)thisChat;


// batch processing
//
- (void) startBatchMessageProcessing;
- (void) stopBatchMessageProcessing;


// update messages
//
+ (void) markPreviousOutstandingMPMessages;
+ (void) sendOutstandingMPMessages;
- (void) markCDMessageRead:(CDMessage *)cdMessage shouldSave:(BOOL)shouldSave;
- (void) markCDMessageFailed:(NSString *)messageID shouldSave:(BOOL)shouldSave;
- (void) markCDMessageCreated:(NSString *)messageID;
- (void) deleteCDMessage:(NSString *)messageID;

// Delete chat and schedule message
- (void) deleteChat:(CDChat *)chatToDelete;
- (NSString *) requestDeleteChat:(CDChat *)cdChat;
- (void) requestDeleteScheduleMessage:(CDMessage *)scheduleCDMessage;
- (void) requestDeleteForAllScheduleMessage;

// group chat
- (CDMessage *) addGroupChatControlAddMessageForChat:(CDChat *)groupChat shouldSend:(BOOL)shouldSend;

- (void) assignCurrentDisplayedChat:(CDChat *)displayedChat;
- (NSUInteger) numberOfUnreadChats;
- (void) updateChatBadgeCount;
- (void) updateScheduleBadgeCount;
- (NSUInteger) totalUnreadMessagesUseCache:(BOOL)useCache;

// process message
//
- (void) startupMessageProcessing;
- (void) shutdownMessageProcessing;

@end
