//
//  ChatDialogController.m
//  mp
//
//  Created by M Tsai on 11-9-22.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "DialogTableController.h"
#import "MPFoundation.h"


#import "MPChatManager.h"
#import "CDChat.h"
#import "CDContact.h"
#import "CDMessage.h"
#import "CDResource.h"

#import "MPContactManager.h"

#import "DialogInfoCellController.h"

#import "MediaImageController.h"
#import "MediaLetterController.h"
#import "LocationShareController.h"
#import "TKTableView.h"

#import "ChatSettingController.h"


/*! how many read messages should be show without loading more */
NSUInteger const kMPParamMessageCountInitial = 10;
NSUInteger const kMPParamMessageCountLoadMore = 50;

NSString* const MP_DAILOG_UPDATE_NAME_NOTIFICATION = @"MP_DAILOG_UPDATE_NAME_NOTIFICATION";

NSString* const kMPParamMessageTextStickerVibrate = @"(vibrate)";

/*! robot commands */
NSString* const kDTCRobotStartEcho = @"rsecho";
NSString* const kDTCRobotStartSend = @"rssend";





@interface DialogTableController (PrivateMethods)
- (void) setButtons;
@end

@implementation DialogTableController

@synthesize delegate;
@synthesize cdChat;
@synthesize messages;
@synthesize messageCells;

@synthesize readMessageCount;
@synthesize allMessageShowing;
@synthesize keyboardHeight;
@synthesize firstMessageEver;
@synthesize tempMessage;
@synthesize parentController;
@synthesize firstRun;

@synthesize pendingHiddenChat;
@synthesize imageManager;

@synthesize runningRobot;
@synthesize lastSentRobotMessage;

@synthesize shouldScrollToBottomAfterReload;

@synthesize throttleScrollToLastTimer;

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // clear delegates to avoid crash
    // - e.g. hide progress bar runs on a timer that can fire after table deallocs, then crash
    //
    for (id iCellController in self.messageCells) {
        if ([iCellController respondsToSelector:@selector(setDelegate:)]) {
            [iCellController setDelegate:nil];
        }
    }
    
    imageManager.delegate = nil;
    [imageManager release];
    
    [firstMessageEver release];
    [cdChat release];
    [messages release];
    [messageCells release];
    
    [tempMessage release];
    [pendingHiddenChat release];
    [lastSentRobotMessage release];
    [throttleScrollToLastTimer release];
    
    //[parentController release];
    [super dealloc];
}



- (id)initWithStyle:(UITableViewStyle)style cdChat:(CDChat *)newChat parentController:(UIViewController *)controller
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.cdChat = newChat;
        self.parentController = controller;        
        self.firstRun = YES;
        
        self.readMessageCount = kMPParamMessageCountInitial;
        self.allMessageShowing = NO;
        self.runningRobot = kDTCRobotNone;
        
        self.shouldScrollToBottomAfterReload = YES;
        
        MPImageManager *newIM = [[MPImageManager alloc] init];
        newIM.delegate = self;
        self.imageManager = newIM;
        [newIM release];
        
        
        // Listen to new message notifications
        //
        
        // new in-coming messages
        //
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(addNewMessageFromNotification:) name:MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION object:nil];
        
        // msg status updates
        //
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(addMessageUpdateFromNotification:) name:MP_CHATMANAGER_UPDATE_MESSAGE_NOTIFICATION object:nil];
        
        // history cleared
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMessages:) name:MP_CHAT_CLEAR_HISTORY_NOTIFICATION object:nil];
        
        // invite message deleted
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMessages:) name:MP_CHATSETTING_DELETE_INVITE_NOTIFICATION object:nil];
        
        // multimsg message received
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMessages:) name:MP_CHATMANAGER_NEW_MULTIMSG_NOTIFICATION object:nil];
        
        // upload progress updates
        //
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(updateMessageProgress:) name:MP_SOCKETCENTER_WRITE_PROGRESS_NOTIFICATION object:nil];
        
        
        // listen for presence state change
        // - so we can update when it changes
        //
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleContactReload:) name:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleContactReload:) name:MP_CONTACTMANAGER_INDEX_NOTIFICATION object:nil];
        
        
        [[NSNotificationCenter defaultCenter] removeObserver:self.tableView name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self.tableView name:UIKeyboardWillHideNotification object:nil];
        
    }
    return self;
}




- (void)didReceiveMemoryWarning
{
    DDLogInfo(@"DTC: receive low memory warning");

    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Tools



/*!
 @abstract gets the last 10 message + all undread messages
 
 Use:
 - which msg should be displayed initially
 
 */
- (NSArray *)getMessagesMaxReadCount:(NSUInteger)maxReadCount {
    
    // reset first message
    self.firstMessageEver = nil;
    
    NSMutableArray *latestMessages = [[[NSMutableArray alloc] init] autorelease];
    
    
    // messages sorted by sent time - ascending
    NSArray *sortedMessages = [self.cdChat sortedMessagesBySentDate];
    
    if ([sortedMessages count] > 0) {
        self.firstMessageEver = [sortedMessages objectAtIndex:0];
    }
    
    NSEnumerator *reverseE = [sortedMessages reverseObjectEnumerator];
    
    CDMessage *object;
        
    int readCount = 0;
    while ((object = [reverseE nextObject])) {
        
        CDMessageState msgState = [object getStateValue];
        
        // from myself so is read
        //
        if ([object isFromSelf] && msgState != kCDMessageStateOutFailed) {
            readCount++;
        }
        // if message from others & is read, increament read count
        else if (msgState == kCDMessageStateInRead) {
            readCount++;
        }
        // otherwise message is unread and should be added without increment
        // - skip over hidden messages
        //
        if ([[object isHidden] boolValue] == NO) {
            [latestMessages insertObject:object atIndex:0];
        }
        
        if (readCount > maxReadCount) {
            break;
        }
        if ([object isEqual:self.firstMessageEver]) {
            self.allMessageShowing = YES;
        }
    }
    return latestMessages;
}




#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    DDLogInfo(@"DTC: view did load");

    // Replace tableview with customized one
    //
    TKTableView *myTV = [[TKTableView alloc] init];
    myTV.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView = myTV;
    [myTV release];
    
    
    // size table view
    //
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    self.tableView.frame = CGRectMake(0.0, 0.0, appFrame.size.width, appFrame.size.height-kMPParamDialogToolBarHeight);
    
    //self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine; 
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];

    //self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    // set content insets
    [self clearContentInsets];
    
    // add footer buffer
    // - makes sure text is not hidden by light bulb
    //
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
    footerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footerView;
    [footerView release];
    
}

