//
//  CDContact.m
//  mp
//
//  Created by M Tsai on 11-9-7.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "CDContact.h"
#import "CDChat.h"
#import "CDMessage.h"

#import "MPFoundation.h"
#import "MPContactManager.h"


/*! domain IP for users who have blocked you */
NSString* const kMPParamUserBlockedYouDomainIP = @"0.0.0.0";

/*!
 
 addFriendDate      when person was added as a friend - used to check if contact is friend and is new 
 isFriend           - deprecated - use addFriendDate instead
 isBlocked          was this person blocked
 domainServerName   the specific server that user was logged into - connect to for faster perf.
 domainClusterName  the cluster that users belongs to
 
 
 */

@implementation CDContact
@dynamic userID;
@dynamic presenceState;
@dynamic headshotSerialNumber;
@dynamic nickname;

@dynamic lastLoginDate;
@dynamic addFriendDate;
@dynamic addDate;

@dynamic domainServerName;
@dynamic domainClusterName;
@dynamic statusMessage;
@dynamic contactState;
@dynamic chats;
@dynamic messages;
//@dynamic isFriend;
@dynamic isBlocked;
@dynamic abRecordID;
@dynamic abName;
@dynamic registeredPhone;


#pragma mark - Default Methods

/*!
 @abstract initialization for each object
 
 @discussion 
 
 called right when new object is inserted and before user has chance to modify
 - setup addDate, this is used to check if this contact is new frined suggestion.  Compared with saved setting
 
 */
- (void) awakeFromInsert {
    
    // set add date to right now
    self.addDate = [NSDate date];
	[super awakeFromInsert];
    
}


#pragma mark - CD Query 


/*!
 @abstract gets contacts that meets predicate requirements
 
 @param fetchLimit limits the number of fetches returned -1 means no limit
 @return success - array of resources, fail - nil no resource found
 
 */
+ (NSArray *) contactsForPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fetchLimit:(NSInteger)fetchLimit {
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
	// load resource if it already exists
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    [fetchRequest setEntity:entity];
    
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
    if (sortDescriptors) {
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    if (fetchLimit > 0) {
        [fetchRequest setFetchLimit:fetchLimit];
    }
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    return results;
}


/*!
 @abstract get all available CD Contacts
 
 @discuss queries CD to get all available CDContacts
 
 @return
 success		array of CDContacts
 fail			nil
 
 */
+ (NSArray *) allContacts {
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    [fetchRequest setEntity:entity];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    return results;
}

/*!
 @abstract deletes all contacts
 
 @discuss if account is deleted
 
 @return
 success		delete every contacts in DB
 
 */
+ (void) deleteAllContacts {
    
    NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	NSArray *allContacts = [CDContact allContacts];
    for (CDContact *iContact in allContacts){
        [managedObjectContext deleteObject:iContact];
    }
    [AppUtility cdSaveWithIDString:@"CNT-delete all contacts!" quitOnFail:NO];
}

/*!
 @abstract get all valid friends
 
 @discussion queries CD to get contacts who are friend that can be contacted
 
  - addFriendDate exists
  - isBlocked == NO
 
 @return
 success		array of CDContacts
 fail			nil
 
 */
+ (NSArray *) allValidFriends {
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // add date exists & not blocked
    NSDate *referenceDate = [NSDate dateWithTimeIntervalSince1970:2000000];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(addFriendDate > %@) AND (isBlocked != YES)", referenceDate];

    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    return results;
}

/*!
 @abstract get all valid contacts 
 
 @discussion queries CD to get contacts who are contacts that are not blocked
 - isBlocked == NO
 
 @return
 success		array of CDContacts
 fail			nil
 
 */
+ (NSArray *) allValidContacts {
    
    // add date exists & not blocked
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(isBlocked != YES)"];
        
    // Then execute fetch it
    NSArray *results = [self contactsForPredicate:pred sortDescriptors:nil fetchLimit:-1];
    
    return results;
}

/*!
 @abstract returns all contacts who are blocked
 
 @discussion we want most recent added friends at the top and non-friends at the bottom
  - so sort by addFriendDate decending
 
 @return
 success		array of CDContacts
 fail			nil
 
 */
+ (NSArray *) blockedContacts {
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // add blocked users
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(isBlocked == %@)",[NSNumber numberWithBool:YES]];  //@"(isBlocked == YES)"];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"addFriendDate" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];
    [fetchRequest setSortDescriptors:sortDescriptors];    
    [sortDescriptors release];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    return results;
}


/*!
 @abstract get contact who are not yet friends
 
 @discussion queries CD to get contacts who are friend that can be contacted
 
 - addFriendDate is null
 - isBlocked == NO
 - presence is not canceled account
 
 @return
 success		array of CDContacts
 fail			nil
 
 */
+ (NSArray *) suggestedContacts {
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // add date exists & not blocked
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(addFriendDate == %@) AND (isBlocked != YES) AND (presenceState != %@) AND (userID != %@)", 
                         [NSDate dateWithTimeIntervalSince1970:0], 
                         [NSNumber numberWithInt:MPContactPresenceStateAccountCanceled], 
                         [[MPSettingCenter sharedMPSettingCenter] getUserID] ];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"addDate" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [sortDescriptors release];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    return results;
}


