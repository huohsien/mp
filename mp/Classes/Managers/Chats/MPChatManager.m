//
//  MPChatManager.m
//  mp
//
//  Created by M Tsai on 11-9-20.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "MPChatManager.h"
#import "CDContact.h"
#import "CDChat.h"
#import "CDMessage.h"
#import "CDMPMessage.h"

#import "MPFoundation.h"
#import "SynthesizeSingleton.h"


CGFloat const kMPParamSendMessageTimeout = 30.0;

NSString* const MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION = @"MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION";
NSString* const MP_CHATMANAGER_UPDATE_MESSAGE_NOTIFICATION = @"MP_CHATMANAGER_UPDATE_MESSAGE_NOTIFICATION";
NSString* const MP_CHATMANAGER_NEW_MULTIMSG_NOTIFICATION = @"MP_CHATMANAGER_NEW_MULTIMSG_NOTIFICATION";
NSString* const MP_CHATMANAGER_TYPING_NOW_NOTIFICATION = @"MP_CHATMANAGER_TYPING_NOW_NOTIFICATION";


NSString* const MP_CHATMANAGER_NEW_SCHEDULED_NOTIFICATION = @"MP_CHATMANAGER_NEW_SCHEDULED_NOTIFICATION";
NSString* const MP_CHATMANAGER_UPDATE_SCHEDULE_NOTIFICATION = @"MP_CHATMANAGER_UPDATE_SCHEDULE_NOTIFICATION";

NSString* const MP_CHATMANAGER_UPDATE_BADGECOUNT_NOTIFICATION = @"MP_CHATMANAGER_UPDATE_BADGECOUNT_NOTIFICATION";


//NSString* const kEchoUserID = @"99999999";
NSString* const kEchoUserID = @"00000448";



@interface MPChatManager (Private)

@end



@implementation MPChatManager

@synthesize isEchoTestOn;
@synthesize echoMessageID;

@synthesize totalUnreadMessagesCache;
@synthesize playInAppTimer;

@synthesize currentDisplayedChatID;
@synthesize updateBadgeTimer;

@synthesize disableMessageProcessing;

@synthesize isBatchProcessingOn;
@synthesize batchNewMessages;
@synthesize batchUpdatedMessageIDs;

// no dealloc for singletons!
//
SYNTHESIZE_SINGLETON_FOR_CLASS(MPChatManager);

/*!
 @abstract translate from CDMessageType to MPMessageType
 */
+ (NSDictionary *)cdTypeToMPTypeDictionary {
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                kMPMessageTypeChat , [NSNumber numberWithInt:kCDMessageTypeText],
                                kMPMessageTypeGroupChat, [NSNumber numberWithInt:kCDMessageTypeTextGroup],
                                kMPMessageTypeImage, [NSNumber numberWithInt:kCDMessageTypeImage],
                                kMPMessageTypeAudio, [NSNumber numberWithInt:kCDMessageTypeAudio],
                                kMPMessageTypeVideo, [NSNumber numberWithInt:kCDMessageTypeVideo],
                                kMPMessageTypeFile, [NSNumber numberWithInt:kCDMessageTypeFile],
                                kMPMessageTypeCall, [NSNumber numberWithInt:kCDMessageTypeCall],
                                kMPMessageTypeContact, [NSNumber numberWithInt:kCDMessageTypeContact],
                                kMPMessageTypeGroupChat, [NSNumber numberWithInt:kCDMessageTypeGroupEnter],
                                kMPMessageTypeGroupChat, [NSNumber numberWithInt:kCDMessageTypeGroupLeave],
                                kMPMessageTypeChat, [NSNumber numberWithInt:kCDMessageTypeSticker],
                                kMPMessageTypeGroupChat, [NSNumber numberWithInt:kCDMessageTypeStickerGroup],
                                kMPMessageTypeImage, [NSNumber numberWithInt:kCDMessageTypeLetter],
                                kMPMessageTypeLocation, [NSNumber numberWithInt:kCDMessageTypeLocation],
                                nil];
    return dictionary;
}


#pragma mark - MPChatManager


/*!
 @abstracat Setup Manager
 */
- (void) managerSetup {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getBackgroundMOCQueue], @"Must be dispatched on backQueue");

    // mark created messages as failed
    // 
    [CDMessage markOutCreatedAsOutFailed];

    self.isBatchProcessingOn = NO;
    
    NSMutableArray *arrayNew = [[NSMutableArray alloc] init];
    self.batchNewMessages = arrayNew;
    [arrayNew release];
    
    NSMutableArray *arrayUpdated = [[NSMutableArray alloc] init];
    self.batchUpdatedMessageIDs = arrayUpdated;
    [arrayUpdated release];
    
}

- (id)init
{
    self = [super init];
    if (self) {
        
        // allow processing by default
        self.disableMessageProcessing = NO;
        

        // always run in background
        //
        if (dispatch_get_current_queue() != [AppUtility getBackgroundMOCQueue]) {
            
            dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
            
            // protect attributes in netQueue
            //
            dispatch_async(backQueue, ^{
                [self managerSetup];
            });
        }
        else {
            [self managerSetup];
        }
    }
    return self;
}


- (void) dealloc {
    
    [echoMessageID release];
    [playInAppTimer release];
    [currentDisplayedChatID release];
    [updateBadgeTimer release];
    
    [batchNewMessages release];
    [batchUpdatedMessageIDs release];
    [super dealloc];
    
}


#pragma mark - App Status Methods


/*!
 @abstract get total unread messages
 
 Use:
 - update badgecount upon logout
 
 */
- (NSUInteger) totalUnreadMessagesPrivate {
    
    // query all chats and check unread message count
    //
    NSUInteger totalUnreadMessages = 0;
    
    NSArray *allChats = [CDChat allChats];
    for (CDChat *iChat in allChats) {
        totalUnreadMessages += [iChat numberOfUnreadMessages];
    }
    return totalUnreadMessages;
}

- (NSUInteger) totalUnreadMessagesUseCache:(BOOL)useCache {

    if (useCache) {
        return self.totalUnreadMessagesCache;
    }
    
    self.totalUnreadMessagesCache = [self totalUnreadMessagesPrivate];
    
    return self.totalUnreadMessagesCache;
}


/*!
 @abstract Set this chat as currently being viewed
 - so we can exclude in in unread chat count
 
 */
- (void) assignCurrentDisplayedChat:(CDChat *)displayedChat {
    
    NSManagedObjectID *chatID = [displayedChat objectID];
    
    dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
    
    // protect attributes in backQ
    //
    dispatch_async(backQueue, ^{
        
        self.currentDisplayedChatID = chatID;
        
    });
}

/*!
 @abstract Counts chats that have unread messages
 
 */
- (NSUInteger) numberOfUnreadChats {
    
    NSUInteger totalUnreadChats = 0;
    
    NSArray *allChats = [CDChat allChats];
    for (CDChat *iChat in allChats) {
        if ([iChat numberOfUnreadMessages] > 0) {
            totalUnreadChats++;
        }
    } 
    return totalUnreadChats;
}

/*!
 @abstract Updates the badge count for "Chats" Tab
 
 @discussion When ever a new unread messages arrives or when a message is read, we should update this count.  Also used at launch to get current count.  This checks the number of chats with unread message > 0.
 
 */
- (void) updateChatBadgeCountPrivate {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getBackgroundMOCQueue], @"Must be dispatched on backQueue");
    
    // query all chats and check unread message count
    //
    NSUInteger totalUnreadChats = 0;
    NSUInteger chatsExcludingDisplayed = 0;
    
    NSArray *allChats = [CDChat allChats];
    for (CDChat *iChat in allChats) {
        if ([iChat numberOfUnreadMessages] > 0) {
            totalUnreadChats++;
            if (![[iChat objectID] isEqual:self.currentDisplayedChatID]) {
                chatsExcludingDisplayed++;
            }
        }
    } 
    
    [AppUtility setBadgeCount:totalUnreadChats controllerIndex:kMPTabIndexChat];
    
    // tell others that we updated badge count 
    // - HC view should also update count
    // - chat dialog badge also should update
    // - object sent is unread chat number excluding the currently viewed chat - used by chat dialog
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[NSNotificationCenter defaultCenter] 
         postNotificationName:MP_CHATMANAGER_UPDATE_BADGECOUNT_NOTIFICATION 
         object:[NSNumber numberWithInt:chatsExcludingDisplayed]];
        
    });
}

/*!
 @abstract Run chat badge udpate in background queue
 
 */