- (void)viewDidUnload
{
    DDLogInfo(@"DTC: did unload");
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    DDLogInfo(@"DTC: vwa");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    DDLogInfo(@"DTC: vda");
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Data Model

/*!
 @abstract Find the previous message given the one of interest
 
 Usage:
 - Find previous message to check if a message needs to be reordered since it state just change to "Sent"
 
 */

- (CDMessage *) getPreviousMessageForMessage:(CDMessage *)message {
    
    NSEnumerator *reverseE = [self.messages reverseObjectEnumerator];
    CDMessage *iMessage;
    
    BOOL returnNextMessage = NO;
    
    while ((iMessage = [reverseE nextObject])) {
        if (returnNextMessage) {
            return iMessage;
        }
        
        if (iMessage == message) {
            returnNextMessage = YES;
        }
    }
    return nil;
}


/*!
 @abstract Get last cell that was successfull sent or received
 
 Use:
 - helps find the last message to show in the dialog
 
 */
- (NSIndexPath *) getLastSuccessfulMessageIndexPath {
    
    NSUInteger cellCount = [self.messageCells count];
    
    // look for row backwards
    for (int row=cellCount-1; row >= 0; row--) {
        id iCell = [self.messageCells objectAtIndex:row];
        if ([iCell respondsToSelector:@selector(cdMessage)]) {
            
            CDMessage *iMessage = [iCell performSelector:@selector(cdMessage)];
            
            if ([iMessage getStateValue] != kCDMessageStateOutFailed &&
                [iMessage getStateValue] != kCDMessageStateOutCreated) {
                return [NSIndexPath indexPathForRow:row inSection:0];
            }
        }
    }
    return nil;
}

/*!
 @abstract Finds a previous message with a valid sent date
 
 Use:
 - finds a valid sent date to compare to decide if a date message should appear
 - helps skip over locally generated group control message that do not have sent dates
 */

- (NSDate *) getPreviousSentDateInCells:(NSArray *)cells {
    
    NSEnumerator *reverseE = [cells reverseObjectEnumerator];
    id object;
    
    while ((object = [reverseE nextObject])) {
        
        if ([object respondsToSelector:@selector(cdMessage)]) {
            CDMessage *iMessage = [object cdMessage];
            
            NSDate *iDate = iMessage.sentDate;
            
            if (iDate) {
                return iDate;
            }
        }
    }
    return nil;

}


/*!
 @abstract checks if a dateview should be added
 
 @param message     Message to add to chat
 @param cells       Existing cell controllers
 
 @return indexpath if date was added, nil if no date added
 
 - is last message a different date? - Y add a date view
 */
 
- (NSIndexPath *) checkAndAddDateView:(CDMessage *)newMessage 
             previousMessage:(CDMessage *)previousMessage 
                       cells:(NSMutableArray *)cells {
    
    NSDate *lastDate = [Utility stripTimeFromDate:previousMessage.sentDate];
    NSDate *thisDate = [Utility stripTimeFromDate:newMessage.sentDate];
    
    /*
     If dates do not exists, fall back on the create dates.
     This is helpful in following situations:
      - When either message are local group control message which don't have sent dates
      - If a message was just created and sent was not returned yet by DS
      - CreateDate can be inaccurate for msg received from DS, but these have sentDates!
     
     
    if (!lastDate) {
        lastDate = [Utility stripTimeFromDate:previousMessage.createDate];
    }*/
    
    // allow new messages to show date message in between
    // - failed messages will not show date message in between
    //
    if (thisDate == nil && [newMessage getStateValue] == kCDMessageStateOutCreated) {
        thisDate = [Utility stripTimeFromDate:newMessage.createDate];
    }
    
    
    NSDate *printDate = nil;
    
    // * last date must exists to print time
    // 1) both dates exists && this day is different
    // 2) if this is the first message ;)
    if ( (thisDate && lastDate && [thisDate compare:lastDate] != NSOrderedSame) || previousMessage == nil) {
        
        if (thisDate) {
            printDate = thisDate;
        }
        // if this message has not been sent yet, so probably just create
        // - use today's date
        else {
            printDate = [Utility stripTimeFromDate:[NSDate date]];
        }
    }
    
    // create date cell and append it
    //
    if (printDate) {
        
        NSString *dateString = [Utility stringForDate:printDate componentString:@"yMdEEEE"];

        DialogInfoCellController *controller = [[DialogInfoCellController alloc] initWithInfo:dateString messageType:kDInfoTypeDate];
        [cells addObject:controller];
        [controller release];
        
        return [NSIndexPath indexPathForRow:[cells count]-1 inSection:0];
    }
    return nil;
}


/*!
 @abstract Finds cell index to insert a message's cell given it's message order insert location
 
 @return index to insert in to self.messageCells, NSNotFound if no valid index available
 */

- (NSInteger) cellInsertIndexForMessageInsertIndex:(NSInteger)msgInsertIndex {
    
    if (msgInsertIndex == NSNotFound) {
        return NSNotFound;
    }
    
    // look for message afterwards
    // - we want to be right next to this
    //
    CDMessage *followingMessage = [self.messages objectAtIndex:msgInsertIndex];
    
    NSInteger cellInsertIndex = NSNotFound;
    
    int i = 0;
    int previousMessageCell = 0;
    for (id cellController in self.messageCells) {
        
        if ([cellController respondsToSelector:@selector(cdMessage)]) {
            CDMessage *iMessage = [(DialogMessageCellController *)cellController cdMessage];
            if ([iMessage isEqual:followingMessage]) {
                
                // insert before join messages
                // - don't want to split up control and join messages
                //
                if ([iMessage isGroupControlMessage]) {
                    cellInsertIndex = previousMessageCell + 1;
                }
                else {
                    cellInsertIndex = i;
                }
                break;
            }
            previousMessageCell = i;
        }
        i++;
    }
    return cellInsertIndex;
}

/*!
 @abstract checks if a dateview should be added
 
 @param message         Message to add to chat
 @param cells           Existing cell controllers
 @param insertIndex     Where to insert this message in self.messages
 
 @return indexpath if date was added, nil if no date added
 
 - is last message a different date? - Y add a date view
 */

- (NSIndexPath *) addGroupLeaveView:(CDMessage *)newMessage cells:(NSMutableArray *)cells insertIndex:(NSInteger)insertIndex {
    
    NSString *actionString = nil;
    CDMessageType thisType = [newMessage.type intValue];
    if (thisType == kCDMessageTypeGroupLeave) {
        actionString = [NSString stringWithFormat:NSLocalizedString(@"%@ left", @"DialogMessage - text: User left group chat"), [newMessage.contactFrom displayName]];
        
        DialogInfoCellController *controller = [[DialogInfoCellController alloc] initWithInfo:actionString messageType:kDInfoTypeLeave];
        
        NSInteger cellInsertIndex = [self cellInsertIndexForMessageInsertIndex:insertIndex];
        
        NSIndexPath *resultIP = [NSIndexPath indexPathForRow:[cells count] inSection:0];
        if (cellInsertIndex == NSNotFound) {
            [cells addObject:controller];
        }
        else {
            resultIP = [NSIndexPath indexPathForRow:cellInsertIndex inSection:0];
            [cells insertObject:controller atIndex:cellInsertIndex];
        }
        [controller release];
        return resultIP;
    }
    return nil;
}

/*!
 @abstract gets the last real message to find new joins
 
 Excluding: date, join, left messages
 
 */
- (CDMessage *) getLastRealMessageInCells:(NSArray *)cells {
    
    NSEnumerator *reverseE = [cells reverseObjectEnumerator];
    id object;
    
    while ((object = [reverseE nextObject])) {
        
        if ([object respondsToSelector:@selector(cdMessage)]) {
            CDMessage *iMessage = [object cdMessage];
            
            CDMessageType msgType = [iMessage.type intValue];
            
            if (msgType != kCDMessageTypeGroupLeave || msgType != kCDMessageTypeGroupEnter ) {
                return iMessage;
            }
        }
    }
    return nil;
}


/*!
 @abstract checks if a join views should be added
 
 @return Array of IndexPaths that was just added
 
 - is last message a different date? - Y add a date view
 
 */
- (NSArray *) addGroupJoinView:(CDMessage *)newMessage cells:(NSMutableArray *)cells {
    
    // only for group chats
    if (![newMessage.chat isGroupChat]) {
        return nil;
    }
    
    CDMessage *lastRealMessage = [self getLastRealMessageInCells:cells];
    
    NSSet *invitedContacts = nil;
    
    // compare with previous message
    if (lastRealMessage) {
        NSMutableSet *lastParticipants = [lastRealMessage getAllParticipants];
        NSMutableSet *thisParticipants = [newMessage getAllParticipants];
        
        // did this message increase in size?
        //
        [thisParticipants minusSet:lastParticipants];
        if ([thisParticipants count] > 0) {
            invitedContacts = thisParticipants;
        }
    }
    // this is the first message or will be the first message
    else if ([newMessage.mID isEqualToString:self.firstMessageEver.mID] || self.firstMessageEver == nil) {
        invitedContacts = [newMessage getAllParticipants];
    }
    
    if (invitedContacts) {
        
        // sort contacts by name
        //
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [sortDescriptor release];
        
        NSArray *sortedContacts = [invitedContacts sortedArrayUsingDescriptors:sortDescriptors];
        [sortDescriptors release];
        
        NSMutableArray *newIPs = [[[NSMutableArray alloc] initWithCapacity:[sortedContacts count]] autorelease];
        
        for (CDContact *iContact in sortedContacts){
            
            NSString *actionString = [NSString stringWithFormat:NSLocalizedString(@"%@ joined", @"DialogMessage - text: User joined group chat"), [iContact displayName]];
            
            DialogInfoCellController *controller = [[DialogInfoCellController alloc] initWithInfo:actionString messageType:kDInfoTypeJoin];
            [cells addObject:controller];
            [controller release];
            
            [newIPs addObject:[NSIndexPath indexPathForRow:[cells count]-1 inSection:0]];
        }
        
        if ([newIPs count] > 0) {
            return newIPs;
        }
    }
    return nil;
}



/*!
 @abstract Add message to a cell controller list
 
 @param message             Message to add to chat
 @param cells               Existing cell controllers
 @param checkOrder          Should we check order and insert in the right location.
 @param shouldMarkRead      Should we mark message read - set to NO when constructing the table from DB since this is done in a batch
 @param shouldSaveRead      Should save when message is marked as read
 
 @return array of IndexPaths of cells added
 
 Handles:
 - insert of date messages
 - insert group join messages
 
 Use:
 - construct initial cells
 - when new messages arrives
 - load more
    ~ create prepend cells including previous first message
    ~ then replace head messageCells head with new prepend cells
 
 */
- (NSArray *) addMessage:(CDMessage *)message previousMessage:(CDMessage *)previousMessage cells:(NSMutableArray *)cells checkOrder:(BOOL)checkOrder shouldMarkRead:(BOOL)shouldMarkRead shouldSaveRead:(BOOL)shouldSaveRead {
    
    CDMessageState msgState = [message getStateValue];
    
    NSMutableArray *ips = [[[NSMutableArray alloc] init] autorelease];
    
    // check if duplicate message being added
    // - otherwise duplicate msg may show if mem warning + sending letter || location
    //
    if ([self.messages count] > 0 && [self.messages indexOfObject:message] != NSNotFound) {
        DDLogWarn(@"DTC: detected duplicate (dont' add) %@ - %@", message.text, message.mID);
        return ips;  // empty array
    }
    
    // if message needs to be inserted above
    // - change the previous message and find the correct index
    //
    NSInteger msgInsertIndex = NSNotFound;
    if (checkOrder) {
        
        // reorder if
        // - NOT a failed message AND
        // - NOT a newly created msg AND
        // - (sent date is NOT descending OR previous is a failed message)
        //
        NSUInteger messageCount = [self.messages count];
        if (messageCount > 0 && 
            msgState != kCDMessageStateOutCreated &&
            msgState != kCDMessageStateOutFailed &&
            ([message.sentDate compare:previousMessage.sentDate] != NSOrderedDescending ||
             [previousMessage getStateValue] == kCDMessageStateOutFailed
             )
            ) 
        {
            
            NSEnumerator *reverseE = [self.messages reverseObjectEnumerator];

            CDMessage *iMessage = nil;
            int i = 0;
            while (iMessage = [reverseE nextObject]) {   
                DDLogInfo(@"DTC: compare iMessage: %@ - %@", iMessage.text, iMessage.mID);

                CDMessageState iState = [iMessage getStateValue];
                // don't compare with failed messages or created messages
                if (iState != kCDMessageStateOutFailed &&
                    iState != kCDMessageStateOutCreated) {
                    
                    NSComparisonResult compareSentDate = [message.sentDate compare:iMessage.sentDate];
                    
                    // msg date is greater the this msg
                    // - then msg should be right after this msg
                    //
                    if ( compareSentDate == NSOrderedDescending) 
                    {
                        msgInsertIndex = messageCount - i;
                        DDLogInfo(@"DTC: insert %@ at %d/%d - %@", message.text, msgInsertIndex, messageCount, message.mID);
                        break;
                    }
                    // is sent date is the same
                    // - check mID
                    else if (compareSentDate == NSOrderedSame){
                        // if mID is greater than this mID
                        // - then msg should be right after this msg
                         NSComparisonResult compMID = [message.mID compare:iMessage.mID];
                        if (compMID == NSOrderedDescending) {
                            msgInsertIndex = messageCount - i;
                            DDLogInfo(@"DTC: insert %@ at %d/%d - %@", message.text, msgInsertIndex, messageCount, message.mID);
                            break;
                        }
                        else if (compMID == NSOrderedSame) {
                            DDLogWarn(@"DTC: detected duplicate (dont' add) %@ - %@", message.text, message.mID);
                            return ips;  // empty array
                        }
                        
                        // otherwise check next
                    }
                    // check next 
                }
                i++;
            }
            
            // if message older than all messages
            // - belong on top?
            // 
            // test by: receive messages, cut off network, clear chat history, turn off network
            // - then DS will send an old message that should be reordered to the top
            //
            if (msgInsertIndex == NSNotFound) {
                
                CDMessage *firstMessage = [self.messages objectAtIndex:0];
                
                NSComparisonResult compareFirstDate = [message.sentDate compare:firstMessage.sentDate];

                
                if (compareFirstDate == NSOrderedAscending) {
                    msgInsertIndex = 0;
                    DDLogWarn(@"DTC: insert at 0 - sent time is smaller: %@", message.mID);
                }
                else if (compareFirstDate == NSOrderedSame) {
                    NSComparisonResult compMID = [message.mID compare:firstMessage.mID];
                    if (compMID == NSOrderedAscending) {
                        DDLogWarn(@"DTC: insert at 0 - mID is smaller: %@", message.mID);
                        msgInsertIndex = 0;
                    }
                }
                else {
                    DDLogWarn(@"DTC: no insert location found mID: %@", message.mID);
                }
                
                
                /*old create time sorting
                 
                // check if message should be inserted at the start
                // - should be very close in time, otherwise it is further back in time, depends on time set when reordered
                //   see chat manager process in-coming message
                //
                NSTimeInterval timeDiff = [message.createDate timeIntervalSinceDate:[[self.messages objectAtIndex:0] createDate]];
                
                if ( timeDiff > -0.001 && timeDiff < 0.001 ) {
                    msgInsertIndex = 0;
                }
                // otherwise it does not need to be shown
                // - load more will show it
                 */
                 
            }
            
            
            // if at the end anyways, then no insert needed
            if (msgInsertIndex == messageCount) {
                DDLogWarn(@"DTC: insert at end == no insert: %@", message.mID);
                msgInsertIndex = NSNotFound;
            }
            // run an assert to catch a bad mistake
            else {
                NSAssert(msgInsertIndex < messageCount, @"crash: message reorder index is out of bounds!");
            }
            
        }
        // check if a message should be place before a join control message
        // - if message has less participants than a control message's participants
        //
        /* else if ([previousMessage isGroupControlMessage]) {

            NSMutableSet *prevParticipants = [previousMessage getAllParticipants];
            NSMutableSet *thisParticipants = [message getAllParticipants];
            
            // new msg has less participants, then msg should go before the join control message
            //
            [prevParticipants minusSet:thisParticipants];
            if ([prevParticipants count] > 0) {
                msgInsertIndex = messageCount - 1;
            } 
        } */
        
        // reset the previous message
        //
        if (msgInsertIndex != NSNotFound) {
            if (msgInsertIndex == 0) {
                previousMessage = nil;
            }
            else {
                previousMessage = [self.messages objectAtIndex:msgInsertIndex-1];
            }
            
        }
        
    } // end check order
    
    
    /*
     
     Don't insert date messsage for insert messages
     - possibly may need one later, but KISS for now
     
     */
    if (msgInsertIndex == NSNotFound) {
        
        // add date cells if needed
        NSIndexPath *dateIP = [self checkAndAddDateView:message previousMessage:previousMessage cells:cells];
        if (dateIP) {
            [ips addObject:dateIP];
        }
    }
    

    // add leave group cell
    NSIndexPath *leaveIP = [self addGroupLeaveView:message cells:cells insertIndex:msgInsertIndex];
    
    
    if (leaveIP) {
        [ips addObject:leaveIP];
    }
    // if not leave
    // - then content message -> create content row cell
    //
    else {
        
        /*
         Don't insert add messages for insert messages
         - possibly may need one later, but KISS for now
         */
        if (msgInsertIndex == NSNotFound) {
            // add join group cell
            NSArray *joinIPs = [self addGroupJoinView:message cells:cells];
            if (joinIPs) {
                [ips addObjectsFromArray:joinIPs];
            }
        }
        
        DialogMessageCellController *controller = [[DialogMessageCellController alloc] initWithMessage:message previousMessage:previousMessage];
        controller.delegate = self;
        
        if (controller) {
            DDLogVerbose(@"DTC-am: pre-add cnt:%d", [cells count]);
            
            NSInteger cellInsertIndex = [self cellInsertIndexForMessageInsertIndex:msgInsertIndex];
            
            NSIndexPath *messageIP = nil;
            // append at end
            if (cellInsertIndex == NSNotFound) {
                DDLogInfo(@"DTC-am: append cell at end:%d", [cells count]-1);
                [cells addObject:controller];
                messageIP = [NSIndexPath indexPathForRow:[cells count]-1 inSection:0];
            }
            // insert cell
            else {
                DDLogInfo(@"DTC-am: insert cell at:%d", cellInsertIndex);

                [cells insertObject:controller atIndex:cellInsertIndex];
                messageIP = [NSIndexPath indexPathForRow:cellInsertIndex inSection:0];
            }
            
            [controller release];
                        
            if (messageIP) {
                [ips addObject:messageIP];
            }
            
            DDLogInfo(@"DTC-am: post-add cnt:%d - IP:%@", [cells count], messageIP);
        }
    }
    
    // mark each message as read if it was only in-delivered state
    // - don't save to CD for each message - save upon exit
    // - only save if requested to save CPU time
    if (shouldMarkRead) {
        [[MPChatManager sharedMPChatManager] markCDMessageRead:message shouldSave:shouldSaveRead];
    }
    
    
    if ([ips count] == 0) {
        DDLogInfo(@"DTC: missing add IPs!");
    }
    
    // if message was added while we are in the dailog
    // - also update messages array to stay in sync
    //
    if (checkOrder) {
        
        if (msgInsertIndex == NSNotFound) {
            [self.messages addObject:message];
        }
        else {
            DDLogVerbose(@"DTC-am: insert msg at:%d", msgInsertIndex);
            [self.messages insertObject:message atIndex:msgInsertIndex];
        }
    }
    
    return ips;
}

/*!
 @abstract Construct cells with messages
 */
- (NSMutableArray *) constructCellsWithMessages:(NSArray *)newMessages {
    
    
    NSMutableArray *msgCells = [[[NSMutableArray alloc] init] autorelease];
    
    CDMessage *previousMessage = nil;
    
    // add existing chat messages
    //
    for (CDMessage *iMessage in newMessages){
        [self addMessage:iMessage previousMessage:previousMessage cells:msgCells checkOrder:NO shouldMarkRead:NO shouldSaveRead:NO];
        previousMessage = iMessage;
    }
    
    // make sure remaining messages are all marked as read
    //
    [self.cdChat markAllInDeliveredMessageRead];

    DDLogInfo(@"DTC-ccwm: new cells set %d", [msgCells count]);
    return msgCells;
}


/*!
 @abstract Update message states 
  - check if previous out-message's state should be modified to be consistent with this msg's state
 
 Use:
 - correct state if for some reason state updates messages did not make it to this client
 
 Assume:
 - if a message is Read, then previous messages should be read
 - if a message is Deliv, then previous messages should be Delivered or Read
 - don't modify created messages - not sent yet
 
 @TEMP 
 - is this the best solution?
 - requested by Allen 4/16
 
 */
- (void) updateMessageStates:(NSArray *)updateMesssages {
    
    if (![self.cdChat isGroupChat]) {
        BOOL isModified = NO;
        
        CDMessageState currentState = kCDMessageStateOutSent;
        
        NSEnumerator *reverseE = [updateMesssages reverseObjectEnumerator];
        CDMessage *object;
        
        while ((object = [reverseE nextObject])) {
            
            CDMessageState iState = [object getStateValue];
            
            if (currentState == kCDMessageStateOutRead &&
                (iState == kCDMessageStateOutSent || iState == kCDMessageStateOutDelivered)
                ) 
            {
                DDLogWarn(@"DTC-ums: change mID:%@ to Read state from:%@", object.mID, [object getStateString]);
                object.state = [NSNumber numberWithInt:currentState];
                isModified = YES;
            }
            else if (currentState == kCDMessageStateOutDelivered &&
                     iState == kCDMessageStateOutSent) 
            {
                DDLogWarn(@"DTC-ums: change mID:%@ to Delivered state from:%@", object.mID, [object getStateString]);
                object.state = [NSNumber numberWithInt:currentState];
                isModified = YES;
            }
            
            // change current state
            // - if sent, can change to read or delivered
            // - if delivered, can change to read
            //
            if (currentState == kCDMessageStateOutSent) {
                switch (iState) {
                    case kCDMessageStateOutRead:
                        currentState = kCDMessageStateOutRead;
                        break;
                        
                    case kCDMessageStateOutDelivered:
                        currentState = kCDMessageStateOutDelivered;
                        break;
                        
                    default:
                        break;
                }
            }
            else if (currentState == kCDMessageStateOutDelivered) {
                switch (iState) {
                    case kCDMessageStateOutRead:
                        currentState = kCDMessageStateOutRead;
                        break;
                        
                    default:
                        break;
                }
            }
        }
        if (isModified) {
            [AppUtility cdSaveWithIDString:@"Updated message status" quitOnFail:NO];
        }
    }
}

/*!
 @abstract Request delegate to shake
 */
- (void) shakeDialog {
    
    if ([self.delegate respondsToSelector:@selector(DialogTableController:shouldShake:)]) {
        [self.delegate DialogTableController:self shouldShake:YES];
    }
    
}

/*!
 @abstract Shake view if there is at least one unread vibrate sticker present
 
 Use:
 - check during initial loading to decide if we should shake
 
 */
- (void) shakeIfUnreadVibrateInMessages:(NSArray *)displayMessages {
   
    for (CDMessage *iMessage in displayMessages) {
        if ([iMessage getStateValue] == kCDMessageStateInDelivered &&
            ([iMessage isType:kCDMessageTypeSticker] || [iMessage isType:kCDMessageTypeStickerGroup]) &&
            [iMessage.text isEqualToString:kMPParamMessageTextStickerVibrate]
            ) 
        {
            [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(shakeDialog) userInfo:nil repeats:NO];
        }
    }
}


/*!
 @abstract contruct data model for table
 
 Use:
 - initial loading
 
 */
- (void)constructTableGroups
{
    //self.messages = [[NSMutableArray alloc] initWithArray:[self getLastTenReadAndAllUnreadMessages]];
    
    NSArray *newMessages = [self getMessagesMaxReadCount:self.readMessageCount];
    DDLogInfo(@"DTC-ctg: got message count from CD: %d", [newMessages count]);
    
    [self shakeIfUnreadVibrateInMessages:newMessages];
    
    // mod state values if needed
    //
    [self updateMessageStates:newMessages];
    
    self.messageCells = [self constructCellsWithMessages:newMessages];
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:newMessages];
    self.messages = array;
    [array release];

    self.tableGroups = [NSArray arrayWithObjects:self.messageCells, nil]; 
    
}

