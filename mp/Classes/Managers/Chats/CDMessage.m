//
//  CDMessage.m
//  mp
//
//  Created by M Tsai on 11-9-20.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "CDMessage.h"
#import "CDChat.h"
#import "CDContact.h"
#import "CDMessage.h"
#import "CDResource.h"

#import "MPFoundation.h"
#import "TKFileManager.h"

CGFloat const kMPParamImageJPEGCompressionPreview = 0.5;
CGFloat const kMPParamImageJPEGCompressionOriginal = 0.7;
CGFloat const kMPParamImageMaxBytesPreview = 35000;
CGFloat const kMPParamImageMaxBytes = 200000;



@implementation CDMessage

@synthesize previewImage;
@synthesize fileData;
@synthesize stickerResource;

@dynamic state;
@dynamic downloadURL;
@dynamic sequenceNumber;
@dynamic mID;
@dynamic type;
@dynamic typeInfo;
@dynamic createDate;
@dynamic sentDate;
@dynamic lastStateDate;
@dynamic text;
@dynamic sequenceTotal;
@dynamic filename;
@dynamic parentMessage;

@dynamic contactsTo;
@dynamic messages;
@dynamic contactsRead;
@dynamic contactFrom;
@dynamic contactsDelivered;
@dynamic contactsEntered;

@dynamic chat;
@dynamic lastForChat;
@dynamic lastForChatPrevious;
@dynamic isMadeHere;
@dynamic didSendReadReceipt;
@dynamic attachLength;

// scheduled messages
@dynamic dateScheduled;
@dynamic isHidden;
@dynamic isScheduled;


- (void) dealloc {
    
    [stickerResource release];
    [previewImage release];
    [fileData release];
    [super dealloc];
}


#pragma mark - 
#pragma mark Relationship Methods


