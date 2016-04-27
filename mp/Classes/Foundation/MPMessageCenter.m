//
//  MPMessageCenter.m
//  mp
//
//  Created by M Tsai on 11-9-5.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "MPMessageCenter.h"
#import "MPFoundation.h"

#import "MPChatManager.h"

#import "SynthesizeSingleton.h"

NSString* const MP_MESSAGECENTER_SENT_CONFIRMATION_NOTIFICATION = @"MP_MESSAGECENTER_SENT_CONFIRMATION_NOTIFICATION";
NSString* const MP_MESSAGECENTER_SENT_TIMEOUT_NOTIFICATION = @"MP_MESSAGECENTER_SENT_TIMEOUT_NOTIFICATION";

NSString* const MP_MESSAGECENTER_ACCEPT_CONFIRMATION_NOTIFICATION = @"MP_MESSAGECENTER_ACCEPT_CONFIRMATION_NOTIFICATION";
NSString* const MP_MESSAGECENTER_REJECT_CONFIRMATION_NOTIFICATION = @"MP_MESSAGECENTER_REJECT_CONFIRMATION_NOTIFICATION";


@interface MPMessageCenter (Private)
- (void) messageTimedOut:(NSString *)messageID;
@end


@implementation MPMessageCenter

@synthesize messageIDsRequiringWriteBufferConfirmation;
@synthesize messageIDsRequiringSentConfirmation;
@synthesize messageIDsRequiringAcceptRejectConfirmation;
@synthesize messageIDFromTag;

@synthesize currentWriteTimeout;
@synthesize lastWriteDate;

@synthesize timeOutTimers;
@synthesize disconnectTimeoutTimer;
@synthesize pendingMPMessages;

SYNTHESIZE_SINGLETON_FOR_CLASS(MPMessageCenter);


- (id)init {
    
    self = [super init];
    if (self) {
        
        // listen for socket write failures
        // - to delete group chats
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processDisconnect:) name:MP_SOCKETCENTER_DISCONNECT_LOGIN_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processConnectSuccess:) name:MP_SOCKETCENTER_CONNECT_SUCCESS_NOTIFICATION object:nil];
 
        // if session starts up, then cleanup previous session info
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanUpSession:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        self.currentWriteTimeout = kMPParamNetworkTimeoutWriteToBuffer;
        self.lastWriteDate = [NSDate date];
        
        NSMutableArray *tOArray = [[NSMutableArray alloc] init];
        self.timeOutTimers = tOArray;
        [tOArray release];
        
    }    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [messageIDsRequiringAcceptRejectConfirmation release];
    [messageIDsRequiringWriteBufferConfirmation release];
    [messageIDsRequiringSentConfirmation release];
    [messageIDFromTag release];
    
    [timeOutTimers release];
    [lastWriteDate release];
    [disconnectTimeoutTimer release];
    [pendingMPMessages release];
    
    [super dealloc];
}

#pragma mark - Tools

/*!
 @abstract Post notification failure
 */
- (void) postFailure:(NSString *)messageID {
    
    // update message state first
    // - so UI can use this info to update view
    [[MPChatManager sharedMPChatManager] markCDMessageFailed:messageID shouldSave:YES];
    
    // then send notification to UI components
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_MESSAGECENTER_SENT_TIMEOUT_NOTIFICATION object:messageID];
    });
    
}

/*!
 @abstract Save tag for later lookup to restore original messageID
 
 */
- (void) saveTag:(long)tag forMessage:(NSString *)messageID {

    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    
    if (!self.messageIDFromTag) {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.messageIDFromTag = newD;
        [newD release];
    }
    
    NSString *tagString = [NSString stringWithFormat:@"%ld", tag];
    [self.messageIDFromTag setValue:messageID forKey:tagString];
    
    DDLogVerbose(@"MC: save tag - %@ - %@ - %@", tagString, messageID, self.messageIDFromTag);

    
}


/*!
 @abstract Post notification failure
 */
- (NSString *) getMessageIDForTag:(long)tag {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    
    if (!self.messageIDFromTag) {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.messageIDFromTag = newD;
        [newD release];
        DDLogWarn(@"MC: get msgID but tag dictionary not available!");
    }
    
    NSString *tagString = [NSString stringWithFormat:@"%ld", tag];
    NSString *mID = [self.messageIDFromTag valueForKey:tagString];
    
    DDLogVerbose(@"MC: get tag - %@ - %@ - %@", tagString, mID, self.messageIDFromTag);

    [self.messageIDFromTag removeObjectForKey:tagString];

    return mID;
}