/*!
 @abstract reload table from db data
 */
- (void) loadMoreMessages {
    
    if (!self.allMessageShowing) {
        
        self.readMessageCount = [self.messages count] + kMPParamMessageCountLoadMore;
        CGFloat currentNegOffset = self.tableView.contentSize.height - self.tableView.contentOffset.y;
        
        [self.messages removeAllObjects];
        [self.messageCells removeAllObjects];
        [self updateAndReload];
        
        // show dialog at same point as before reload
        CGFloat newOffset = self.tableView.contentSize.height-currentNegOffset;
        [self.tableView setContentOffset:CGPointMake(0, newOffset)];
    }

}

/*!
 @abstract reload table from db data
 */
- (void) reloadMessages:(NSNotification *)notification {
    DDLogInfo(@"DTC-rm: reloading messages");
    NSManagedObjectID *chatID = [notification object];
    
    // if reload for this chat or chat not specified
    //
    if ([chatID isEqual:[self.cdChat objectID]] || chatID == nil) {
        
        // reset values before reload 
        self.readMessageCount = kMPParamMessageCountInitial;
        self.allMessageShowing = NO;
        
        [self.messages removeAllObjects];
        [self.messageCells removeAllObjects];
        [self updateAndReload];
        [self scrollToBottomWithAnimation:NO];
    }
}

