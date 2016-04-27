//
//  CDContact.h
//  mp
//
//  Created by M Tsai on 11-9-7.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

/*!
 @header CDContact
 
 CDContact represents contacts for MP service.
 
 Usage:
  * contacts will be created and update using presence results
 

 
 @copyright TernTek
 @updated 2011-09-07
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import "MPImageSource.h"


@class CDChat, CDMessage;
@class MPPresence;

/*!
 @abstract available contact states
 
 @discussion other states may be available in the future
 
 */
typedef enum {
	MPContactStateNormal = 0,
    MPContactStateBlocked = 1
} MPContactState;


/*!
 @abstract presence states for contact
 
 @discussion other states may be available in the future
 
 MPContactPresenceStateAccountCanceled  Account was deleted by user
 MPContactPresenceStateOffline          User is offline
 MPContactPresenceStateOnline           User is online
 MPContactPresenceStateOff              User has turned presence permission off
 
 */
typedef enum {
    MPContactPresenceStateAccountCanceled = -1,
	MPContactPresenceStateOffline = 0,
    MPContactPresenceStateOnline = 1,
    MPContactPresenceStateOff = 2
} MPContactPresenceState;



@interface CDContact : NSManagedObject <MFMessageComposeViewControllerDelegate, MPImageSource> {
@private
}


@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * domainServerName;
@property (nonatomic, retain) NSString * domainClusterName;
@property (nonatomic, retain) NSString * statusMessage;

/*! @abstract phone number that is registered in M+, so we know which number to call */
@property (nonatomic, retain) NSString * registeredPhone;

/*! @abstract phonebook name - updated upon phonebook sync */
@property (nonatomic, retain) NSString * abName;

/*! 
 @abstract phonebook recordID, this indicates that this is a phonebook contact 

 @discussion -1 default value = invalid recordID so recordID must be > -1 to use
 */
@property (nonatomic, retain) NSNumber * abRecordID;

@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSNumber * presenceState;
@property (nonatomic, retain) NSNumber * headshotSerialNumber;
@property (nonatomic, retain) NSNumber * contactState;
//@property (nonatomic, retain) NSNumber * isFriend;
@property (nonatomic, retain) NSNumber * isBlocked;

@property (nonatomic, retain) NSDate * lastLoginDate;

/*! If defined, then contact is a friend - detect if new friend */
@property (nonatomic, retain) NSDate * addFriendDate;

/*! When contact was added - sort by addDate for friend suggestions & detect new suggestions */
@property (nonatomic, retain) NSDate * addDate;


@property (nonatomic, retain) NSSet* chats;
@property (nonatomic, retain) NSSet* messages;


// CD Query
+ (NSArray *) allContacts;
+ (void) deleteAllContacts;
+ (NSArray *) allValidFriends;
+ (NSArray *) allValidContacts;
+ (NSArray *) blockedContacts;
+ (NSArray *) suggestedContacts;
+ (NSUInteger) newSuggestedContactsCount;
+ (NSUInteger) newFriendContactsCount;


// CD Update
+ (CDContact *) contactForPresence:(MPPresence *)presenceObject
                            create:(BOOL)shouldCreate
                       addAsFriend:(BOOL)addAsFriend
                  onlyAddIfCreated:(BOOL)onlyAddIfCreated
                  updateBadgeCount:(BOOL)updateCount
                 updatePhoneNumber:(BOOL)updatePhoneNumber
                              save:(BOOL)shouldSave;


+ (CDContact *) contactWithUserID:(NSString *)aUserID
                         nickName:(NSString *)aNickName
                 domainServerName:(NSString *)aServer
                domainClusterName:(NSString *)aCluster
                    statusMessage:(NSString *)aStatus
                   headShotNumber:(NSInteger)aHeadShot
                         presence:(NSInteger)aPresence
                        loginDate:(NSDate *)aLoginDate
                      addAsFriend:(BOOL)addAsFriend
                       shouldSave:(BOOL)shouldSave
                     shouldUpdate:(BOOL)shouldUpdate;

+ (CDContact *)mySelf;
+ (void)updateMyNickname:(NSString *)nickName 
       domainClusterName:(NSString *)clusterName 
        domainServerName:(NSString *)serverName 
           statusMessage:(NSString *)sMessage;
+ (CDContact *) getContactWithUserID:(NSString *)aUserID;
+ (CDContact *) getContactWithABRecordID:(NSNumber *)recordID;

// query methods
//

- (BOOL) isMySelf;
- (NSString *)userAddressIncludeDomain:(BOOL)includeDomain;
- (NSString *)presenceString;
- (BOOL)isOnline;
- (NSString *)displayName;
- (BOOL) isNewFriend;
- (BOOL) isNewFriendSuggestion;
- (BOOL) isFriend;
- (BOOL) isSyncedFromPhoneBook;
- (BOOL) isInAddressBook;
- (BOOL) hasBlockedMe;
- (BOOL) isBlockedByMe;
- (BOOL) isUserAccountedCanceled;
- (NSString *) oneLineStatusMessage;

// action
- (void) makeFriend;
- (void) unFriend;
- (void) blockUser;
- (void) unBlockUser;
- (void) callRegisteredPhone;
- (void) smsRegisteredPhone;

@end