- (void)addContactsToObject:(CDContact *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contactsTo" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contactsTo"] addObject:value];
    [self didChangeValueForKey:@"contactsTo" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeContactsToObject:(CDContact *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contactsTo" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contactsTo"] removeObject:value];
    [self didChangeValueForKey:@"contactsTo" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addContactsTo:(NSSet *)value {    
    [self willChangeValueForKey:@"contactsTo" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contactsTo"] unionSet:value];
    [self didChangeValueForKey:@"contactsTo" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeContactsTo:(NSSet *)value {
    [self willChangeValueForKey:@"contactsTo" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contactsTo"] minusSet:value];
    [self didChangeValueForKey:@"contactsTo" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
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




- (void)addContactsDeliveredObject:(CDContact *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contactsDelivered" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contactsDelivered"] addObject:value];
    [self didChangeValueForKey:@"contactsDelivered" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeContactsDeliveredObject:(CDContact *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contactsDelivered" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contactsDelivered"] removeObject:value];
    [self didChangeValueForKey:@"contactsDelivered" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addContactsDelivered:(NSSet *)value {    
    [self willChangeValueForKey:@"contactsDelivered" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contactsDelivered"] unionSet:value];
    [self didChangeValueForKey:@"contactsDelivered" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeContactsDelivered:(NSSet *)value {
    [self willChangeValueForKey:@"contactsDelivered" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contactsDelivered"] minusSet:value];
    [self didChangeValueForKey:@"contactsDelivered" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}




- (void)addContactsReadObject:(CDContact *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contactsRead" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contactsRead"] addObject:value];
    [self didChangeValueForKey:@"contactsRead" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeContactsReadObject:(CDContact *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contactsRead" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contactsRead"] removeObject:value];
    [self didChangeValueForKey:@"contactsRead" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addContactsRead:(NSSet *)value {    
    [self willChangeValueForKey:@"contactsRead" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contactsRead"] unionSet:value];
    [self didChangeValueForKey:@"contactsRead" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeContactsRead:(NSSet *)value {
    [self willChangeValueForKey:@"contactsRead" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contactsRead"] minusSet:value];
    [self didChangeValueForKey:@"contactsRead" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}



- (void)addContactsEnteredObject:(CDContact *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contactsEntered" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contactsEntered"] addObject:value];
    [self didChangeValueForKey:@"contactsEntered" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeContactsEnteredObject:(CDContact *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"contactsEntered" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"contactsEntered"] removeObject:value];
    [self didChangeValueForKey:@"contactsEntered" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addContactsEntered:(NSSet *)value {    
    [self willChangeValueForKey:@"contactsEntered" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contactsEntered"] unionSet:value];
    [self didChangeValueForKey:@"contactsEntered" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeContactsEntered:(NSSet *)value {
    [self willChangeValueForKey:@"contactsEntered" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"contactsEntered"] minusSet:value];
    [self didChangeValueForKey:@"contactsEntered" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


#pragma mark - Default Methods

/*!
 @abstract initialization for each object
 
 @discussion 
 
 called right when new object is inserted and before user has chance to modify
 - adds a create date, which is used for sorting
 
 */
- (void) awakeFromInsert {
 
    // set create date to right now
    //self.createDate = [NSDate date];
    
    // if an time offset exists apply to the create date
    // - this can then be used as a sent date if message recovers
    //
    NSNumber *timeOffset = [[AppUtility getAppDelegate] sharedCacheObjectForKey:kMPSharedNSCacheKeyDSTimeOffset];
    if (timeOffset) {
        self.createDate =  [NSDate dateWithTimeIntervalSinceNow:[timeOffset floatValue]];
    }
    // get timeoffset from disk as backup
    else {
        timeOffset = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSharedNSCacheKeyDSTimeOffset];
        if (timeOffset) {
            self.createDate =  [NSDate dateWithTimeIntervalSinceNow:[timeOffset floatValue]];
        }
    }
    [super awakeFromInsert];
}


#pragma mark - Update Methods

/*!
 @abstract set Chat and update the last update date
 
 @param newChat associate this message to this chat. If chat does not exists, look for one that matches.
 
 Use:
 - use this to set chats, so we always know when the last update time was
 This helps sorts the chat list.  So don't use CDMessage.chat = xxx directly
 
 */
- (void) updateChat:(CDChat *)newChat {
    
    if (newChat) {
        self.chat = newChat;
        
        // only set last message for visible messages
        if ([self.isHidden boolValue] == NO) {
            self.chat.lastMessagePrevious = self.chat.lastMessage;
            self.chat.lastMessage = self;
            self.chat.lastUpdateDate = [NSDate date];
        }
    }
}

/*!
 @abstract Reveals a hidden message
 
 Use:
 - Make sure a message show if it was a previously hidden message
 - When scheduled message is sent out (@scheduled received)

 */
- (void) revealHidden {
    
    // if was hidden, show it now
    if ([self.isHidden boolValue] == YES) {
        
        self.isHidden = [NSNumber numberWithBool:NO];
        
        // set create date to sort this message properly
        self.createDate = [NSDate date];
        // show message as last message
        [self updateChat:self.chat];
    }
    
    // otherwise, nothing to do if already revealed
}


/*!
 @abstract mark this person as having received this message
 
 - first checks if this is a contact we actually sent this message to
 - so it is ok to run of unrelated userIDs
 
 @return YES if overall state actually changed - and UI needs update
 */
- (BOOL) markDeliveredForUserID:(NSString *)userID {
    
    BOOL isUserInContactsTo = NO;
    for (CDContact *iContact in self.contactsTo){
        if ([iContact.userID  isEqualToString:userID]) {
            [self addContactsDeliveredObject:iContact];
            // make sure this message is not hidden
            [self revealHidden];
            isUserInContactsTo = YES;
            break;
        }
    }
    
    BOOL didChange = NO;
    
    // only update state if valid from userID provided
    if (isUserInContactsTo) {
        // don't go backwards
        if ([self.state intValue] != kCDMessageStateOutRead) {
            self.state = [NSNumber numberWithInt:kCDMessageStateOutDelivered];
            didChange = YES;
        }
    }
    
    // save externally
    /*if (didChange) {
        [AppUtility cdSaveWithIDString:@"CDM: mark delivered" quitOnFail:NO];
    }*/
    return didChange;
}

/*!
 @abstract mark this person as having read this message
 
 - first checks if this is a contact we actually sent this message to
 - so it is ok to run of unrelated userIDs
 
 @return YES if overall state actually changed
 */
- (BOOL) markReadForUserID:(NSString *)userID {
    
    BOOL didChange = NO;
    BOOL isUserInContactsTo = NO;
    
    for (CDContact *iContact in self.contactsTo){
        if ([iContact.userID  isEqualToString:userID]) {
            [self addContactsReadObject:iContact];
            // make sure this message is not hidden
            [self revealHidden];
            isUserInContactsTo = YES;
            didChange = YES;
            break;
        }
    }
    

    // only update state if valid from userID provided
    if (isUserInContactsTo) {
        if ([self.state intValue] != kCDMessageStateOutRead) {
            self.state = [NSNumber numberWithInt:kCDMessageStateOutRead];
            didChange = YES;
        }
    }
    
    /* save externally
    if (didChange) {
        [AppUtility cdSaveWithIDString:@"CDM: mark read" quitOnFail:NO];
    }*/
    return didChange;
}

#pragma mark - Query Methods



/*!
 @abstract Check if is of certain type
 */
- (BOOL) isType:(CDMessageType)testType {
    
    return ([self.type intValue] == testType);

}


/*
 kCDMessageStateOutCreated = 0,
 kCDMessageStateOutSent = 1,
 kCDMessageStateOutDelivered = 2,
 kCDMessageStateOutRead = 3,
 
 kCDMessageStateInDelivered = 10,
 kCDMessageStateInRead = 11
 */

/*!
 @abstract determine if this message is from self
 */
- (BOOL)isFromSelf {
    
    if ([self getStateValue] < kCDMessageStateInDelivered) {
        return YES;
    }
    return NO;
    
    //return [self.contactFrom isMySelf];
}

/*!
 @abstract determine if this message is actually sent from self
 
 - when talking to myself, we only want messages we actually sent and not receive
 
 */
- (BOOL)isSentFromSelf {
    NSInteger stateValue = [self.state intValue];
    if (stateValue == kCDMessageStateInRead || 
        stateValue == kCDMessageStateInDelivered ||
        stateValue == kCDMessageStateInReadDownloaded) {
        return NO;
    }
    return YES;
}

/*!
 @abstract determine if this message is from self
 
 Use:
 - Find the first unread message to display
 */
- (BOOL)isInboundNotRead {
    NSInteger stateValue = [self.state intValue];
    if (stateValue == kCDMessageStateInDelivered) {
        return YES;
    }
    return NO;
}


/*!
 @abstract Is a group control message
 
 Use:
 - Determine if this is msg is used to help determine group membership changes
 
 */
- (BOOL)isGroupControlMessage {
        
    // check for regular text?
    //
    if (([self isType:kCDMessageTypeTextGroup] || [self isType:kCDMessageTypeText]) && 
         [self.text length] == 0) {
        return YES;
    }
    
    return NO;
}

/*!
 @abstract Should this message be added to the dialog view?
 
 State updates should not be added. Only messages that are just created should be:
 
 out-created        locally generated message, dialog will add by itself usually - but add just in case
 in-delivered       in inbound message, so add to dialog
 out-sent-blocked   locally generated message - but to blocked users, so it is artificially marked sent
 out-failed         msg can fail immediately when network is not available, so add
 
 out-sent           only for scheduled messages that where previously hidden
 
 remaining states should only update message status and not add new chat message to view.
 
 */
- (BOOL) shouldAddToDialog {
    
    NSManagedObjectContext *moc = [AppUtility cdGetManagedObjectContext];
    
    // make sure we get changes from bkground
    [moc refreshObject:self mergeChanges:NO];
    
    NSInteger stateValue = [self.state intValue];
    if (stateValue == kCDMessageStateOutCreated || 
        stateValue == kCDMessageStateOutSentBlocked ||
        stateValue == kCDMessageStateOutFailed ||
        stateValue == kCDMessageStateInDelivered) {
        return YES;
    }
    // if scheduled message just sent out, show in dialog!
    if (stateValue == kCDMessageStateOutSent && [self.isScheduled boolValue] == YES) {
        return YES;
    }
    return NO;
}


/*!
 @abstract gets state value
 
 */
- (CDMessageState) getStateValue {
    return [self.state intValue];
}

/*!
 @abstract gets the string rep of message state
 
 Use:
 - message time status indicators
 
 */
- (NSString *) getStateString {
    
    NSInteger stateV = [self.state intValue];
    
    switch (stateV) {

        case kCDMessageStateOutSent:
            return NSLocalizedString(@"Sent", @"Message-staus: Message is successfully sent to Server");
            break;
            
        case kCDMessageStateOutSentBlocked:
            return NSLocalizedString(@"Sent", @"Message-staus: Message is successfully sent to Server");
            break;
            
        case kCDMessageStateOutDelivered:
            // group chat does not show delivered
            if ([self.chat isGroupChat]) {
                return NSLocalizedString(@"Sent", @"Message-staus: Message is successfully delivered to other");
            }
            else {
                return NSLocalizedString(@"Delivered", @"Message-staus: Message is successfully delivered to other");
            }
            break;
            
        case kCDMessageStateOutRead:
            if ([self.chat isGroupChat]) {
                return [NSString stringWithFormat:NSLocalizedString(@"Read %d/%d", nil), 
                        [self.contactsRead count], [self.contactsTo count]];
            }
            else {
                return NSLocalizedString(@"Read", @"Message-staus: Message was read by other");
            }
            break;
            
        default:
            break;
    }
    return nil;
}




/*!
 @abstract get text description that respresents this message
 
 Use:
 - last message or scheduled message description
 
 */
- (NSString *) getDescriptionString {
    
    NSString *messageText = self.text;
    
    switch ([self.type intValue]) {
        // sticker message
        case kCDMessageTypeSticker:
        case kCDMessageTypeStickerGroup:
            //messageText = [[self.cdMessage.text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]] componentsJoinedByString:@""];
            messageText = [NSString stringWithFormat:NSLocalizedString(@"Sticker", @"Message - text: sticker message")]; //, messageText];
            break;
            
        case kCDMessageTypeImage:
            messageText = NSLocalizedString(@"Photo", @"Message - text: photo message");
            break;
            
        case kCDMessageTypeLetter:
            messageText = NSLocalizedString(@"Letter", @"Message - text: letter message");
            break;
            
        case kCDMessageTypeLocation:
            messageText = NSLocalizedString(@"Location", @"Message - text: location message");
            break;
            
        case kCDMessageTypeGroupLeave:
            messageText = [NSString stringWithFormat:NSLocalizedString(@"%@ left", @"Message - text: group leave message"), [self.contactFrom displayName]];
            break;
            
        default:
            break;
    }
    return messageText;
}





/*!
 @abstract gets participants of this message - excluding myself
 
 Use:
 - to compare particpants and know when people joined a group chat
 
 */
- (NSMutableSet *) getAllParticipants {
    
    NSMutableSet *set = [[[NSMutableSet alloc] initWithObjects:self.contactFrom, nil] autorelease];
    [set unionSet:self.contactsTo];
    
    // Remove myself as a participant
    NSString *myUserID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    CDContact *mySelf = nil;
    for (CDContact *iContact in set) {
        if ([iContact.userID isEqualToString:myUserID]) {
            mySelf = iContact;
            break;
        }
    }
    
    if (mySelf) {
        [set minusSet:[NSSet setWithObject:mySelf]];
    }
    return set;

}


/*!
 @abstract sorted list of contacts
 */
- (NSArray *) sortedContactsTo {
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
    
    NSArray *sortedContacts = [self.contactsTo sortedArrayUsingDescriptors:sortDescriptors];
    [sortDescriptors release];
    
    return sortedContacts;
}

/*!
 @abstract name to display
 
 - if name exists, use it
 - otherwise it is the name of participants
 
 */
- (NSString *) displayName {
    
    NSArray *sortedContacts = [self sortedContactsTo];
    
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
    
    // only format for mulitple to contacts
    //
    // - don't add text number, use badge to show number instead (schedule message)
    /*NSUInteger contactCount = [sortedContacts count];
    if (contactCount > 1) {
        // if name too long then shorten it
        if ([nameString length] > 15) {
            [nameString deleteCharactersInRange:NSMakeRange(15, [nameString length] - 15)];
            [nameString appendString:@"..."];
        }
        [nameString appendFormat:@"(%d)", [sortedContacts count]];
    }*/
    
    // in case no names, than add a default one for empty group chats
    //
    NSString *finalName = NSLocalizedString(@"No Contacts", @"CDMessage - title: if no members exists in this group chat");
    if ([nameString length] > 0) {
        finalName = [NSString stringWithString:nameString];
    }
    [nameString release];
    
    return finalName;
}


/*!
 @abstract Get the standard filename
 
 Use:
 - save attachment with this filename
 
 */
- (NSString *) attachmentFilename {
    // filename is mID.file
    return [NSString stringWithFormat:@"%@.file", self.mID];
}


#pragma mark - Time Query



/*!
 @abstract Creates and caches date formatters
 */
+ (NSDateFormatter *)dateFormatter
{
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *formatter = [dictionary objectForKey:@"CDMessageDateFormatter"];
    if (!formatter)
    {
        formatter = [[[NSDateFormatter alloc] init] autorelease];
        
        NSString *timeComponents = @"Hm";
        
        NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:timeComponents options:0 locale:[NSLocale currentLocale]];
        [formatter setDateFormat:dateFormat];

        [dictionary setObject:formatter forKey:@"CDMessageDateFormatter"];
    }
    return formatter;
}


/*!
 @abstract gets the sent time for this message
 
 Use:
 - message time stamps
 
 */
- (NSString *) getSentTimeString {
    
    NSString *sString = [[CDMessage dateFormatter] stringFromDate:self.sentDate];
    return sString;
    
}





#pragma mark - Query Methods - Xlate to MPMessage helpers

/*!
 @abstract provide string representation of sequence string
 
 nil if no sequence
 
 */
- (NSString *)sequenceString {
    
    NSString *seq = nil;
    
    if ([self.sequenceTotal intValue] > 1) {
        seq = [NSString stringWithFormat:@"%@/%@", self.sequenceNumber, self.sequenceTotal];
    }
    return seq;
}

/*!
 @abstract get the cached preview Image
 
 This image should be cache when the CDMessage was first received.
 Ask the FileManager for that file back.
 
 */
- (UIImage *) previewImage {
    
    if (previewImage) {
        return previewImage;
    }

    // use file name to get the preview image!
    //
    TKFileManager *fileManager = [[TKFileManager alloc] init];
    previewImage = [fileManager getPreviewImageForFilename:self.filename];
    [previewImage retain];
    [fileManager release];
    
    // fall back to parent message
    if (!previewImage && self.parentMessage) {
        return self.parentMessage.previewImage;
    }
    return previewImage;
}

/*!
 @abstract Gets full image for this message
 
 - no download attempt
 - not cached, since it may be too big
 
 */
- (UIImage *) fullImage {
    
    UIImage *fullImage = nil;
    
    // use file name to get the preview image!
    //
    TKFileManager *fileManager = [[TKFileManager alloc] init];
    fullImage = [fileManager getImageForFilename:self.filename];
    [fileManager release];
    
    // fall back to parent message
    if (!fullImage && self.parentMessage) {
        return [self.parentMessage fullImage];
    }
    return fullImage;
}


/*!
 @abstract Gets nsdata for this message's attachment
 
 @return nil if no file data available
 
 */
- (NSData *) getFileData {
    
    if (self.fileData) {
        return self.fileData;
    }
    
    // get data, no download
    //
    TKFileManager *fileManager = [[TKFileManager alloc] init];
    NSData *data = [fileManager getFileDataForFilename:self.filename url:nil];
    [fileManager release];
    
    if (data) {
        return data;
    }
    // otherwise try parent
    else if (self.parentMessage) {
        return [self.parentMessage getFileData];
    }
    return nil;
}


/*!
 @abstract get data representation of image
 - also compresses
 */
- (NSData *) previewImageData {
    
    NSData *imageData = nil;
    if (self.previewImage) {
        
        // keep compressing until image is small enough
        double compressionRatio=kMPParamImageJPEGCompressionPreview*2.0;
        int compressTimes = 0;
        while ([imageData length] > kMPParamImageMaxBytesPreview || imageData == nil || compressTimes > 5) { 
            compressionRatio=compressionRatio*0.50;
            DDLogVerbose(@"CDM: preview image too large:%d use compression:%f - time:%d", [imageData length], compressionRatio, compressTimes);
            imageData=UIImageJPEGRepresentation(self.previewImage, compressionRatio);
            compressTimes++;
        }        
        
        //NSData *imageData = UIImagePNGRepresentation(self.previewImage);
        //imageData = UIImageJPEGRepresentation(self.previewImage, kMPParamImageJPEGCompressionPreview);
    }
    if (!imageData && self.parentMessage) {
        return self.parentMessage.previewImageData;
    }
    return imageData;
}


/*!
 @abstract get download URL for this message
 
 @return URL string to access the file to download
 
 Note : the URL format of http download 
 http://xx.xx.xx.xx/downloadxxxxx?from=A&to=B&filename=xxxx.xx(&offset=xxxx)
 xx.xx.xx.xx :  the domain address of sender’s Domain Server , http download should use 
 domain-address(global address) , can not use from-address ( internal address ) . 
 downloadxxxx : download type : e,g, downloadimage , downloadaudio, downloadvideo , downloadcontact 
 downloadheadshot …. 
 from :  receiver’s USERID
 to :  sender’s(file owner) USERID 
 filename :  the filename (from sender) to be downloaded
 offset : (optional : default=0) is the start download position (in bytes) of the download file .
 
 */
- (NSString *) getDownloadURL {
    
    // images - letter is also uses @image DS message type
    //
    if ([self.type intValue] == kCDMessageTypeImage || [self.type intValue] == kCDMessageTypeLetter) {
        
        
        NSString *domainServer = self.contactFrom.domainClusterName;
        NSString *toString = self.contactFrom.userID;
        NSString *fromString =  [MPHTTPCenter httpRequestUserID]; 
        NSString *fileName = self.filename;
        
        NSString *encryptedTo = [MPHTTPCenter httpRequestEncryptIfNeeded:toString];
        NSString *encodedTo = [Utility stringByAddingPercentEscapeEncoding:encryptedTo];
        NSString *encodeFlag = [MPHTTPCenter httpRequestEncodeFlag];
        
        if (domainServer && toString && fromString && fileName) {
            NSString *urlString = [NSString stringWithFormat:@"http://%@/download/downloadimage?from=%@&to=%@&filename=%@&domainTo=%@%@", kMPParamNetworkMPDownloadServer, fromString, encodedTo, fileName, domainServer, encodeFlag];
            
            return urlString;
            //NSString *encodedString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            //return encodedString;
        }
    }
    return nil;
}

/*!
 @abstract gets the sticker resource if this is a sticker message
 
 */
- (CDResource *) stickerResource {
    
    if (stickerResource) {
        return stickerResource;
    }
    
    if ([self.type intValue] == kCDMessageTypeSticker || [self.type intValue] == kCDMessageTypeStickerGroup) {
        //return [CDResource stickerForText:self.text];
        return [[MPResourceCenter sharedMPResourceCenter] stickerForText:self.text];
    }
    return nil;
}


#pragma mark - CD Query

/*!
 @abstract Fault in messages
 
 */
+ (void) batchFetch:(NSArray *)messages {
    
    NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDMessage" 
											  inManagedObjectContext:managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self IN %@", messages];
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
    // Then execute fetch it
    NSError *error = nil;
    [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
}




/*!
 @abstract gets resources that meets predicate requirements
 
 @param fetchLimit  limits the number of fetches returned -1 means no limit
 @param batchSize   fetch items in batch sizes, -1 means no batch size sepecified
 
 @return success - array of resources, fail - nil no resource found
 
 */
+ (NSArray *) messageForPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fetchLimit:(NSInteger)fetchLimit batchSize:(NSInteger)batchSize getAsFaults:(BOOL)getAsFaults {
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDMessage" 
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
    
    if (batchSize > 0) {
        [fetchRequest setFetchBatchSize: batchSize];
    }
    
    // by default CD gets objects as faults
    if (!getAsFaults) {
        [fetchRequest setReturnsObjectsAsFaults:getAsFaults];
    }
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    return results;
}

+ (NSArray *) messageForPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fetchLimit:(NSInteger)fetchLimit batchSize:(NSInteger)batchSize {
    
    return [self messageForPredicate:predicate sortDescriptors:sortDescriptors fetchLimit:fetchLimit batchSize:batchSize getAsFaults:YES];
}

// no batch size
+ (NSArray *) messageForPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fetchLimit:(NSInteger)fetchLimit {
    return [self messageForPredicate:predicate sortDescriptors:sortDescriptors fetchLimit:fetchLimit batchSize:-1];
}


/*!
 @abstract Gets message with a specific ID
 
 @return array of one message is a duplicate is found 
 
 Use:
 - Check if this is a duplicate message, if so ignore it
 
 */
+ (NSArray *) messageWithMessageID:(NSString *)messageID {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(mID = %@)", messageID];
    NSArray *results = [CDMessage messageForPredicate:predicate sortDescriptors:nil fetchLimit:1];    
    return results;
    
}


/*!
 @abstract Get messages related to a specific chat
 
 @param relatedChat The chat's messages that we want to query
 @param acending    Should order by ascending sentDate?
 @param limit       Limit number of results returned 
 
 Looks for failed messages first since they should always be at the end of a dialog.
 Then look for regular messages.
 
 Use:
 - Get Last message text
 
 */
+ (NSArray *) messagesForChat:(CDChat *)relatedChat acending:(BOOL)ascending limit:(NSInteger)limit {
    
    // first check if there are failed messages
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(chat = %@) AND (state = %@)", relatedChat, [NSNumber numberWithInt:kCDMessageStateOutFailed]];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createDate" ascending:ascending];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [sortDescriptor release];
    
    NSArray *results = [CDMessage messageForPredicate:predicate sortDescriptors:sortDescriptors fetchLimit:limit];  
    [sortDescriptors release];
    
    if ([results count] > 0) {
        return results;
    }
    
    
    // don't show schedule messages (isHidden = NO)
    //
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(chat = %@) AND (isHidden = NO)", relatedChat];
    
    NSSortDescriptor *sortSent = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:ascending];
    NSSortDescriptor *sortMID = [[NSSortDescriptor alloc] initWithKey:@"mID" ascending:ascending];
    NSArray *sortSentDescriptors = [[NSArray alloc] initWithObjects:sortSent, sortMID, nil];
    [sortSent release];
    [sortMID release];
    
    results = [CDMessage messageForPredicate:pred sortDescriptors:sortSentDescriptors fetchLimit:limit];  
    [sortSentDescriptors release];
    
    return results;
}

/*!
 @abstract Gets all messages for chat
 - not as faults
 
 Use:
 - to fault all messages for a particular chat
 
 */
+ (NSArray *) messagesForChat:(CDChat *)relatedChat {
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(chat = %@)", relatedChat];
    
    NSArray *results = [CDMessage messageForPredicate:pred sortDescriptors:nil fetchLimit:-1 batchSize:-1 getAsFaults:NO];
    
    return results;
}


/*!
 @abstract Gets last X messages from userID
 
 @return last messages coming from a particular user, sorted with largest messageID first
 
 Use:
 - To compare message ID which should always be in sequence
 
 */
+ (NSArray *) messagesFromUserID:(NSString *)userID {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(contactFrom.userID = %@)", userID];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createDate" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [sortDescriptor release];
    
    NSArray *results = [CDMessage messageForPredicate:predicate sortDescriptors:sortDescriptors fetchLimit:40];  
    [sortDescriptors release];
    
    return results;
}


/*!
 @abstract Gets a new create time if the message is out of order
 
 @return nil if reorder not needed, nsdate if new create date should be set
 
 Use:
 - To compare sent time which should always be in sequence
 
 */
+ (void) reorderedCreateTimeForMPMessage:(CDMessage *)newCDMessage {
    
    // get array of message from the same users
    // - from newest to oldest create time
    NSArray *userMessages = [CDMessage messagesFromUserID:newCDMessage.contactFrom.userID];
    
    
    // is message out of order?
    // - is sentDate order same as create date order?
    //
    int i = 0;
    int foundIndex = [userMessages indexOfObject:newCDMessage]; // usally at 0
    
    CDMessage *previousMessage = nil;
    
    for (CDMessage *iMessage in userMessages) {
        
        NSComparisonResult compareResult = [newCDMessage.sentDate compare:iMessage.sentDate];
        
        // is message newer than previous ones
        // - then order is wrong!
        if (compareResult == NSOrderedDescending) {
            
            // reorder not needed, since message already in right order
            if (i == foundIndex + 1) {
                return;
            }
            else {
                break;
            }
        }
        // if same sent time is same - only int resolution
        // - then compare messageIDs for fine resolution sorting
        //
        else if ( compareResult == NSOrderedSame ) {
            
            if ([newCDMessage.mID compare:iMessage.mID] == NSOrderedDescending) {
                // reorder not needed, since message already in right order
                if (i == foundIndex + 1) {
                    return;
                }
                else {
                    break;
                }
            }
        }
        
        
        /* Compare using mID only, but this will not work if user reinstall - ID are reset
           - or scheduled messages which have old mIDs
         
        // is message newer than previous ones
        // - then order is wrong!
        if ([newCDMessage.mID compare:iMessage.mID] == NSOrderedDescending) {
            
            // reorder not needed, since message already in right order
            if (i == foundIndex + 1) {
                return;
            }
            else {
                break;
            }
        }*/
        
        i++;
        previousMessage = iMessage;
    }
    
    if (previousMessage) {
        DDLogVerbose(@"Msg: Message reorder needed for %@", newCDMessage.mID);
        NSDate *newCreateDate = [previousMessage.createDate dateByAddingTimeInterval:-0.0001];
        newCDMessage.createDate = newCreateDate;
        return;
    }
}

/*!
 @abstract Gets all messages
 
 Use:
 - used to clear all chat history
 
 */
+ (NSArray *) allMessages {
    
    NSArray *results = [CDMessage messageForPredicate:nil sortDescriptors:nil fetchLimit:-1];    
    return results;
}

/*!
 @abstract Gets all messages that are waiting to be sent out
 
 - Only includes the primay parent messages.
 - Child multicast will not be returned
 
 
 */
+ (NSArray *) scheduledMessages {
    
    NSPredicate *pred = nil;
    
    pred = [NSPredicate predicateWithFormat:@"(dateScheduled > %@) AND (state == %@)", [NSDate dateWithTimeIntervalSince1970:0], [NSNumber numberWithInt:kCDMessageStateOutScheduled]];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateScheduled" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [sortDescriptor release];
    
    NSArray *results = [CDMessage messageForPredicate:pred sortDescriptors:sortDescriptors fetchLimit:-1];
    [sortDescriptors release];
    
    return results;
}


/*!
 @abstract Gets all messages that are waiting to be sent out
 
 - Only includes the primay parent messages.
 - Child multicast will not be returned
 
 
 */
+ (NSUInteger) scheduledMessagesCount {
    
    NSPredicate *pred = nil;
    
    pred = [NSPredicate predicateWithFormat:@"(dateScheduled > %@) AND (state == %@)", [NSDate dateWithTimeIntervalSince1970:0], [NSNumber numberWithInt:kCDMessageStateOutScheduled]];
    
    NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDMessage" 
											  inManagedObjectContext:managedObjectContext];
	
	// load resource if it already exists
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
 @abstract Delete files associated to specified messages
 
 Use:
 - before deleting chats
 - before clearing message history
 
 */
+ (void) deleteFilesForMessages:(NSSet *)messages {
    
    TKFileManager *fileManager = [[TKFileManager alloc] init];
    for (CDMessage *iMessage in messages){
        [fileManager deleteFilename:iMessage.filename deletePreivew:YES];
    }
    [fileManager release];
}

/*!
 @abstract Clear messages and related files
 
 @return    can we proceed with delete chat: 
            - YES: no since SM message exist and chat should remain
            - NO: all messages can ge removed so go ahead and delete chat as well
 
 Note:
 - some messages are skipped and not cleared
   ~ enter/leave, scheduled messages
 
 Use:
 - before deleting chats
 - before clearing message history
 
 */
+ (BOOL) clearMessages:(NSSet *)messages {
    
    NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDMessage" 
											  inManagedObjectContext:managedObjectContext];
    
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:entity];
    [fetch setPredicate:[NSPredicate predicateWithFormat:@"self IN %@", [messages allObjects]] ];
    //[fetch setReturnsObjectsAsFaults:NO];
    [fetch setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"contactsTo", @"messages", @"contactsRead", @"contactFrom", @"contactsDelivered", @"contactsEntered", nil]];
                                                  
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetch error:&error];
    [fetch release];
                                                  
    BOOL shouldDeleteChat = YES;
    
    NSMutableSet *deleteMessages = [[NSMutableSet alloc] init];
    
    for (CDMessage *iMessage in results) {
        
        // - don't remove enter leave messages: 
        //    ~ delete these since there is no need to see who saw which messages, messages are all gone now
        // - don't remove pending scheduled message: parent or child
        //
        if (/*[iMessage.type intValue] != kCDMessageTypeGroupEnter && 
            [iMessage.type intValue] != kCDMessageTypeGroupLeave &&*/
            [iMessage.state intValue] != kCDMessageStateOutScheduled) {
            [deleteMessages addObject:iMessage];
        }
        else {
            shouldDeleteChat = NO;
        }
    }
    
    [CDMessage deleteFilesForMessages:deleteMessages];
    
    // if schedule message exists, we need to delete individually
    //
    for (CDMessage *iMessage in deleteMessages){
        [AppUtility cdDeleteManagedObject:iMessage];
    }

    [deleteMessages release];
    return shouldDeleteChat;
}


/*!
 @abstract Delete message given the messageID
 
 Use:
 - delete failed message that fail to be sent out
 - Scheduled and Broadcast msg failed to be sent to DS properly
 
 */
+ (void) deleteMessage:(CDMessage *)deleteMsg {
    
    if (deleteMsg) {
        // delete files
        [CDMessage deleteFilesForMessages:[NSSet setWithObject:deleteMsg]];
        [AppUtility cdDeleteManagedObject:deleteMsg];
        [AppUtility cdSaveWithIDString:@"Delete specified Msg" quitOnFail:YES];
    }
}

/*!
 @abstract Delete message given the messageID
 
 Use:
 - delete failed message that fail to be sent out
 - Scheduled and Broadcast msg failed to be sent to DS properly
 - Invite message send failed
 
 */
+ (void) deleteMessageWithID:(NSString *)messageID {
    
    CDMessage *deleteMsg = [CDMessage cdMessageWithID:messageID isMadeHere:nil];
    
    [CDMessage deleteMessage:deleteMsg];
}


/*!
 @abstract Deletes failed scheduled messages.
 
 Failed SM are caused by:
 - network issues
 - DS not responding with "sent"
 - DS rejected this scheduled message (not handled yet!)
 
 Look for SM that are still in created state.  Accepted SM should be in "scheduled out" state
 
 Use:
 - Don't delete right after creating a new SM.  There is a possible race condition
 - Delete when user has enter edit mode for SM list. - should be safe to perform at this time.
 
 */
+ (void) deleteFailedScheduledMessages {
        
    NSPredicate *pred = nil;
    
    pred = [NSPredicate predicateWithFormat:@"(dateScheduled > %@) AND (state == %@)", [NSDate dateWithTimeIntervalSince1970:0], [NSNumber numberWithInt:kCDMessageStateOutCreated]];
    
    NSArray *results = [CDMessage messageForPredicate:pred sortDescriptors:nil fetchLimit:-1];
    
    // delete all these messages
    for (CDMessage *failedSMMessage in results) {
        [AppUtility cdDeleteManagedObject:failedSMMessage];
    }
    
    [AppUtility cdSaveWithIDString:@"delete failed Schedule Msg" quitOnFail:NO];
}


/*!
 @abstract gets a message given a message ID
 
 @param messageID the messageID we search look for
 @param isMadeHere specifies if message we want is made locally or remotely. set to nil if it does not matter
 
 Use:
 - find and update the (read)state of an existing message
 
 */
+ (CDMessage *) cdMessageWithID:(NSString *)messageID isMadeHere:(NSNumber *)isMadeHere {
    
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDMessage" 
											  inManagedObjectContext:managedObjectContext];
	
    
	// load Contact from Core Data and udpate it
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *pred = nil;
    
    if (isMadeHere == nil) {
        pred = [NSPredicate predicateWithFormat:@"(mID == %@)",messageID];
    }
    else {
        pred = [NSPredicate predicateWithFormat:@"(mID == %@) AND (isMadeHere == %@)",
                messageID, isMadeHere];
    }
    
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:pred];
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    CDMessage *resultMessage = nil;
    
    if ([results count] > 0) {
        resultMessage = [results objectAtIndex:0];
    }

    return resultMessage;
}

/*!
 @abstract Mark all message as previous session
 
 Use:
 - change created messages from previous session to failed since a crash probably occurred.
 - otherwise messages stuck in created state cannot be deleted
 
 */
+ (void) markOutCreatedAsOutFailed {
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(state == %@)", [NSNumber numberWithInt:kCDMessageStateOutCreated]];
    
    NSArray *createdMessages = [CDMessage messageForPredicate:pred sortDescriptors:nil fetchLimit:-1];
    
    DDLogInfo(@"CDM: mark OutCreated as OutFailed: %d", [createdMessages count]);
    
    for (CDMessage *iMessage in createdMessages) {
        iMessage.state = [NSNumber numberWithInt:kCDMessageStateOutFailed];
    }
    
    if ([createdMessages count] > 0) {
        [AppUtility cdSaveWithIDString:@"set OutCreated as OutFailed" quitOnFail:NO];
    }
}



#pragma mark - Message Factory

/*!
 @abstract For creating child multicast messages

 */
+ (CDMessage *) outChildMessageForParentMID:(NSString *)parentMID toContact:(CDContact *)toContact messageType:(CDMessageType)messageType text:(NSString *)text attachmentObject:(id)attachmentObject hideMessage:(BOOL)hideMessage typeInfo:(NSString *)typeInfo{

    //CDChat *findChat = [CDChat chatWithCDContacts:[NSArray arrayWithObject:toContact] groupID:nil shouldSave:NO];
    
    // don't touch for scheduled msg
    // - marked by hideMessage
    CDChat *findChat = [CDChat chatWithCDContacts:[NSArray arrayWithObject:toContact] groupID:nil checkForNewGroupInvites:NO shouldCreate:YES shouldSave:NO shouldTouch:hideMessage?NO:YES];

    
    return [CDMessage outCDMessageForChat:findChat messageType:messageType text:text attachmentData:attachmentObject isMulticast:NO multicastParentMID:parentMID multicastToContacts:nil dateScheduled:nil hideMessage:hideMessage typeInfo:typeInfo shouldSave:NO];    
}


/*!
 @abstract Creates an outgoing CDMessage
 
 @param chat Chat room that we send message from (optional parameter)
 @param messageType The type of message that should be sent
 @param attachmentObject An attachment or an array of contacts for group enter message type
 
 
 @param isMulticast If multiple contacts, then create a multicast message & also gen child messages
 @param multicastParentMID The parent mID that the child should inherit
 @param multicastToContacts Who to send multicast message to
 @param dateScheduled Marks this as a scheduled message
 @param hideMessage Hides this message, so it does not get show in chat list or chat dialog until it becomes sent
 
 @param typeInfo Used to store type specific info - Letter Msg Type: LetterID
 
 Use:
 - used when a new message is created in the chat dialog
 - this CDMessage is then used to generate a MPMessage to send over the network
 
 */
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
                         shouldSave:(BOOL)shouldSave 

{
    
    // If multicast, but only 1 toContact!
    // - then create a regular P2P chat instead
    if (isMulticast) {
        NSUInteger multicastCount = [multicastToContacts count];
        if (multicastCount == 1) {
            isMulticast = NO;
            //chat = [CDChat chatWithCDContacts:[NSArray arrayWithObject:[multicastToContacts anyObject]] groupID:nil  shouldSave:YES];
            
            // if scheduled then don't touch chat
            chat = [CDChat chatWithCDContacts:[NSArray arrayWithObject:[multicastToContacts anyObject]] groupID:nil checkForNewGroupInvites:NO shouldCreate:YES shouldSave:YES shouldTouch:dateScheduled?NO:YES];
        }
        // multicast must have more than 0 contacts
        else if (multicastCount == 0) {
            return nil;
        }
    }

    
    NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDMessage" 
											  inManagedObjectContext:managedObjectContext];
	
    // create new Message
    //
    CDMessage *newMessage = [NSEntityDescription insertNewObjectForEntityForName:[entity name] 
                                                          inManagedObjectContext:managedObjectContext]; 
   
    // outgoing message
    //
    newMessage.isMadeHere = [NSNumber numberWithBool:YES];
    
    // create new message ID
    //
    if (multicastParentMID) {
        newMessage.mID = multicastParentMID;  // inherit parent's ID
    }
    else {
        newMessage.mID = [AppUtility generateMessageID];  // parent messages get their own ID
    }
    
    if ([newMessage.mID length] < 20) {
        DDLogWarn(@"Msg-ocdmfc: invalidID %@", newMessage.mID);
    }
    
    // if hidden, should also be a scheduled message
    // - child SM needs this
    if (hideMessage) {
        newMessage.isHidden = [NSNumber numberWithBool:YES];
        newMessage.isScheduled = [NSNumber numberWithBool:YES];
    }
    
    // assign scheduled date - marked as a scheduled message
    // - for parent SM
    if (dateScheduled) {
        newMessage.dateScheduled = dateScheduled;
        newMessage.isHidden = [NSNumber numberWithBool:YES];  // hide message until they are changed to sent status
        newMessage.isScheduled = [NSNumber numberWithBool:YES];
    }
    
    // associate chat
    //
    if (chat){
        
        NSManagedObjectContext *msgMOC = [newMessage managedObjectContext];
        NSManagedObjectContext *chatMOC = [chat managedObjectContext];
        if (![msgMOC isEqual:chatMOC]) {
            DDLogVerbose(@"GOT NON MATCHING MOC: %@ %@", msgMOC, chatMOC);
        }
        
        [newMessage updateChat:chat];

    }
    
    // sets message type
    // - set to gchat if needed
    //
    CDMessageType msgType = messageType;
    
    // if valid groupID, then it is a group text
    if (messageType == kCDMessageTypeText && [chat.groupID length] > 3) {
        msgType = kCDMessageTypeTextGroup;
    }
    // if valid groupID, then it is a group sticker
    else if (messageType == kCDMessageTypeSticker && [chat.groupID length] > 3) {
        msgType = kCDMessageTypeStickerGroup;
    }
    newMessage.type = [NSNumber numberWithInt:msgType];
    
    
    // add msg type specific info
    // - used by: Letter, ..
    newMessage.typeInfo = typeInfo;

    
    // set message state
    // - just created
    newMessage.state = [NSNumber numberWithInt:kCDMessageStateOutCreated];    
    newMessage.lastStateDate = [NSDate date];
    
    // set from/to contacts
    //
    newMessage.contactFrom = [CDContact mySelf];
    
    // setup text message for chat or gchat
    //
    newMessage.text = text;
    
    /*
     Generate child message for multicast
     
     - child ID will all be the same, but not the same as the parents
     - schedule child msg are hidden
     - 
     
     */
    if (isMulticast) {
        if ([multicastToContacts count] > 0) {
            [newMessage addContactsTo:multicastToContacts];
            
            // children get another ID, so it is easier to find parent first for state updates
            //
            NSString *childrenID = [AppUtility generateMessageID];

            
            // also create child messages!
            // - just like parent msg - but only a single to: recipient
            // - child msg are not sent out, only the parent is sent
            //
            for (CDContact *iContact in multicastToContacts) {
                
                BOOL shouldHide = NO;
                // hide message until they are changed to sent status
                if (dateScheduled) {
                    shouldHide = YES;
                }
                
                // create regular P2P message
                // - parent message will execute cdsave
                CDMessage *iMessage = [CDMessage outChildMessageForParentMID:childrenID toContact:iContact messageType:messageType text:text attachmentObject:attachmentObject hideMessage:shouldHide typeInfo:typeInfo];
                
                // add as an child
                [newMessage addMessagesObject:iMessage];
            }
        }
        else {
            DDLogVerbose(@"CDM: WARN multicast but no contacts!");
            return nil;
        }
    }
    // chat defined
    else if (chat) {
        [newMessage addContactsTo:chat.participants];
    }
    else {
        DDLogVerbose(@"CDM: WARN need chat or multicast contacts to create message");
        return nil;
    }
    
    // process attachment object depending the message type
    // 
    if (attachmentObject) {

        // if image attachment, create a preview
        if (messageType == kCDMessageTypeImage || 
            messageType == kCDMessageTypeLetter ||
            messageType == kCDMessageTypeLocation) {
                        
            // iOS created file name is is mID.file
            newMessage.filename = [newMessage attachmentFilename];
            
            // only create files for parent message
            // - child are not sent out
            if (!multicastParentMID) {
                // create file manager to save data
                //
                TKFileManager *fileManager = [[TKFileManager alloc] init];
                NSData *previewData = nil;
                
                // only create Preview for image & location message
                // - letters don't need previews
                if (messageType == kCDMessageTypeImage || messageType == kCDMessageTypeLocation) {
                    UIImage *compressedImage = nil;
                    UIImage *originalImage = (UIImage *)attachmentObject;
                    CGSize imageSize = [originalImage size];
                    
                    // compress image
                    // - scale is used in case of retina display
                    // - we want pixels to be less than the max width
                    //
                    if (imageSize.width*originalImage.scale > kMPParamSendImageWidthMaxPreview) {
                        // new height scaled proportionally
                        //
                        CGFloat newHeight = imageSize.height * kMPParamSendImageWidthMaxPreview/imageSize.width;
                        CGSize newSize = CGSizeMake(kMPParamSendImageWidthMaxPreview, newHeight);
                        
                        compressedImage = [UIImage imageWithImage:originalImage scaledToSize:newSize maintainScale:NO];
                    }
                    // small image, no need to compress
                    else {
                        compressedImage = originalImage;
                    }
                    
                    // set preview image and save to disk
                    //
                    newMessage.previewImage = compressedImage;
                    previewData = UIImagePNGRepresentation(compressedImage);
                    [fileManager setPreviewData:previewData forFilename:newMessage.filename];
                }
                

                // create data file for original image: only for image and letter
                // - and save to disk
                if (messageType == kCDMessageTypeImage || messageType == kCDMessageTypeLetter) {
                    
                    // keep compressing until image is small enough
                    double compressionRatio=kMPParamImageJPEGCompressionOriginal*2.0;
                    NSData *imageData = nil;
                    int compressTimes = 0;
                    while ([imageData length] > kMPParamImageMaxBytes || imageData == nil || compressTimes > 5) { 
                        compressionRatio=compressionRatio*0.50;
                        DDLogVerbose(@"CDM: image too large:%d use compression:%f - time:%d", [imageData length], compressionRatio, compressTimes);
                        imageData=UIImageJPEGRepresentation(attachmentObject,compressionRatio);
                        compressTimes++;
                    }
                    newMessage.fileData = imageData;
                    
                    //newMessage.fileData = UIImagePNGRepresentation((UIImage *) attachmentObject);
                    
                    [fileManager setFileData:newMessage.fileData forFilename:newMessage.filename];
                    DDLogVerbose(@"CDM-nom: create preview file:%d large file: %d", [previewData length], [newMessage.fileData length]);
                    
                    // store length of message - to track progress
                    NSUInteger attachmentLength = [newMessage.fileData length];
                    newMessage.attachLength = [NSNumber numberWithInteger:attachmentLength];
                }
                [fileManager release];
            }
        }
    }
    
    // save to CD
    //
    if (shouldSave) {
        if ([AppUtility cdSaveWithIDString:@"save newOutCDMessageForChat" quitOnFail:NO] != NULL) {
            return nil;
        }
    }
    return newMessage;
}

/*!
 @abstract Creates an outgoing CDMessage
 
 @param messageType the type of message that should be sent
 @param attachmentObject can be an attachment or array of contacts for group enter message type
 
 Use:
 - for 95% basic message creation
 - following message cannot use
   ~ Broadcast, Scheduled, Letter!
 
 */
+ (CDMessage *) outCDMessageForChat:(CDChat *)chat 
                        messageType:(CDMessageType)messageType 
                               text:(NSString *)text 
                     attachmentData:(id)attachmentObject
                         shouldSave:(BOOL)shouldSave {
    
    return [CDMessage outCDMessageForChat:chat messageType:messageType text:text attachmentData:attachmentObject isMulticast:NO multicastParentMID:nil multicastToContacts:nil dateScheduled:nil hideMessage:NO typeInfo:nil shouldSave:shouldSave];

}


/*!
 @abstract creates outgoing message given chat objectID
 
 Use:
 - if chat object was from another thread: main thread creating message in background
 
 */
+ (CDMessage *) outCDMessageForChatObjectID:(NSManagedObjectID *)objectID
                        messageType:(CDMessageType)messageType 
                               text:(NSString *)text 
                     attachmentData:(id)attachmentObject
                         shouldSave:(BOOL)shouldSave {
 
    NSManagedObjectContext *moc = [AppUtility cdGetManagedObjectContext];
    CDChat *thisChat = (CDChat *)[moc objectWithID:objectID];
    
    return [self outCDMessageForChat:thisChat messageType:messageType text:text attachmentData:attachmentObject shouldSave:shouldSave];
}


/*!
 @abstract Creates an outgoing CDMessage given only ToContacts
 
 Use:
 - for testing mainly or if we are lazy about finding the chat related to these contacts
 
 */
+ (CDMessage *) outCDMessageForContacts:(NSArray *)toContacts
                           messageType:(CDMessageType)messageType 
                                  text:(NSString *)text 
                        attachmentData:(id)attachmentObject
                                shouldSave:(BOOL)shouldSave {
    
    
    CDChat *findChat = [CDChat chatWithCDContacts:toContacts groupID:nil shouldSave:YES];
    
    return [self outCDMessageForChat:findChat messageType:messageType text:text attachmentData:attachmentObject shouldSave:shouldSave];
}


/*!
 @abstract Creates an outgoing CDMessage given only ToContacts
 

 
 Use:
 - mainly for broadcast messages or scheduled message when a CDChat is not already available
 
 */
+ (CDMessage *) outCDMessageForContacts:(NSArray *)toContacts
                            messageType:(CDMessageType)messageType 
                                   text:(NSString *)text 
                         attachmentData:(id)attachmentObject 
                            isMulticast:(BOOL)isMulticast 
                          dateScheduled:(NSDate *)dateScheduled
                             shouldSave:(BOOL)shouldSave {
    
    
    CDChat *findChat = [CDChat chatWithCDContacts:toContacts groupID:nil shouldSave:YES];
    
    return [self outCDMessageForChat:findChat messageType:messageType text:text attachmentData:attachmentObject shouldSave:shouldSave];
}

/*!
 @abstract Duplicates and forwards message to specified contacts
 
 */
+ (CDMessage *) forwardMessage:(CDMessage *)originalMessage toChat:(CDChat *)forwardChat {
    
    id fileObject = nil;
    CDMessageType msgType = [originalMessage.type intValue];
    
    if (msgType == kCDMessageTypeLocation) {
        fileObject = originalMessage.previewImage;
    }
    else if (msgType == kCDMessageTypeImage || msgType == kCDMessageTypeLetter) {
        fileObject = [originalMessage fullImage];
    }
    
    CDMessage *newMessage = [CDMessage outCDMessageForChat:forwardChat
                                                  messageType:[originalMessage.type intValue] 
                                                         text:originalMessage.text  
                                               attachmentData:fileObject 
                                                  isMulticast:NO 
                                           multicastParentMID:nil 
                                          multicastToContacts:nil 
                                                dateScheduled:nil 
                                                  hideMessage:NO 
                                                     typeInfo:originalMessage.typeInfo 
                                                   shouldSave:YES];
    
    
    
    
    return newMessage;
}



/*!
 @abstract creates a new CDMessage from a new incoming MPMessage
 
 @param mpMessage message from network to add as a chat message
 
 @return
 success		CDMessage
 fail			nil         duplicate message, invalid address, could not save
 
 */
+ (CDMessage *) cdMessageFromInComingMPMessage:(MPMessage *)mpMessage 
                                        cdChat:(CDChat *)newChat 
                                    shouldSave:(BOOL)shouldSave 
                                         error:(NSError **)anError {
    
	
    // Check if message already exists
    // - if so, then we should ignore it
    // - this may occur if we didn't have a chance to send a delivered message back to DS
    //
    NSArray *existingMessages = [CDMessage messageWithMessageID:mpMessage.mID];
    if ([existingMessages count] > 0) {
        DDLogWarn (@"Msg: duplicate mID found! %@", mpMessage.mID);
        if (anError != NULL) {
            *anError = [NSError errorWithDomain:@"CDMessageError" code:kCDMessageErrorDuplicateMID userInfo:nil];
        }
        return nil;
    }
    
    // Verify the address are correct
    // 
    NSDictionary *fromContact = [mpMessage fromContactsDictionary];
    NSArray *toContacts = [mpMessage toContactsDictionaries];
    if (fromContact == nil || toContacts == nil) {
        DDLogWarn (@"MS: Ignore New InMsg - WARN invalid address from:%@ to:%@", fromContact, toContacts);
        if (anError != NULL) {
            *anError = [NSError errorWithDomain:@"CDMessageError" code:kCDMessageErrorInvalidAddress userInfo:nil];
        }
        return nil;
    }
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDMessage" 
											  inManagedObjectContext:managedObjectContext];
	
    // create new Message
    //
    CDMessage *newMessage = [NSEntityDescription insertNewObjectForEntityForName:[entity name] 
                                                          inManagedObjectContext:managedObjectContext]; 
    // set message ID
    //
    newMessage.mID = mpMessage.mID;
    
    
    // incoming message
    //
    newMessage.isMadeHere = [NSNumber numberWithBool:NO];
    
    // set chat
    //
    [newMessage updateChat:newChat];
    
    
    // set sequence number
    //
    newMessage.sequenceNumber = [mpMessage sequenceNumber];
    newMessage.sequenceTotal = [mpMessage sequenceTotal];
    
    // set the correct message type
    //
    NSString *action = [mpMessage.properties valueForKey:kMPMessageKeyAction];
    NSString *sticker = [mpMessage.properties valueForKey:kMPMessageKeySticker];
    NSString *letterID = [mpMessage.properties valueForKey:kMPMessageKeyLetter];
    
    // if chat or group chat -> text
    if ([mpMessage.mType isEqualToString:kMPMessageTypeChat]) {
        
        newMessage.type = [NSNumber numberWithInt:kCDMessageTypeText];

        if ([sticker isEqualToString:@"yes"]) {
            newMessage.type = [NSNumber numberWithInt:kCDMessageTypeSticker];
        }
    }
    else if ([mpMessage.mType isEqualToString:kMPMessageTypeChat] || 
        [mpMessage.mType isEqualToString:kMPMessageTypeGroupChat]) {
        
        newMessage.type = [NSNumber numberWithInt:kCDMessageTypeText];
        
        if ([sticker isEqualToString:@"yes"]) {
            newMessage.type = [NSNumber numberWithInt:kCDMessageTypeSticker];
        }
        // check if group action
        else if ([action isEqualToString:@"leave"])
        {
            newMessage.type = [NSNumber numberWithInt:kCDMessageTypeGroupLeave];
        }
    }
    // if image -> image or letter
    // - it stored in typeInfo
    //
    else if ([mpMessage.mType isEqualToString:kMPMessageTypeImage]){
        if (letterID) {
            newMessage.type = [NSNumber numberWithInt:kCDMessageTypeLetter];
            newMessage.typeInfo = letterID;
        }
        else {
            newMessage.type = [NSNumber numberWithInt:kCDMessageTypeImage];
        }
    }
    // if location -> location
    else if ([mpMessage.mType isEqualToString:kMPMessageTypeLocation]) {
        newMessage.type = [NSNumber numberWithInt:kCDMessageTypeLocation];
    }
    // if audio -> audio
    //else if ([mpMessage.mType isEqualToString:kMPMessageType
    
    // set the sent date
    //
    newMessage.sentDate = [mpMessage sentDate];
    
    // set message state
    // - from me, then msg was just created
    // - also set to and from contacts
    //
    newMessage.state = [NSNumber numberWithInt:kCDMessageStateInDelivered]; 
    /*if ([mpMessage isFromSelf]){
        newMessage.state = [NSNumber numberWithInt:kCDMessageStateOutCreated];
        // from self & to
    }
    // - from others, then delivered
    else {
        newMessage.state = [NSNumber numberWithInt:kCDMessageStateInDelivered];    
    }*/
    
    // add from contact
    //
    NSString *userID = [fromContact objectForKey:kMPMessageKeyUserID];
    NSString *nick = [fromContact valueForKey:kMPMessageKeyNickName];
    NSString *domain = [fromContact valueForKey:kMPMessageKeyDomain];
    NSString *fromAddress = [fromContact valueForKey:kMPMessageKeyFromAddress];
    
    // don't save yet, save at the end
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
                                           shouldSave:NO shouldUpdate:NO];
    
    // TODO: critical event
    if (!newFrom) {
        DDLogWarn (@"MS: Ignore New InMsg - WARN invalid from u:%@ n:%@ d:%@", userID, nick, domain);
        [[AppUtility cdGetManagedObjectContext] deleteObject:newMessage];
        if (anError != NULL) {
            *anError = [NSError errorWithDomain:@"CDMessageError" code:kCDMessageErrorInvalidAddress userInfo:nil];
        }

        return nil;
    }
    newMessage.contactFrom = newFrom;
    

    BOOL isGroupChat = [newChat isGroupChat];
    NSString *myUserID = [[MPSettingCenter sharedMPSettingCenter] getUserID];

    // add to contacts
    //
    for (NSDictionary *iContactD in toContacts){
        BOOL shouldAddContact = YES;
        NSString *userID = [iContactD objectForKey:kMPMessageKeyUserID];
        
        // if not group chat (broadcast chat), then only add myself as to address
        // - this helps unknown contacts from being added to friend suggestions
        // - only add contact who are in group chat or non-friends who send you a message as friend suggestions
        //
        if (!isGroupChat && ![userID isEqualToString:myUserID]) {
            shouldAddContact = NO;
        }
        
        if (shouldAddContact) {
            NSString *nick = [iContactD valueForKey:kMPMessageKeyNickName];
            NSString *domain = [iContactD valueForKey:kMPMessageKeyDomain];
            NSString *fromAddress = [iContactD valueForKey:kMPMessageKeyFromAddress];
            
            CDContact *iContact = [CDContact contactWithUserID:userID
                                                      nickName:nick
                                              domainServerName:fromAddress
                                             domainClusterName:domain
                                                 statusMessage:nil
                                                headShotNumber:NSNotFound
                                                      presence:NSNotFound
                                                     loginDate:nil
                                                   addAsFriend:NO
                                                    shouldSave:NO shouldUpdate:NO];
            
            if (!iContact) {
                DDLogWarn (@"MS:WARN - Ignore Invalid ToContact u:%@ n:%@ d:%@", userID, nick, domain);
                [[AppUtility cdGetManagedObjectContext] deleteObject:newMessage];
                
                if (anError != NULL) {
                    *anError = [NSError errorWithDomain:@"CDMessageError" code:kCDMessageErrorInvalidAddress userInfo:nil];
                }
                return nil;
            }
            [newMessage addContactsToObject:iContact];
        }
    }
    
    // set date to now
    //
    newMessage.lastStateDate = [NSDate date];
    
    // set text string
    //
    newMessage.text = mpMessage.text;
    
    // set file information
    //
    // do later - after design file manager
    
    
    // gets the downloadURL
    //
    newMessage.downloadURL = [mpMessage downloadURL];
    newMessage.attachLength = [NSNumber numberWithInteger:mpMessage.attachLength];
    
    // gets filename
    //
    newMessage.filename = [mpMessage valueForProperty:kMPMessageKeyFilename];
    
    // get preview image
    //
    if (mpMessage.previewImageData && newMessage.filename){
        
        newMessage.previewImage = [UIImage imageWithData:mpMessage.previewImageData];
        
        // save to file manager
        //
        TKFileManager *fileManager = [[TKFileManager alloc] init];
        [fileManager setPreviewData:mpMessage.previewImageData forFilename:newMessage.filename];
        [fileManager release];
        
    }
    
    // mht: 12/5/6 removed since we change back to sort by sent time in chat dialog
    // adjust new create time if out of order
    // [CDMessage reorderedCreateTimeForMPMessage:newMessage];
    
    // save to CD
    //
    if (shouldSave) {
        if ([AppUtility cdSaveWithIDString:@"save newCDMessageFromInComingMPMessage" quitOnFail:YES] != NULL) {
            if (anError != NULL) {
                *anError = [NSError errorWithDomain:@"CDMessageError" code:kCDMessageErrorSaveFailed userInfo:nil];
            }

            return nil;
        }
    }
    return newMessage;
}

#pragma mark - Image Source


@end