/*!
 @abstract get contact count who are not yet friends
 
 @discussion queries CD to get contacts who are friend that can be contacted
 
 - addFriendDate is null
 - isBlocked == NO
 - presence is not canceled account
 
 @return
 success		array of CDContacts
 fail			nil
 
 */
+ (NSUInteger) newSuggestedContactsCount {
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSDate *lastViewDate = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAppEnterBackgroundAfterViewingFriendSuggestionDate];
    
    // add date exists & not blocked
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(addFriendDate == %@) AND (addDate > %@) AND (isBlocked != YES) AND (presenceState != %@) AND (userID != %@)", 
                         [NSDate dateWithTimeIntervalSince1970:0],
                         lastViewDate,
                         [NSNumber numberWithInt:MPContactPresenceStateAccountCanceled], 
                         [[MPSettingCenter sharedMPSettingCenter] getUserID] ];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];
    
    // Then execute fetch it
    NSError *error = nil;
    NSUInteger count = [managedObjectContext countForFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    return count;
}

/*!
 @abstract get contact count who are new friends
 
 @discussion queries CD to get contacts who are friend that can be contacted

 
 @return count of contacts
 
 */
+ (NSUInteger) newFriendContactsCount {
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSDate *lastResignDate = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAppResignActiveAfterViewingFriendDate];
    NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    
    NSUInteger count = 0;
    if (lastResignDate && userID) {
        
        // add friend date is new
        // - not blocked
        // - not cancelled account
        // - not myself
        //
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(addFriendDate > %@) AND (isBlocked != YES) AND (presenceState != %@) AND (userID != %@)",
                             lastResignDate,
                             [NSNumber numberWithInt:MPContactPresenceStateAccountCanceled], 
                             userID];
        
        [fetchRequest setEntity:entity];
        [fetchRequest setPredicate:pred];
        
        // Then execute fetch it
        NSError *error = nil;
        count = [managedObjectContext countForFetchRequest:fetchRequest error:&error];
    }
    [fetchRequest release];

    return count;
}



#pragma mark - CD Update

/*!
 @abstract gets CDContacts that matches the provided to/from addresses
 
 @param addAsFriend     should this contact be considered a friend
 @param shouldSave      should we save to CD right away?
 @param shouldUpdate    should we update contact data if it already exists
                        - If this info is coming from a message, then NO.  
                          This is because data directly from PS should be more reliable.
 Note:
 - a generic method to create or find a contact
 - use NSNotFound for integer parameters if none is provided and nil for object params
 
 Use:
 - update presence information
 - get contacts related to a CDMessage from a MPMessage's attributes
 
 
 */
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
                     shouldUpdate:(BOOL)shouldUpdate {
    
    DDLogVerbose(@"CT-cwuid: get contact U:%@ N:%@ F:%@ D:%@", aUserID, aNickName, aServer, aCluster);
    
    
    // need a user id to get contact
    if (![AppUtility isUserIDValid:aUserID]) {
        return nil;
    }
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(userID == %@)",aUserID];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    CDContact *resultContact = nil;
    
    // if this contact already exists
    if ([results count] > 0) {
        
        resultContact = [results objectAtIndex:0];
        
        // if no need to update, then just return the found contact w/o modification
        if (!shouldUpdate) {
            return resultContact;
        }
        
    }
    // create a new contact object and return it
    //
    else {
        
        resultContact = [NSEntityDescription insertNewObjectForEntityForName:[entity name] 
                                                      inManagedObjectContext:managedObjectContext];
        resultContact.userID = aUserID;
    }
    
    // only update results if they are available!
    //
    if (resultContact) {
        
        if ([aNickName length] > 0) {
            resultContact.nickname = aNickName;
        }
        if (aCluster) {
            resultContact.domainClusterName = aCluster;
        }
        if (aServer) {
            resultContact.domainServerName = aServer;
        }
        if (aStatus) {
            resultContact.statusMessage = aStatus;
        }
        
        // 0 is no headshot, if increment then new headshot is available
        //
        if (aHeadShot != NSNotFound && [resultContact.headshotSerialNumber intValue] < aHeadShot) {
            // TODO: also upload head shot here
            resultContact.headshotSerialNumber = [NSNumber numberWithInt:aHeadShot];
        }
        if (aPresence != NSNotFound) {
            resultContact.presenceState = [NSNumber numberWithInt:aPresence];
        }
        if (aLoginDate) {
            resultContact.lastLoginDate = aLoginDate;
        }
        if (addAsFriend) {
            [resultContact makeFriend];
        }
    }
    
    // save to CD
    //
    if (shouldSave) {
        
        if ([AppUtility cdSaveWithIDString:@"save contactWithUserID" quitOnFail:YES] != NULL) {
            return nil;
        }
    }
    return resultContact;
}