#pragma mark - Sent Confirmation

/*!
 @abstract remove message with given ID from pending message
 */
- (void) removePendingMessageForID:(NSString *)messageID {
    
    MPMessage *messageToRemove = nil;
    
    for (MPMessage *iMsg in self.pendingMPMessages) {
        if ([iMsg.mID isEqualToString:messageID]) {
            messageToRemove = iMsg;
            break;
        }
    }
    
    if (messageToRemove) {
        [self.pendingMPMessages removeObject:messageToRemove];
    }
}

/*!
 @abstract Register message id for confirmation
 
 */
- (void) registerForSentConfirmationWithMessageID:(NSString *)messageID enableAcceptRejectConfirmation:(BOOL)enabledAcceptReject mpMessage:(MPMessage *)mpMessage {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");

    if (!self.messageIDsRequiringWriteBufferConfirmation) {
        NSMutableSet *newSet = [[NSMutableSet alloc] init];
        self.messageIDsRequiringWriteBufferConfirmation = newSet;
        [newSet release];
    }
    [self.messageIDsRequiringWriteBufferConfirmation addObject:messageID];
    
    if (!self.messageIDsRequiringSentConfirmation) {
        NSMutableSet *newSet = [[NSMutableSet alloc] init];
        self.messageIDsRequiringSentConfirmation = newSet;
        [newSet release];
    }
    [self.messageIDsRequiringSentConfirmation addObject:messageID];
    
    // also register for accept reject confirmation
    if (enabledAcceptReject) {
        if (!self.messageIDsRequiringAcceptRejectConfirmation) {
            NSMutableSet *newSet = [[NSMutableSet alloc] init];
            self.messageIDsRequiringAcceptRejectConfirmation = newSet;
            [newSet release];
        }
        [self.messageIDsRequiringAcceptRejectConfirmation addObject:messageID];
    }
    
    // save actual message to resend if needed
    if (!self.pendingMPMessages) {
        NSMutableArray *newArray = [[NSMutableArray alloc] init];
        self.pendingMPMessages = newArray;
        [newArray release];
    }
    // if already in list don't add the message
    // - this prevents mutating while pendingMPMessages is being enumerated
    //
    if ([self.pendingMPMessages indexOfObject:mpMessage] == NSNotFound) {
        [self.pendingMPMessages addObject:mpMessage];
    }
}



/*!
 @abstract Inform MC that message was successfully written to buffer
 */
- (void) didWriteBufferForMessageID:(long)messageTag {

    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");

    // convert tag back to messageID
    //
    NSString *mID = [self getMessageIDForTag:messageTag];
    
    // if message is registered then send out notification
    if ([self.messageIDsRequiringWriteBufferConfirmation member:mID]) {
        
        DDLogVerbose(@"MC: write FIN - %@", mID);
        // don't monitor it any more
        // - this also lets timeout block know we finished writing
        [self.messageIDsRequiringWriteBufferConfirmation removeObject:mID];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // start write timeout timer
            NSTimer *sendTimer = [NSTimer scheduledTimerWithTimeInterval:kMPParamNetworkTimeoutWaitForConfirmation target:self selector:@selector(messageTimedOut:) userInfo:mID repeats:NO];
            [self.timeOutTimers addObject:sendTimer];
        });
        
        /*dispatch_queue_t netQ = [AppUtility getQueueNetwork];
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, kMPParamNetworkTimeoutWaitForConfirmation * NSEC_PER_SEC);
        
        // start second phase timer to wait for DS confirmation message to come back
        //
        dispatch_after(delay, netQ, ^{
            [self messageTimedOut:mID];
        });*/
    }
    else {
        DDLogVerbose(@"MC: write FIN no match - %@ - %@ - %@", mID, self.messageIDsRequiringWriteBufferConfirmation, self.messageIDFromTag);
    }
}


/*!
 @abstract Check if confirmation is needed, if so then post a notification
 */