- (void) updateChatBadgeCountInBackground {
    
    DDLogInfo(@"CM-ucbc: update chat badge");

    if (dispatch_get_current_queue() != [AppUtility getBackgroundMOCQueue]) {
        
        dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
        
        // protect attributes in backQ
        //
        dispatch_async(backQueue, ^{
            
            [self updateChatBadgeCountPrivate];
            
        });
        
    }
    else {
        [self updateChatBadgeCountPrivate];
    }
}

- (void) doNothing {
    // do nothing
}

/*!
 @abstract Throttle updates to once every 0.5 seconds
 
 */
- (void) updateChatBadgeCount {
    /*
     Throttle badge updates using a timer
     */
    if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.updateBadgeTimer invalidate];
            self.updateBadgeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateChatBadgeCountInBackground) userInfo:nil repeats:NO];

        });
    }
    else {
        [self.updateBadgeTimer invalidate];
        self.updateBadgeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateChatBadgeCountInBackground) userInfo:nil repeats:NO];
    }
}




/*!
 @abstract Updates the badge count for "Chats" Tab
 
 @discussion When ever a new unread messages arrives or when a message is read, we should update this count.  Also used at launch to get current count.  This checks the number of chats with unread message > 0.
 
 */
- (void) updateScheduleBadgeCountPrivate {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getBackgroundMOCQueue], @"Must be dispatched on backQueue");
    
    // query all chats and check unread message count
    //
    NSUInteger scheduleCount = [CDMessage scheduledMessagesCount];   
    [AppUtility setBadgeCount:scheduleCount controllerIndex:kMPTabIndexScheduled];
}

- (void) updateScheduleBadgeCount {
    
    if (dispatch_get_current_queue() != [AppUtility getBackgroundMOCQueue]) {
        
        dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
        
        // protect attributes in backQ
        //
        dispatch_async(backQueue, ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            [self updateScheduleBadgeCountPrivate];
            [pool drain];
        });
    }
    else {
        [self updateScheduleBadgeCountPrivate];
    }
}



#pragma mark - Chat & Message Management


/*!
 @abstract delete chat in background MOC
 
 - Should use background to avoid CoreData inconsistencies
   ~ crash may occur if delete in main thread and try to access chat in background thread
   ~ e.g. got Sent reply from leave chat - race condition to delete chat and update sent status for message.
 
 */
- (void) deleteChat:(CDChat *)chatToDelete {
    
    if (dispatch_get_current_queue() != [AppUtility getBackgroundMOCQueue]) {
        
        NSManagedObjectID *deleteID = [chatToDelete objectID];
        
        dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
        
        // protect attributes in netQueue
        //
        dispatch_async(backQueue, ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            CDChat *backDeleteChat = (CDChat *)[[AppUtility cdGetManagedObjectContext] objectWithID:deleteID];
            [CDChat deleteChat:backDeleteChat];
            
            [pool drain];
        });
        
    }
    else {
        [CDChat deleteChat:chatToDelete];
    }
    
}



/*!
 @abstract properly deletes a chat
 
 @return messageID if delete is pending (leave message), nil if user can delete right away (p2p)
 
 */
- (NSString *) requestDeleteChat:(CDChat *)cdChat {
    
    // create leave message if group chat
    if ([cdChat isGroupChat]){
        CDMessage *leaveMessage = [CDMessage outCDMessageForChat:cdChat messageType:kCDMessageTypeGroupLeave text:nil attachmentData:nil shouldSave:YES];
        DDLogInfo(@"CM-rdc: gen leave msgID %@", leaveMessage.mID);
        [self sendCDMessage:leaveMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];
        return leaveMessage.mID;
    }
    // p2p chat can delete immediately - let caller save
    else {
        [CDChat deleteChat:cdChat];
        return nil;
    }
}

/*!
 @abstract sends out a schedule message delete request
  
 */
- (void) requestDeleteScheduleMessage:(CDMessage *)scheduleCDMessage {
    
    MPMessage *deleteMessage = [MPMessage deleteScheduleMessage:scheduleCDMessage.mID];
    
    [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessageWithConfirmation:deleteMessage  enableAcceptRejectConfirmation:YES];
}


/*!
 @abstract sends out delete request for all schedule messages
 
 */
- (void) requestDeleteForAllScheduleMessage {
    
    NSArray *deleteSMs = [CDMessage scheduledMessages];
    
    for (CDMessage *iMessage in deleteSMs) {
        
        MPMessage *deleteMessage = [MPMessage deleteScheduleMessage:iMessage.mID];
        [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessageWithConfirmation:deleteMessage  enableAcceptRejectConfirmation:YES];
    
    }
}




#pragma mark - Notifications


/*!
 @abstract Plays in-app sound or vibration
 
 Use:
 - when new chat content arrives: called by process message below
 
 */
- (void) playInAppNotificationTimer:(NSTimer *)thisTimer {
    
    BOOL isGroup = [thisTimer.userInfo boolValue];
    
    //static ALuint soundID = 0;

    NSString *valueKey = isGroup?kMPSettingPushGroupAlertIsOn:kMPSettingPushP2PAlertIsOn;
    BOOL isAlertOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:valueKey] boolValue];
    
    // only play if main alert is still on
    //
    if (isAlertOn) {
        BOOL soundOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:isGroup?kMPSettingPushGroupInAppIsSoundOn:kMPSettingPushP2PInAppIsSoundOn] boolValue];
        
        NSString *soundFile = [[MPSettingCenter sharedMPSettingCenter] valueForID:isGroup?kMPSettingPushGroupRingTone:kMPSettingPushP2PRingTone];
        
        if (soundOn) {
            
            [Utility asPlaySystemSoundFilename:soundFile];
            
            /*
            // play audio
            if (soundID) {
                [Utility audioStop:soundID];
            }        
            soundID = [Utility audioPlayEffect:soundFile];
             */
        }
        
        BOOL vibrateOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:isGroup?kMPSettingPushGroupInAppIsVibrateOn:kMPSettingPushP2PInAppIsVibrateOn] boolValue];
        
        if (vibrateOn) {
            [Utility vibratePhone];
        }
    }
    
}

#pragma mark - Group Chat

/*!
 @abstract Adds an add control message to indicate when contacts where invited
 
 @param shouldSend If message should be sent out
         - create should not send, since we don't want to create tons of empty group chats
         - invite should send so inviter sees feedback immediately and other group members are synced.
 
 blank messages lets client know when contacts are added to group chats. Done by comparing blank message
 to previous message.
 
 @return the control message that was created.
 
 Use:
 - called in main thread - if sending
 - call after group chat creation - no send
 - call after invite finished - send out
 - call after receiving left message - no send
   ~ msg allows next message know that someone left in case that same person was added back right away
 
 */
- (CDMessage *) addGroupChatControlAddMessageForChat:(CDChat *)groupChat shouldSend:(BOOL)shouldSend 
{
    
    // only for group chats
    //
    if ([groupChat isGroupChat]) {
        CDMessage *newCDMessage = [CDMessage outCDMessageForChat:groupChat 
                                                     messageType:kCDMessageTypeTextGroup 
                                                            text:@"" 
                                                  attachmentData:nil  
                                                      shouldSave:YES];
        if (shouldSend) {
            // sends this message
            //
            [[MPChatManager sharedMPChatManager] sendCDMessage:newCDMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];
            
            // post notification for scroll view to show new message
            NSManagedObjectID *objectID = [newCDMessage objectID];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION object:[NSArray arrayWithObject:objectID]];
            });
            
        }
        // if locally created message, then set to an aritifical state
        // - helps keep message in order
        else {
            // - InDelivered ~ will be counted as unread message.. ok actually
            //
            newCDMessage.state = [NSNumber numberWithInt:kCDMessageStateInRead];
            // sentDate not set so this message is always at the top for newly created group chats
            // - if used after leave set sent date just a bit later
        }
        
        if (newCDMessage) {
            return newCDMessage;
        }
    }
    return nil;
   
}





#pragma mark - Network: Send Message



/*!
 @abstract sends locally created CDMessage over the network
 
 Use:
 - send messages created by user in viewcontrollers
 
 kCDMessageTypeText = 0,
 kCDMessageTypeCall = 1,
 kCDMessageTypeImage = 2,
 kCDMessageTypeAudio = 3,
 kCDMessageTypeVideo = 4,
 kCDMessageTypeFile = 5,
 kCDMessageTypeContact = 6,
 kCDMessageTypeContainer = 100
 
 */