/*!
 @abstract Gets contacts that represents myself
 */
+ (CDContact *)mySelf {
    
    NSString *userIDString = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    
    // make sure we already have a valid user id for the user
    if (![AppUtility isUserIDValid:userIDString]) {
        return nil;
    }
    
    NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(userID == %@)",userIDString];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    CDContact *resultContact = nil;
    
    if ([results count] > 0) {
        resultContact = [results objectAtIndex:0];
    }
    // create a new contact object and return it
    //
    else {
        resultContact = [NSEntityDescription insertNewObjectForEntityForName:[entity name] 
                                                      inManagedObjectContext:managedObjectContext];
        resultContact.userID = userIDString;
        // this allows a url to be created, so we can try downloading our headshot if it is not available
        //
        // @TEMP - just start with 0 & recover from get user info
        //
        // resultContact.headshotSerialNumber = [NSNumber numberWithInteger:1]; 
        
        if ([AppUtility cdSaveWithIDString:@"save mySelf" quitOnFail:YES] != NULL) {
            return nil;
        }
    }
    
    return resultContact;
}

/*!
 @abstract update contact information
 
 only defined values are updated. nil values will not be updated
 */
+ (void)updateMyNickname:(NSString *)nickName 
       domainClusterName:(NSString *)clusterName 
        domainServerName:(NSString *)serverName 
           statusMessage:(NSString *)sMessage {
    
    CDContact *me = [CDContact mySelf];
    
    BOOL isModified = NO;
    
    if ([nickName length] > 0) {
        me.nickname = nickName;
        isModified = YES;
    }
    
    if ([clusterName length] > 0) {
        me.domainClusterName = clusterName;
        isModified = YES;
    }
    
    if ([serverName length] > 0) {
        me.domainServerName = serverName;
        isModified = YES;
    }
    
    if ([sMessage length] > 0) {
        me.statusMessage = sMessage;
        isModified = YES;
    }
    
    // save if modified
    //
    if (isModified) {
        [AppUtility cdSaveWithIDString:@"Contact: save my info" quitOnFail:NO];
    }
}


/*!
 @abstract gets CDContact that matches the userID in presence string
 - if none found, one is created
 
 @param presenceString      string with basic information of contact - see below
 @param create              should create a new object if a matching contact was not found
 @param addAsFriend         if created, should we make this contact a friend?
 @param onlyAddIfCreated    only add as friends if contact is newly created
                            ~ prevent adding friends that we unfriended from queryNoArguments
 @param updateBadgeCount    should new friend badge count be udpated after adding as a friend?
 @param updatePhoneNumber   MSISDN should be ignored if contact already exists
 @param save                should new CDPerson be saved to CD? - NO so you can save in a batch
 
 Example:
 
 0  phone-number
 1  USERID
 2  presence
 3  domain-address
 4  from-address
 5  nickname
 6  headshot
 7  logintime
 8  status
 
 (886911223344,10012345,1,61.66.229.112,192.168.1.23,John,6,<epochtime>,上班)
  - Expect presence string to be stripped of ( and )
 
 @return
 success		CDContact
 fail			nil         - neg presence state, can't save, etc.
 
 Use:
 - used to update presence from DS presence updates messages
 - used to create new contacts from GetUserInfo results
 
 */