- (void) checkIfSentConfirmationNeeded:(NSString *)messageID {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    // if not in AR then remove from pending
    if (![self.messageIDsRequiringAcceptRejectConfirmation member:messageID]) {
        [self removePendingMessageForID:messageID];
    }
    
    // if message is registered then send out notification
    if ([self.messageIDsRequiringSentConfirmation member:messageID]) {
        
        // don't monitor it any more
        // - this also lets timeout block know we got the sent ack!
        [self.messageIDsRequiringSentConfirmation removeObject:messageID];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_MESSAGECENTER_SENT_CONFIRMATION_NOTIFICATION object:messageID];
        });
    }    
}

/*!
 @abstract Check if confirmation is needed, if so then post a notification
 
 @param didAccept - is an accept message, else an reject message
 @return didNotify - if so, then message does not need to be forwarded, just notify is enough
 
 */
- (BOOL) checkIfAcceptRejectConfirmationNeeded:(NSString *)messageID didAccept:(BOOL)didAccept message:(MPMessage *)message {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    // remove if message exists in pending array
    //
    [self removePendingMessageForID:messageID];
    
    BOOL didNotify = NO;
    // if message is registered then send out notification
    if ([self.messageIDsRequiringAcceptRejectConfirmation member:messageID]) {
        
        // don't monitor it any more
        // - this also lets timeout block know we got the sent ack!
        [self.messageIDsRequiringAcceptRejectConfirmation removeObject:messageID];
        
        // create userinfo dictionary
        //
        NSString *cause = [message valueForProperty:kMPMessageKeyCause];
        NSDictionary *userInfo = nil;
        if ([cause length] > 0) {
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:cause, kMPMessageKeyCause, nil];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (didAccept) {
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_MESSAGECENTER_ACCEPT_CONFIRMATION_NOTIFICATION object:messageID ];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:MP_MESSAGECENTER_REJECT_CONFIRMATION_NOTIFICATION object:messageID userInfo:userInfo];
            }

        });
        didNotify = YES;
    }    
    return didNotify;
}




#pragma mark - Timeout Handlers

/*!
 @abstract Confirm is write buffer was successful - Phase I
 
 Check write buffer set
 - mID present:         write buffer didn't finish ==> send out notif & return 
 ~ don't clear msg registration, in case ack comes back later
 - mID not present:     write buffer finished ==> do nothing & continue
 
 */
- (void) writeBufferTimedOut:(NSTimer *)timer {
    
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");
    
    NSString *messageID = [timer userInfo];
    
    // remove timer since it is done
    [self.timeOutTimers removeObject:timer];
    
    dispatch_async([AppUtility getQueueNetwork], ^{
        // if write buffer has not finished yet
        // - timeout and send fail notif
        if ([self.messageIDsRequiringWriteBufferConfirmation member:messageID]) {
            DDLogInfo(@"MC: write buffer TOut - %@", messageID);
            [self postFailure:messageID];
        } 
        // else - write finished properly already & removed mID, do nothing
    });

}


/*!
 @abstract Message confirmation timed out, check if sent ack received.
 
 Accept and Reject(AR) checked first since these are the most important if they are registered.  Since 
 for registered AR messages getting a "sent" ack does not really mean anything.  They can only proceed if an AR ack
 comes back.
 
 Check accept/reject first
 - mID present:         accept/reject not recieved ==> send out notif & return 
                        ~ don't clear msg registration, in case ack comes back later
 - mID not present:     accept/reject received or never registered ==> do nothing & continue
 
 Check sent:
 - mID present:         sent not received ==> send out failure notif & return
                        ~ don't clear message registration, in case sent ack comes back later
 - mID not present:     sent received == then do nothing & continue
 
 */
- (void) messageTimedOut:(NSTimer *)timer {
    
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");
    
    NSString *messageID = [timer userInfo];

    // remove from array since it has finished running
    [self.timeOutTimers removeObject:timer];
    
    dispatch_async([AppUtility getQueueNetwork], ^{
        // if accept/reject ack has not cleared message yet
        // - timeout and send fail notif
        if ([self.messageIDsRequiringAcceptRejectConfirmation member:messageID]) {
            
            [self postFailure:messageID];
        } 
        
        // if sent ack has not cleared message yet
        // - timeout and send fail notif
        if ([self.messageIDsRequiringSentConfirmation member:messageID]) {
            
            [self postFailure:messageID];
            
        }    
        // else - sent ack already removed mID, do nothing
    });
}


/*!
 @abstract Timeout all message and notify observers
 
 Use:
 - cancel timers when disconnect event occurs.  
    ~ Timers not needed since we will timeout messages together and not on individual timers.
 
 */