#pragma mark - TableView Delegate

/*!
 @abstract Called when data is reloaded - custom TKTableView delegate
 */
- (void) dataDidReload {
    
    //DDLogVerbose(@"data reloaded");
    if (self.shouldScrollToBottomAfterReload) {
        self.shouldScrollToBottomAfterReload = NO;
        [self scrollToStartPosition];
    }
    
}

// respond to cell selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // tap row to dismiss keypad
    if ([self.delegate respondsToSelector:@selector(DialogTableController:hideKeypad:)]) {
        [self.delegate DialogTableController:self hideKeypad:YES];
    }
    
}

/*!
 Each row may having varying row height
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!self.tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<CellController> *controller = [[self.tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([controller respondsToSelector:@selector(rowHeightForTableWidth:)])
	{
		return [controller rowHeightForTableWidth:self.tableView.frame.size.width];
	}
	else {
		return kMPParamTableRowHeight;
	}
}


#pragma mark - Add Messages to Table

/*!
 @abstract Delete a message from the data model
 
 - find message IP and next cell's IP in cell controllers
 - delete message from self.messages
 - delete message IP from tableview
 - refresh next IP if it is visible
 
 - don't delete msg from DB since we are just moving it
 
 Use:
 - If we need to move a message from it's current position
 */
- (void) deleteRowForMessage:(CDMessage *)deleteMsg {
    
    NSUInteger cellCount = [self.messageCells count];
    
    // find delete cell and the following cell
    // - follow cell should refresh in case headshow should be shown
    NSIndexPath *foundIP = nil;
    NSIndexPath *nextIP = nil;
    DialogMessageCellController *foundCell = nil;
    
    // look for row backwards
    for (int row=cellCount-1; row >= 0; row--) {
        id iCell = [self.messageCells objectAtIndex:row];
        if ([iCell respondsToSelector:@selector(cdMessage)]) {
            
            if (foundIP) {
                nextIP = [NSIndexPath indexPathForRow:row inSection:0];
                break;
            }
            
            if ([iCell performSelector:@selector(cdMessage)] == deleteMsg) {
                foundIP = [NSIndexPath indexPathForRow:row inSection:0];
                foundCell = iCell;
            }
            
        }
    }
    
    if (foundIP && foundCell) {
        
        // delete from self.messages
        [self.messages removeObject:deleteMsg];

        id nextCell = nil;
        
        if (nextIP) {
            // set next cell previous message properly
            //
            nextCell = [self.messageCells objectAtIndex:[nextIP row]];
            if ([nextCell respondsToSelector:@selector(previousMessage)]) {
                [nextCell setPreviousMessage:foundCell.previousMessage];
            }
            
        }
        
        // delete from data model
        [self.messageCells removeObject:foundCell];
        
        
        BOOL animated = YES;
        
        // only animate if table is visible
        // - otherwise crash will occur
        if (!self.tableView.window) {
            animated = NO;
            DDLogInfo(@"DTC-anm: skip delete animation - DTC not visible");
        }
        if (animated) {
            
            NSUInteger currentRows = [self.tableView numberOfRowsInSection:0];
            if ([self.messageCells count] != currentRows - 1) {
                DDLogInfo(@"DTC-anm: skip delete allCells:%d != current:%d - 1", [self.messageCells count], currentRows);
                animated = NO;
            }
        }
        
        if (animated) {
            [self.tableView beginUpdates];
            
            // refresh next ip if it is visible
            NSArray *visibleIPs = [self.tableView indexPathsForVisibleRows];
            for (NSIndexPath *iIP in visibleIPs) {
                
                if ([iIP isEqual:nextIP]) {
                    
                    if ([nextCell respondsToSelector:@selector(refreshHeadViewForCell:animated:)]) {
                        UITableViewCell *nextTableCell = [self.tableView cellForRowAtIndexPath:nextIP];
                        if (nextTableCell) {
                            [nextCell refreshHeadViewForCell:nextTableCell animated:YES];
                        }
                    }
                    
                }
            }
            
            // delete from tableview
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:foundIP] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        
    }
    else {
        DDLogVerbose(@"DTC: delete message not found!");
        
    }
}


/*!
 @abstract Refresh if messages are visible
 
 */
