//
//  MPContactManager.h
//  mp
//
//  Created by M Tsai on 11-9-7.
//  Copyright 2011年 TernTek. All rights reserved.
//

/*!
 @header MPContactManager
 
 Data model manager for CDContacts.  Each view controller should instantiate it's own CM to help display contacts.
 
 A single background CM is created to help run global processes such as:
  - request contact info updates to M+ servers
  - handling network updates responses and properly update the DB
 
 @copyright TernTek
 @updated 2011-11-20
 @meta http-equiv="refresh" content="0;http://www.terntek.com"
 */

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>


/*! 
 Reload main thread data model and reload tableview 
 - object is NSSet of contacts' userID that should be reloaded 
 */
extern NSString* const MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION;

/*! just reload tableview, data was not changed, but indexing has */
extern NSString* const MP_CONTACTMANAGER_RELOAD_TABLE_NOTIFICATION;

/*! index tableviews, since we may have added new contacts */
extern NSString* const MP_CONTACTMANAGER_INDEX_NOTIFICATION;


/*! phone sync has started */
extern NSString* const MP_CONTACTMANAGER_PHONESYNC_START_NOTIFICATION;

/*! phone sync has completed */
extern NSString* const MP_CONTACTMANAGER_PHONESYNC_COMPLETE_NOTIFICATION;

/*! blocked users recovered */
extern NSString* const MP_CONTACTMANAGER_BLOCKED_RECOVERED_NOTIFICATION;



@class MPMessage;
@class TTCollationWrapper;
@class CDContact;

@interface MPContactManager : NSObject {
    
    ABAddressBookRef addressBook;
    NSMutableDictionary *addressBookDictionary;
    NSArray *sortedRecordIDKeys;
    NSMutableArray *lastSyncContacts;
    BOOL isSyncRunning;
    BOOL isSyncPending;
    
    NSArray *contacts;
    NSMutableDictionary *userIDToContactsD;
    TTCollationWrapper *collation;
    NSMutableArray *filteredContacts;
    
    NSArray *currentGroupMemberIDs;
    NSString *currentGroupMemberSectionTitle;
    NSString *currentGroupMemberIndexTitle;
    
    NSInteger numberOfPhonesInAddressBook;
    BOOL didAddressBookChange;
    BOOL shouldCheckForAddressBookChangeManually;

    NSDate *lastABCallBackDate;
    
}


@property (nonatomic, assign) ABAddressBookRef addressBook;

/*! 
 @abstract dictionary that hold contact info from iPhone AB 
 @discussion This keep state of AB contacts while we are querying presence info to find friends 
 
 Note: this should be flushed when going to background, so new contacts can be synced - to avoid stale info
 
 */ 
@property (nonatomic, retain) NSMutableDictionary *addressBookDictionary;

/*! @abstract sorts recordID of AB dictionary and saves it here. Used to iterate through dictionary. */
@property (nonatomic, retain) NSArray *sortedRecordIDKeys;

/*! @abstract contacts that were last sent to be synced, keeps state to use when async response comes back */
@property (nonatomic, retain) NSMutableArray *lastSyncContacts;

/*! @abstract indicates that sync is currently running, acts as resource lock so we don't start it again */
@property (assign) BOOL isSyncRunning;

/*! @abstract indicates that sync is going to start soon, so dont try to start another sync */
@property (assign) BOOL isSyncPending;


/*!
 @abstract array of CDContacts cached 
 - for background queue only!
 */
@property (nonatomic, retain) NSArray *contacts;


/*! 
 @abstract datamodel that translates userID to a contact object 
 - mainthread only!
 - used for collation 
 */
@property (nonatomic, retain) NSMutableDictionary *userIDToContactsD;

/*! 
 @abstract collation object to organize contacts for table views 
 - mainthread only!
 */
@property (nonatomic, retain) TTCollationWrapper *collation;

/*! 
 @abstract search result contacts 
 - mainthread only
 */
@property (nonatomic, retain) NSMutableArray *filteredContacts;




