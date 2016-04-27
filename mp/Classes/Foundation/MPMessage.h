//
//  MPMessage.h
//  mp
//
//  Created by M Tsai on 11-9-1.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString* const kMPMessageTypeLogin;
extern NSString* const kMPMessageTypeLogout;
extern NSString* const kMPMessageTypeSent;
extern NSString* const kMPMessageTypeDelivered;
extern NSString* const kMPMessageTypeRead;
extern NSString* const kMPMessageTypeAccept;
extern NSString* const kMPMessageTypeReject;
extern NSString* const kMPMessageTypeInput;

extern NSString* const kMPMessageTypeChat;
extern NSString* const kMPMessageTypeNickname;
extern NSString* const kMPMessageTypeGroupChat;
extern NSString* const kMPMessageTypeImage;
extern NSString* const kMPMessageTypeFindFriends;
extern NSString* const kMPMessageTypePresence;

extern NSString* const kMPMessageTypeGroupChatLeave;
extern NSString* const kMPMessageTypeImage;
extern NSString* const kMPMessageTypeAudio;
extern NSString* const kMPMessageTypeVideo;
extern NSString* const kMPMessageTypeFile;
extern NSString* const kMPMessageTypeContact;
extern NSString* const kMPMessageTypeCall;
extern NSString* const kMPMessageTypeHeadShot;
extern NSString* const kMPMessageTypeLocation;

// container message
extern NSString* const kMPMessageTypeMultimsg;

// schedule message
extern NSString* const kMPMessageTypeSchedule;
extern NSString* const kMPMessageTypeScheduleDelete;

extern NSString* const kMPMessageNetworkPing;
extern NSString* const kMPMessageNetworkAck;


// Parameter Keys
//
extern NSString* const kMPMessageKeyID;
extern NSString* const kMPMessageKeyFrom;
extern NSString* const kMPMessageKeyTo;
extern NSString* const kMPMessageKeySequence;
extern NSString* const kMPMessageKeyAttachLength;
extern NSString* const kMPMessageKeyCause;
extern NSString* const kMPMessageKeyGroupID;
extern NSString* const kMPMessageKeyText;


extern NSString* const kMPMessageKeyFilename;
extern NSString* const kMPMessageKeyDomain;
extern NSString* const kMPMessageKeyFromAddress;
extern NSString* const kMPMessageKeyOperator;
extern NSString* const kMPMessageKeyLanguage;
extern NSString* const kMPMessageKeySentTime;
extern NSString* const kMPMessageKeyIcon;
extern NSString* const kMPMessageKeyCommand;

extern NSString* const kMPMessageKeySticker;

/*! letter ID paramter in @image message */
extern NSString* const kMPMessageKeyLetter;


// group chat params
extern NSString* const kMPMessageKeyAction;
extern NSString* const kMPMessageKeyEnter;
extern NSString* const kMPMessageKeyWithoutPN;
extern NSString* const kMPMessageKeyWithPN;
extern NSString* const kMPMessageKeyWithoutQueue;


extern NSString* const kMPMessageKeyAppVersion;
extern NSString* const kMPMessageKeyDeviceModel;

extern NSString* const kMPMessageKeyBadgeCount;

extern NSString* const kMPMessageKeyUserID;
extern NSString* const kMPMessageKeyNickName;

extern NSString* const kMPMessageKeySchedule;
extern NSString* const kMPMessageKeyScheduleTime;

/*!
 
 These are attributes that are often used by most messages.
 The remaining attributes can be found in properties dictionary.

 */

@interface MPMessage : NSObject {
    
    NSString *mType;
    NSString *mID;
    NSString *groupID;
    NSArray *to;
    NSString *from;
    NSString *text;
    NSString *sequence;
    NSUInteger attachLength;
    NSUInteger cause;
    NSMutableDictionary *properties;
    NSData *attachmentData;
    NSData *previewImageData;

}



/*! @abstract type and function of message */
@property(nonatomic, retain) NSString *mType;

/*! @abstract message ID */
@property(nonatomic, retain) NSString *mID;

/*! @abstract group chat ID */
@property(nonatomic, retain) NSString *groupID;

/*! @abstract destination of message */
@property(nonatomic, retain) NSArray *to;

/*! @abstract source of message */
@property(nonatomic, retain) NSString *from;

/*! @abstract text string of message */
@property(nonatomic, retain) NSString *text;