- (void) refreshRowForMessage:(CDMessage *)message {
    
    // first check if we need to move this message
    // - is it's previous message "failed" or 
    // - message's sent date is older than previous messages's sent date or
    // - message's sent date is same AND message ID is smaller
    //
    CDMessage *prevMsg = [self getPreviousMessageForMessage:message];
    NSComparisonResult compareSent = [message.sentDate compare:prevMsg.sentDate];
    
    if ([prevMsg getStateValue] == kCDMessageStateOutFailed ||
         compareSent == NSOrderedAscending ||
        (compareSent == NSOrderedSame && [message.mID compare:prevMsg.mID] == NSOrderedAscending)
        ) 
    {
        
        // Then delete this message cell and insert it to a new position
        //
        [self deleteRowForMessage:message];
        NSArray *addedIPs =[self addMessage:message previousMessage:[self.messages lastObject] cells:self.messageCells checkOrder:YES shouldMarkRead:YES shouldSaveRead:YES];
        
        
        BOOL animated = YES;
        
        // only animate if table is visible
        // - otherwise crash will occur
        if (!self.tableView.window) {
            animated = NO;
            DDLogInfo(@"DTC-anm: skip refresh animation - DTC not visible");
        }
        
        NSUInteger rowsToInsert = [addedIPs count];
        if (animated && rowsToInsert > 0) {
            
            NSUInteger currentRows = [self.tableView numberOfRowsInSection:0];
            if ([self.messageCells count] != currentRows + rowsToInsert) {
                DDLogInfo(@"DTC-anm: skip refresh allCells:%d != current:%d + new:%d", [self.messageCells count], currentRows, rowsToInsert);
                animated = NO;
            }
        }
        
        if (animated) {
            [self.tableView insertRowsAtIndexPaths:addedIPs withRowAnimation:UITableViewRowAnimationBottom];
        }
        
        // scroll to this row
        //[self scrollToShowLastMessageWithKeyboardHeight:self.keyboardHeight animated:YES];
        
    }
    // otherwise just refresh this cell
    else {
        
        /*
        // search through all cells
        for (id iCell in self.messageCells) {
            
            if ([iCell respondsToSelector:@selector(cdMessage)]) {
                CDMessage *cellMessage = [iCell cdMessage];
                
                if ([cellMessage isEqual:message]) {
                    //if ([message getStateValue] == kCDMessageStateOutSent) {
                    //    [self scrollToShowLastMessageWithKeyboardHeight:self.keyboardHeight animated:YES];
                    //}
                    [iCell performSelector:@selector(refreshCell)];
                    break;
                }
            }
        }*/
        
        
        
        /* Efficient, but visible rows results may possibly be inaccurate?? */
         
         NSArray *visibleIPs = [self.tableView indexPathsForVisibleRows];
        
        NSUInteger cellCount = [self.messageCells count];
        
        
        for (NSIndexPath *iIP in visibleIPs) {
            if ([iIP row] < cellCount) {
                
                id cellObject = [self.messageCells objectAtIndex:[iIP row]];
                
                if ([cellObject respondsToSelector:@selector(cdMessage)]) {
                    CDMessage *cellMessage = [cellObject cdMessage];
                    
                    if ([cellMessage isEqual:message]) {
                        //if ([message getStateValue] == kCDMessageStateOutSent) {
                        //    [self scrollToShowLastMessageWithKeyboardHeight:self.keyboardHeight animated:YES];
                        //}
                        [cellObject performSelector:@selector(refreshCell)];
                        break;
                    }
                }
                
            }
        }
    }
}

/*!
 @abstract add a message to dialog 
 
 @param newMessage can be from an NSNotification (incoming message) or CDMessage (outgoing message)
 @param animated - animated are dynamically added messages - not animated are loaded from DB
 
 */
- (void) addNewMessage:(CDMessage *)newMessage animated:(BOOL)animated {
    
    //DDLogVerbose(@"DTC-addN: %@ ?= %@", newMessage.chat, self.cdChat);
    // is message for this chat??
    //
    if ([newMessage.chat isEqualToChat:self.cdChat]) {
        
        // check if order is incorrect for messages that just 
        NSArray *addedIPs = [self addMessage:newMessage previousMessage:[self.messages lastObject] cells:self.messageCells checkOrder:YES shouldMarkRead:YES shouldSaveRead:YES];
        
        // only animate if table is visible
        // - otherwise crash will occur
        // - do scroll to the bottom when tableview shows again since a new message came in
        if (animated && !self.tableView.window) {
            animated = NO;
            self.shouldScrollToBottomAfterReload = YES;
            DDLogInfo(@"DTC-anm: skip insert animation - DTC not visible");
        }
        
        NSUInteger rowsToInsert = [addedIPs count];
        if (animated && rowsToInsert > 0) {
            
            NSUInteger currentRows = [self.tableView numberOfRowsInSection:0];
            if ([self.messageCells count] != currentRows + rowsToInsert) {
                DDLogInfo(@"DTC-anm: skip insert allCells:%d != current:%d + new:%d", [self.messageCells count], currentRows, rowsToInsert);
                animated = NO;
            }
        }
        
        
        if (animated) {
            // animate - for content message cells (stickers)
            // 
            id lastCell = [self.messageCells lastObject];
            if ([lastCell respondsToSelector:@selector(setShouldStartAnimation:)]) {
                // mark last cell to show animation
                [lastCell setShouldStartAnimation:YES];
                
                // if should vibrate
                //
                if ([newMessage.text isEqualToString:kMPParamMessageTextStickerVibrate]) {
                    if ([self.delegate respondsToSelector:@selector(DialogTableController:shouldShake:)]) {
                        [self.delegate DialogTableController:self shouldShake:YES];
                    }
                }
            }
            
            DDLogVerbose(@"DTC-anm: pre-insert msgcnt:%d msgCellCnt: %d IPS %@", [self.messages count], [self.messageCells count], addedIPs);

            if (rowsToInsert > 0) {
                [self.tableView insertRowsAtIndexPaths:addedIPs withRowAnimation:UITableViewRowAnimationBottom];
            }
            
        }
        else {
            DDLogVerbose(@"DTC-anm: not animated!");
        }

        
        // if not animated, then we should only scroll once after we finish adding the batch of views
        // - to save processing time
        // - animated is usually for single messages
        if (animated) {
            DDLogInfo(@"DTC-anm: scroll to last msg");
            [self scrollToShowLastMessageWithKeyboardHeight:self.keyboardHeight animated:animated];
        }
    }
}


/*!
 @abstract If a new outbound state update is received but old messages are not delivered or read, then update their state too
 
 This is sort of cheating to make sure previous outbound states are consistent with new outbound message states.
  - if new message is read, then all previous messages should also be read
  - this may not really be needed, since we make sure delivered/read messages are sent to the DS view sent confirmations 12/5/5
 
 @TEMP 
 - is this the best solution?
 - requested by Allen 12/4/16
 
 */
- (void) updateMessageStateForNewMessage:(CDMessage *)aMessage {
 
    // skip group chats
    if ([self.cdChat isGroupChat]) {
        return;
    }
    
    // code
    // - look for the previous out message
    //
    NSInteger location = [self.messages indexOfObject:aMessage];
    
    
    // check it's state to see if update is needed
    // - if so, update state and refresh that message too
    //
    if ([aMessage getStateValue] != kCDMessageStateOutSent &&
        location != NSNotFound && 
        location != 0) {
        NSArray *subMessages = [self.messages subarrayWithRange:NSMakeRange(0, location)];
        
        NSMutableArray *refreshMessages = [[NSMutableArray alloc] init];
        
        if ([aMessage getStateValue] == kCDMessageStateOutRead) {
            for (CDMessage *iMessage in subMessages) {
                if ([iMessage getStateValue] == kCDMessageStateOutSent ||
                    [iMessage getStateValue] == kCDMessageStateOutDelivered) {
                    DDLogWarn(@"DTC-umsfnm: change mID:%@ to Read state from:%@", iMessage.mID, [iMessage getStateString]);

                    iMessage.state = aMessage.state;
                    [refreshMessages addObject:iMessage];
                }
            }
        }
        else if ([aMessage getStateValue] == kCDMessageStateOutDelivered) {
            for (CDMessage *iMessage in subMessages) {
                if ([iMessage getStateValue] == kCDMessageStateOutSent) {
                    DDLogWarn(@"DTC-umsfnm: change mID:%@ to Delivered state from:%@", iMessage.mID, [iMessage getStateString]);

                    iMessage.state = aMessage.state;
                    [refreshMessages addObject:iMessage];
                }
            }
        }
        
        if ([refreshMessages count] > 0) {
            [AppUtility cdSaveWithIDString:@"Save message state updates" quitOnFail:NO];
            for (CDMessage *iMessage in refreshMessages) {
                [self refreshRowForMessage:iMessage];
            }
        }
        [refreshMessages release];
    }
}

/*!
 @abstract adds message given it's objectID
 
 @param objectID CDMessage object ID to add to this view
 
 Use:
 - to add outgoing image message that was created in the background queue
 - add in coming message from network
 
 */
- (void) addNewMessageWithObjectID:(NSManagedObjectID *)objectID {
    DDLogVerbose(@"DTC-add: got objectID");
    
    // fetch message object from ID
    NSManagedObjectContext *moc = [AppUtility cdGetManagedObjectContext];
    CDMessage *newMessage = (CDMessage *)[moc objectWithID:objectID];
    
    
    if ([newMessage.type intValue] == kCDMessageTypeGroupLeave) {
        // post notification so chat dialog can update's its name
        // - after leaving the members may have changed
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_DAILOG_UPDATE_NAME_NOTIFICATION object:self.cdChat];
    }
    
    // make sure we get changes from bkground
    //[moc refreshObject:newMessage mergeChanges:NO];
    
    NSInteger stateValue = [newMessage.state intValue];
    
    // only add messags that are in-bound delievered.
    // - Don't rely on state, we should trust all message sent using this notification
    // - Since state may not be accurate due to race condition: 
    //   e.g. mainthread freezes & sent reply already recieved, then get notif, and then message is in "unexpected" Sent state!
    // 
    if (YES /*[newMessage shouldAddToDialog]*/) {
        DDLogInfo(@"DTC-add: msg ADD %d %@ - r:%d", stateValue, newMessage.mID, self.runningRobot);
        [self addNewMessage:newMessage animated:YES];
        
        // echo response
        /*if (self.runningRobot == kDTCRobotEcho) {
            [self sendText:newMessage.text];
        }
        else if (self.runningRobot == kDTCRobotSend) {
            if ([self.lastSentRobotMessage hasPrefix:newMessage.text]) {
                DDLogInfo(@"DTC-add: send robot - %@", newMessage.text);
                NSInteger msgCount = [[[self.lastSentRobotMessage componentsSeparatedByString:@"_"] lastObject] intValue];
                self.lastSentRobotMessage = [NSString stringWithFormat:@"t_%d", msgCount+1];
                [self sendText:self.lastSentRobotMessage];
            }
        }*/
    }

}