/*! 
 @abstract objectID of contacts are already in group for group invitations
 @discussion If attribute is defined, then these contacts should be added to top of the table and left out in other sections
 
 Use:
 - can also be used to represent already selected contacts
 */
@property (nonatomic, retain) NSArray *currentGroupMemberIDs;

/*! text that appears on the section bar for group member section */
@property (nonatomic, retain) NSString *currentGroupMemberSectionTitle;

/*! short text that appears on the index for group member section - keep less than 4 chars */
@property (nonatomic, retain) NSString *currentGroupMemberIndexTitle;



/*! @abstract the number of phones used to determine if we should run phone sync  */
@property (nonatomic, assign) NSInteger numberOfPhonesInAddressBook;

/*! @abstract did addressbook change from last run - also used to check if phone sync should occur */
@property (nonatomic, assign) BOOL didAddressBookChange;

/*! Should we check if AB was changed after reading in AB info? */
@property (nonatomic, assign) BOOL shouldCheckForAddressBookChangeManually;

/*! Last date we AB callback marked AB as dirty */
@property (nonatomic, retain) NSDate *lastABCallBackDate;

// app status
+ (void) clearFriendBadgeCount;
+ (void) updateFriendBadgeCount;

// contact list 
- (void) flushState;
- (void) markAddressBookAsChangedFromABCallBack:(BOOL)fromABCallBack;
- (void) reloadContacts;
- (NSInteger) getNewFriendCount;
+ (void) makeFriend:(CDContact *)contact updateBadgeCount:(BOOL)updateCount;
+ (void) unFriend:(NSString *)contactUserID updateBadgeCount:(BOOL)updateCount;
+ (BOOL) processAddFriendNotification:(NSNotification *)notification contactToAdd:(CDContact *)addContact;


- (void) processPresenceText:(NSString *)presenceText;
- (void) processGetUserInformation:(NSArray *)presenceArray responseDictionary:(NSDictionary *)responseDictionary;


- (void) handleMessage:(MPMessage *)newMessage;

// collation 
+ (BOOL) isFriendAHelper:(CDContact *)friend;
- (void) setGroupMembers:(NSSet *)members sectionTitle:(NSString *)sectionTitle indexTitle:(NSString *)indexTitle;
- (NSArray *) getCollationContacts;
- (void) startCollationIndexing;
- (void) startCollationIndexingExcludeHelper:(BOOL)excludeHelper;

+ (void) startFriendInfoQueryInBackGroundForceStart:(BOOL)forceStart;
+ (void) tryStartingPhoneBookSyncForceStart:(BOOL)shouldForceStart delayed:(BOOL)shouldDelay;

- (void) resetPhoneSyncProcess;

// phone book
- (NSSet *) getABEmailProperties;
- (NSSet *) getABPhonePropertiesTWMobileOnly:(BOOL)twMobileOnly;
- (UIImage *) personImageWithRecordID:(NSNumber *)recordIDNumber;
- (NSString *) getMatchingPhoneString:(NSString *)phoneToMatch abRecordID:(NSNumber *)recordID;
- (NSDictionary *) personDictionaryForRecordID:(NSNumber *)recordID;


// table methods
- (BOOL) isIndexAtCountSection:(NSIndexPath *)indexPath;
- (NSInteger) numberOfTotalContactsForMode:(NSString *)modeString;
- (NSInteger) numberOfSections;
- (NSInteger) numberOfRowsInSection:(NSInteger)section;
- (CDContact *) personAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *) indexPathForPerson:(CDContact *)person;
- (NSString *) titleForHeaderInSection:(NSInteger)section;
- (NSArray *) sectionIndexTitlesForTableView;
- (NSInteger) tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;

#pragma mark - Search Methods

- (void) removeAllfilteredContacts;
- (NSInteger) searchNumberOfRowsInSection:(NSInteger)section;
- (CDContact *) searchContactAtIndexPath:(NSIndexPath *)indexPath;
- (void) filterContentForSearchText:(NSString*)searchText;
- (NSIndexPath *) searchIndexPathForPerson:(CDContact *)contact;

@end