+ (CDContact *) contactForPresence:(MPPresence *)presenceObject
                            create:(BOOL)shouldCreate
                       addAsFriend:(BOOL)addAsFriend
                  onlyAddIfCreated:(BOOL)onlyAddIfCreated
                  updateBadgeCount:(BOOL)updateCount
                 updatePhoneNumber:(BOOL)updatePhoneNumber
                              save:(BOOL)shouldSave {
    
    if (!presenceObject) {
        return nil;
    }
    
    NSString *userIDString = presenceObject.aUserID;
    
    // need a user id otherwise, there is nothing todo
    if (![AppUtility isUserIDValid:userIDString]) {
        DDLogVerbose(@"CT-cfpa: WARN - bad presence array - invalid userid - %@", presenceObject);
        return nil;
    }
    
    NSString *nickname = presenceObject.aNickname;
    NSString *domainAddress = presenceObject.aDomainAddress;
    NSString *fromAddress = presenceObject.aFromAddress;
    NSString *statusMessage = presenceObject.aStatusMessage;
    NSNumber *headshot = presenceObject.aHeadShot;
    NSNumber *presence = presenceObject.aPresence;
    NSDate *logintime = presenceObject.aLoginTime;
    NSString *phoneNumber = presenceObject.aMSISDN;
    NSNumber *recordIDNumber = presenceObject.aRecordID;
    
    // TODO: Work Around - Server needs to remove + signs
    // - allow '+' for M+ Helper
    //nickname = [nickname stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    //statusMessage = [statusMessage stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(userID == %@)",userIDString];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    CDContact *resultContact = nil;
    
    BOOL freshlyMade = NO;
    
    if ([results count] > 0) {
        resultContact = [results objectAtIndex:0];
    }
    // create a new contact object and return it
    //
    else {
        
        // If presence is -1, then this contact has cancelled their account
        // 
        if ([presence intValue] < 0) {
            DDLogVerbose(@"CT-cfpa: Don't create canceled account uid: %@", userIDString);
            return nil;
        }
        
        if (shouldCreate) {
            resultContact = [NSEntityDescription insertNewObjectForEntityForName:[entity name] 
                                                          inManagedObjectContext:managedObjectContext];
            freshlyMade = YES;
        }
        // return nil if no contact found and not created
        else {
            return nil;
        }
       
    }
    if (resultContact) {
        
        // used to compare with new presence
        //NSInteger originalPresence = [resultContact.presenceState intValue];
        
        resultContact.userID = userIDString;
        // check if valid nickname, otherwise don't update
        // - deleted account don't include nicknames
        //
        if ([nickname length] > 0) {
            resultContact.nickname = nickname;
        }
        resultContact.domainClusterName = domainAddress;
        resultContact.domainServerName = fromAddress;
        resultContact.statusMessage = statusMessage;
        resultContact.headshotSerialNumber = headshot;
        resultContact.presenceState = presence;
        resultContact.lastLoginDate = logintime;
        
        // if new contact or requested, we should udpate the phone number
        // - GetUserInfo action=query may not give the phone number format we desire
        //               action=add however, simply returns the format that we want
        // - so for "add" we want to update, for "query" we don't want to update
        if (freshlyMade || updatePhoneNumber) {
            resultContact.registeredPhone = phoneNumber;
        }
        
        if (recordIDNumber) {
            if ([recordIDNumber intValue] == 0) {
                NSLog(@"PRS:%@", presenceObject);
            }
            resultContact.abRecordID = recordIDNumber;
        }
        
        // if account canceled, remove as a friend
        // - but keep contact in DB since old messages may exist
        // - unfriend and remove from group chats
        //
        NSInteger newPresence = [presence intValue];
        if (newPresence == MPContactPresenceStateAccountCanceled) {
            //if (newPresence != originalPresence) {
                [resultContact unFriend];
                
                // remove from group chats
                NSMutableSet *removeGroupChats = [[NSMutableSet alloc] initWithCapacity:[resultContact.chats count]];
                for (CDChat *iChat in resultContact.chats) {
                    if ([iChat isGroupChat]) {
                        [removeGroupChats addObject:iChat];
                    }
                }
                [resultContact removeChats:removeGroupChats];
                [removeGroupChats release];
            //}            
        }
        else if (addAsFriend && ![resultContact isFriend]) {
            
            // if an old contact, but we only add fresh contacts as friend -> then don't add
            if (onlyAddIfCreated && !freshlyMade) {
                // don't add as friend
            }
            else {
                [resultContact makeFriend];
                if (updateCount) {
                    [MPContactManager updateFriendBadgeCount];
                }
            }
        }
    }
    
    // save to CD
    //
    if (shouldSave) {
        if ([AppUtility cdSaveWithIDString:@"save contactForPresenceArray" quitOnFail:YES] != NULL) {
            return nil;
        }
    }
    return resultContact;
}