@property(nonatomic, retain) NSString *sequence;
@property(nonatomic, assign) NSUInteger attachLength;
@property(nonatomic, assign) NSUInteger cause;
@property(nonatomic, retain) NSMutableDictionary *properties;

/*! attachment data to send out */
@property(nonatomic, retain) NSData *attachmentData;

/*! preview image of data */
@property(nonatomic, retain) NSData *previewImageData;


- (id) initWithID:(NSString *)msgID 
             type:(NSString *)type 
          groupID:(NSString *)aGroupID 
               to:(NSArray *)toArray 
             from:(NSString *)fromString 
             text:(NSString *)textString
         sequence:(NSString *)sequenceString 
       attachData:(NSData *)attachData 
      previewData:(NSData *)preData
         filename:(NSString *)filename;


/*!
 @abstract constructs a new message given raw data from the network
 
 @discussion This method will scan through the message looking for special reserved characters
 such as: ?,=,&.  While scanning, the method will store the message types and key value pairs
 that it encounters.
 
 @return autoreleased MPMessage that represents network message
 
 - ignore message length
 - message type
 - read in key and values
 ~ handle each property: save as attribute or into properties dictionary
 
 example:
 
 00061@login?id=2011082328260333000001&from=20121312&to=1020345
 
 */
+ (MPMessage *)messageWithData:(NSData *)data;
+ (NSArray *)messagesWithData:(NSData *)data;

/*!
 @abstract create raw data from this message
 
 @discussion Create a the NSData object from this message object.  This used to send
 messages over the network.
 
 @return NSData representation suitable for net transmission
 
 - construct the string using object properties
 - prepend message length to the start of the message
 - convert to NSData
 
 example:
 00061@login?id=2011082328260333000001&from=20121312&to=1020345
 
 */
- (NSData *)rawNetworkData;
- (MPMessage *)generateReplyWithMessageType:(NSString *)messageType;
- (NSString *) toAddressString;

/*!
 @abstract get value for non-core properties stored in the properties dictionary
 */
- (NSString *)valueForProperty:(NSString *)messageKey;
- (BOOL) isFromSelf;


/*!
 @abstract gets the NSDate when message was sent
 
 @return date if successful, nil if no date
 
 */
- (NSDate *)sentDate;

/*!
 @abstract get sequence number
 */
- (NSNumber *)sequenceNumber;

/*!
 @abstract get the total number of messages in this sequence
 */
- (NSNumber *)sequenceTotal;



- (NSArray *)toContactsDictionaries;
- (NSDictionary *)fromContactsDictionary;
- (BOOL) isChatContentType;
- (BOOL) isChatStateUpdate;
- (BOOL) isChatDialogUpdate;
- (NSString *) senderUserID;


/*!
 @abstract Generates a login message
 
 @return login MPMessage including userID and authentication key
 
 example:
 00061@login?id=2011082328260333000001&from=20121312&to=1020345
 
 */
+ (MPMessage *)messageLoginIsSuspend:(BOOL)isSuspend;
+ (MPMessage *)messageLogoutIsSuspend:(BOOL)isSuspend;

+ (MPMessage *)messageHeadshotSmallImage:(UIImage *)smallImage largeImage:(UIImage *)largeImage;
+ (MPMessage *)deleteScheduleMessage:(NSString *)messageID;
+ (MPMessage *)deliveredMessageForBlocked;
+ (MPMessage *)deliveredMessageDummyWithID:(NSString *)aMessageID;


/*!
 @abstract Generates a text chat message
 
 @return text chat MPMessage
 
 example:
 @chat?id=xxxx&to=xxx&from=10021233[Beer]@61.66.229.110&text=xxxx
 
 */
+ (MPMessage *)messageChatTo:(NSString *)toString textMessage:(NSString *)messageString;

/*!
 @abstract Generates a nickname update
 
 @return text nickname MPMessage
 
 example:
 @nickname?id=x&text=Beer
 
 */
+ (MPMessage *)messageNickname;

+ (MPMessage *)messageFindFriends:(NSArray *)phoneNumbers;
+ (MPMessage *)messageGroupChat;
+ (MPMessage *)messageImage:(UIImage *)image;
+ (MPMessage *)messageTest;

// encoding
+ (NSString *)decodeDSParameter:(NSString *)rawString;
+ (NSString *)encodeDSParameter:(NSString *)rawString;

- (NSString *)downloadURL;

@end