- (void)sendCDMessagePrivate:(CDMessage *)cdMessage requireSentConfirmation:(BOOL)requireSentConfirmation enableAcceptRejectConfirmation:(BOOL)enabledAcceptRejectConfirmation {
   
    // BLOCK: don't send messages to people who blocked you!!!
    // - only for P2P chats
    // - allow group chats - accepted by other party
    // - also allow broad cast and scheduled so it appears the message is sent out, other side should discard message
    //
    // 2012-3-3 mht: allow all message to be sent out!
    /*if (![cdMessage.chat isGroupChat] && [cdMessage.contactsTo count] == 1 && [cdMessage.isScheduled boolValue] == NO) {
        
        CDContact *reciever = [cdMessage.contactsTo anyObject];
        if ([reciever hasBlockedMe]) {
            
            // mark as sent - so users thinks he sent out the message properly
            cdMessage.sentDate = [NSDate date];
            cdMessage.state = [NSNumber numberWithInt:kCDMessageStateOutSentBlocked];
            [AppUtility cdSaveWithIDString:@"ChatM - scdm: set sent date - try to sent to user who blocked you" quitOnFail:NO];
            
            return;
        }
    }*/
    
    
    // convert to MPMessage
    //
    NSString *mpType = [[MPChatManager cdTypeToMPTypeDictionary] objectForKey:cdMessage.type];
    //CDMessageType cdType = [cdMessage.type intValue];
    
    // construct to array
    //
    NSMutableArray *toArray = [[NSMutableArray alloc] init];
    for (CDContact *iContact in cdMessage.contactsTo){
        [toArray addObject:[iContact userAddressIncludeDomain:YES]];
    }
    
    NSString *fromAddress = nil;
    
    // include domain for all messages for now
    fromAddress = [cdMessage.contactFrom userAddressIncludeDomain:YES];
    
    // only text message use fromaddress
    /*if (cdType == kCDMessageTypeText || cdType == kCDMessageTypeTextGroup) {
        fromAddress = [cdMessage.contactFrom userAddressIncludeDomain:YES];
    }
    // rest uses cluster address - to download attachments
    else {
        fromAddress = [cdMessage.contactFrom userAddressIncludeDomain:NO];
    }*/
    NSString *seq = [cdMessage sequenceString];
    
    MPMessage *newMessage = [[MPMessage alloc] initWithID:cdMessage.mID 
                                                     type:mpType 
                                                  groupID:cdMessage.chat.groupID 
                                                       to:toArray 
                                                     from:fromAddress 
                                                     text:cdMessage.text 
                                                 sequence:seq 
                                               attachData:[cdMessage getFileData]
                                              previewData:[cdMessage previewImageData] 
                                                 filename:cdMessage.filename];
    [toArray release];
    
    
    /*** Special message modifcations init can't perform since CDMessage type info NOT available ***/
    
    CDMessageType messageType = [cdMessage.type intValue];
    
    /*
     for sticker add sticker=yes for chat and gchat
     */
    if (messageType == kCDMessageTypeSticker || messageType == kCDMessageTypeStickerGroup) {
        [newMessage.properties setValue:@"yes" forKey:kMPMessageKeySticker];
    }    
    /*
     for group enter or leave messages
     
     Enter Message:
     @gchat?id=xxxxxxxx&WithoutPN=1&to=B+c&from=A&action=enter&enter=C+D

     Leave Message:
     @gchat?id=xxxxxxxx&WithoutPN=1&to=B+C&from=A&action=leave
     */
    else if (messageType == kCDMessageTypeGroupLeave) {
        [newMessage.properties setValue:@"1" forKey:kMPMessageKeyWithoutPN];
        [newMessage.properties setValue:@"leave" forKey:kMPMessageKeyAction];
    }
    // letters add letter parameter to MPMessage
    // &letter=<letterID>
    else if (messageType == kCDMessageTypeLetter) {
        [newMessage.properties setValue:cdMessage.typeInfo forKey:kMPMessageKeyLetter];
    }
    // location, add tag to make sure notifications are sent
    else if (messageType == kCDMessageTypeLocation) {
        [newMessage.properties setValue:@"1" forKey:kMPMessageKeyWithPN];
    }

    // if scheduled message
    // "schedule=1326782376"
    if (cdMessage.dateScheduled) {
        NSString *dateString = [NSString stringWithFormat:@"%d", (NSInteger)[cdMessage.dateScheduled timeIntervalSince1970]];
        [newMessage.properties setValue:dateString forKey:kMPMessageKeySchedule];
    }
    
    
    // Register
    if (requireSentConfirmation) {
        
        if (!newMessage.mID) {
            DDLogWarn(@"CM-scdmp: msg missing mID %@", cdMessage);
        }
        // Forward to MessageCenter 
        // - save msgID for confirmation
        // - register for SocketCenter Timeout & check for no network
        //
        [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessageWithConfirmation:newMessage  enableAcceptRejectConfirmation:enabledAcceptRejectConfirmation];
    }
    else {
        // Forward to MessageCenter
        //
        [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:newMessage];
    }
    [newMessage release];
    
}


/*!
 @abstract sends locally created CDMessage over the network
 
 Use:
 - send messages created by user in viewcontrollers
 
 kCDMessageTypeText = 0,
 kCDMessageTypeCall = 1,
 kCDMessageTypeImage = 2,
 kCDMessageTypeAudio = 3,
 kCDMessageTypeVideo = 4,
 kCDMessageTypeFile = 5,
 kCDMessageTypeContact = 6,
 kCDMessageTypeContainer = 100
 
 */
- (void)sendCDMessage:(CDMessage *)cdMessage requireSentConfirmation:(BOOL)requireSentConfirmation enableAcceptRejectConfirmation:(BOOL)enabledAcceptRejectConfirmation {
    
    // run in main so transient attachment files can be accessed
    //
    [self sendCDMessagePrivate:cdMessage requireSentConfirmation:(BOOL)requireSentConfirmation enableAcceptRejectConfirmation:enabledAcceptRejectConfirmation];

    
    /*
    // always run in background
    //
    if (dispatch_get_current_queue() != [AppUtility getBackgroundMOCQueue]) {
        
        NSManagedObjectID *objectID = [cdMessage objectID];
        
        dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
        
        // run in background - reconstruct object from ID
        //
        dispatch_async(backQueue, ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            NSManagedObjectContext *moc = [AppUtility cdGetManagedObjectContext];
            CDMessage *newCDMessage = (CDMessage *)[moc objectWithID:objectID]; 
            [self sendCDMessagePrivate:newCDMessage requireSentConfirmation:(BOOL)requireSentConfirmation];
            
            [pool drain];
        });
        
    }
    else {
        [self sendCDMessagePrivate:cdMessage requireSentConfirmation:(BOOL)requireSentConfirmation];
    }*/
}

// default do not register for confirmation
- (void)sendCDMessage:(CDMessage *)cdMessage {
    [self sendCDMessage:cdMessage requireSentConfirmation:NO enableAcceptRejectConfirmation:NO];
}



/*!
 @abstract Sends a typing now message for a specified chat
 

 Use:
 - call to send a typing now message - when user is typing
 - only for P2P chat rooms
 - don't send if permission is turned off
 
 
 @input?id=2012022800000152949356&from=00000152[naturaltel]@10.39.106.12{175.99.90.210}&to=00000160[cherrydreamkimo]@10.39.106.12{175.99.90.210}&text=1&withoutQueue=1
 
 */
- (void) sendTypingNowMessageForChat:(CDChat *)thisChat {
    
    CDContact *reciever = [thisChat.participants anyObject];
    
    // no typing message for group chats
    //
    if ([thisChat isGroupChat]) {
        return;
    }
    // p2p contact has blocked me - don't send either
    // - mht 2012-3-3: don't block any messages
    // - let receiver take care of this
    /*else {
        if ([reciever hasBlockedMe]) {
            return;
        }
    }*/
    
    // if permission is off, then no typing message
    //
    NSNumber *isPermissionOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPresencePermission];
    if ([isPermissionOn boolValue] == NO) {
        return;
    }
    
    // if person is not online
    // - no need to sent typing message
    //
    CDContact *p2pContact = [thisChat p2pUser];
    if (p2pContact) {
        if (![p2pContact isOnline]) {
            return;
        }
    }
    
    
    // construct to array
    //
    NSMutableArray *toArray = [[NSMutableArray alloc] initWithObjects:[reciever userAddressIncludeDomain:YES], nil];
        
    // include domain for all messages for now    
    NSString *fromAddress = [[AppUtility getAppDelegate] sharedCacheObjectForKey:@"myMplusAddress"];
    if ([fromAddress length] < 1) {
        DDLogInfo(@"CM: fetching mySelf address");
        fromAddress = [[CDContact mySelf] userAddressIncludeDomain:YES];
        [[AppUtility getAppDelegate] sharedCacheSetObject:fromAddress forKey:@"myMplusAddress"];
    }
    
    MPMessage *newMessage = [[MPMessage alloc] initWithID:[AppUtility generateMessageID]
                                                     type:kMPMessageTypeInput 
                                                  groupID:thisChat.groupID
                                                       to:toArray 
                                                     from:fromAddress 
                                                     text:@"1" 
                                                 sequence:nil 
                                               attachData:nil
                                              previewData:nil 
                                                 filename:nil];
    [toArray release];
    
    [newMessage.properties setValue:@"1" forKey:kMPMessageKeyWithoutQueue];
    [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:newMessage];
    [newMessage release];
}