/*!
 @abstract Get user given the userID
 
 Use:
 - to get a test user to send messages

 */
+ (CDContact *) getContactWithUserID:(NSString *)aUserID {
        
    // need a user id to get contact
    if (![AppUtility isUserIDValid:aUserID]) {
        return nil;
    }
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(userID == %@)",aUserID];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    CDContact *resultContact = nil;
    
    if ([results count] > 0) {
        resultContact = [results objectAtIndex:0];
    }
    
    return resultContact;
}



/*!
 @abstract Get user given the addressbook record ID
 
 Use:
 - get M+ user information for phonebook users
 
 */
+ (CDContact *) getContactWithABRecordID:(NSNumber *)recordID {
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDContact" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(abRecordID == %@)",recordID];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    CDContact *resultContact = nil;
    
    if ([results count] > 0) {
        resultContact = [results objectAtIndex:0];
    }
    
    return resultContact;
}




#pragma mark -
#pragma mark Query Methods


/*!
 @abstract is this contact myself?
 
 @discussion We avoid adding myself to chat participants
  
 */
- (BOOL) isMySelf {
    
    NSString *myUserID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    
    if ([myUserID isEqualToString:self.userID]) {
        return YES;
    }
    return NO;
    
}

/*!
 @abstract gets the address string for this contact using the domain server address
 
 @param useServer should we try to use the server address instead of cluster address
 
 userID[nickname]@domainServer
 
 Use:
 - server address: used by chat and gchat
 - cluster adress: used by attachment from addresses
 
 */
- (NSString *)userAddressIncludeDomain:(BOOL)includeDomain {
    
    if ([self.userID length] < 1 && [self.domainServerName length] < 1) {
        DDLogVerbose(@"CDC: Cant get address - invalid contact");
        return nil;
    }
    
    NSString *result = self.userID;
    
    
    // addresses used in MPMessages - so encode the nickname
    // - is is hard to encode later since we don't want to encode the brackets too []
    if ([self.nickname length] > 0) {
        result = [result stringByAppendingFormat:@"[%@]", [MPMessage encodeDSParameter:self.nickname]];
    }
    
    // add from address
    result = [result stringByAppendingFormat:@"@%@", self.domainServerName];

    // add domain address
    //
    if (includeDomain && [self.domainClusterName length] > 0) {
        result = [result stringByAppendingFormat:@"{%@}", self.domainClusterName];
    }
    return result;
}

/*!
 @abstract Provides a string that represents contact's current presence status or last login time
 
 Use:
 - show presence info for friend list and top of chat dialog
 */
- (NSString *)presenceString {
    
    MPContactPresenceState currentState = [self.presenceState intValue];
    
    switch (currentState) {
        
        // if online, return string status
        case MPContactPresenceStateOnline:
            return NSLocalizedString(@"online", @"CD: Contact is currently online");
            break;
            
        // if presence is off, don't show anything 
        case MPContactPresenceStateOff:
            return @"";
            break;
        
        // if offline, show last login time(today) or date(not today)
        default:
            // if never logged in, then show nothing
            //
            if ([self.lastLoginDate compare:[NSDate dateWithTimeIntervalSince1970:0]] == NSOrderedSame) {
                return @"";
            }
            // otherwise show last login date
            return [Utility terseDateString:self.lastLoginDate];
            break;
    }
}

/*!
 @abstract is the contact online?
 
 Use:
 - determine how to format presence info
 */
- (BOOL)isOnline {
    
    // if online, return this status
    //
    if ([self.presenceState intValue] == MPContactPresenceStateOnline) {
        return YES;
    }
    return NO;
}

/*!
 @abstract provides formatted name string for UI display
 */
