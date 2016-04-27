//
//  CDChat.m
//  mp
//
//  Created by M Tsai on 11-9-20.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "CDChat.h"
#import "CDContact.h"
#import "CDMessage.h"
#import "MPChatManager.h"

#import "AppUtility.h"
#import "TKLog.h"


NSString* const MP_CHAT_CLEAR_HISTORY_NOTIFICATION = @"MP_CHAT_CLEAR_HISTORY_NOTIFICATION";


@implementation CDChat
@dynamic name;
@dynamic alertState;
@dynamic userID;
@dynamic groupID;
@dynamic lastMessage;
@dynamic lastMessagePrevious;
@dynamic lastUpdateDate;
@dynamic pendingText;
@dynamic isHiddenChat;

@dynamic messages;
@dynamic participants;

@synthesize isBrandNew;
@synthesize lastMsgIsFromMe;
@synthesize lastMsgDidFail;
@synthesize lastMsgText;
@synthesize lastMsgDateString;
@synthesize unreadMsgNumber;


- (NSString *)description{
    
    NSString *descriptionString = [NSString stringWithFormat:@"Name: %@, UID: %@, GID: %@, Last: %@ HiddenC:%@", self.name, self.userID, self.groupID, self.lastMessage, self.isHiddenChat?@"Y":@"N"];
    return descriptionString;
}

#pragma mark - 
#pragma mark Relationship Methods

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