#pragma mark - Network: In-coming Message


/*!
 @abstract Enable message processing

 */
- (void) startupMessageProcessing {
    
    dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
    DDLogInfo(@"CM: startup message processing");

    if (dispatch_get_current_queue() != backQueue) {
        
        // protect attributes in netQueue
        // - run sync to make sure this gets done first
        //
        dispatch_sync(backQueue, ^{
            self.disableMessageProcessing = NO;
        });
        
    }
    else {
        self.disableMessageProcessing = NO;
    }
    
}

/*!
 @abstract Enable message processing
 - run sync to make sure this gets done first
 
 */
- (void) shutdownMessageProcessing {
    dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
    DDLogInfo(@"CM: shutdown message processing");
    if (dispatch_get_current_queue() != backQueue) {
        
        // protect attributes in netQueue
        // - run sync to make sure this gets done first
        //
        dispatch_sync(backQueue, ^{
            self.disableMessageProcessing = YES;
        });
        
    }
    else {
        self.disableMessageProcessing = YES;
    }
}


/*!
 @abstract get chat participants
 
 @param shouldSave Should we save change to CD right away
 
 @discussion only "to" will exclude self.  "from" can include self since you can send messages to your self.
 
 - if groupID exists, then get multiple participants
 - if groupID does not exists, then only get a single from contact for P2P chat
 
 @return array of contacts participating in chat, nil if problem occurred
 
 Use:
 - to create chat from a MPMessage, needs to have a list of participants first
   ~ a single contact repressents a P2P message
 
 */
- (NSArray *) participantsInMPMessage:(MPMessage *)mpMessage shouldSave:(BOOL)shouldSave {
    
    NSString *myUserID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    
    NSMutableArray *participants = [[[NSMutableArray alloc] init] autorelease];
    
    // add from contact
    //
    NSDictionary *fromContact = [mpMessage fromContactsDictionary];
    NSString *userID = [fromContact objectForKey:kMPMessageKeyUserID];
    NSString *nick = [fromContact valueForKey:kMPMessageKeyNickName];
    NSString *domain = [fromContact valueForKey:kMPMessageKeyDomain];
    NSString *fromAddress = [fromContact valueForKey:kMPMessageKeyFromAddress];
    
    // add from address contact
    //
    CDContact *newFrom = [CDContact contactWithUserID:userID
                                             nickName:nick
                                     domainServerName:fromAddress
                                    domainClusterName:domain
                                        statusMessage:nil
                                       headShotNumber:NSNotFound
                                             presence:NSNotFound
                                            loginDate:nil
                                          addAsFriend:NO
                                           shouldSave:shouldSave shouldUpdate:NO];
    
    if (newFrom){
        [participants addObject:newFrom];
    }
    // something wrong with addresses!
    else {
        return nil;
    }
    
    // add to contacts
    // - only add it for group messages
    //
    if ([AppUtility isMessageIDValid:mpMessage.groupID]) {
        NSArray *toContacts = [mpMessage toContactsDictionaries];
        
        // address must be correct
        if (fromContact == nil || toContacts == nil) {
            return nil;
        }
        
        for (NSDictionary *iContactD in toContacts){
            NSString *aUserID = [iContactD objectForKey:kMPMessageKeyUserID];
            
            // skip self
            if ([aUserID isEqualToString:myUserID]) {
                continue;
            }
            
            NSString *aNick = [iContactD valueForKey:kMPMessageKeyNickName];
            NSString *aDomain = [iContactD valueForKey:kMPMessageKeyDomain];
            NSString *aFromAddress = [iContactD valueForKey:kMPMessageKeyFromAddress];
            
            CDContact *iContact = [CDContact contactWithUserID:aUserID
                                                      nickName:aNick
                                              domainServerName:aFromAddress
                                             domainClusterName:aDomain
                                                 statusMessage:nil
                                                headShotNumber:NSNotFound
                                                      presence:NSNotFound
                                                     loginDate:nil
                                                   addAsFriend:NO
                                                    shouldSave:shouldSave shouldUpdate:NO];
            
            if (iContact) {
                [participants addObject:iContact];
            }
        }
    }
    return participants;
}

/*!
 @abstract Get participant in mpMessage
 
 - By default: saves participants
 
 */
- (NSArray *) participantsInMPMessage:(MPMessage *)mpMessage {
    return [self participantsInMPMessage:mpMessage shouldSave:YES];
}


/*!
 @abstract handles message related to this object
 
 handles following messages


 extern NSString* const kMPMessageTypeSent;
 extern NSString* const kMPMessageTypeDelivered;
 extern NSString* const kMPMessageTypeRead;

 extern NSString* const kMPMessageTypeChat;
 extern NSString* const kMPMessageTypeGroupChat;
 extern NSString* const kMPMessageTypeGroupChatLeave;
 
 extern NSString* const kMPMessageTypeImage;
 extern NSString* const kMPMessageTypeImage;
 extern NSString* const kMPMessageTypeAudio;
 extern NSString* const kMPMessageTypeVideo;
 extern NSString* const kMPMessageTypeFile;
 
 */