- (void) timeoutAllMessages {
    
    //NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    dispatch_async([AppUtility getQueueNetwork], ^{
        
        // only unique strings from each set will appear in notifyMessages
        NSSet *notifyMessages = [self.messageIDsRequiringSentConfirmation setByAddingObjectsFromSet:self.messageIDsRequiringAcceptRejectConfirmation];
        
        // clear out all messages, so timeout fire later will not do anything
        [self.messageIDsRequiringWriteBufferConfirmation removeAllObjects];
        [self.messageIDsRequiringSentConfirmation removeAllObjects];
        [self.messageIDsRequiringAcceptRejectConfirmation removeAllObjects];
        
        [self.pendingMPMessages removeAllObjects];
        
        // send notification to all registered messages
        //
        DDLogInfo(@"MC: TOut all messages: %@", notifyMessages);
        for (NSString *iMessageID in notifyMessages) {
            [self postFailure:iMessageID];
        }
        
    });
    

    
    // invalidate all timers
    /*dispatch_async(dispatch_get_main_queue(), ^{
    
        for (NSTimer *iTimer in self.timeOutTimers) {
            [iTimer invalidate];
        }
        [self.timeOutTimers removeAllObjects];
        
    });*/
}

/*!
 @abstract Process connect (logged in) notification from SC
 
 - invalidate timeout all timer
 - resend any pending messages
 
 */
- (void) processConnectSuccess:(NSNotification *)notification {
    

    DDLogInfo(@"MC-pcs: connect event");
    [self.disconnectTimeoutTimer invalidate];

    
    // find messages that should be sent again
    //
    dispatch_async([AppUtility getQueueNetwork], ^{
        
        // resend each message
        for (MPMessage *iMsg in self.pendingMPMessages) {
            
            // send out message again
            // - no need for AR confirmation, since mID should still be there.
            // 
            [self processOutGoingMessageWithConfirmation:iMsg enableAcceptRejectConfirmation:NO];
            
        }
        
    });
}

/*!
 @abstract Process disconnect notification from SC
 
 - timeout and drain all pending messages
 
 */
- (void) processDisconnect:(NSNotification *)notification {
    
    DDLogInfo(@"MC-pd: disconnect event");

    // timeout pending messages in a little bit
    //
    // remove all individual timers
    // - these are only valid if we are still connected
    //
    for (NSTimer *iTimer in self.timeOutTimers) {
        [iTimer invalidate];
    }
    [self.timeOutTimers removeAllObjects];
    
    if (![self.disconnectTimeoutTimer isValid]) {
        self.disconnectTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kMPParamNetworkTimeoutFreshDisconnect target:self selector:@selector(timeoutAllMessages) userInfo:nil repeats:NO];
    }
    
    /*
    // always run in network queue
    //
    dispatch_queue_t netQ = [AppUtility getQueueNetwork];
    
    if (dispatch_get_current_queue() != netQ) {
        
        dispatch_async(netQ, ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            [self timeoutAllMessages];
            [pool drain];
        });
    }
    else {
        [self timeoutAllMessages];
    }*/
}


/*!
 @abstract Reset values associated with this session
 
 Use:
 - call at the end of this session to clean our pending buffer messages
   ~ messages don't need to recover between sessions.
 
 */
- (void) cleanUpSession:(NSNotification *)notification {
    
    [self timeoutAllMessages];
    
}


#pragma mark - Message Handling



/*!
 @abstract Sents out message to the network
 
 @discusssion currently sends directly to network center for encapsulation.
 - socket center is thread safe so no need to change queues here
 
 */
- (void) processOutGoingMessage:(MPMessage *)outMessage {
    
    
    NSData *outData = [outMessage rawNetworkData];
    [[AppUtility getSocketCenter] addDataToWriteQueue:outData];
    
    
}

/*!
 @abstract Sents out message to the network
 
 @discusssion Adds timeout to write operations views is informed about write failure
 
 */
