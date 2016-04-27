//
//  CDMessage.h
//  mp
//
//  Created by M Tsai on 11-9-20.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MPImageSource.h"


/*!
 @abstract available message types shown in the UI
 
 @discussion This lets the ViewController know how to display and handle the message
 
 Container: can combine multiple messages such as a photo album
 
 GroupEnter: when someone joins this chat
 GroupLeave: when someone leaves this chat
 
 */
typedef enum {
	kCDMessageTypeText = 0,
    kCDMessageTypeTextGroup = 1,
    kCDMessageTypeCall = 2,
    kCDMessageTypeSticker = 3,
    kCDMessageTypeStickerGroup = 4,
    kCDMessageTypeImage = 10,
    kCDMessageTypeAudio = 11,
    kCDMessageTypeVideo = 12,
    kCDMessageTypeFile = 13,
    kCDMessageTypeContact = 14,
    kCDMessageTypeLetter = 15,
    kCDMessageTypeLocation = 16,
    kCDMessageTypeGroupEnter = 20,
    kCDMessageTypeGroupLeave = 21,
    kCDMessageTypeContainer = 100
} CDMessageType;


/*!
 @abstract Possible Errors
 
 */
enum CDMessageError {
    kCDMessageErrorSaveFailed = 0,
	kCDMessageErrorInvalidAddress = 1,
    kCDMessageErrorDuplicateMID = 2
};



/*!
 @abstract message delivery status
 
 @discussion 
 
 State can be used to tell if message is inbound or outbound!
 out        for messages originated at this client
 in         for messages received by this client
 
 
 Created        created by client, but not sent (DS has not successfully received)
 Sent           received by network services
 SentBlocked    artificially sent out since other p2p user blocked you!
 SentFailed     msg failed to sent out
 
 Delivered      received by remote user's client
 Read           seen by other user
 Scheduled      DS has accepted this message and has queued it for delivery
                - assigned to both parent and child messages
 ReadDownloaded only for in messages. Read and also downloaded (Letter show different image)
 
 note: delivered and read only makes sense for 1:1 messages
 group chat need to track this individually
 
 == Transient Attributes ==
 previewImage       Holds preview image if it was loaded before
 fileData           attachement data for the attached file
 
 */
typedef enum {
	kCDMessageStateOutCreated = 1,
    kCDMessageStateOutSent = 2,
	kCDMessageStateOutDelivered = 3,
	kCDMessageStateOutRead = 4,
	kCDMessageStateOutScheduled = 5,
    kCDMessageStateOutSentBlocked = 6,
    kCDMessageStateOutFailed = 7,
    
    kCDMessageStateInDelivered = 10,
    kCDMessageStateInRead = 11,
    kCDMessageStateInReadDownloaded = 12
} CDMessageState;

@class MPMessage;
@class CDChat, CDContact, CDMessage, CDResource;

@interface CDMessage : NSManagedObject {
    
    // transient attributes
    UIImage *previewImage;
    NSData *fileData;
    CDResource *stickerResource;
    
@private
}
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) NSString * downloadURL;
@property (nonatomic, retain) NSNumber * sequenceNumber;
@property (nonatomic, retain) NSString * mID;
@property (nonatomic, retain) NSNumber * type;

/*! when object was created, used for dialog sorting */
@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSDate * sentDate;
@property (nonatomic, retain) NSDate * lastStateDate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * sequenceTotal;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * attachLength;
@property (nonatomic, retain) CDMessage * parentMessage;

/*! contacts who were sent this message */
@property (nonatomic, retain) NSSet * contactsTo;
@property (nonatomic, retain) NSSet * messages;

/*! contacts who read this message */
@property (nonatomic, retain) NSSet * contactsRead;

/*! who wrote this message */
@property (nonatomic, retain) CDContact * contactFrom;

/*! conctacts who got this message */
@property (nonatomic, retain) NSSet* contactsDelivered;

/*! conctacts who entered this chat */
@property (nonatomic, retain) NSSet* contactsEntered;

@property (nonatomic, retain) CDChat * chat;
@property (nonatomic, retain) CDChat * lastForChat;
@property (nonatomic, retain) CDChat * lastForChatPrevious;


/*! this message is written by me and created with this client app */
@property (nonatomic, retain) NSNumber * isMadeHere;

/*!
 @abstract When this message will be scheduled by the DS for delivery
 
 This is marks a message as a parent scheduled message.
 */
@property (nonatomic, retain) NSDate * dateScheduled;


/*!
 @abstract Should we show this message?
 
 Used to hide scheduled messages that have not been sent out yet.
 - parent and child messages are hidden at first

 */
@property (nonatomic, retain) NSNumber *isHidden;


/*!
 @abstract Is this a scheduled message?
 
 Used to check if we should show this message: if msg just came in and we are viewing a dialog
 
 */
@property (nonatomic, retain) NSNumber *isScheduled;


/*!
 @abstract Extra info that is type specific
 
 If only one data needed store directly.  If multiple values required use JSON format in the future.
 
 Use:
 - Letter msg type: store letterID
 */
@property (nonatomic, retain) NSString *typeInfo;



// temp properties
@property (nonatomic, retain) UIImage *previewImage;
@property (nonatomic, retain) NSData *fileData;
@property (nonatomic, retain) CDResource *stickerResource;