- (void) processMessage:(MPMessage *)newMessage {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getBackgroundMOCQueue], @"Must be dispatched on backQueue");
    
    
    // disable message processing
    // - used when deleting an account.
    // - prevents core data conflict, so messages don't try to access deleted chats & messages
    //
    if (self.disableMessageProcessing == YES) {
        return;
    }
    
    // TODO: don't send delivered & READ to blocked users.

    
    /*
     Got in-coming chat or gchat message
     
     - create CDMessage
      * get contact info
     
     - get associated CDChat
      * related message to chat
     
     */
    if ([newMessage isChatContentType]) {
        
        NSArray *participants = [self participantsInMPMessage:newMessage shouldSave:NO];
        
        if (!participants) {
            DDLogInfo(@"CM-pm: WARN - corrupted particpants in new message");
            
            // Send dummy delivered
            // - only ID needed, don't need to actually sent it back since there is something wrong 
            //   with this message and we didn't get is properly
            //
            MPMessage *dummyDelivered = [MPMessage deliveredMessageDummyWithID:newMessage.mID];
            [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:dummyDelivered];
            
            return;
        }
        
        // BLOCK: if P2P chat and the person is blocked, then ignore this message!
        // - only for non group chats
        // - should only be one participant for multicast p2p chats (participantsInMPMessage does this correctly)
        //
        if (![AppUtility isMessageIDValid:newMessage.groupID]) {
            CDContact *sender = [participants objectAtIndex:0];
            if ([sender isBlockedByMe]) {
                
                // Need to send dummy delivered to DS so it will not queue this message and know
                // that we got it ok
                //
                MPMessage *dummyDelivered = [MPMessage deliveredMessageForBlocked];
                [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:dummyDelivered];
                
                return;
            }
        }
        
        
        // check if leave message's group is available
        // - if not, then ignore this message
        //
        NSString *action = [newMessage.properties valueForKey:kMPMessageKeyAction];
        BOOL isLeaveMessage = [action isEqualToString:@"leave"]?YES:NO;
        
        if (isLeaveMessage) {
            CDChat *leaveChat = [CDChat getChatForGroupID:newMessage.groupID];
            
            // make sure leave message if fresh from DB
            // - invite may have be added in main thread MOC
            // - and will not show up if not refreshed
            //
            //[AppUtility cdRefreshObject:leaveChat];
            //NSManagedObjectContext *moc = [AppUtility cdGetManagedObjectContext];
            [leaveChat.managedObjectContext refreshObject:leaveChat mergeChanges:NO];
            
             
            BOOL ignoreLeave = NO;
            // Ignore, if chat does not exists
            if (!leaveChat) {
                ignoreLeave = YES; 
            }
            // Ignore, if user is not in this chat
            else {
                NSString *senderUserID = [newMessage senderUserID];
                if (![leaveChat isUserIDInChat:senderUserID]) {
                    ignoreLeave = YES;
                    [leaveChat printParticipantIDs];
                }
            }
            
            // send delivered reply and don't ignore it
            //
            if (ignoreLeave) {
                MPMessage *replyMessage = [newMessage generateReplyWithMessageType:kMPMessageTypeDelivered];
                [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:replyMessage];
                return;
            }
        }
        
        // also check for new group invites
        // - except for leave messages
        // - disable save and aggregate below instead
        //
        CDChat *cdChat = [CDChat chatWithCDContacts:participants 
                                            groupID:newMessage.groupID 
                            checkForNewGroupInvites:!isLeaveMessage 
                                         shouldSave:NO]; // YES];
        
        // default, send a delivered reply
        //
        BOOL sendDeliveredMessage = YES;
        
        // nil is returned if duplicate message
        //
        NSError *msgError = nil;
        CDMessage *cdMessage = [CDMessage cdMessageFromInComingMPMessage:newMessage cdChat:cdChat shouldSave:NO error:&msgError];
        
        CDMessage *groupControlMessage = nil;
        
        // if message is valid
        //
        if (cdMessage) {
            // if leave, remove these participants from chat
            if(isLeaveMessage) {
                [cdChat removeParticipantsObject:cdMessage.contactFrom];
                
                // add dummy message after leave message
                // - so we can tell if B is added
                // - set to sentDate a little after the leave message
                //   ~ helps show right last message time
                //   ~ keeps msg in proper sequence - get proper last message for "joins" after this "leave"
                //
                groupControlMessage = [self addGroupChatControlAddMessageForChat:cdMessage.chat shouldSend:NO];
                groupControlMessage.sentDate = [cdMessage.sentDate dateByAddingTimeInterval:0.001];
            }
        }
        
        // if error from creating cdMessage
        //
        if (msgError) {
            NSInteger errorCode = [msgError code];
            
            // if save failed, don't send delivered
            // - we want to server to send this message again
            //
            if (errorCode == kCDMessageErrorSaveFailed) {
                sendDeliveredMessage = NO;
            }
            // otherwise for duplicate mID or invalid message, reply with delivered
        }
        
        // Should delivered message be sent out?
        if (sendDeliveredMessage) {
            
            // Message is now safely delivered
            // - send delivered message back
            // - always reply even if msg is invalid
            //
            MPMessage *replyMessage = [newMessage generateReplyWithMessageType:kMPMessageTypeDelivered];
            replyMessage.sequence = kMPMessageTypeDelivered;
            [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:replyMessage];
            
            // leave message does not need delivered or read replies
            // - client gets sent reply then deletes the chat anyways
            //
            if (!isLeaveMessage) {
                NSString *toAddress =  [replyMessage toAddressString]; //

                // only if to address is valid
                // - e.g. gchat @delivered does not have to address, so no need to keep track of it
                //
                if ([toAddress length] > 0) {
                    // create a record in case it does not get sent out
                    [CDMPMessage createMPMessageWithMID:replyMessage.mID mType:replyMessage.mType toAddress:toAddress shouldSave:NO];
                }

            }
        }
        
        // save CD changes
        //
        if (!self.isBatchProcessingOn) {
            [AppUtility cdSaveWithIDString:@"process in-coming cdmessage" quitOnFail:NO];
        }
        
        
        if (cdMessage) {
            
            // send notification to reload contacts
            // - to main queue
            //
            NSManagedObjectID *objectID = [cdMessage objectID];
            NSManagedObjectID *controlMessageID = [groupControlMessage objectID];
            
            BOOL isGroup = [cdChat isGroupChat];
            
            // aggregate message updates
            if (self.isBatchProcessingOn) {
                if (cdMessage) {
                    [self.batchNewMessages addObject:cdMessage];
                }
                if (groupControlMessage) {
                    [self.batchNewMessages addObject:groupControlMessage];
                }
                
                // play audio even for batch
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.playInAppTimer invalidate];
                    
                    NSNumber *isGroupNumber = [NSNumber numberWithBool:isGroup];
                    // play sound effects
                    // - delay so we don't keep playing sound for a burst of messages
                    self.playInAppTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(playInAppNotificationTimer:) userInfo:isGroupNumber repeats:NO];
                    
                });
                
            }
            // batch is off, update single message
            else {
                // update badge count before new msg notification
                [self updateChatBadgeCount];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSArray *msgObjectIDs = [NSArray arrayWithObjects:objectID, controlMessageID, nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION object:msgObjectIDs];
                    
                    [self.playInAppTimer invalidate];
                    
                    NSNumber *isGroupNumber = [NSNumber numberWithBool:isGroup];
                    // play sound effects
                    // - delay so we don't keep playing sound for a burst of messages
                    self.playInAppTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(playInAppNotificationTimer:) userInfo:isGroupNumber repeats:NO];
                    
                });
            }
            
        }
    }
    /*
     Got message status udpate
     - find the associated message - matching mID
     
     - update status
        ~ sent - set state to sent
        ~ delivered or read
          - p2p set state to delivered
          - add contact to delivered/read relationship
     
     - scheduled
        ~ sent          set parent and all children to scheduled
        ~ schedule      set parent and all children to sent
        ~ delivered     set parent and specific child to delivered
        ~ read          set parent and specific child to read
     
     - multicast
        ~ sent          set parent and all children to sent
        ~ delivered     parent & specific child message -> set to delivered
        ~ read          parent & specific child message -> set to read
     
     */
    // handle message updates
    //
    else if ([newMessage isChatStateUpdate]) {

        // look for a matching ID
        CDMessage *cdMessage = [CDMessage cdMessageWithID:newMessage.mID isMadeHere:nil]; //[NSNumber numberWithBool:YES]];

        // if message is just deleted, treat it as a non message update
        //
        if (cdMessage) {
            if ([cdMessage isDeleted] || cdMessage.managedObjectContext == nil) {
                cdMessage = nil;
            }
        }
        
        CDMessageState currentCDMessageState;
        @try {
            currentCDMessageState = [cdMessage getStateValue];
        }
        @catch (NSException *exception) {
            NSString *exceptionName = [exception name];
            DDLogError(@"CM-pm: Raised Exception %@: %@", exceptionName, [exception reason]);
            cdMessage = nil;
        }

        
        if (!cdMessage) {
            DDLogInfo(@"CM: state update for non message");

            // Make sure we reply Sent confirmations
            //
            if ([newMessage.mType isEqualToString:kMPMessageTypeDelivered] ||
                [newMessage.mType isEqualToString:kMPMessageTypeRead] ||
                [newMessage.mType isEqualToString:kMPMessageTypeMultimsg] ){
                
                // got the message safely
                // - sent confirmation to DS
                MPMessage *replyMessage = [newMessage generateReplyWithMessageType:kMPMessageTypeSent];
                [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:replyMessage];
                
            }
            // confirmation SM was sent out successfully
            // - sent out @del reply even if we don't have this message anymore (may happen if reinstall)
            //
            else if ([newMessage.mType isEqualToString:kMPMessageTypeSchedule] ){

                DDLogWarn(@"CM: reply @del for missing SM message!");

                // DS will wait for a confirmaion
                // - so send dummy delivered
                //
                MPMessage *dummyDelivered = [MPMessage deliveredMessageDummyWithID:newMessage.mID];
                [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:dummyDelivered];
            }
            else if ([newMessage.mType isEqualToString:kMPMessageTypeSent] ){
                
                // save timeoffset that is used to set create time for failed messages
                // - so the create time can be used as a sent time if the message recovers from failed - to del/read state
                // - this is set once per session
                //
                NSNumber *timeOffset = [[AppUtility getAppDelegate] sharedCacheObjectForKey:kMPSharedNSCacheKeyDSTimeOffset];
                if (!timeOffset) {
                    //NSDate *now = [NSDate date];
                    //NSDate *dsdate = newMessage.sentDate;
                    // + if DS date is ahead of client, - if DS is behind client
                    timeOffset = [NSNumber numberWithFloat:[newMessage.sentDate timeIntervalSinceNow]];
                    
                    if (timeOffset) {
                        [[AppUtility getAppDelegate] sharedCacheSetObject:timeOffset forKey:kMPSharedNSCacheKeyDSTimeOffset];
                        
                        // also save it to disk
                        // - may be needed for sessions where login did not get an @sent yet, but a failed message is already created
                        // - this assumes that the timeoffset does not change dramatically between each session
                        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSharedNSCacheKeyDSTimeOffset settingValue:timeOffset];
                         DDLogInfo(@"ChatM-pm: set DS time offset %@", timeOffset);
                    }
                    
                }
            }
           
        }
        // message is sent to server
        //
        else if ([newMessage.mType isEqualToString:kMPMessageTypeSent] ){
            
            // if sent for delivered or read messages
            if ([newMessage.sequence length] > 0) {
                if ([newMessage.sequence isEqualToString:kMPMessageTypeDelivered] || 
                    [newMessage.sequence isEqualToString:kMPMessageTypeRead]) {
                    [CDMPMessage findAndDeleteMPMessagesWithMID:newMessage.mID mType:newMessage.sequence];
                    
                    // no need to continue
                    return;
                }
            }
            
            //BOOL isScheduled = NO;
            //NSString *msgID = nil;
            
            // Don't go backward in state
            // - This is needed by schedule message since DS can send @sent with the same ID back which can cause problems
            //
            if (currentCDMessageState == kCDMessageStateOutSent || 
                currentCDMessageState == kCDMessageStateOutDelivered ||
                currentCDMessageState == kCDMessageStateOutRead
                ) {
                return;
            }
            
            NSNumber *newState = [NSNumber numberWithInt:kCDMessageStateOutSent];
            NSDate *sentDate = [newMessage sentDate];
            
            // if scheduled
            // - sent just means the DS got it ok
            // - change to scheduled out state
            // - same state inherited by child messages
            //
            if (cdMessage.dateScheduled) {
                //isScheduled = YES;
                //msgID = cdMessage.mID;
                newState = [NSNumber numberWithInt:kCDMessageStateOutScheduled];
                sentDate = nil;
            }
            
            cdMessage.state = newState;
            cdMessage.sentDate = sentDate;
            
            NSMutableArray *objectIDs = [[NSMutableArray alloc] init];
            [objectIDs addObject:[cdMessage objectID]];

            // update children state
            //
            for (CDMessage *iChild in cdMessage.messages) {
                iChild.state = newState;
                iChild.sentDate = sentDate;
                [objectIDs addObject:[iChild objectID]];
            }
            
            [AppUtility cdSaveWithIDString:@"ChatM-pm: mark msg SENT" quitOnFail:NO];            
            
            NSString *soundFile = @"sent.caf";
            [Utility asPlaySystemSoundFilename:soundFile];  
            
            // testing - wait does prevent race condition [NSThread sleepForTimeInterval:1.0];
            // send notification to reload contacts
            // - to main queue
            //
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_UPDATE_MESSAGE_NOTIFICATION object:objectIDs userInfo:[NSDictionary dictionaryWithObject:newState forKey:@"state"]];
                
                /*// SM posts different notification so create SM view gets confirmation that DS got this message
                if (isScheduled) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_UPDATE_SCHEDULE_NOTIFICATION object:msgID userInfo:nil];
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_UPDATE_MESSAGE_NOTIFICATION object:objectIDs userInfo:[NSDictionary dictionaryWithObject:newState forKey:@"state"]];
                }*/
            });
            
            
            // @TEST
            // for testing - keep sending message if we get replies
            //
            if (self.isEchoTestOn && [cdMessage.mID isEqualToString:self.echoMessageID]) {
                [self runEchoTest];
            }
            [objectIDs release];
            
        }
        // message delivered to other client
        else if ([newMessage.mType isEqualToString:kMPMessageTypeDelivered]){
            
            NSDictionary *fromContact = [newMessage fromContactsDictionary];
            // only mark read if from is valid
            if (fromContact) {
                
                NSString *fromID = [fromContact objectForKey:kMPMessageKeyUserID];
                BOOL didChange = [cdMessage markDeliveredForUserID:fromID];
                
                // if failed message set the sent date using create date
                NSDate *newSentDate = nil;
                if (currentCDMessageState == kCDMessageStateOutFailed || currentCDMessageState == kCDMessageStateOutCreated) {
                    newSentDate = cdMessage.createDate;
                    cdMessage.sentDate = newSentDate;
                }
                
                NSMutableArray *objectIDs = [[NSMutableArray alloc] init];
                if (didChange) 
                    [objectIDs addObject:[cdMessage objectID]];
                
                
                // mark related child with new state
                // - non related children will be skipped
                for (CDMessage *iChild in cdMessage.messages) {
                    if ([iChild markDeliveredForUserID:fromID]) {
                        [objectIDs addObject:[iChild objectID]];
                        // only update if new date is available
                        if (newSentDate) {
                            iChild.sentDate = newSentDate;
                        }
                    }
                }
                
                if ([objectIDs count] > 0) {
                    
                    if (self.isBatchProcessingOn) {
                        [self.batchUpdatedMessageIDs addObjectsFromArray:objectIDs];
                    }
                    else {
                        [AppUtility cdSaveWithIDString:@"ChatM-pm: mark msg DELIV" quitOnFail:NO];            
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_UPDATE_MESSAGE_NOTIFICATION object:objectIDs userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[cdMessage.state intValue]] forKey:@"state"]];
                        }); 
                    }
                    
                }
                [objectIDs release];
            }

            // don't need to send confirmation if inside a multimsg
            //
            if (!self.isBatchProcessingOn) {
                // got the message safely
                // - sent confirmation to DS
                MPMessage *replyMessage = [newMessage generateReplyWithMessageType:kMPMessageTypeSent];
                [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:replyMessage];
            }

            
        }
        // message was read by other
        else if ([newMessage.mType isEqualToString:kMPMessageTypeRead]){
            
            NSDictionary *fromContact = [newMessage fromContactsDictionary];
            
            // mark only if valid from found
            if (fromContact) {
                NSString *fromID = [fromContact objectForKey:kMPMessageKeyUserID];
                BOOL didChange = [cdMessage markReadForUserID:fromID];
                
                // if failed message set the sent date using create date
                NSDate *newSentDate = nil;
                if (currentCDMessageState == kCDMessageStateOutFailed || currentCDMessageState == kCDMessageStateOutCreated) {
                    newSentDate = cdMessage.createDate;
                    cdMessage.sentDate = newSentDate;
                }
                
                
                NSMutableArray *objectIDs = [[NSMutableArray alloc] init];
                if (didChange) 
                    [objectIDs addObject:[cdMessage objectID]];
                
                // mark related child with new state
                // - non related children will be skipped
                for (CDMessage *iChild in cdMessage.messages) {
                    if ([iChild markReadForUserID:fromID]) {
                        [objectIDs addObject:[iChild objectID]];
                        // only update if new date is available
                        if (newSentDate) {
                            iChild.sentDate = newSentDate;
                        }
                    }
                }
                
                
                if ([objectIDs count] > 0) {
                    
                    if (self.isBatchProcessingOn) {
                        [self.batchUpdatedMessageIDs addObjectsFromArray:objectIDs];
                    }
                    else {
                        [AppUtility cdSaveWithIDString:@"ChatM-pm: mark msg READ" quitOnFail:NO];            
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_UPDATE_MESSAGE_NOTIFICATION object:objectIDs userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[cdMessage.state intValue]] forKey:@"state"]];
                        });
                    }
                }
                [objectIDs release];
            }
            
            // don't need to send confirmation if inside a multimsg
            //
            if (!self.isBatchProcessingOn) {
                // got the message safely
                // - sent confirmation to DS
                MPMessage *replyMessage = [newMessage generateReplyWithMessageType:kMPMessageTypeSent];
                [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:replyMessage];
            }
            
        }
        // confirmation SM was sent out successfully
        //
        else if ([newMessage.mType isEqualToString:kMPMessageTypeSchedule] ){
            
            NSNumber *newState = [NSNumber numberWithInt:kCDMessageStateOutSent];
            NSDate *sentDate = [newMessage sentDate];
            
            // don't update state if already Sent, Delivered or Read
            if (currentCDMessageState == kCDMessageStateOutScheduled) {
                cdMessage.state = newState;
            }
            
            cdMessage.sentDate = sentDate;
            [cdMessage revealHidden];
            
            NSMutableArray *objectIDs = [[NSMutableArray alloc] init];
            [objectIDs addObject:[cdMessage objectID]];
            
            // update children 
            // - state & sent time
            // - reveal - not hidden
            // - update create time to now - for proper ordering
            //
            for (CDMessage *iChild in cdMessage.messages) {
                
                // don't update state if already Sent, Delivered or Read
                if ([iChild getStateValue] == kCDMessageStateOutScheduled) {
                    cdMessage.state = newState;
                }
                
                iChild.state = newState;
                iChild.sentDate = sentDate;
                [iChild revealHidden];
                [objectIDs addObject:[iChild objectID]];
            }
            
            NSString *saveString = [NSString stringWithFormat:@"ChatM-pm: mark schedMsg as SENT - mID %@", cdMessage.mID];
            [AppUtility cdSaveWithIDString:saveString quitOnFail:NO];        
            
            // DS will wait for a confirmaion
            // - so send dummy delivered
            //
            MPMessage *dummyDelivered = [MPMessage deliveredMessageDummyWithID:newMessage.mID];
            [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:dummyDelivered];
            
            
            // testing - wait does prevent race condition [NSThread sleepForTimeInterval:1.0];
            // send notification to reload chat info
            // - to main queue
            //
            dispatch_async(dispatch_get_main_queue(), ^{
                // this is more like a new message
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION object:objectIDs userInfo:[NSDictionary dictionaryWithObject:newState forKey:@"state"]];
                
                // also update schedule list
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_NEW_SCHEDULED_NOTIFICATION   object:objectIDs userInfo:[NSDictionary dictionaryWithObject:newState forKey:@"state"]];
            });
            
            // count should reduce by one
            [self updateScheduleBadgeCount];
            [objectIDs release];
        }
    }
    // dialog udpates
    // - typing now
    else if ([newMessage isChatDialogUpdate]) {
        
        NSArray *participants = [self participantsInMPMessage:newMessage];
        if (!participants) {
            DDLogVerbose(@"CM-pm: WARN - corrupted particpants in new message");
            return;
        }
        
        // BLOCK: if P2P chat and the person is blocked, then ignore this message!
        // - only for non group chats
        // - should only be one participant for multicast p2p chats (participantsInMPMessage does this correctly)
        //
        if (![AppUtility isMessageIDValid:newMessage.groupID]) {
            CDContact *sender = [participants objectAtIndex:0];
            if ([sender isBlockedByMe]) {
                return;
            }
        }
        
        
        /*
         Typing Now
         - get the associated cdChat and post a typing now message
         
         */
        if ([newMessage.mType isEqualToString:kMPMessageTypeInput] ){

            CDChat *cdChat = [CDChat chatWithCDContacts:participants groupID:newMessage.groupID checkForNewGroupInvites:NO shouldCreate:NO shouldSave:NO];
            
            // only send typing now if chat exists
            // - otherwise it is a brad new chat, so typing now is not needed
            //
            if (cdChat) {
                // send notification to reload contacts
                // - to main queue
                //
                NSManagedObjectID *objectID = [cdChat objectID];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_TYPING_NOW_NOTIFICATION object:objectID];
                });
            }
        
        }
        
    }
}