- (void) privateProcessOutGoingMessageWithConfirmation:(MPMessage *)outMessage enableAcceptRejectConfirmation:(BOOL)enabledAcceptReject {
    
    dispatch_queue_t netQ = [AppUtility getQueueNetwork];
    NSAssert(dispatch_get_current_queue() == netQ, @"Must be dispatched on netQueue");
    
    // get string that we can pass to other threads
    NSString *outMessageID = [NSString stringWithString:outMessage.mID];
    
    // fail if network is not available
    //
    /*if (![[AppUtility getSocketCenter] isNetworkReachable]) {
        DDLogInfo(@"MC: msg fail - no net: %@", outMessage.mID);
        [self postFailure:outMessageID];
        return;
    }*/
    
    // If not logged in
    // - tell SC to login asap
    // - and fail
    //
    if (![[AppUtility getSocketCenter] isLoggedIn]) {
        [[AppUtility getSocketCenter] resetRetry];
        
        // if disconnect still fresh, register message to send out when connection recovers
        //
        if ([[AppUtility getSocketCenter] isDisconnectFresh]) {
            DDLogInfo(@"MC: disconnect still fresh, register msgID: %@", outMessage.mID);
            [self registerForSentConfirmationWithMessageID:outMessageID enableAcceptRejectConfirmation:enabledAcceptReject mpMessage:outMessage];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // also start a disconnect timer if there is not on already running
                if (![self.disconnectTimeoutTimer isValid]) {
                    self.disconnectTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kMPParamNetworkTimeoutFreshDisconnect target:self selector:@selector(timeoutAllMessages) userInfo:nil repeats:NO];
                }
            });
            
        }
        // if not stale disconnect, then fail the message
        else {
            DDLogInfo(@"MC: msg fail - no CNT: %@", outMessage.mID);
            [self postFailure:outMessageID];
        }
        return;
    }
    
    NSData *outData = [outMessage rawNetworkData];
    NSDate *currentDate = [NSDate date];
    
    NSTimeInterval timeDiff = [currentDate timeIntervalSinceDate:self.lastWriteDate];
    
    // write was written recently
    // - increase timeout
    // - assume 10kbytes/sec
    //
    if ( (self.currentWriteTimeout - timeDiff) > kMPParamNetworkTimeoutWriteToBuffer*.5 ) {
        
        CGFloat extendTime = [outData length]/kMPParamNetworkMinUploadSpeed;
        
        // how much longer to finish
        // - new timeout
        CGFloat timeLeftToFinish = self.currentWriteTimeout - timeDiff + extendTime;
        
        // but at least the default value
        //
        self.currentWriteTimeout = MAX(timeLeftToFinish, kMPParamNetworkTimeoutWriteToBuffer);
    }
    else {
        CGFloat estTime = [outData length]/kMPParamNetworkMinUploadSpeed;
        self.currentWriteTimeout = MAX(estTime, kMPParamNetworkTimeoutWriteToBuffer);
    }
    
    self.lastWriteDate = currentDate;
    
    DDLogInfo(@"MC: write w/TOut %f", self.currentWriteTimeout);
    
    // always run in network queue
    //

    // Register for confirmations
    //
    [self registerForSentConfirmationWithMessageID:outMessageID enableAcceptRejectConfirmation:enabledAcceptReject mpMessage:outMessage];
    
    // Start timer
    //
    if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            // start write timeout timer
            NSTimer *writeTimer = [NSTimer scheduledTimerWithTimeInterval:self.currentWriteTimeout target:self selector:@selector(writeBufferTimedOut:) userInfo:outMessageID repeats:NO];
            [self.timeOutTimers addObject:writeTimer];            
            [pool drain];
        });
    }
    else {
        // start write timeout timer
        NSTimer *writeTimer = [NSTimer scheduledTimerWithTimeInterval:self.currentWriteTimeout target:self selector:@selector(writeBufferTimedOut:) userInfo:outMessageID repeats:NO];
        [self.timeOutTimers addObject:writeTimer];
    }
    

    
    /* don't use dispatch since we can't cancel these
     
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, self.currentWriteTimeout * NSEC_PER_SEC);
    // start a timer to wait for write buffer to finish
    //
    dispatch_after(delay, netQ, ^{
        [self writeBufferTimedOut:outMessageID];
    }); 
    */
    
    
    // write to SC
    // - no timeout, but sent it our tag to able to check progress
    //
    long messageTag = [AppUtility getTagWithMessageID:outMessageID];
    [[AppUtility getSocketCenter] addDataToWriteQueue:outData timeout:-1.0 tag:messageTag];
    
    // Save messageID
    //
    [self saveTag:messageTag forMessage:outMessageID];

}

/*!
 @abstract Sents out message to the network
 
 @discusssion Adds timeout to write operations views is informed about write failure
 
 */