- (NSString *)displayName {
    //DDLogInfo(@"**N**-%@-%@-%@", self.nickname, self.abName, self.abRecordID);
    if (self.abName) {
        return self.abName;
    }
    return self.nickname;
}




/*!
 @abstract Checks if this is a new friend
 
 */
- (BOOL) isNewFriend {
    
    BOOL isNew = NO;
    
    if (self.addFriendDate) {
        
        NSDate *lastResignDate = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAppResignActiveAfterViewingFriendDate];
        
        if ([self.addFriendDate compare:lastResignDate] == NSOrderedDescending) {
            isNew = YES;
        }
    }
    return isNew;
}

/*!
 @abstract Checks if this is a new friend suggestion
 
 Use:
 - check if suggestion is a new one
 */
- (BOOL) isNewFriendSuggestion {
    
    BOOL isNew = NO;
    
    if (self.addDate) {
        
        NSDate *lastDate = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAppEnterBackgroundAfterViewingFriendSuggestionDate];
        
        if ([self.addDate compare:lastDate] == NSOrderedDescending) {
            isNew = YES;
        }
    }
    return isNew;
}


/*!
 @abstract Checks if this is a friend
 */
- (BOOL) isFriend {
    if ([self.addFriendDate compare:[NSDate dateWithTimeIntervalSince1970:1000000]] == NSOrderedDescending) {
        return YES;
    }
    return NO;
}

/*!
 @abstract Is friend from phonebook?
 */
- (BOOL) isSyncedFromPhoneBook {
    if (self.abRecordID) {
        if ([self.abRecordID intValue] > -1) {
            return YES;
        }
        return NO;
    }
    // no abrecord defined at all == nil
    else {
        return NO;
    }
}


/*!
 @abstract Is contact is currently in addressbook
 */
- (BOOL) isInAddressBook {     
    
    if (![self isSyncedFromPhoneBook]) {
        return NO;
    }
    
    __block NSDictionary *personD = nil;
    
    dispatch_sync([AppUtility getBackgroundMOCQueue], ^{
    
        personD = [[AppUtility getBackgroundContactManager] personDictionaryForRecordID:self.abRecordID];
    
    });
    
    if (personD) {
        return YES;
    }
    
    return NO;
}


/*!
 @abstract has contact blocked me?
 
 @discussion Used to determine if we can sent messages to this person
  - are we blocked?
 
 @param YES if you are blocked by this contact
 
 Check if address is 0.0.0.0
 
 Note: This is not used 2012-3-3 - let the receiver take care of blocking p2p messages
 */
- (BOOL)hasBlockedMe {
    if ([self.domainClusterName isEqualToString:kMPParamUserBlockedYouDomainIP]) {
        return YES;
    }
    return NO;
}

/*!
 @abstract isBlockedByMe
 
 @discussion Used to determine if we can sent messages to this person
 - are we blocked?
 
 @param YES if you are blocked by this contact
 
 Check if address is 0.0.0.0
 */
- (BOOL)isBlockedByMe {
    
    BOOL result = [self.isBlocked boolValue];
    return result;
}

/*!
 @abstract Check if this user's account is still valid 
 
 @discussion Used to determine if we can sent messages to this person
 
 @param YES if account is no good by checking presence state
 
 */
- (BOOL) isUserAccountedCanceled {
    
    if ([self.presenceState intValue] == MPContactPresenceStateAccountCanceled) {
        return YES;
    }
    return NO;
}


/*!
 @abstract Gets status message without new lines
 
 */
- (NSString *) oneLineStatusMessage {
    NSString *oneLine = [self.statusMessage stringByReplacingOccurrencesOfString:@"\n" withString:@" "]; 
    return oneLine;
}


#pragma mark - Actions

/*!
 @abstract Changes this contact state to a friend
 */
- (void) makeFriend {
    // never add myself as a friend
    if (![self isMySelf]){
        self.addFriendDate = [NSDate date];
    }
}

/*!
 @abstract Changes this contact state to a friend
 
 - set to default date
 
 */
- (void) unFriend {
    self.addFriendDate = [NSDate dateWithTimeIntervalSince1970:0];
}

/*!
 @abstract Mark user as block
 
 @discussion Messages from this user will be ignored, user will show up in block list
 
 */
- (void) blockUser {
    
    self.isBlocked = [NSNumber numberWithBool:YES];
    
}