/*!
 @abstract handles message related to this object
 
 Thread safe, can be called from any thread
 */
- (void) handleMessage:(MPMessage *)newMessage {
    
    //NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    if (dispatch_get_current_queue() != [AppUtility getBackgroundMOCQueue]) {
        
        dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
        
        // protect attributes in netQueue
        //
        dispatch_async(backQueue, ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            [self processMessage:newMessage];
            
            [pool drain];
        });
        
    }
    else {
        [self processMessage:newMessage];
    }
    
}

#pragma mark - Batch Message Processing


/*!
 @abstract Tell Chat Manager to batch CD saves and UI notifications to execute later
 
 Use:
 - called by message center
 
 */
- (void) startBatchMessageProcessing {
    
    DDLogInfo(@"ChatM: batch msg processing - start");

    dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
    
    // protect attributes in netQueue
    //
    dispatch_async(backQueue, ^{
        
        self.isBatchProcessingOn = YES;
        
    });
}

/*!
 @abstract Tell Chat Manager to end batch process and execute CD save and UI notification
 
 Use:
 - called by message center
 
 */
- (void) stopBatchMessageProcessing {
    
    DDLogInfo(@"ChatM: batch msg processing - stop");

    dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
    
    // protect attributes in netQueue
    //
    dispatch_async(backQueue, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        self.isBatchProcessingOn = NO;
        
        [AppUtility cdSaveWithIDString:@"ChatM-pm: stop batch and update messages" quitOnFail:NO];            

        NSMutableArray *newMsgs = [[NSMutableArray alloc] initWithCapacity:[self.batchNewMessages count]];
        for (CDMessage *iMsg in self.batchNewMessages) {
            [newMsgs addObject:[iMsg objectID]];
        }
        NSArray *updateMsgs = [self.batchUpdatedMessageIDs copy];

        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([newMsgs count] > 0 || [updateMsgs count] > 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_NEW_MULTIMSG_NOTIFICATION 
                                                                    object:nil];
            }
            
            /*
            if ([newMsgs count] > 0) {
                // send new message notif first
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION 
                                                                    object:newMsgs];
            }
            if ([updateMsgs count] > 0) {
                // then send message updates notifi next
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_UPDATE_MESSAGE_NOTIFICATION 
                                                                    object:updateMsgs];
            }*/
        });
        
        [newMsgs release];
        [updateMsgs release];

        [self.batchNewMessages removeAllObjects];
        [self.batchUpdatedMessageIDs removeAllObjects];
        
        [pool drain];
    });
    
}