- (void) processOutGoingMessageWithConfirmation:(MPMessage *)outMessage enableAcceptRejectConfirmation:(BOOL)enabledAcceptReject {
    
    // Save messageID
    //
    dispatch_queue_t netQ = [AppUtility getQueueNetwork];

    if (dispatch_get_current_queue() != netQ) {
        
        dispatch_async(netQ, ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            [self privateProcessOutGoingMessageWithConfirmation:outMessage enableAcceptRejectConfirmation:enabledAcceptReject];
            [pool drain];
        });
    }
    else {
        [self privateProcessOutGoingMessageWithConfirmation:outMessage enableAcceptRejectConfirmation:enabledAcceptReject];
    }
}


/*!
 @abstract process message data
 
 @discuss Does the following for incoming network data
 - create message object from data
 - dispatch this message to the interested managers to handle the message
 
 This should be running on the networkQueue since it is only called by the socket center
 - jobs should also be sent to the appropriate queues
 
 */
- (void) processInComingMessageData:(NSData *)inMessageData {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getQueueNetwork], @"Must be dispatched on networkQueue");
    
    NSArray *messages = [MPMessage messagesWithData:inMessageData];
    
    BOOL shouldTurnOnBatchProcessing = NO;
    
    MPMessage *lastMessage = [messages lastObject];
    
    // if multimessage than start batch processing
    if ([lastMessage.mType isEqualToString:kMPMessageTypeMultimsg]) {
        
        if ([messages count] >= kMPParamChatMessageBatchProcessingMessageCountMin) {
            shouldTurnOnBatchProcessing = YES;
        }
        
        if (shouldTurnOnBatchProcessing) {
            [[MPChatManager sharedMPChatManager] startBatchMessageProcessing];
        }
    }
    
    for (MPMessage *inMessage in messages) {
        //MPMessage *inMessage = [MPMessage messageWithData:inMessageData];

        // if multimessage than stop batch processing
        if ([inMessage.mType isEqualToString:kMPMessageTypeMultimsg] && shouldTurnOnBatchProcessing) {
            [[MPChatManager sharedMPChatManager] stopBatchMessageProcessing];
        }
        
        if ([inMessage.mType isEqualToString:kMPMessageTypeAccept]) {
            // check if confirmation is needed
            // - if so, then it is not a login or logout message
            //
            if (![self checkIfAcceptRejectConfirmationNeeded:inMessage.mID didAccept:YES message:inMessage]) {
                [[AppUtility getSocketCenter] handleMessage:inMessage];
            }
        }
        else if ([inMessage.mType isEqualToString:kMPMessageTypeReject]) {
            if (![self checkIfAcceptRejectConfirmationNeeded:inMessage.mID didAccept:NO message:inMessage]) {
                [[AppUtility getSocketCenter] handleMessage:inMessage];
            }        
        }
        // if contact related messages
        //
        else if ([inMessage.mType isEqualToString:kMPMessageTypePresence]){
            
            dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
            
            dispatch_async(back_queue, ^{
                [[AppUtility getBackgroundContactManager] handleMessage:inMessage];
            });
        }
        // if chat related messages
        //
        else if ([inMessage isChatContentType]){
            
            [[MPChatManager sharedMPChatManager] handleMessage:inMessage];
            
        }
        // if status updates
        //
        else if ([inMessage isChatStateUpdate]){
            
            [[MPChatManager sharedMPChatManager] handleMessage:inMessage];
            
            // ~ check in for updates
            //   if sent is not received, other states can act as confirmation instead.
            //
            // send notification if confirmation requested
            //if ([inMessage.mType isEqualToString:kMPMessageTypeSent]) {
                
                // always run in network queue
                //
                dispatch_queue_t netQ = [AppUtility getQueueNetwork];
                if (dispatch_get_current_queue() != netQ) {
                    
                    dispatch_async(netQ, ^{
                        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                        [self checkIfSentConfirmationNeeded:inMessage.mID];
                        [pool drain];
                    });
                }
                else {
                    [self checkIfSentConfirmationNeeded:inMessage.mID];
                }
                
            //}
        }
        else if ([inMessage isChatDialogUpdate]) {
            
            [[MPChatManager sharedMPChatManager] handleMessage:inMessage];
            
        }
        else {
            DDLogError(@"MC: unknown in-coming msg %@", inMessage);
        }
    }
}

@end