/*! was a read receipt sent for this message - used to make sure this was sent */
@property (nonatomic, retain) NSNumber * didSendReadReceipt;

+ (void) batchFetch:(NSArray *)messages;

+ (NSArray *) messageForPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fetchLimit:(NSInteger)fetchLimit batchSize:(NSInteger)batchSize getAsFaults:(BOOL)getAsFaults;
+ (NSArray *) messageForPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fetchLimit:(NSInteger)fetchLimit batchSize:(NSInteger)batchSize;

+ (NSArray *) messagesForChat:(CDChat *)relatedChat acending:(BOOL)ascending limit:(NSInteger)limit;
+ (NSArray *) messagesForChat:(CDChat *)relatedChat;

+ (void) deleteFilesForMessages:(NSSet *)messages;
+ (BOOL) clearMessages:(NSSet *)messages;
+ (void) deleteMessage:(CDMessage *)deleteMsg;
+ (void) deleteMessageWithID:(NSString *)messageID;
+ (void) deleteFailedScheduledMessages;

+ (void) markOutCreatedAsOutFailed;

+ (NSArray *) allMessages;
+ (NSArray *) scheduledMessages;
+ (NSUInteger) scheduledMessagesCount;


+ (CDMessage *) cdMessageWithID:(NSString *)messageID isMadeHere:(NSNumber *)isMadeHere;
+ (CDMessage *) cdMessageFromInComingMPMessage:(MPMessage *)mpMessage 
                                        cdChat:(CDChat *)newChat 
                                    shouldSave:(BOOL)shouldSave 
                                         error:(NSError **)anError;

+ (CDMessage *) outCDMessageForChat:(CDChat *)chat 
                        messageType:(CDMessageType)messageType 
                               text:(NSString *)text 
                     attachmentData:(id)attachmentObject
                        isMulticast:(BOOL)isMulticast 
                 multicastParentMID:(NSString *)multicastParentMID
                multicastToContacts:(NSSet *)multicastToContacts
                      dateScheduled:(NSDate *)dateScheduled 
                        hideMessage:(BOOL)hideMessage 
                           typeInfo:(NSString *)typeInfo
                         shouldSave:(BOOL)shouldSave;

+ (CDMessage *) outCDMessageForChat:(CDChat *)chat 
                           messageType:(CDMessageType)messageType 
                                  text:(NSString *)text 
                        attachmentData:(id)attachmentObject
                            shouldSave:(BOOL)shouldSave;

+ (CDMessage *) outCDMessageForContacts:(NSArray *)toContacts
                               messageType:(CDMessageType)messageType 
                                      text:(NSString *)text 
                            attachmentData:(id)attachmentObject
                                shouldSave:(BOOL)shouldSave;

+ (CDMessage *) outCDMessageForChatObjectID:(NSManagedObjectID *)objectID
                                messageType:(CDMessageType)messageType 
                                       text:(NSString *)text 
                             attachmentData:(id)attachmentObject
                                 shouldSave:(BOOL)shouldSave;
+ (CDMessage *) forwardMessage:(CDMessage *)originalMessage toChat:(CDChat *)forwardChat;

- (BOOL) markDeliveredForUserID:(NSString *)userID;
- (BOOL) markReadForUserID:(NSString *)userID;
- (void) updateChat:(CDChat *)newChat;
- (void) revealHidden;

// image & attachment
- (NSString *) sequenceString;
- (NSData *) previewImageData;
- (NSString *) getDownloadURL;
- (UIImage *) fullImage;
- (NSData *) getFileData;

// query
- (BOOL) isType:(CDMessageType)testType; 
- (BOOL) isFromSelf;
- (BOOL) isSentFromSelf;
- (BOOL) isGroupControlMessage;
- (BOOL) shouldAddToDialog;
- (BOOL) isInboundNotRead;
- (NSMutableSet *) getAllParticipants;
- (CDMessageState) getStateValue;


// display
- (NSString *) getStateString;
- (NSString *) getSentTimeString;
- (NSString *) displayName;
- (NSString *) getDescriptionString;

@end


@interface CDMessage (CoreDataGeneratedAccessors)

- (void)addContactsToObject:(CDContact *)value;
- (void)removeContactsToObject:(CDContact *)value;
- (void)addContactsTo:(NSSet *)value;
- (void)removeContactsTo:(NSSet *)value;

- (void)addMessagesObject:(CDMessage *)value;
- (void)removeMessagesObject:(CDMessage *)value;
- (void)addMessages:(NSSet *)value;
- (void)removeMessages:(NSSet *)value;

- (void)addContactsDeliveredObject:(CDContact *)value;
- (void)removeContactsDeliveredObject:(CDContact *)value;
- (void)addContactsDelivered:(NSSet *)value;
- (void)removeContactsDelivered:(NSSet *)value;

- (void)addContactsReadObject:(CDContact *)value;
- (void)removeContactsReadObject:(CDContact *)value;
- (void)addContactsRead:(NSSet *)value;
- (void)removeContactsRead:(NSSet *)value;

- (void)addContactsEnteredObject:(CDContact *)value;
- (void)removeContactsEnteredObject:(CDContact *)value;
- (void)addContactsEntered:(NSSet *)value;
- (void)removeContactsEntered:(NSSet *)value;

@end