/*!
 @abstract adds new message to dialog
 
 @param object can be NSNotification (incoming message) or CDMessage (outgoing message)
 
 */
- (void) addNewMessageFromNotification:(NSNotification *)notification {
    
    NSArray *objectIDs = [notification object];

    DDLogVerbose(@"DTC-add: got notif");

    for (NSManagedObjectID *iObjectID in objectIDs) {
        [self addNewMessageWithObjectID:iObjectID];
    }
    
}




/*!
 @abstract adds message update given it's objectID
 
 @param objectID CDMessage object ID to add to this view
 
 Use:
 - refresh UI so that the new message state is reflected
 
 */
- (void) addMessageUpdateWithObjectID:(NSManagedObjectID *)objectID {
    DDLogVerbose(@"DTC-amu: got objectID");
    
    // fetch message object from ID
    NSManagedObjectContext *moc = [AppUtility cdGetManagedObjectContext];
    CDMessage *newMessage = (CDMessage *)[moc objectWithID:objectID];
    
    
    if ([newMessage.type intValue] == kCDMessageTypeGroupLeave) {
        // post notification so chat dialog can update's its name
        // - after leaving the members may have changed
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_DAILOG_UPDATE_NAME_NOTIFICATION object:self.cdChat];
    }
    
    // make sure we get changes from bkground
    //[moc refreshObject:newMessage mergeChanges:NO];
    
    NSInteger stateValue = [newMessage.state intValue];
    
    DDLogInfo(@"DTC-amu: msg StateUpdate %d %@", stateValue, newMessage.mID);
    
    NSInteger thisState = [newMessage.state intValue];
    
    // for out message state changes
    if (thisState == kCDMessageStateOutSent || 
        thisState == kCDMessageStateOutDelivered || 
        thisState == kCDMessageStateOutRead) {
        
        [self refreshRowForMessage:newMessage];
        
        [self updateMessageStateForNewMessage:newMessage];
        
    }
    
}

/*!
 @abstract adds message state update
 
 @param object can be NSNotification (incoming message) or CDMessage (outgoing message)
 
 */
- (void) addMessageUpdateFromNotification:(NSNotification *)notification {
    
    NSArray *objectIDs = [notification object];
    
    DDLogVerbose(@"DTC-amup: got notif");
    
    for (NSManagedObjectID *iObjectID in objectIDs) {
        [self addMessageUpdateWithObjectID:iObjectID];
    }
    
}




/*!
 @abstract Search for a matching message and update it's progress
 
 */
- (void) updateMessageProgress:(NSNotification *)notification {
    
    
    NSDictionary *userInfo  = [notification userInfo];
    
    NSNumber *tag = [userInfo valueForKey:kMPSCUserInfoKeyTag];
    NSNumber *bytes = [userInfo valueForKey:kMPSCUserInfoKeyBytes];
    
    // search backwards to find new message quickly - if match, then exit
    //
    NSEnumerator *reverseE = [self.messageCells reverseObjectEnumerator];
    DialogMessageCellController *object;
    
    while ((object = [reverseE nextObject])) {
        
        if ([object respondsToSelector:@selector(cdMessage)]) {
            CDMessageType msgType = [object.cdMessage.type intValue];
            
            if (msgType == kCDMessageTypeImage || 
                msgType == kCDMessageTypeLetter ) {
                // matching message found
                if ([object.cdMessage.mID hasSuffix:[tag stringValue]]) {
                    
                    [object updateProgress:[bytes integerValue] isIncreamental:YES];
                    // no need to update others
                    break;
                }
            }
        }
    }    
}

#pragma mark - Testing

/*!
 @abstract Send text messages in out of sequence
 
 Send:
 2, 4, 6, 3, 5, 1
 
 */
- (void) sendOutOfSequenceText {
    
    NSMutableArray *testMsges = [[NSMutableArray alloc] initWithCapacity:6];
    NSArray *texts = [NSArray arrayWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", nil];
    NSArray *sequences = [NSArray arrayWithObjects:@"2", @"4", @"6", @"3", @"5", @"1", nil];

    
    for (NSString *iText in texts) {
        
        CDMessage *newCDMessage = [CDMessage outCDMessageForChat:self.cdChat messageType:kCDMessageTypeText text:iText attachmentData:nil  shouldSave:YES];
        [testMsges addObject:newCDMessage];
        
        [NSThread sleepForTimeInterval:0.1];
        
    }
    
    // Send out of sequence
    //
    for (NSString *iSeq in sequences) {
        
        for (CDMessage *iMessage in testMsges) {
            
            if ([iMessage.text isEqual:iSeq]) {
                
                [NSThread sleepForTimeInterval:0.2];
                
                // sends this message
                //
                [[MPChatManager sharedMPChatManager] sendCDMessage:iMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];
                                
                // add view to scroll view
                //
                [self addNewMessage:iMessage animated:YES];
            }
        }
    }
    [testMsges release];
}


#pragma mark - External Methods

/*!
 @abstract send text to other chat participants
 
 Use:
 - used by input views to send text to this chat room
 
 */
- (void) sendText:(NSString *)textMessage {
    
    
    CDMessage *newCDMessage = [CDMessage outCDMessageForChat:self.cdChat messageType:kCDMessageTypeText text:textMessage attachmentData:nil  shouldSave:YES];
    
    // sends this message
    //
    [[MPChatManager sharedMPChatManager] sendCDMessage:newCDMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];
    
    // add view to scroll view
    //
    [self addNewMessage:newCDMessage animated:YES];
    
    // start robots
    //
    /*if (self.runningRobot == kDTCRobotNone) {
        
        if ([textMessage hasPrefix:kDTCRobotStartEcho]) {
            self.runningRobot = kDTCRobotEcho;
        }
        else if([textMessage hasPrefix:kDTCRobotStartSend]) {
            self.runningRobot = kDTCRobotSend;
            // send out first message
            self.lastSentRobotMessage = @"t_1";
            [self sendText:self.lastSentRobotMessage];
        }
        
    }*/
}

/*!
 @abstract send sticker to other chat participants
 
 Use:
 - used by input views to send stickers to this chat room
 
 */
- (void) sendStickerResource:(CDResource *)resource {
    
    CDMessage *newCDMessage = [CDMessage outCDMessageForChat:self.cdChat messageType:kCDMessageTypeSticker text:resource.text attachmentData:nil  shouldSave:YES];
    
    // sends this message
    //
    [[MPChatManager sharedMPChatManager] sendCDMessage:newCDMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];
    
    // add view to scroll view
    //
    [self addNewMessage:newCDMessage animated:YES];
}


/*!
 @abstract remove inset when keyboard goes away
 - always account for toolbar
 
 Use:
 - call when keyboard goes away
 
 */
- (void) clearContentInsets {
    //DDLogInfo(@"DTC: clear inset - b:%f k:%f", self.tableView.contentInset.bottom, self.keyboardHeight);

    self.keyboardHeight = 0.0;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
  
    //DDLogInfo(@"DTC: clear insetE - b:%f k:%f", self.tableView.contentInset.bottom, self.keyboardHeight);
}

/*!
 @abstract scrolls table to the very bottom
 
 Use:
 
 */
- (void) scrollToBottomWithAnimation:(BOOL)animated {
    
    // don't go negative in case content size is less than viewable area
    //
    CGFloat bottomY = MAX(self.tableView.contentSize.height - self.tableView.frame.size.height + self.tableView.contentInset.bottom, 0.0);
    
    // use scroll view properties
    //
    CGPoint bottomPoint = CGPointMake(0.0, bottomY);
    if (animated) {
        [self.tableView setContentOffset:bottomPoint animated:YES];
    }
    else {
        self.tableView.contentOffset = bottomPoint;
    }
    
}

/*!
 @abstract scrolls table to the very bottom
 
 Use:
 - help keep latest message in view when keyboard appears
 
 */
- (void) scrollToLastIndexPathAnimated:(BOOL)animated {
    
    // scroll view so that it last message is visible
    // - use actual UI rows showing
    // - safer since datamodel may not match UI right at this moment
    //
    NSUInteger cellCount = [self.tableView numberOfRowsInSection:0]; // [self.messageCells count];
    if (cellCount > 0) {
                
        NSIndexPath *lastIP = [NSIndexPath indexPathForRow:cellCount-1 inSection:0];
        DDLogInfo(@"DTC-stslm: scroll to last IP: %@", lastIP);
        
        DDLogInfo(@"DTC-stlip: actual scroll executed to last IP: %@", lastIP);
        [self.tableView scrollToRowAtIndexPath:lastIP atScrollPosition:UITableViewScrollPositionBottom animated:animated];
        
    }
    
}

/*!
 @abstract scrolls table to the very bottom
 
 Use:
 - help keep latest message in view when keyboard appears
 
 */
- (void) scrollToLastIndexPath:(NSTimer *)timer {
    
    NSDictionary *userInfo = [timer userInfo];
    BOOL animated = [[userInfo objectForKey:@"animated"] boolValue];
    
    [self scrollToLastIndexPathAnimated:animated];

}

/*!
 @abstract scrolls table to the very bottom
 
 Use:
 - help keep latest message in view when keyboard appears
 
 */
- (void) scrollToShowLastMessageWithKeyboardHeight:(CGFloat)kbHeight animated:(BOOL)animated {
    //DDLogInfo(@"DTC: scroll last - b:%f k:%f OldK:%f", self.tableView.contentInset.bottom, kbHeight, self.keyboardHeight);

    BOOL sameKBHeight = NO;
    
    if (self.keyboardHeight == kbHeight) {
        sameKBHeight = YES;
    }
    
    // save this, so we know how to scroll without it
    self.keyboardHeight = kbHeight;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbHeight, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    // if keyboard is showing scroll right away
    // - otherwise scroll will be too high
    if (kbHeight > 0) {
        if (sameKBHeight) {
            animated = NO;
        }
        [self scrollToLastIndexPathAnimated:animated];
    }
    // throttle when view is full screen - multi photos
    // - this can come in very quickly
    else {
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:animated], @"animated", nil];
        
        [self.throttleScrollToLastTimer invalidate];
        self.throttleScrollToLastTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(scrollToLastIndexPath:) userInfo:userInfo repeats:NO];
    }
    
    //DDLogInfo(@"DTC: scroll lastE - b:%f k:%f", self.tableView.contentInset.bottom, kbHeight);
}

