//
//  CDChat.h
//  mp
//
//  Created by M Tsai on 11-9-20.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/*! inform that this chat was cleared - object: this chat objectID */
extern NSString* const MP_CHAT_CLEAR_HISTORY_NOTIFICATION;

/*!
 @abstract Chat name style formats
 
 Full       Regular name
 Title      Appends number of participants for group chat
 */
typedef enum {
	kCDChatNameStyleFull,
   	kCDChatNameStyleTitle
} CDChatNameStyle;


@class CDContact, CDMessage;

@interface CDChat : NSManagedObject {
    
    // transient attributes
    BOOL isBrandNew;
    
    BOOL lastMsgIsFromMe;
    BOOL lastMsgDidFail;
    NSString *lastMsgText;
    NSString *lastMsgDateString;
    NSUInteger unreadMsgNumber;
    
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * alertState;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * groupID;
@property (nonatomic, retain) CDMessage *lastMessage;
@property (nonatomic, retain) CDMessage *lastMessagePrevious;
@property (nonatomic, retain) NSDate * lastUpdateDate;

/*! text left in textfield when we last left the chat room */
@property (nonatomic, retain) NSString * pendingText;

/*! is chat a hiddenchat? */
@property (nonatomic, retain) NSNumber * isHiddenChat;

@property (nonatomic, retain) NSSet* messages;
@property (nonatomic, retain) NSSet* participants;


// Transient 

/*! mark if this is a brand new chat just created: used to add group chat add-control messages - transient */
@property (nonatomic, assign) BOOL isBrandNew;

/*! did I send last message */
@property(nonatomic, assign) BOOL lastMsgIsFromMe;

/*! did last message fail */
@property(nonatomic, assign) BOOL lastMsgDidFail;

/*! text of last message */
@property(nonatomic, retain) NSString *lastMsgText;

/*! last message date */
@property(nonatomic, retain) NSString *lastMsgDateString;

/*! unread message number */
@property(nonatomic, assign) NSUInteger unreadMsgNumber;




+ (NSArray *) allChats;
+ (void) deleteChat:(CDChat *)deleteChat;
+ (void) deleteAllChats;

+ (CDChat *) chatWithCDContacts:(NSArray *)contacts 
                        groupID:(NSString *)groupID 
        checkForNewGroupInvites:(BOOL)checkInvites 
                   shouldCreate:(BOOL)shouldCreate
                     shouldSave:(BOOL)shouldSave 
                    shouldTouch:(BOOL)shouldTouch;

+ (CDChat *) chatWithCDContacts:(NSArray *)contacts 
                        groupID:(NSString *)groupID 
        checkForNewGroupInvites:(BOOL)checkInvites 
                   shouldCreate:(BOOL)shouldCreate
                     shouldSave:(BOOL)shouldSave;

+ (CDChat *) chatWithCDContacts:(NSArray *)contacts 
                        groupID:(NSString *)groupID 
        checkForNewGroupInvites:(BOOL)checkInvites
                     shouldSave:(BOOL)shouldSave;

+ (CDChat *) chatWithCDContacts:(NSArray *)contacts 
                        groupID:(NSString *)groupID 
                     shouldSave:(BOOL)shouldSave;
+ (CDChat *) getChatForGroupID:(NSString *)groupID;

+ (void) clearAllHiddenChat;
+ (NSArray *) chatsIsHidden:(BOOL)isHidden;
+ (void) clearAllChatHistory;


// query
- (NSArray *) sortedParticipants;
- (NSString *) displayNameStyle:(CDChatNameStyle)style;
- (BOOL) isEqualToChat:(CDChat *)otherChat;
- (NSArray *) sortedMessages;
- (NSArray *)sortedMessagesBySentDate;
- (NSUInteger) numberOfUnreadMessages;
- (BOOL) isGroupChat;
- (BOOL) totalParticipantCount;
- (CDContact *) p2pUser;
- (NSString *) p2pUserID;
- (void) printParticipantIDs;
- (BOOL) isUserIDInChat:(NSString *)searchUserID;

// last message
- (CDMessage *) lastMessageFromDB;
- (NSString *) lastMessageText;
//- (NSString *) lastMessageTextUsingDB;
- (NSString *) lastMessageTextForLast2Messages:(NSArray *)chatMessages;

// action
- (void) markAllInDeliveredMessageRead;
- (void) addContactsToGroupChat:(NSArray *)contacts;
- (void) removeContactsFromGroupChat:(NSArray *)contacts;
- (BOOL) clearChatHistory;

@end



@interface CDChat (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(CDMessage *)value;
- (void)removeMessagesObject:(CDMessage *)value;
- (void)addMessages:(NSSet *)value;
- (void)removeMessages:(NSSet *)value;

- (void)addParticipantsObject:(CDContact *)value;
- (void)removeParticipantsObject:(CDContact *)value;
- (void)addParticipants:(NSSet *)value;
- (void)removeParticipants:(NSSet *)value;

@end