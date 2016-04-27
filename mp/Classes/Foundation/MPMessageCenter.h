//
//  MPMessageCenter.h
//  mp
//
//  Created by M Tsai on 11-9-5.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>


/*! when a sent reply is received for important message - object = messageID */
extern NSString* const MP_MESSAGECENTER_SENT_CONFIRMATION_NOTIFICATION;

/*! if timeout occurred and "accept/reject" or "sent" ack was not received */
extern NSString* const MP_MESSAGECENTER_SENT_TIMEOUT_NOTIFICATION;

/*! got an accept reply for a message */
extern NSString* const MP_MESSAGECENTER_ACCEPT_CONFIRMATION_NOTIFICATION;

/*! got a reject reply for a message */
extern NSString* const MP_MESSAGECENTER_REJECT_CONFIRMATION_NOTIFICATION;


@class  MPMessage;

/*
 Keep this class stateless and only use class methods
 */
@interface MPMessageCenter : NSObject {

    NSMutableSet *messageIDsRequiringWriteBufferConfirmation;
    NSMutableSet *messageIDsRequiringSentConfirmation;
    NSMutableSet *messageIDsRequiringAcceptRejectConfirmation;
    
    NSMutableDictionary *messageIDFromTag;
    
    CGFloat currentWriteTimeout;
    NSDate *lastWriteDate;
    
    NSMutableArray *timeOutTimers;
    
    NSTimer *disconnectTimeoutTimer;
    NSMutableArray *pendingMPMessages;
}


/*!
 @abstract creates singleton object
 */
+ (MPMessageCenter *)sharedMPMessageCenter;

/*! messageIDs that need write buffer confirmation - protect in network queue */
@property (nonatomic, retain) NSMutableSet *messageIDsRequiringWriteBufferConfirmation;

/*! messageIDs that need sent confirmation - protect in network queue */
@property (nonatomic, retain) NSMutableSet *messageIDsRequiringSentConfirmation;

/*! messageIDs that need accept/reject confirmation - protect in network queue */
@property (nonatomic, retain) NSMutableSet *messageIDsRequiringAcceptRejectConfirmation;


/*! converts messageTag to messageID */
@property (nonatomic, retain) NSMutableDictionary *messageIDFromTag;


/*! allows write timeout to dynamically change - should increase if successive large writes made*/
@property (nonatomic, assign) CGFloat currentWriteTimeout;

/*! last time when large write was made */
@property (nonatomic, retain) NSDate *lastWriteDate;

/*! timeout timers are stored here - protect in main queue */
@property (nonatomic, retain) NSMutableArray *timeOutTimers;

/*! when to timeout all pending messages after a disconnect occurs */
@property (nonatomic, retain) NSTimer *disconnectTimeoutTimer;

/*! Stores messages in case we need to sent them out again */
@property (nonatomic, retain) NSMutableArray *pendingMPMessages;


/*!
 @abstract process message data
 
 @discuss Does the following for incoming network data
 - create message object from data
 - dispatch this message to the interested managers to handle the message
 
 */
- (void) processInComingMessageData:(NSData *)inMessageData;

/*!
 @abstract Sents out message to the network
 
 @discusssion currently sends directly to network center for encapsulation.
 
 In the future we can consider setting priority queues if required
 
 */
- (void) processOutGoingMessage:(MPMessage *)outMessage;
- (void) processOutGoingMessageWithConfirmation:(MPMessage *)outMessage enableAcceptRejectConfirmation:(BOOL)enabledAcceptReject ;

- (void) didWriteBufferForMessageID:(long)messageTag;

@end