#pragma mark - Update Messages


/*!
 @abstract Marks outstanding message as previous 
 
 - to differentiate which message should be sent out now and which msg are from this session which should be not sent out
 - msg from this session may just be in DB temporarily
 
 Use:
 - call right before login
 
 */
+ (void) markPreviousOutstandingMPMessages {
    
    // always run in background
    //
    dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
    
    dispatch_async(backQueue, ^{
        [CDMPMessage markAllMPMessagesAsPreviousSession];
    });

}


/*!
 @abstract Send read and delivered messages that did not sent out properly before
 
 - delay added so incoming messages can be processed before sending these out
 
 */
+ (void) sendOutstandingMPMessages {
    
    // always run in background
    //
    dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC);

    dispatch_after(delay, backQueue, ^{
        
        NSArray *messages = [CDMPMessage mpMessagesFromPreviousSession];
        
        DDLogInfo(@"CM: found %d outstanding mpmessages", [messages count]);
        
        if ([messages count] > 0) {
            
            NSString *fromString = [[AppUtility getAppDelegate] sharedCacheObjectForKey:@"myMplusAddress"];
            if ([fromString length] < 1) {
                DDLogInfo(@"CM: fetching mySelf address");
                fromString = [[CDContact mySelf] userAddressIncludeDomain:YES];
                [[AppUtility getAppDelegate] sharedCacheSetObject:fromString forKey:@"myMplusAddress"];
            }     
            
            for (CDMPMessage *iMessage in messages) {
                
                // configure addresses
                //
                NSMutableArray *toArray = [[NSMutableArray alloc] init];
                [toArray addObject:iMessage.toAddress];
                
                MPMessage *replyMessage = [[[MPMessage alloc] initWithID:iMessage.mID 
                                                                    type:iMessage.mType 
                                                                 groupID:nil 
                                                                      to:toArray 
                                                                    from:fromString 
                                                                    text:nil 
                                                                sequence:iMessage.mType      //[cdMessage sequenceString] 
                                                              attachData:nil 
                                                             previewData:nil 
                                                                filename:nil] autorelease];
                
                [toArray release];
                [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:replyMessage];
            }
        }
    });
}



/*!
 @abstract mark message as read and send a reply over the network
 
 */
- (void) markCDMessageReadPrivate:(CDMessage *)cdMessage shouldSave:(BOOL)shouldSave{
    
    // TODO: save to cd right away? or wait until later for better performance
    cdMessage.state = [NSNumber numberWithInt:kCDMessageStateInRead];
    
    // send out reply message
    //
    //NSString *myUserID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    
    // configure addresses
    //
    NSMutableArray *toArray = [[NSMutableArray alloc] init];
    
    // get my own address using cache
    NSString *fromString = [[AppUtility getAppDelegate] sharedCacheObjectForKey:@"myMplusAddress"];
    if ([fromString length] < 1) {
        DDLogInfo(@"CM: fetching mySelf address");
        fromString = [[CDContact mySelf] userAddressIncludeDomain:YES];
        [[AppUtility getAppDelegate] sharedCacheSetObject:fromString forKey:@"myMplusAddress"];
    }
    
    // add sender to reply
    // - only need to reply to sender
    //
    NSString *toAddress = [cdMessage.contactFrom userAddressIncludeDomain:YES];
    [toArray addObject:toAddress];
    
    // create read message
    // - attachment data should all be nil
    //
    MPMessage *replyMessage = [[[MPMessage alloc] initWithID:cdMessage.mID 
                                                        type:kMPMessageTypeRead 
                                                     groupID:nil 
                                                          to:toArray 
                                                        from:fromString 
                                                        text:nil 
                                                    sequence:kMPMessageTypeRead      //[cdMessage sequenceString] 
                                                  attachData:nil 
                                                 previewData:nil filename:nil] autorelease];
    
    [toArray release];
    
    [[MPMessageCenter sharedMPMessageCenter] processOutGoingMessage:replyMessage];
    
    // save below
    [CDMPMessage createMPMessageWithMID:cdMessage.mID mType:kMPMessageTypeRead toAddress:toAddress shouldSave:NO];
    
    if (shouldSave) {
        // need to save so main thread will get new results
        [AppUtility cdSaveWithIDString:@"Mark Read" quitOnFail:NO];
    }

}