/*!
 @abstract Mark user as unblock
 
 @discussion Message will be accepted again from this user
 
 */
- (void) unBlockUser {
    self.isBlocked = [NSNumber numberWithBool:NO];
}



/*!
 @abstract Call out
 */
- (void) callRegisteredPhone {
    
    [AppUtility call:self.registeredPhone];
    
}


/*!
 @abstract SMS registered phone
 */
- (void) smsRegisteredPhone {
	
    [AppUtility sms:self.registeredPhone delegate:self];
    
}


#pragma mark - SMS Methods

// Dismisses the message composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result 
{   
	if (result == MessageComposeResultFailed) {
		[AppUtility showAlert:kAUAlertTypeComposeFailsureSMS];
	}
    [[[AppUtility getAppDelegate] containerController] dismissModalViewControllerAnimated:YES];
	
	//[self.navigationController.parentViewController dismissModalViewControllerAnimated:YES];
}



#pragma mark - Relationship Methods


- (void)addChatsObject:(CDChat *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"chats" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"chats"] addObject:value];
    [self didChangeValueForKey:@"chats" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeChatsObject:(CDChat *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"chats" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"chats"] removeObject:value];
    [self didChangeValueForKey:@"chats" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addChats:(NSSet *)value {    
    [self willChangeValueForKey:@"chats" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"chats"] unionSet:value];
    [self didChangeValueForKey:@"chats" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeChats:(NSSet *)value {
    [self willChangeValueForKey:@"chats" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"chats"] minusSet:value];
    [self didChangeValueForKey:@"chats" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


- (void)addMessagesObject:(CDMessage *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"messages" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"messages"] addObject:value];
    [self didChangeValueForKey:@"messages" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeMessagesObject:(CDMessage *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"messages" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"messages"] removeObject:value];
    [self didChangeValueForKey:@"messages" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addMessages:(NSSet *)value {    
    [self willChangeValueForKey:@"messages" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"messages"] unionSet:value];
    [self didChangeValueForKey:@"messages" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeMessages:(NSSet *)value {
    [self willChangeValueForKey:@"messages" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"messages"] minusSet:value];
    [self didChangeValueForKey:@"messages" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

#pragma mark - Image methods

/*!
 @abstract gets name of image file
 */
- (NSString *) imageName {
    return self.userID;
}

/*!
 @abstract gets version of image file
 */
- (NSString *) imageVersion {
    return [self.headshotSerialNumber stringValue];
}

/*!
 @abstract gets url to download original image file
 
 http://61.66.229.112/downloadheadshot?from=A&to=B&filename=headshot.jpg
 http://61.66.229.110/downloadheadshot?USERID=10000011
 
 domain server used
 
 */
- (NSString *) imageURLForContext:(NSString *)displayContext ignoreVersion:(BOOL)ignoreVersion {
    
    BOOL shouldGetURL = NO;
    
    // don't worry about version - get the image anyways
    if (ignoreVersion) {
        shouldGetURL = YES;
    }
    else if ([self.headshotSerialNumber intValue] > 0) {
        shouldGetURL = YES;
    }
    
    // if user has blocked you, don't get their headshot
    //
    if ([self.domainClusterName isEqualToString:kMPParamUserBlockedYouDomainIP]) {
        shouldGetURL = NO;
    }
    
    // only provide url if
    if (shouldGetURL && self.domainClusterName && self.userID) {
        
        NSString *encryptedID = [MPHTTPCenter httpRequestEncryptIfNeeded:self.userID];
        NSString *encodedID = [Utility stringByAddingPercentEscapeEncoding:encryptedID];
        NSString *encodeFlag = [MPHTTPCenter httpRequestEncodeFlag];
        
        // get small image
        if ([displayContext isEqualToString:kMPImageContextList]) {
            NSString *url = [NSString stringWithFormat:@"http://%@/download/downloadsmallheadshot?USERID=%@&domainTo=%@%@", kMPParamNetworkMPDownloadServer, encodedID, self.domainClusterName, encodeFlag];
            return url;
        }
        // get large image
        else {
            NSString *url = [NSString stringWithFormat:@"http://%@/download/downloadheadshot?USERID=%@&domainTo=%@%@", kMPParamNetworkMPDownloadServer, encodedID, self.domainClusterName, encodeFlag];
            return url;
        }
    }
    return nil;
}


@end