/*!
 @abstract scrolls to dialog initial start position
 
 Near top of screen
 - show oldest unread message
 - show last message
 
 Use:
 - used to show starting position
 
 
 */
- (void) scrollToStartPosition {
    
    // 0.3.83 EC Change start position to the bottom showing last message
    //
    DDLogInfo(@"DTC-stsp: scroll to start position");
    [self scrollToShowLastMessageWithKeyboardHeight:self.keyboardHeight animated:NO];
    
    /*
     Scroll to last unread message
     
    NSInteger row = -1;
    
    for (id iCellController in self.messageCells) {
        row++;
        if ([iCellController respondsToSelector:@selector(cdMessage)]) {
            if ([[iCellController cdMessage] isInboundNotRead]) {
                break;
            }
        }
    }
    
    if (row > -1) {
        // scroll view so that it last message is visible
        //
        NSIndexPath *unreadIP = [NSIndexPath indexPathForRow:row inSection:0];
        [self.tableView scrollToRowAtIndexPath:unreadIP atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }*/
    
}

#pragma mark - Notification Handlers


/*!
 @abstract Update contact headshot and name when contact information is updated
 - find all visible IPs
   ~ each IP get cell controller & refresh head view
 
 */
- (void) handleContactReload:(NSNotification *)notification {
    
    NSSet *reloadIDs = [notification object];
    
    // if specified reload
    // - then check if we need it
    if (reloadIDs) {
        BOOL isNotifForMe = NO;
        
        for (CDContact *iContact in self.cdChat.participants) {
            if ([reloadIDs member:iContact.userID]) {
                [self.imageManager getImageForObject:iContact context:kMPImageContextList];
                isNotifForMe = YES;
            }
        } 
        
        // if reload not for this chat then ignore it
        if (!isNotifForMe) {
            return;
        }
    }
    // check all for updates
    else {
        // get headshot for all chat participants
        // - if not available, then image will be downloaded
        for (CDContact *iContact in self.cdChat.participants) {
            [self.imageManager getImageForObject:iContact context:kMPImageContextList];
        }  
    }
    
    NSLog(@"DTC: contact reload requested");  
    
    // refresh head views for each cell
    //
    NSArray *visibleIPs = [self.tableView indexPathsForVisibleRows];
    NSUInteger cellCount = [self.messageCells count];
    
    for (NSIndexPath *iIP in visibleIPs) {
        if ([iIP row] < cellCount) {
            
            id iController = [self.messageCells objectAtIndex:[iIP row]];
            
            if ([iController respondsToSelector:@selector(refreshHeadViewForCell:animated:)]) {
                UITableViewCell *iTableCell = [self.tableView cellForRowAtIndexPath:iIP];
                if (iTableCell) {
                    [iController refreshHeadViewForCell:iTableCell animated:NO];
                }
            }
        }
    }
    
}

#pragma mark - DialogMessageCellController Delegate 

/*!
 @abstract Gets visible table cell for this controller
 */
- (UITableViewCell *)DialogMessageCellController:(DialogMessageCellController *)cellControlller visibleCellForMessage:(CDMessage *)message {
    
    NSArray *visibleIPs = [self.tableView indexPathsForVisibleRows];
    
    NSUInteger cellCount = [self.messageCells count];
    
    NSIndexPath *foundIP = nil;
    
    for (NSIndexPath *iIP in visibleIPs) {
        if ([iIP row] < cellCount) {
            
            id cellObject = [self.messageCells objectAtIndex:[iIP row]];
            
            if ([cellObject isEqual:cellControlller]) {
                foundIP = iIP;
                break;
            }
        }
    }
    
    if (foundIP) {
        return [self.tableView cellForRowAtIndexPath:foundIP];
    }
    return nil;
}


/*!
 @abstract Asks table to delete this message and cell controller
 */
- (void)DialogMessageCellController:(DialogMessageCellController *)cellController deleteMessage:(CDMessage *)message {
    
    
    NSArray *visibleIPs = [self.tableView indexPathsForVisibleRows];
    NSUInteger cellCount = [self.messageCells count];
    
    // find delete cell and the following cell
    // - follow cell should refresh in case headshow should be shown
    NSIndexPath *previousIP = nil;
    NSIndexPath *foundIP = nil;
    NSIndexPath *nextIP = nil;
    
    for (NSIndexPath *iIP in visibleIPs) {
        if ([iIP row] < cellCount) {
            
            if (foundIP) {
                nextIP = iIP;
                break;
            }
            
            id cellObject = [self.messageCells objectAtIndex:[iIP row]];
            if ([cellObject isEqual:cellController]) {
                foundIP = iIP;
            }
            else {
                previousIP = iIP;
            }
        }
    }
    
    if (foundIP) {
        // remove from data model
        [self.messages removeObject:message];
        
        NSMutableArray *deleteCells = [[NSMutableArray alloc] initWithCapacity:2];
        [deleteCells addObject:foundIP];
        
        id nextCell = nil;
        // link previous message to the next cell
        if (nextIP) {
            nextCell = [self.messageCells objectAtIndex:[nextIP row]];
            if ([nextCell respondsToSelector:@selector(previousMessage)]) {
                [nextCell setPreviousMessage:cellController.previousMessage];
            }
        }
        // if no next row and this is last msg, then also delete date cells
        else if (previousIP) {
            id previousCell = [self.messageCells objectAtIndex:[previousIP row]];
            if ([previousCell respondsToSelector:@selector(infoType)]) {
                if ([previousCell infoType] == kDInfoTypeDate) {
                    [deleteCells addObject:previousIP];
                    [self.messageCells removeObject:previousCell];
                }
            }
        }
        [self.messageCells removeObject:cellController];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:deleteCells withRowAnimation:UITableViewRowAnimationFade];
        if ([nextCell respondsToSelector:@selector(refreshHeadViewForCell:animated:)]) {
            UITableViewCell *nextTableCell = [self.tableView cellForRowAtIndexPath:nextIP];
            if (nextTableCell) {
                [nextCell refreshHeadViewForCell:nextTableCell animated:YES];
            }
        }
        [self.tableView endUpdates];
        [deleteCells release];
        
        // delete from DB
        [CDMessage deleteMessage:message];
    }
    else {
        DDLogVerbose(@"DTC: delete message not found!");
        
    }
}



/*!
 @abstract Asks delegate (table) to forward this message
 */
- (void)DialogMessageCellController:(DialogMessageCellController *)cellControlller forwardMessage:(CDMessage *)message {
    
    self.tempMessage = message;
    
    SelectContactController *nextController = [[SelectContactController alloc] 
                                               initWithTableStyle:UITableViewStylePlain 
                                               type:kMPSelectContactTypeForwardMessage
                                               viewContacts:nil];
    nextController.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:nextController];
    [nextController release];
    
    [AppUtility customizeNavigationController:navController];

    [[AppUtility getAppDelegate].containerController presentModalViewController:navController animated:YES];
    [navController release];

}




/*!
 @abstract User requested a larger view of the image from this message view
 
 */
- (void)DialogMessageCellController:(DialogMessageCellController *)cellControlller showImage:(UIImage *)image message:(CDMessage *)message {
    
    //TODO: provide date title
    //
    MediaImageController *newController = [[MediaImageController alloc] initWithImage:image title:@"image" filename:cellControlller.cdMessage.filename];
    newController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newController];
    [newController release];
    [self.parentController presentModalViewController:navController animated:YES];
    [navController release];
    
    // save message in case forward is requested
    self.tempMessage = message;
    
}


#define LETTER_VIEW_TAG 14001

/*!
 @abstract User requested to read a letter
 */
- (void)DialogMessageCellController:(DialogMessageCellController *)cellControlller showLetter:(UIImage *)letterImage message:(CDMessage *)message {
    
    self.tempMessage = message;
    
    UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];

    UIView *existingLetterView = [containerVC.view viewWithTag:LETTER_VIEW_TAG];
    
    // only show if a letter is not already showing
    //
    if (!existingLetterView) {
        CGRect appFrame = [Utility appFrame];
        
        //CGRect letterRect = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height);
        
        LetterDisplayView *letterView = [[LetterDisplayView alloc] initWithFrame:appFrame letterImage:letterImage];
        letterView.delegate = self;
        letterView.tag = LETTER_VIEW_TAG;
        
        
        [containerVC.view addSubview:letterView];
        [letterView release];
    }
}