/*!
 @abstract mark message as read and send a reply over the network
 
 */
- (void) markCDMessageRead:(CDMessage *)cdMessage shouldSave:(BOOL)shouldSave{
    
    // if just delivered, then mark as read
    //
    if ([cdMessage.state intValue] == kCDMessageStateInDelivered) {
    
        // always run in background
        //
        if (dispatch_get_current_queue() != [AppUtility getBackgroundMOCQueue]) {
            
            NSManagedObjectID *objectID = [cdMessage objectID];
            
            
            dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
            
            // protect attributes in netQueue
            //
            dispatch_async(backQueue, ^{
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                
                NSManagedObjectContext *moc = [AppUtility cdGetManagedObjectContext];
                CDMessage *newCDMessage = (CDMessage *)[moc objectWithID:objectID]; 
                [self markCDMessageReadPrivate:newCDMessage shouldSave:shouldSave];
                
                [pool drain];
            });
            
        }
        else {
            [self markCDMessageReadPrivate:cdMessage shouldSave:shouldSave];
        }
    }
}


/*!
 @abstract mark message as failed
 
 */
- (void) markCDMessageFailedPrivate:(NSString *)messageID shouldSave:(BOOL)shouldSave{

    // get message object
    //
    // look for a matching ID
    CDMessage *cdMessage = [CDMessage cdMessageWithID:messageID isMadeHere:[NSNumber numberWithBool:YES]];
    
    CDMessageState mState = [cdMessage.state intValue];
    
    // if message exists and it was just created
    // - or failed before
    //
    if (cdMessage && 
        (mState == kCDMessageStateOutCreated || mState == kCDMessageStateOutFailed) ) {

        NSNumber *newState = [NSNumber numberWithInt:kCDMessageStateOutFailed];
        cdMessage.state = newState;
        
        /*
        // if an time offset exists apply to the create date
        // - this can then be used as a sent date if message recovers
        //
        NSNumber *timeOffset = [[AppUtility getAppDelegate] sharedCacheObjectForKey:kMPSharedNSCacheKeyDSTimeOffset];
        if (timeOffset) {
            cdMessage.createDate = [NSDate dateWithTimeInterval:[timeOffset floatValue] sinceDate:cdMessage.createDate];
        }
        // get timeoffset from disk as backup
        else {
            timeOffset = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSharedNSCacheKeyDSTimeOffset];
            if (timeOffset) {
                cdMessage.createDate = [NSDate dateWithTimeInterval:[timeOffset floatValue] sinceDate:cdMessage.createDate];
            }
        }*/
        
        NSString *saveMsg = [NSString stringWithFormat:@"ChatM: Mark Failed st: %@ msgID: %@", newState, messageID];
        //DDLogInfo(@"CM: mark failed st: %@ mID: %@", newState, messageID);
        [AppUtility cdSaveWithIDString:saveMsg quitOnFail:NO];            
    }
}

/*!
 @abstract mark message as failed
 
 */
- (void) markCDMessageFailed:(NSString *)messageID shouldSave:(BOOL)shouldSave{
    
    // play failed audio
    [Utility asPlaySystemSoundFilename:@"failed.caf"];
    
    dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];

    // always insert DB in background
    //
    if (dispatch_get_current_queue() != backQueue) {
        
        // run sync to make sure we finish this before doing anything else
        //
        dispatch_sync(backQueue, ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            [self markCDMessageFailedPrivate:messageID shouldSave:shouldSave];
            
            [pool drain];
        });
    }
    else {
        [self markCDMessageFailedPrivate:messageID shouldSave:shouldSave];
    }
}


/*!
 @abstract Reset message to newly created state
 
 */
- (void) markCDMessageCreated:(NSString *)messageID {
    
    dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
    
    // run sync to make sure we finish this before doing anything else
    //
    dispatch_sync(backQueue, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // get message object
        //
        // look for a matching ID
        CDMessage *cdMessage = [CDMessage cdMessageWithID:messageID isMadeHere:[NSNumber numberWithBool:YES]];
        
        
        cdMessage.state = [NSNumber numberWithInt:kCDMessageStateOutCreated];
        cdMessage.createDate = [NSDate date];
        
        [AppUtility cdSaveWithIDString:@"ChatM: mark creatd" quitOnFail:NO];            


        [pool drain];
    });
}


/*!
 @abstract Deletes message given it's ID
 
 */
- (void) deleteCDMessage:(NSString *)messageID {
    
    dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
    
    // run sync to make sure we finish this before doing anything else
    //
    dispatch_sync(backQueue, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // get message object
        //
        // look for a matching ID
        CDMessage *cdMessage = [CDMessage cdMessageWithID:messageID isMadeHere:[NSNumber numberWithBool:YES]];
        [CDMessage deleteMessage:cdMessage];
        
        [pool drain];
    });
}




#pragma mark - Test

/*!
 @abstract Keep sending message to echo until failure
 */
- (void) runEchoTestPrivate {
    
    NSString *payLoad = @"The standard Lorem Ipsum passage, used since the 1500s Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Section 1.10.32 of de Finibus Bonorum et Malorum, written by Cicero in 45 BCSed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?1914 translation by H. RackhamBut I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness. No one rejects, dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure. To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it? But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?Section 1.10.33 of de Finibus Bonorum et Malorum, written by Cicero in 45 BCAt vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.1914 translation by H. RackhamOn the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains.consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Section 1.10.32 of de Finibus Bonorum et Malorum, written by Cicero in 45 BCSed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?1914 translation by H. RackhamBut I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness. No one rejects, dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure. To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it? But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?Section 1.10.33 of de Finibus Bonorum et Malorum, written by Cicero in 45 BCAt vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur a";    
    self.isEchoTestOn = YES;
    static int messageNumber = 0;
    
    CDContact *testContact = [CDContact getContactWithUserID:kEchoUserID];
    
    NSString *text = [NSString stringWithFormat:@"test-1-%d:\n%@", messageNumber, payLoad];
    
    CDMessage *newCDMessage = [CDMessage outCDMessageForContacts:[NSArray arrayWithObject:testContact] messageType:kCDMessageTypeText text:text attachmentData:nil shouldSave:YES];
    
    // used to look for response
    self.echoMessageID = newCDMessage.mID;
    
    // sends this message
    //
    [self sendCDMessage:newCDMessage];
    
    NSManagedObjectID *objectID = [newCDMessage objectID];
    
    // post notification for scroll view to show new message
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION object:[NSArray arrayWithObject:objectID]];
    });
    
    
    /*
    NSString *text1 = [NSString stringWithFormat:@"test-2-%d", messageNumber];
    
    CDMessage *newCDMessage1 = [CDMessage outCDMessageForContacts:[NSArray arrayWithObject:testContact] messageType:kCDMessageTypeText text:text1 attachmentData:nil shouldSave:YES];
    
    // sends this message
    //
    [[MPChatManager sharedMPChatManager] sendCDMessage:newCDMessage1];
    
    NSString *text2 = [NSString stringWithFormat:@"test-3-%d", messageNumber];
    
    CDMessage *newCDMessage2 = [CDMessage outCDMessageForContacts:[NSArray arrayWithObject:testContact] messageType:kCDMessageTypeText text:text2 attachmentData:nil shouldSave:YES];
    
    // sends this message
    //
    [[MPChatManager sharedMPChatManager] sendCDMessage:newCDMessage2];
    
    
    NSString *text3 = [NSString stringWithFormat:@"test-4-%d", messageNumber];
    
    CDMessage *newCDMessage3 = [CDMessage outCDMessageForContacts:[NSArray arrayWithObject:testContact] messageType:kCDMessageTypeText text:text3 attachmentData:nil shouldSave:YES];
    
    // sends this message
    //
    [[MPChatManager sharedMPChatManager] sendCDMessage:newCDMessage3];
    
    */
    messageNumber++;
    
}

/*!
 @abstract Keep sending message to echo until failure
 */
- (void) runEchoTest {
    
    // always run in background
    //
    if (dispatch_get_current_queue() != [AppUtility getBackgroundMOCQueue]) {
        
        dispatch_queue_t backQueue = [AppUtility getBackgroundMOCQueue];
        
        // protect attributes in netQueue
        //
        dispatch_async(backQueue, ^{
            
            [self runEchoTestPrivate];
            
        });
    }
    else {
        [self runEchoTestPrivate];
    }
}




@end