- (void)addParticipantsObject:(CDContact *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"participants" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"participants"] addObject:value];
    [self didChangeValueForKey:@"participants" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeParticipantsObject:(CDContact *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"participants" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"participants"] removeObject:value];
    [self didChangeValueForKey:@"participants" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addParticipants:(NSSet *)value {    
    [self willChangeValueForKey:@"participants" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"participants"] unionSet:value];
    [self didChangeValueForKey:@"participants" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeParticipants:(NSSet *)value {
    [self willChangeValueForKey:@"participants" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"participants"] minusSet:value];
    [self didChangeValueForKey:@"participants" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


#pragma mark - 
#pragma mark Class Methods


+ (void) prefetchChat:(CDChat *)prefetchChat {
    
    NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDChat" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate *pred = nil;
    
    // if group ID specified, search for this group
    if (prefetchChat.groupID){
        pred = [NSPredicate predicateWithFormat:@"(groupID == %@)", prefetchChat.groupID];
    }
    // if only one contact provided, search for this contacts's chat
    else if (prefetchChat.userID) {
        pred = [NSPredicate predicateWithFormat:@"(userID == %@)",prefetchChat.userID];
    }
    // so if multiple contacts and no groupID, then create a new chat
    
    //NSArray *results = nil;
    
    // search only if predicate exists
    if (pred) {
        [fetchRequest setEntity:entity];
        [fetchRequest setReturnsObjectsAsFaults:NO];
        [fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"messages.messages", nil]];

        [fetchRequest setPredicate:pred];        
        
        // Then execute fetch it
        NSError *error = nil;
        [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }
    [fetchRequest release];
}

/*!
 @abstract get all available CD Chats ordered by most recent
 
 @discuss queries CD to get all available CDChats 
 
 @return
 success		array of CDChats
 fail			nil
 
 Use:
 - for chat list view
 
 */
+ (NSArray *) allChats {
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDChat" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUpdateDate" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [sortDescriptors release];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    return results;
}








/*!
 @abstract Delete chat object and files associated with this chat
 
 - deletes history first
 - checks if there are any scheduled messages left
    ~ if so don't delete, just delete the lastUpdateDate
    ~ otherwise deleting the chat will also delete the Scheduled message
 
 Use:
 - whenever you delete one chat at a time.
 
 */
+ (void) deleteChat:(CDChat *)deleteChat {
    
    // should clear all messages except scheduled ones
    BOOL shouldProceedToDeleteChat = [deleteChat clearChatHistory]; 
    
    // is schedule message still exist, don't delete
    if ( !shouldProceedToDeleteChat /*[deleteChat.messages count] > 0*/) {
        deleteChat.lastUpdateDate = nil;
    }
    else {
        //[CDMessage batchFetch:[deleteChat.messages allObjects]];
        //[CDChat prefetchChat:deleteChat];
        [AppUtility cdDeleteManagedObject:deleteChat];
    }
}

/*!
 @abstract deletes all possible chats
 
 @discuss When account is about to be deleted
 
 @return
 success		delete every chat in DB
 
 */
+ (void) deleteAllChats {
    
    NSArray *allChats = [CDChat allChats];
    
    // delete regular chats
    for (CDChat *iChat in allChats){
        NSString *messageID = [[MPChatManager sharedMPChatManager] requestDeleteChat:iChat];
        // if group chat
        // - send leave, but delete it right away
        if ([messageID length] > 0) {
            [CDChat deleteChat:iChat];
        }
        // p2p chats are already delete above
    }
    [AppUtility cdSaveWithIDString:@"CHT-delete all chats!" quitOnFail:NO];
}




/*!
 @abstract gets CDChat given participants and groupID
 
 @param contacts ID of all participants EXCLUDING self!
 @param groupID ID for group chat - usually the first message ID number
 @param checkForNewGroupInvites - if there are more contacts specified than current participants of an Existing chat, add them!
 @param shouldCreate    Create chat if it does not already exists
 @param shouldTouch     Should update lastUpdateDate - scheduled msg should not update this.
 
 Only queries if CDChat already exists. Creates if it does not exist.
 
 = provide params for each situation =
 
 Out-going msg:
  * new P2P chat: ToContact
  * new Group chat: ToContacts
 
 In-coming msg: 
  * group: AllContacts + groupID
  * P2P: fromContact
 
 
 if a single contact -> p2p chat
 if multiple contact -> gchat
 
 */
+ (CDChat *) chatWithCDContacts:(NSArray *)contacts 
                        groupID:(NSString *)groupID 
        checkForNewGroupInvites:(BOOL)checkInvites 
                   shouldCreate:(BOOL)shouldCreate
                     shouldSave:(BOOL)shouldSave 
                    shouldTouch:(BOOL)shouldTouch {
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDChat" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate *pred = nil;
    
    // if group ID specified, search for this group
    if (groupID){
        pred = [NSPredicate predicateWithFormat:@"(groupID == %@)",groupID];
    }
    // if only one contact provided, search for this contacts's chat
    else if ([contacts count] == 1) {
        CDContact *otherPerson = [contacts objectAtIndex:0];
        pred = [NSPredicate predicateWithFormat:@"(userID == %@)",otherPerson.userID];
    }
    // so if multiple contacts and no groupID, then create a new chat
    
    NSArray *results = nil;
    
    // search only if predicate exists
    if (pred) {
        [fetchRequest setEntity:entity];
        [fetchRequest setPredicate:pred];
        
        // Then execute fetch it
        NSError *error = nil;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }
    [fetchRequest release];

    
    CDChat *resultChat = nil;
    
    // if an existing chat found
    //
    if ([results count] > 0) {
        resultChat = [results objectAtIndex:0];
        
        // check if someone was invited into this group chat
        // - then add them
        if (checkInvites && [resultChat isGroupChat]) {
            for (CDContact *iContact in contacts) {
                if (![resultChat.participants member:iContact]) {
                    
                    if (![iContact isUserAccountedCanceled]) {
                        DDLogVerbose(@"Chat: new invite found %@", [iContact displayName]);
                        [resultChat addParticipantsObject:iContact];
                    }
                    else {
                        DDLogVerbose(@"Chat: don't invite cancelled accnt - %@", [iContact displayName]);
                    }
                    
                }
            }
        }
    }
    // create a new chat object and return it
    //
    else {
        
        if (!shouldCreate) {
            return nil;
        }
        
        resultChat = [NSEntityDescription insertNewObjectForEntityForName:[entity name] 
                                                      inManagedObjectContext:managedObjectContext];
        
        // mark as brand new
        //
        resultChat.isBrandNew = YES;
        
        if (shouldTouch) {
            // set lastupdate to this creation date
            // - helps sort new chats at the top even though there are no messages yet
            resultChat.lastUpdateDate = [NSDate date];
        }
        
        // set chat name and groupID for new in-coming gchat
        //
        if (groupID) {
            resultChat.groupID = groupID;
        }
        // if new out-going gchat, create groupID
        //
        else if ([contacts count] > 1){
            resultChat.groupID = [AppUtility generateMessageID];
        }
        // if only one contact, set userID
        else if([contacts count] == 1){
            resultChat.userID = [[contacts objectAtIndex:0] userID];
        }
        
        // set participants
        //
        [resultChat addParticipants:[NSSet setWithArray:contacts]];
        
    }
        
    // save to CD
    //
    if (shouldSave) {
        if ([AppUtility cdSaveWithIDString:@"save chatWithCDContacts" quitOnFail:YES] != NULL) {
            return nil;
        }
    }
    
    return resultChat;
}

// touch set to YES
//
+ (CDChat *) chatWithCDContacts:(NSArray *)contacts 
                        groupID:(NSString *)groupID 
        checkForNewGroupInvites:(BOOL)checkInvites 
                   shouldCreate:(BOOL)shouldCreate
                     shouldSave:(BOOL)shouldSave {
    return [CDChat chatWithCDContacts:contacts groupID:groupID checkForNewGroupInvites:checkInvites shouldCreate:shouldCreate shouldSave:shouldSave shouldTouch:YES];
}


// always create if chat does not exists
//
+ (CDChat *) chatWithCDContacts:(NSArray *)contacts 
                        groupID:(NSString *)groupID 
        checkForNewGroupInvites:(BOOL)checkInvites
                     shouldSave:(BOOL)shouldSave {
    
    return [CDChat chatWithCDContacts:contacts groupID:groupID checkForNewGroupInvites:checkInvites shouldCreate:YES shouldSave:shouldSave];
}


/*!
 Default:
 - check for invites = NO
 - shouldCreate = YES
 - shouldTouch = YES
 */
+ (CDChat *) chatWithCDContacts:(NSArray *)contacts 
                        groupID:(NSString *)groupID 
                     shouldSave:(BOOL)shouldSave {
    
    return [CDChat chatWithCDContacts:contacts groupID:groupID checkForNewGroupInvites:NO shouldSave:shouldSave];
}


/*!
 @abstract looks in DB for a matching chatID and does not create
 
 Use:
 - check if leave message needs to be processed
 
 */
+ (CDChat *) getChatForGroupID:(NSString *)groupID {
    
    if ([groupID length] < 1) {
        return nil;
    }
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDChat" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(groupID == %@)",groupID];

    
    NSArray *results = nil;
    
    // search only if predicate exists
    if (pred) {
        [fetchRequest setEntity:entity];
        [fetchRequest setPredicate:pred];
        
        // Then execute fetch it
        NSError *error = nil;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }
    [fetchRequest release];
    
    
    CDChat *resultChat = nil;
    
    // if an existing chat found
    //
    if ([results count] > 0) {
        resultChat = [results objectAtIndex:0];
    }
    
    return resultChat;
}



/*!
 @abstract Reveals all chats - Set all isHiddenChat to NO
 
 Use:
 - when HC is reset
 
 */
+ (void) clearAllHiddenChat {
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDChat" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(isHiddenChat == %@)",[NSNumber numberWithBool:YES]];
    
    NSArray *results = nil;
    
    // search only if predicate exists
    if (pred) {
        [fetchRequest setEntity:entity];
        [fetchRequest setPredicate:pred];
        
        // Then execute fetch it
        NSError *error = nil;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }
    [fetchRequest release];
    
    if ([results count] > 0) {
        for (CDChat *iChat in results) {
            iChat.isHiddenChat = [NSNumber numberWithBool:NO];
        }
        [AppUtility cdSaveWithIDString:@"Reveal all hidden chats" quitOnFail:NO];
    }
}





/*!
 @abstract Delete history for all chats
 
 - query all messages
 - clear all messages
 
 
 Use:
 - setting feature
 
 */
+ (void) clearAllChatHistory {
    /*
     Can't simply clear each chat.
     We need to also clear multicast messages that are not part of any chats
     
	NSArray *chats = [CDChat allChats];
    for (CDChat *iChat in chats) {
        [iChat clearChatHistory];
    }*/
    
    NSArray *allMessages  = [CDMessage allMessages];
    
    [CDMessage clearMessages:[NSSet setWithArray:allMessages]];
    
    // bulk save
    [AppUtility cdSaveWithIDString:@"clear all chat history" quitOnFail:NO];
    
}


#pragma mark - Class Queries

/*!
 @abstract gets chats that meets predicate requirements
 
 @param fetchLimit limits the number of fetches returned (-1 == no limit)
 
 @return success - array of resources, fail - nil no resource found
 
 */
+ (NSArray *) chatForPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fetchLimit:(NSInteger)fetchLimit {
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDChat" 
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
 @abstract Gets chats sorted by most recent and match hidden condition
  
 @return
 success		array of CDChats
 fail			nil
 
 Use:
 - for chat list view
 
 */
+ (NSArray *) chatsIsHidden:(BOOL)isHidden {
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(isHiddenChat == %@) AND (lastUpdateDate != %@)",[NSNumber numberWithBool:isHidden], [NSNull null]];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUpdateDate" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
    
    NSArray *results = [CDChat chatForPredicate:pred sortDescriptors:sortDescriptors fetchLimit:-1];
    [sortDescriptors release];
    
    return results;
}



#pragma mark - Query Methods

/*!
 @abstract sorted list of contacts
 */
- (NSArray *) sortedParticipants {
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
    
    NSArray *sortedContacts = [self.participants sortedArrayUsingDescriptors:sortDescriptors];
    [sortDescriptors release];
    
    return sortedContacts;
}

/*!
 @abstract name to display
 
 - if name exists, use it
 - otherwise it is the name of participants
 
 */
- (NSString *) displayNameStyle:(CDChatNameStyle)style {
    
    if ([self.name length] > 0) {
        return self.name;
    }
    
    NSArray *sortedContacts = [self sortedParticipants];
    
    NSMutableString *nameString = [[NSMutableString alloc] init];
    for (CDContact *iContact in sortedContacts) {
        NSString *contactName = [iContact displayName];
        if (contactName) {
            if ([nameString length] == 0) {
                [nameString appendString:[iContact displayName]];
            }
            else {
                [nameString appendFormat:@",%@",[iContact displayName]];
            }
        }
    }
    
    // only format for group chats
    // xxxx...(x)
    //
    if ([self isGroupChat] && style == kCDChatNameStyleTitle) {
        // if name too long then shorten it
        if ([nameString length] > 15) {
            [nameString deleteCharactersInRange:NSMakeRange(15, [nameString length] - 15)];
            [nameString appendString:@"..."];
        }
        NSUInteger participantCount = [self totalParticipantCount];
        // don't append if you are the only person in this chat room!
        if (participantCount > 1) {
            [nameString appendFormat:@"(%d)", participantCount];
        }
    }
    
    // in case no names, than add a default one for empty group chats
    //
    NSString *finalName = NSLocalizedString(@"No Members", @"CDChat - title: if no members exists in this group chat");
    if ([nameString length] > 0) {
        finalName = [NSString stringWithString:nameString];
    }
    [nameString release];
    
    return finalName;
}


/*!
 @abstract Test if two chats are equal
 
 matches user and group IDs
 
 */
- (BOOL)isEqualToChat:(CDChat *)otherChat {
    
    //DDLogVerbose(@"***CH-eq: u:%@ g:%@ - u:%@ g:%@", self.userID, self.groupID, otherChat.userID, otherChat.groupID);

    if (self.userID && [self.userID isEqualToString:otherChat.userID]){
        return YES;
    }
    
    if (self.groupID && [self.groupID isEqualToString:otherChat.groupID]) {
        return YES;
    }
    
    return NO;

}

/*!
 @abstract gets related messages sorted by create time
 
 If this is too slow, consider fetching from DB sorted in the first place!
 
 */
- (NSArray *)sortedMessages {
    
    NSSortDescriptor *sortNameDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"createDate" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortNameDescriptor, nil] autorelease];
    
    return [[self.messages allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

/*!
 @abstract gets related messages sorted by sent time and then messageID
 
 - 
 
 Note:
 - If this is too slow, consider fetching from DB sorted in the first place!
 
 */
- (NSArray *)sortedMessagesBySentDate {
    DDLogInfo(@"CDC-smbsd: start sort");
    
    // first check if there are failed messages
    NSPredicate *regularPredicate = [NSPredicate predicateWithFormat:@"(chat = %@) AND (state != %@) AND (state != %@)", 
                                     self, [NSNumber numberWithInt:kCDMessageStateOutFailed], [NSNumber numberWithInt:kCDMessageStateOutCreated]];
    
    NSSortDescriptor *sortSent = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    NSSortDescriptor *sortMID = [[NSSortDescriptor alloc] initWithKey:@"mID" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortSent, sortMID, nil];
    [sortSent release];
    [sortMID release];
    
    NSArray *regularMessages = [CDMessage messageForPredicate:regularPredicate sortDescriptors:sortDescriptors fetchLimit:-1 batchSize:-1];
    //[[self.messages allObjects] sortedArrayUsingDescriptors:sortDescriptors];
    
    // first check if there are failed messages
    NSPredicate *failedPredicate = [NSPredicate predicateWithFormat:@"(chat = %@) AND (state == %@ OR state == %@)", 
                                     self, [NSNumber numberWithInt:kCDMessageStateOutFailed], [NSNumber numberWithInt:kCDMessageStateOutCreated]];
    
    NSArray *failedMessages = [CDMessage messageForPredicate:failedPredicate sortDescriptors:sortDescriptors fetchLimit:-1 batchSize:-1];
    
    [sortDescriptors release];
    
    NSArray *allMessages = [regularMessages arrayByAddingObjectsFromArray:failedMessages];
    
    DDLogInfo(@"CDC-smbsd: end sort");
    
    return allMessages;

    
    /*
    NSMutableArray *regularMessages = [[[NSMutableArray alloc] initWithCapacity:[sortedMessages count]] autorelease];
    NSMutableArray *failedMessages = [[NSMutableArray alloc] initWithCapacity:[sortedMessages count]];
    
    for (CDMessage *iMessage in sortedMessages) {
        CDMessageState iState = [iMessage getStateValue];
        if (iState == kCDMessageStateOutFailed ||
            iState == kCDMessageStateOutCreated ) 
        {
            [failedMessages addObject:iMessage];
        }
        else {
            [regularMessages addObject:iMessage];
        }
    }
    [regularMessages addObjectsFromArray:failedMessages];
    [failedMessages release];
    
    return regularMessages;
     */
}




/*!
 @abstract get number of un-read message in this chat
 
 @return
 success		number of unread messages
 fail			..
 
 Use:
 - for chat list view
 
 */
- (NSUInteger) numberOfUnreadMessages {
        
    /* This is much slower!
     NSUInteger count = 0;
    
    for (CDMessage *iMessage in self.messages) {
        if ([iMessage.state intValue] == kCDMessageStateInDelivered) {
            count++;
        }
    }*/
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDMessage" 
											  inManagedObjectContext:managedObjectContext];
	
    //NSPredicate *pred = [NSPredicate predicateWithFormat:@"(chat.userID == %@) AND (chat.groupID == %@) AND (state == %@) AND (type != %@) AND (type != %@)", self.userID, self.groupID, [NSNumber numberWithInt:kCDMessageStateInDelivered], [NSNumber numberWithInt:kCDMessageTypeGroupEnter], [NSNumber numberWithInt:kCDMessageTypeGroupLeave]];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(chat == %@) AND (state == %@)", self, [NSNumber numberWithInt:kCDMessageStateInDelivered]];
    
	// load from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];    
    
    // Then execute fetch it
    NSError *error = nil;
    NSUInteger count = [managedObjectContext countForFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    return count;
}


/*!
 @abstract Is this a group chat
 
 */
- (BOOL) isGroupChat {
    
    if ([self.groupID length] > 1 ){
        return YES;
    }
    return NO;
}


/*!
 @abstract Debugging
 
 */
- (void) printParticipantIDs {    
    for (CDContact *iContact in self.participants){
        DDLogVerbose(@"Chat: participant - %@ - %@", iContact.userID, iContact.nickname);
    }
}

/*!
 @abstract Is this a group chat
 
 Use:
 - check if a leave message sender is actually in this chat, if not ignore message
 
 */
- (BOOL) isUserIDInChat:(NSString *)searchUserID {
    
    for (CDContact *iContact in self.participants){
        if ([iContact.userID isEqualToString:searchUserID]) {
            return YES;
        }
    }
    return NO;
}


/*!
 @abstract Number of all participants + yourself
 
 */
- (BOOL) totalParticipantCount {
    
    NSInteger count = [self.participants count] + 1;
    return count;
    
}

/*!
 @abstract Gets the user of other participant in P2P chat
 
 @return p2p contact, or nil for group chat
 
 */
- (CDContact *) p2pUser {
    
    if (![self isGroupChat]){
        CDContact *p2pContact = [self.participants anyObject];
        return p2pContact;
    }
    return nil;
}

/*!
 @abstract Gets the userID of other participant in P2P chat
 
 */
- (NSString *) p2pUserID {
    return [[self p2pUser] userID];
}


#pragma mark - Last Message

/*!
 @abstract Gets last message text for this chat to show in chat list
 
 */
- (CDMessage *) lastMessageFromDB {
    
    NSArray *chatMessages = [CDMessage messagesForChat:self acending:NO limit:2];

    if ([chatMessages count] > 0) {
        return [chatMessages objectAtIndex:0];
    }
    return nil;
}

/*!
 @abstract Gets last message text for this chat to show in chat list
 
 */
- (NSString *) lastMessageTextForLastMessage:(CDMessage *)aLastMessage previousLastMessage:(CDMessage *)aPreviousLastMessage {
    
    NSString *lastText = [aLastMessage getDescriptionString];
    
    // if control message encountered
    if ([lastText length] == 0) {
        
        CDMessage *previousLastMessage = nil;
        @try {
            previousLastMessage = self.lastMessagePrevious;
        }
        @catch (NSException *exception) {
            NSString *exceptionName = [exception name];
            DDLogError(@"Chat-lmtflm: Raised Exception %@: %@", exceptionName, [exception reason]);
            return nil;
        }
        
        // group leave will also be followed by group control message
        //
        if ([previousLastMessage isType:kCDMessageTypeGroupLeave]) {
            lastText = [previousLastMessage getDescriptionString];
        }
        // if invite message
        // - then show the last person added
        else if ( ([aLastMessage isType:kCDMessageTypeTextGroup] || [aLastMessage isType:kCDMessageTypeText]) && 
                 [aLastMessage.text length] == 0 ){
            
            NSMutableSet *lastParticipants = [aPreviousLastMessage getAllParticipants];
            NSMutableSet *thisParticipants = [aLastMessage getAllParticipants];
            
            if (lastParticipants && [thisParticipants count] > 0) {
                [thisParticipants minusSet:lastParticipants];
            }
            
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
            NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
            [sortDescriptor release];
            
            NSArray *sortedContacts = [thisParticipants sortedArrayUsingDescriptors:sortDescriptors];
            [sortDescriptors release];
            
            CDContact *lastAddedContact = [sortedContacts lastObject];
            
            if (lastAddedContact) {
                lastText = [NSString stringWithFormat:NSLocalizedString(@"%@ joined", @"Chat - text: User joined group chat"), [lastAddedContact displayName]];
            }
        }
    }
    return lastText;
}



/*!
 @abstract Gets last message text for this chat to show in chat list
 
 */
- (NSString *) lastMessageText {
    
    return [self lastMessageTextForLastMessage:self.lastMessage previousLastMessage:self.lastMessagePrevious];
    
}


/*!
 @abstract Gets last message text for this chat to show in chat list
 
 */
- (NSString *) lastMessageTextForLast2Messages:(NSArray *)chatMessages {
    
    // get 2 last messages
    //NSArray *chatMessages = [CDMessage messagesForChat:self acending:NO limit:2];
    
    CDMessage *aLastMessage = nil;
    CDMessage *aPreviousLastMessage = nil;
    
    int i = 0;
    for (CDMessage *iMessage in chatMessages) {
        switch (i) {
            case 0:
                aLastMessage = iMessage;
                break;
                
            case 1:
                aPreviousLastMessage = iMessage;
                break;
                
            default:
                break;
        }        
        i++;
    }
    return [self lastMessageTextForLastMessage:aLastMessage previousLastMessage:aPreviousLastMessage];
}


#pragma mark - Instance Action


/*!
 @abstract Mark all messages as read
 
 Use:
 - mark all messages as read after entering the chat dialog
 - mostly as a extra precaution to make sure all messages are marked read
 
 */
- (void) markAllInDeliveredMessageRead {
    
    // first check if there are failed messages
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(chat = %@) AND (state == %@)", 
                                     self, [NSNumber numberWithInt:kCDMessageStateInDelivered]];
    
    NSArray *regularMessages = [CDMessage messageForPredicate:pred sortDescriptors:nil fetchLimit:-1 batchSize:-1];
    CDMessage *lastMessage = [regularMessages lastObject];
    BOOL shouldSave;
    
    DDLogInfo(@"Chat: mark msges save - %d", [regularMessages count]);
    // save only for last message to save CPU
    for (CDMessage *iMessage in regularMessages) {
        shouldSave = [lastMessage isEqual:iMessage]?YES:NO;
        [[MPChatManager sharedMPChatManager] markCDMessageRead:iMessage shouldSave:shouldSave];
    }
}

/*!
 @abstract Add more participants to this group chat
 
 Use:
 - after inviting more contacts to a group chat
 
 */
- (void) addContactsToGroupChat:(NSArray *)contacts {
    [self addParticipants:[NSSet setWithArray:contacts]];
}

/*!
 @abstract Remove participants from group chat
 
 Use:
 - if invite failed, so we need to revert
 
 */
- (void) removeContactsFromGroupChat:(NSArray *)contacts {
    [self removeParticipants:[NSSet setWithArray:contacts]];
}


/*!
 @abstract Clears Chat History
 
 @param     willDeleteChat  Will delete chat after clearing these messages.
 - So if there are no schedule messages, don't delete these messages, let the delete chat cascade the delete.
 
 @return    can we proceed with delete chat: 
 - YES: no since SM message exist and chat should remain
 - NO: all messages can ge removed so go ahead and delete chat as well
 
 
 - don't delete scheduled messages
 - or enter/leave messages
 
 Note:
 - multicast message files are not deleted since other message may use them
 
 Use:
 - action in chat settings and settings
 
 */
- (BOOL) clearChatHistory {
    
    NSManagedObjectID *chatID = [self objectID];
    BOOL shouldDeleteChat = [CDMessage clearMessages:self.messages];
    [AppUtility cdSaveWithIDString:@"save delete chat history" quitOnFail:NO];

    [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHAT_CLEAR_HISTORY_NOTIFICATION object:chatID];

    // getting the objectID here seem to cause crashes in iOS 4.x
    //
    // [[NSNotificationCenter defaultCenter] postNotificationName:MP_CHAT_CLEAR_HISTORY_NOTIFICATION object:[self objectID]];

    return shouldDeleteChat;
}

@end