/*!
 @abstract User requested to show a location
 */
- (void)DialogMessageCellController:(DialogMessageCellController *)cellControlller showLocationLatitude:(CGFloat)latitude longitude:(CGFloat)longitude {
    
    LocationShareController *nextController = [[LocationShareController alloc] init];
    nextController.locationMode = kLSModeView;
    nextController.shareCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    // Create nav controller to present modally
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:nextController];            
    [AppUtility customizeNavigationController:navigationController];
    
    [self.parentController presentModalViewController:navigationController animated:YES];
    [navigationController release];
    [nextController release];
    
}


#pragma mark - SelectContactsControllerDelegate & Forward Message


/*!
 @abstract forward message
 
 - duplicate message
 - send message
 - pop current chat and push the new one on
 
 forward:
 - text only copy text and insert into input dialog
 - sticker, location - send
 
 */
- (void) forwardMessageAndShowChat:(CDChat *)showChat {
    
    
    // Duplicate message
    //
    CDMessage *forwardMessage = [CDMessage forwardMessage:self.tempMessage toChat:showChat];
    
    // Send message
    //
    // sends this message
    //
    [[MPChatManager sharedMPChatManager] sendCDMessage:forwardMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];
    
    
    // text only copies message into chat input field
    //
    /*if ([self.tempMessage isType:kCDMessageTypeText] || [self.tempMessage isType:kCDMessageTypeText]) {
        showChat.pendingText = self.tempMessage.text;
    }
    // other type duplicates and sends message
    else {
        
        // Duplicate message
        //
        CDMessage *forwardMessage = [CDMessage forwardMessage:self.tempMessage toChat:showChat];
        
        // Send message
        //
        // sends this message
        //
        [[MPChatManager sharedMPChatManager] sendCDMessage:forwardMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];
    }*/
    
    // ask chat list to swap in new chat
    //
    if ([self.delegate respondsToSelector:@selector(DialogTableController:showChat:)]) {
        [self.delegate DialogTableController:self showChat:showChat];
    }
    
    self.tempMessage = nil;
    self.pendingHiddenChat = nil;
}



/*!
 @abstract forward message

 - duplicate message
 - send message
 - pop current chat and push the new one on
 
 forward:
 - text only copy text and insert into input dialog
 - sticker, location - send
 
 */
- (void)selectContactsController:(SelectContactController *)selectContactsController chatContacts:(NSArray *)contacts{
    
    CDChat *forwardChat = [CDChat chatWithCDContacts:contacts groupID:nil shouldSave:YES];

    BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    
    // if hidden chat then ask for PIN unlock first
    if (isLocked && [forwardChat.isHiddenChat boolValue] ) {
        
        [[AppUtility getAppDelegate].containerController dismissModalViewControllerAnimated:NO];
        
        self.pendingHiddenChat = forwardChat;
        HiddenController *nextController = [[HiddenController alloc] initWithHCStatus:kHCViewStatusUnlockPIN];
        
        //nextController.title = NSLocalizedString(@"New Schedule", @"Schedule - title: view to edit status message");            
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:nextController];
        [AppUtility customizeNavigationController:navigationController];
        nextController.delegate = self;
        [[AppUtility getAppDelegate].containerController presentModalViewController:navigationController animated:YES];
        [navigationController release];
        [nextController release];
    }
    else {
        [self forwardMessageAndShowChat:forwardChat];
    }
}


#pragma mark - HiddenController

/*!
 @abstract Notifiy Delegate that unlock was successful
 - proceed to open hidden chat after unlocking
 
 Note:
 - don't push now since tabbar is not visiable yet.  
 - This will then prevent nav delegate from calling and cause the tab bar not to hide!
 - Instead flag for the push to happen after viewdidappear is called!
 
 */
- (void)HiddenController:(HiddenController *)controller unlockDidSucceed:(BOOL)didSucceed {
    
    [self forwardMessageAndShowChat:self.pendingHiddenChat];
}




#pragma mark - ScrollView Delegate

/**
 Determine if we should show source indicator at all
 - only show if more than one source present
 
 */
/*- (BOOL)shouldShowSourceByCheckingTableStatus:(BOOL)checkTableStatus tableView:(UITableView *)newTableView {
 
 // only query once to save cycles
 //
 static NSInteger sourceNumber = NSNotFound;
 if (sourceNumber == NSNotFound) {
 sourceNumber = [[AppUtility getABTool] getNumberOfSources];
 }
 
 BOOL showSource = NO;
 if (sourceNumber > 1 ) {
 
 if (checkTableStatus ) {
 if ( newTableView.dragging || newTableView.tracking || newTableView.decelerating ){
 showSource = YES;
 }
 }
 else {
 showSource = YES;
 }
 }
 return showSource;
 }*/





/**
 Deselect rows that are selecting after scrolling ends
 */
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    //DDLogInfo(@"DTC: scroll end - b:%f k:%f", self.tableView.contentInset.bottom, self.keyboardHeight);

	/*[NSThread sleepForTimeInterval:0.2];
     NSIndexPath *selectedIP = [self.tableView indexPathForSelectedRow];
     if (selectedIP) {
     [self.tableView deselectRowAtIndexPath:selectedIP animated:YES];
     }*/
}


/**
 Show source when scrolling begins
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    //DDLogVerbose(@"DTC: scroll begin - b:%f k:%f", self.tableView.contentInset.bottom, self.keyboardHeight);

    // tap row to dismiss keypad
    if ([self.delegate respondsToSelector:@selector(DialogTableController:hideKeypad:)]) {
        [self.delegate DialogTableController:self hideKeypad:YES];
    }
    
	//DDLogVerbose(@"MVC: start dragging");
	//[self showSourceForVisibleCell:YES tableView:(UITableView *)scrollView];
}

/**
 Hides source when dragging is stopped by user
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    /*DDLogVerbose(@"DTC: drag end: %f", scrollView.contentOffset.y);

    if (scrollView.contentOffset.y < 0) {
        DDLogVerbose(@"DTC: At top: %f", scrollView.contentOffset.y);
    }
    
	if (!decelerate) {
        

        
        //DDLogVerbose(@"DTC: drag end - b:%f k:%f", self.tableView.contentInset.bottom, self.keyboardHeight);

		//DDLogVerbose(@"MVC: scroll drag stop");
		//[self showSourceForVisibleCell:NO tableView:(UITableView *)scrollView];
	}*/
}


/**
 Hides source when dragging stops from deceleration
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y == 0) {
        DDLogVerbose(@"DTC: At top: %f", scrollView.contentOffset.y);
        [self loadMoreMessages];
    }
    
    //DDLogVerbose(@"DTC: decel end - b:%f k:%f", self.tableView.contentInset.bottom, self.keyboardHeight);

	//DDLogVerbose(@"MVC: scroll decelerated");
	//[self showSourceForVisibleCell:NO tableView:(UITableView *)scrollView];
}


/*- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    DDLogVerbose(@"DTC: scroll did - b:%f k:%f", self.tableView.contentInset.bottom, self.keyboardHeight);
}*/

#pragma mark - MediaImageController & LetterDisplayView

/*!
 @abstract Asks delegate (table) to forward this message
 */
- (void)MediaImageController:(MediaImageController *)controller forwardImage:(UIImage *)image {
    
    [self.parentController dismissModalViewControllerAnimated:NO];
    
    SelectContactController *nextController = [[SelectContactController alloc] 
                                               initWithTableStyle:UITableViewStylePlain 
                                               type:kMPSelectContactTypeForwardMessage
                                               viewContacts:nil];
    nextController.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:nextController];
    [nextController release];
    
    [AppUtility customizeNavigationController:navController];
    
    [[AppUtility getAppDelegate].containerController presentModalViewController:navController animated:YES];
    [navController release];
}

/*!
 @abstract Asks delegate (table) to forward this message
 */
- (void)LetterDisplayView:(LetterDisplayView *)view forwardImage:(UIImage *)image {
    
    
    SelectContactController *nextController = [[SelectContactController alloc] 
                                               initWithTableStyle:UITableViewStylePlain 
                                               type:kMPSelectContactTypeForwardMessage
                                               viewContacts:nil];
    nextController.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:nextController];
    [nextController release];
    
    [AppUtility customizeNavigationController:navController];
    
    [[AppUtility getAppDelegate].containerController presentModalViewController:navController animated:YES];
    [navController release];
    
}

#pragma mark - Image 

/*!
 @abstract Called when data has completed loading and is ready to use.
 
 - find my cell and update the image!
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager finishLoadingImage:(UIImage *)image{
    NSLog(@"DTC: got head image");
    // refresh head views for each cell
    //
    NSArray *visibleIPs = [self.tableView indexPathsForVisibleRows];
    NSUInteger cellCount = [self.messageCells count];
    
    for (NSIndexPath *iIP in visibleIPs) {
        if ([iIP row] < cellCount) {
            
            id iController = [self.messageCells objectAtIndex:[iIP row]];
            
            if ([iController respondsToSelector:@selector(refreshHeadViewForCell:animated:)]) {
                UITableViewCell *iTableCell = [self.tableView cellForRowAtIndexPath:iIP];
                if (iTableCell) {
                    [iController refreshHeadViewForCell:iTableCell animated:NO];
                }
            }
        }
    }
    
}


@end
