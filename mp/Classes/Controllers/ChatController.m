//
//  ChatController.m
//  mp
//
//  Created by M Tsai on 11-9-26.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "ChatController.h"
#import "CDChat.h"
#import "AppUtility.h"
#import "ChatDialogController.h"
#import "MPChatManager.h"
#import "CDMessage.h"
#import "MPFoundation.h"
#import "MPContactManager.h"
#import "ELCAlbumPickerController.h"

#import <MobileCoreServices/MobileCoreServices.h>  // for photo assets types



#define DELETE_ALL_AS_TAG   18001
#define BROADCAST_AS_TAG    18002

#define kCCSectionHidden    0
#define kCCSectionRegular   1

#define kCCHeaderHeight     40.0

// private methods
//
@interface ChatController () 

- (void)reloadChats;
- (void)setButtonsWithAnimation:(BOOL)animation;
- (void)endEdit:(id)sender animated:(BOOL)newAnimated;


@end

@implementation ChatController

@synthesize chats;
@synthesize hiddenChats;
@synthesize regularChats;

@synthesize pendingDeleteD;
@synthesize broadcastContacts;
@synthesize selectController;
@synthesize pendingMessageID;

@synthesize pendingHiddenChat;
@synthesize shouldPushPendingChat;

@synthesize editButtonItem;

@synthesize pendingMessageToUpdate;
@synthesize uiUpdateTimer;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.pendingDeleteD = newD;
        [newD release];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [pendingMessageID release];
    [selectController release];
    [broadcastContacts release];
    [pendingDeleteD release];
    [chats release];
    [hiddenChats release];
    [regularChats release];
    [editButtonItem release];
    
    [pendingMessageToUpdate release];
    [uiUpdateTimer release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}



#pragma mark - Hidden

/*!
 @abstract Hidden Chat should be shown
 */
- (BOOL) shouldShowHiddenChats {
    return ![[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
}

/*!
 @abstract Hides table header view
 */
- (void) hideHiddenHeader {
    
    [self.tableView beginUpdates];
    self.tableView.tableHeaderView = nil;
    [self.tableView endUpdates];
    
    /*CGRect newFrame = self.tableView.tableHeaderView.frame;
    newFrame.size.height = 0.0;
    
    [self.tableView beginUpdates];
    self.tableView.tableHeaderView.frame = newFrame;
    [self.tableView endUpdates];*/
    
}

/*!
 @abstract Show header that says there is no hidden chats
 */
- (void) showHiddenHeader {
    
    // add hidden tableview
    //
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, kCCHeaderHeight)];
    headerView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
    headerView.clipsToBounds = YES;
    headerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight;
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 10.0, 200.0, 20.0)];
    [AppUtility configLabel:headerLabel context:kAULabelTypeGrayMicroPlus];
    headerLabel.textAlignment = UITextAlignmentCenter;
    headerLabel.text = NSLocalizedString(@"No hidden chats configured", @"ChatList - text: no hidden chats currently exists");
    [headerView addSubview:headerLabel];
    [headerLabel release];
    
    // separator at the bottom 
    UIView *separatorBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, kCCHeaderHeight-1.0, 320.0, 1.0)];
    separatorBar.backgroundColor = [AppUtility colorForContext:kAUColorTypeTableSeparator];
    [headerView addSubview:separatorBar];
    [separatorBar release];
    
    [self.tableView beginUpdates];
    self.tableView.tableHeaderView = headerView;
    [self.tableView endUpdates];

    [headerView release];
    
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(hideHiddenHeader) userInfo:nil repeats:NO];
    /*
    CGRect newFrame = self.tableView.tableHeaderView.frame;
    newFrame.size.height = kCCHeaderHeight;
    
    [UIView animateWithDuration:1.0 
                     animations:^{
                         self.tableView.tableHeaderView.frame = newFrame;
                     } 
                     completion:^(BOOL finished){
                     }];
    */
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    DDLogInfo(@"CC: vdl");

    [super viewDidLoad];
    
    // set title to name of chat
    //
    self.title = NSLocalizedString(@"Chats", @"Nav Title: Chat Listing");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // apply standard table configurations
    [AppUtility configTableView:self.tableView];
    
    [self setButtonsWithAnimation:NO];

    
    // add hidden tableview
    //
    /*
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 0.0)];
    headerView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    headerView.clipsToBounds = YES;
    headerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight;
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 10.0, 200.0, 20.0)];
    [AppUtility configLabel:headerLabel context:kAULabelTypeGrayMicroPlus];
    headerLabel.textAlignment = UITextAlignmentCenter;
    headerLabel.text = NSLocalizedString(@"No hidden chats configured", @"ChatList - text: no hidden chats currently exists");
    [headerView addSubview:headerLabel];
    [headerLabel release];
    self.tableView.tableHeaderView = headerView;
    [headerView release];*/
    

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    /* if (!self.contactManager) {
     MPContactManager *newCM = [[MPContactManager alloc] init];
     self.contactManager = newCM;
     [newCM release];
     }*/
    

    
    
}

- (void)viewDidUnload
{
    DDLogInfo(@"CC: did unload");
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"CC: vwa ");
    
    // make sure exit edit mode 
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(endEdit:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // Reload chat if contacts info was updated - new headshots in particular
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadChats) name:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:nil];
    
    // after indexing is finished - so use new datamodel
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadChats) name:MP_CONTACTMANAGER_RELOAD_TABLE_NOTIFICATION object:nil];
    
    // after indexing is finished - so use new datamodel
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadChats) name:MP_CONTACTMANAGER_INDEX_NOTIFICATION object:nil];
    
    
    // multimsg message received
    // - reload all chats
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadChats) name:MP_CHATMANAGER_NEW_MULTIMSG_NOTIFICATION object:nil];
    
    // listen for new messages from the network!
    // - if new chat comes in reload this view
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleNewMessageNotification:) name:MP_CHATMANAGER_NEW_MESSAGE_NOTIFICATION object:nil];

    
    // listen for message confirmations
    // - to delete group chats
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processConfirmations:) name:MP_MESSAGECENTER_SENT_CONFIRMATION_NOTIFICATION object:nil];
    
    // listen for socket write failures
    // - to delete group chats
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processWriteTimeouts:) name:MP_SOCKETCENTER_WRITE_TIMEOUT_NOTIFICATION object:nil];
    
    // if message timeout
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processMessageTimeout:) name:MP_MESSAGECENTER_SENT_TIMEOUT_NOTIFICATION object:nil];
    

    // refresh badge count
    // - epecially needed if coming back from chat dialog
    [[MPChatManager sharedMPChatManager] updateChatBadgeCount];

    [self reloadChats];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    DDLogInfo(@"CC-vda: view did appear");

    [super viewDidAppear:animated];
    //[self reloadChats];
    
    
    // update HC state it was modified some where else
    [self dataSourceDidFinishLoadingNewDataAnimated:YES];
    
    //NSArray *vcs = [self.navigationController viewControllers];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // exit editing mode
	if (self.tableView.editing == YES) {
		[self endEdit:self animated:NO];
	}
    
    // clear notifications - no need to reload view if we are not viewable!
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // hide hidden chat view
    [self dataSourceDidFinishLoadingNewDataAnimated:YES];
    
    
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
    //return YES;
}

#pragma mark - Generic Table Methods

#define EDIT_BTN_TAG    19201
#define CHAT_BTN_TAG    19202

#define NO_ITEM_TAG 15001

/*!
 @Abstract check if there are any table items and show default view if no items
 */
- (void) showNoItemView {
    // Show no item label
    //
    UIView *noItemView = [self.tableView viewWithTag:NO_ITEM_TAG];

    NSUInteger totalItems = [self.hiddenChats count] + [self.regularChats count];
    if (totalItems == 0 && noItemView == nil) {        
        CGSize headerSize = self.tableView.tableHeaderView.frame.size;
        UILabel *noItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, headerSize.height, self.tableView.frame.size.width-40.0, self.tableView.frame.size.height-headerSize.height)];
        [AppUtility configLabel:noItemLabel context:kAULabelTypeNoItem];
        noItemLabel.text = NSLocalizedString(@"Tap the chat bubble button to start a new chat.", @"ChatList - text: Inform users how to start a new chat, since there are none now");
        noItemLabel.tag = NO_ITEM_TAG;
        [self.tableView addSubview:noItemLabel];
        [noItemLabel release];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    else if (totalItems > 0) {
        [noItemView removeFromSuperview];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    // hide and show edit button
    // - only if not in HC mode (right==canel button) and not edit mode
    //
    if (self.navigationItem.rightBarButtonItem.tag == CHAT_BTN_TAG &&
        !self.tableView.editing) {
        if (totalItems == 0) {
            // disable edit button
            //self.navigationItem.leftBarButtonItem.enabled = NO;
            self.navigationItem.leftBarButtonItem = nil;
        }
        else {
            // enable edit button
            //self.navigationItem.leftBarButtonItem.enabled = YES;
            self.navigationItem.leftBarButtonItem = self.editButtonItem;
        }
    }
}

/*!
 @abstract contruct data model for table
 */
- (void)constructTableGroups
{
	
    // query CD for all chats
    //
    if (!self.chats) {
        NSMutableArray *mutArray = [[NSMutableArray alloc] init];
        self.chats = mutArray;
        [mutArray release];
    }
    
    // create mutable chat arrays
    //
    if (!self.hiddenChats) {
        NSMutableArray *mutArray = [[NSMutableArray alloc] init];
        self.hiddenChats = mutArray;
        [mutArray release];
    }
    if (!self.regularChats) {
        NSMutableArray *mutArray = [[NSMutableArray alloc] init];
        self.regularChats = mutArray;
        [mutArray release];
    }
    
    [self.hiddenChats removeAllObjects];
    [self.regularChats removeAllObjects];
    
    // if not locked, then get hidden chats
    if ( [self shouldShowHiddenChats] ) {
        [self.hiddenChats addObjectsFromArray:[CDChat chatsIsHidden:YES]];
    }
    [self.regularChats addObjectsFromArray:[CDChat chatsIsHidden:NO]];
    
    
    //[self.chats removeAllObjects];
    //[self.chats addObjectsFromArray:[CDChat allChats]];
    

    NSMutableArray *hiddenCells = [[NSMutableArray alloc] init];
    
    for (CDChat *iChat in self.hiddenChats){

        ChatCellController *newCell = [[ChatCellController alloc] initWithCDChat:iChat];
        newCell.delegate = self;
        
        [hiddenCells addObject:newCell];
        [newCell release];
    }
    
    NSMutableArray *regularCells = [[NSMutableArray alloc] init];
    
    for (CDChat *iChat in self.regularChats){
        
        ChatCellController *newCell = [[ChatCellController alloc] initWithCDChat:iChat];
        newCell.delegate = self;
        
        [regularCells addObject:newCell];
        [newCell release];
    }
    
    self.tableGroups = [NSArray arrayWithObjects:hiddenCells, regularCells, nil];
    [hiddenCells release];
    [regularCells release];
    
    // show no item view if needed
    [self showNoItemView];
}



/*!
 @abstract Rebuilds datamodel and refresh tableview
 */
- (void) reloadChats {
    
    [self constructTableGroups];
    [self.tableView reloadData];
    
}


/*!
 @abstract Accumlate received messages and starts timer to update UI
 - helps aggregate if lots of messages comes in at the same time
 */
- (void) handleNewMessageNotification:(NSNotification *)notification {
    
    NSArray *msgObjectIDs = [notification object];
    
    if (!self.pendingMessageToUpdate) {
        NSMutableSet *newSet = [[NSMutableSet alloc] init];
        self.pendingMessageToUpdate = newSet;
        [newSet release];
    }
    
    if (msgObjectIDs) {
        [self.pendingMessageToUpdate addObjectsFromArray:msgObjectIDs];
    }
    
    //[self updateUIWithPendingMessages];
    
    if (![self.uiUpdateTimer isValid]) {
        self.uiUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateUIWithPendingMessages) userInfo:nil repeats:NO];
    }
}

/*!
 @abstract Accumlate received messages and starts timer to update UI
 - helps aggregate if lots of messages comes in at the same time
 */
- (void) updateUIWithPendingMessages {
    
    NSArray *msgObjectIDs = [self.pendingMessageToUpdate allObjects];
    [self.pendingMessageToUpdate removeAllObjects];
    
    if ([msgObjectIDs count] > 0) {
        [self reloadChatsForNewMessages:msgObjectIDs];
    }
}

/*!
 @abstract Rebuilds datamodel and refresh tableview when new msg comes in
 
 - check if msg chat already exists in table
   ~ if not then reload entire table
 
 - if all chats exists, then refresh each chat that got a new message
 
 
 */
- (void) reloadChatsForNewMessages:(NSArray *)msgObjectIDs {
                
    NSManagedObjectContext *moc = [AppUtility cdGetManagedObjectContext];
    
    BOOL shouldReloadEntireChatList = NO;
    
    NSMutableSet *reloadIndexPaths = [[NSMutableSet alloc] initWithCapacity:[msgObjectIDs count]];
    
    for (NSManagedObjectID *iID in msgObjectIDs) {
        CDMessage *iMessage = (CDMessage *)[moc objectWithID:iID];
        
        // make sure that iMessage exits and that chat has not been deleted
        //
        if (iMessage.chat.managedObjectContext != nil) {
            
            // search for the index path in table for this message
            // - only search for first row, otherwise the whole table should be reloaded
            NSIndexPath *iIP = nil;
            for (int sec=0; sec < [self.tableGroups count]; sec++) {
                NSArray *cells = [self.tableGroups objectAtIndex:sec];
                
                for (int row=0; row < [cells count]; row++) {
                    ChatCellController *cellController = [cells objectAtIndex:row];
                    if ([iMessage.chat isEqualToChat:cellController.cdChat]) {
                        iIP = [NSIndexPath indexPathForRow:row inSection:sec];
                        [reloadIndexPaths addObject:iIP];
                        break;
                    }
                }
                if (iIP) {
                    break;
                }
            }

            // if message's chat not found, reload whole table
            if (!iIP) {
                shouldReloadEntireChatList = YES;
                break;
            }
            
        }
        // if any missing messages, something is wrong so reload the whole table
        else {
            shouldReloadEntireChatList = YES;
            break;
        }
    }
    
    // then only refresh that related chat rows
    if (!shouldReloadEntireChatList && [reloadIndexPaths count] > 0) {
        
        // reloadData is actually cheaper! but the reload of cell info is expensive so use reload specific row instead
        //[self.tableView reloadData];
        
        // if only one cell needs to be updated
        if ([reloadIndexPaths count] == 1) {
            
            // if location also need to be changed, then animate it
            NSIndexPath *reloadIP = [reloadIndexPaths anyObject];
            if ([reloadIP row] != 0) {
                NSIndexPath *newIP = [NSIndexPath indexPathForRow:0 inSection:[reloadIP section]];
                
                [self.tableView beginUpdates];
                [self constructTableGroups];
                [self.tableView deleteRowsAtIndexPaths:[reloadIndexPaths allObjects] withRowAnimation:UITableViewRowAnimationTop];
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIP] withRowAnimation:UITableViewRowAnimationBottom];
                [self.tableView endUpdates];
            }
            else {
                [self.tableView reloadRowsAtIndexPaths:[reloadIndexPaths allObjects] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
        else {
            [self.tableView reloadRowsAtIndexPaths:[reloadIndexPaths allObjects] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
    // other wise new chat, so reload the entire table
    else {
        DDLogInfo(@"CC: reload whole table");
        [self constructTableGroups];
        [self.tableView reloadData];
    }
    [reloadIndexPaths release];
}


/*!
 @abstract End edit if no more chats to delete
 */
- (void) endEditIfNoMoreChats {
    // end edit if nothing more to delete!
    if ([self shouldShowHiddenChats]) {
        if ([self.hiddenChats count] == 0 && [self.regularChats count] == 0) {
            [self endEdit:nil animated:YES];
        }
    }
    else {
        if ([self.regularChats count] == 0) {
            [self endEdit:nil animated:YES];
        }
    }
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
	
	return YES;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	//NSUInteger section = [indexPath section];
	//NSUInteger row = [indexPath row];
	
	if (aTableView.editing) {
        return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellEditingStyleNone;
}


/*!
 @abstract Delete a single chat
 */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
    
    
    NSMutableArray *chatArray = nil;
    if (section == 0) {
        chatArray = self.hiddenChats;
    }
    else {
        chatArray = self.regularChats;
    }
    
	// delete favorites from array
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        CDChat *deleteChat = [[chatArray objectAtIndex:row] retain];
        
        DDLogInfo(@"CC-ces: deleting a chat: %@", [deleteChat displayNameStyle:kCDChatNameStyleTitle]);

        
        // request deletion from CM
        NSString *messageID = [[MPChatManager sharedMPChatManager] requestDeleteChat:deleteChat];
        
        // Delete is pending, so save state
        if ([messageID length] > 0) {
            [AppUtility startActivityIndicator];
            [self.pendingDeleteD setValue:deleteChat forKey:messageID];
            
        }
        // p2p chat was deleted
        else {
            // delete from data model
            [chatArray removeObjectAtIndex:row];
            [[self.tableGroups objectAtIndex:section] removeObjectAtIndex:row];
            
            // delete from view
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            // save afterwards
            [AppUtility cdSaveWithIDString:@"CC-ee: deleting a chat" quitOnFail:NO];
            [[MPChatManager sharedMPChatManager] updateChatBadgeCount];  
            
            [self endEditIfNoMoreChats];
            
        }
        [deleteChat release];
    }
}


/*!     
 Background color MUST be set right before cell is displayed
 */
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
}


#pragma mark - Table Section Headers

// show headers
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
    if ([self shouldShowHiddenChats] && [self.hiddenChats count] > 0) {
        if (section == kCCSectionHidden) {
            return NSLocalizedString(@"Hidden Chats", @"ChatList - section: list of hidden chats");
        }
        else if (section == kCCSectionRegular && [self.regularChats count] > 0) {
            return NSLocalizedString(@"Chats", @"ChatList - section: list of regular chats");
        }
    }

	return nil;
}


// return customized section
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
	UIImageView *sectionView = nil;
	
	// add Title
	NSString *title = [self tableView:tableView titleForHeaderInSection:section];
	// if top contacts
	if (title) {
		sectionView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_indexbar_green.png"]] autorelease];
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, 150, 15.0)];
		[AppUtility configLabel:titleLabel context:kAULabelTypeBlackMicroPlus];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = title;
		[sectionView addSubview:titleLabel];
		[titleLabel release];
	}
	return sectionView;
}


//
// Specify the space allocated IF a header is specified for the section
//
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    if (title) {
        return 15.0;
    }
    // iOS 5.0 needs this to hide section
    //
	return 0.0;
}






#pragma mark - Delete Chats


/*!
 @abstract process incoming confirmations
 */
- (void) processConfirmations:(NSNotification *)notification {
    
    NSString *messageID = [notification object];
    
    CDChat *deleteChat = [self.pendingDeleteD valueForKey:messageID];
    
    // if delete chat is found
    if (deleteChat) {
        DDLogInfo(@"CC-pc: deleting gchat pending:%d", [self.pendingDeleteD count]);
        // clear store
        [self.pendingDeleteD removeObjectForKey:messageID];
                
        // delete regular chats
        NSUInteger deleteIndex = [self.regularChats indexOfObject:deleteChat];
        // @TEST - for multiple leave messages 
        // NSUInteger deleteIndex = NSNotFound;

        if (deleteIndex != NSNotFound) {
            [self.regularChats removeObjectAtIndex:deleteIndex];
            [[self.tableGroups objectAtIndex:kCCSectionRegular] removeObjectAtIndex:deleteIndex];
            
            // delete from view
            NSIndexPath *deleteIP = [NSIndexPath indexPathForRow:deleteIndex inSection:kCCSectionRegular];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:deleteIP] withRowAnimation:UITableViewRowAnimationFade];

            [CDChat deleteChat:deleteChat];
            //[[MPChatManager sharedMPChatManager] deleteChat:deleteChat];
            
            [AppUtility cdSaveWithIDString:@"CC-pc: deleting a regular chat" quitOnFail:NO];
            [[MPChatManager sharedMPChatManager] updateChatBadgeCount]; 
        }
        // delete hidden chats
        else {
            deleteIndex = [self.hiddenChats indexOfObject:deleteChat];
            if (deleteIndex != NSNotFound) {
                [self.hiddenChats removeObjectAtIndex:deleteIndex];
                [[self.tableGroups objectAtIndex:kCCSectionHidden] removeObjectAtIndex:deleteIndex];
                
                // delete from view
                NSIndexPath *deleteIP = [NSIndexPath indexPathForRow:deleteIndex inSection:kCCSectionHidden];
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:deleteIP] withRowAnimation:UITableViewRowAnimationFade];
                
                [CDChat deleteChat:deleteChat];
                //[[MPChatManager sharedMPChatManager] deleteChat:deleteChat];
                
                [AppUtility cdSaveWithIDString:@"CC-pc: deleting a hidden chat" quitOnFail:NO];
                [[MPChatManager sharedMPChatManager] updateChatBadgeCount]; 
            } 
        }
        
        
        // stop if no more pending
        if ([self.pendingDeleteD count] == 0) {
            [AppUtility stopActivityIndicator];
            
            [self endEditIfNoMoreChats];
            
        }
    }
    // broadcast msg is accepted by DS - so dismiss composer view
    //
    else if ([messageID isEqualToString:self.pendingMessageID]) {
        
        // erase immediately so timeout will not find this mID laying around
        // - leave for reject to check
        //self.pendingMessageID = nil;
        
        [AppUtility stopActivityIndicator];
        [self dismissModalViewControllerAnimated:YES]; 
    }
}


/*!
 @abstract process message timeouts
 
 Use:
 - can cancel pending image updates
 
 */
- (void) processMessageTimeout:(NSNotification *)notification {
    
    NSString *messageID = [notification object];
    
    CDChat *deleteChat = [self.pendingDeleteD valueForKey:messageID];
    
    // if delete chat is found
    // - clear it from pendingD
    //
    if (deleteChat) {
        DDLogVerbose(@"CC-pwt: cancel gchat delete:%d", [self.pendingDeleteD count]);
        // clear store
        [self.pendingDeleteD removeObjectForKey:messageID];
        
        // delete leave message since it failed
        //
        [CDMessage deleteMessageWithID:messageID];
        
        // stop if no more pending
        if ([self.pendingDeleteD count] == 0) {
            [AppUtility stopActivityIndicator];
            [AppUtility showAlert:kAUAlertTypeNetwork];
        }
    }
    // broadcast message send timed out, so delete msg
    //
    else if ([messageID isEqualToString:self.pendingMessageID]) {
        
        DDLogVerbose(@"Chat: send broadcast message timeout");
        
        [CDMessage deleteMessageWithID:self.pendingMessageID];
        
        self.pendingMessageID = nil;
        
        [AppUtility stopActivityIndicator];
        [AppUtility showAlert:kAUAlertTypeNetwork];  
    }
}


/*!
 @abstract process write socket failures
 
 Use:
 - can cancel pending deletes if network is not available
 
 */
- (void) processWriteTimeouts:(NSNotification *)notification {
    
    NSNumber *longTagNumber = [notification object];
    NSString *tagString = [longTagNumber stringValue];
    
    NSString *fullMessageID = nil;
    for (NSString *iKey in [self.pendingDeleteD allKeys]){
        if ([iKey hasSuffix:tagString]) {
            fullMessageID = iKey;
            break;
        }
    }
    
    if (fullMessageID) {
        CDChat *deleteChat = [self.pendingDeleteD valueForKey:fullMessageID];
        
        // if delete chat is found
        // - clear it from pendingD
        //
        if (deleteChat) {
            DDLogVerbose(@"CC-pwt: cancel gchat delete:%d", [self.pendingDeleteD count]);
            // clear store
            [self.pendingDeleteD removeObjectForKey:fullMessageID];
            
            // stop if no more pending
            if ([self.pendingDeleteD count] == 0) {
                [AppUtility stopActivityIndicator];
                
                [AppUtility showAlert:kAUAlertTypeNetwork];
                
            }
        }
    }
    // network failure - while sending out new broadcast
    //
    else if ([self.pendingMessageID hasSuffix:tagString]) {
        DDLogVerbose(@"SC-pwt: broadcast message net failure");
        
        [CDMessage deleteMessageWithID:self.pendingMessageID];
        self.pendingMessageID = nil;
        
        [AppUtility stopActivityIndicator];
        [AppUtility showAlert:kAUAlertTypeNetwork];  
    }
}

#pragma mark - Button Methods



/*!
 @abstract sets up button for chat view
 
 */
// add edit and add button to navigation bar
- (void)setButtonsWithAnimation:(BOOL)animation {
    
    // if already set or in edit mode
    //
    if (self.navigationItem.rightBarButtonItem.tag == CHAT_BTN_TAG ||
        self.tableView.editing) {
        return;
    }
    
    // edit button
    //
    if (!self.editButtonItem) {
        UIBarButtonItem *editButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Edit",  @"ChatList - Button: edit chat list entries") 
                                                          buttonType:kAUButtonTypeBarNormal 
                                                              target:self 
                                                              action:@selector(pressEdit:)];
        editButton.tag = EDIT_BTN_TAG;
        self.editButtonItem = editButton;
    }
    NSUInteger totalItems = [self.hiddenChats count] + [self.regularChats count];

    if (totalItems > 0) {
        [self.navigationItem setLeftBarButtonItem:self.editButtonItem animated:animation];
    }
    else {
        [self.navigationItem setLeftBarButtonItem:nil animated:animation];
    }
    
    
    // Chat Button
    UIImage *norImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_green6_nor.png"] leftCapWidth:9.0 topCapHeight:15.0];
    
    UIImage *prsImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_green6_prs.png"] leftCapWidth:9.0 topCapHeight:15.0];
    
    UIButton *customButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 45.0, 30.0)];
    [customButton setBackgroundImage:norImage forState:UIControlStateNormal];
    [customButton setBackgroundImage:prsImage forState:UIControlStateHighlighted];
    [customButton setImage:[UIImage imageNamed:@"chat_btn_createchat_nor.png"] forState:UIControlStateNormal];
    [customButton setImage:[UIImage imageNamed:@"chat_btn_createchat_prs.png"] forState:UIControlStateHighlighted];
    [customButton setEnabled:YES];
    
    customButton.backgroundColor = [UIColor clearColor];
    [customButton addTarget:self action:@selector(pressAdd:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem* barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    [customButton release];
    barButtonItem.tag = CHAT_BTN_TAG;
    
    [self.navigationItem setRightBarButtonItem:barButtonItem animated:animation];
    
    [barButtonItem release];
    
}

// handle edit button press event
- (void)pressEdit:(id)sender {
	
	// allow editing
	[self.tableView setEditing:YES animated:YES];	
    
	// set button "Done" to end delete mode
    UIBarButtonItem *doneButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Done",  @"ChatList - Button: done with edit mode") 
                                                        buttonType:kAUButtonTypeBarHighlight 
                                                            target:self action:@selector(endEdit:)];
    [self.navigationItem setLeftBarButtonItem:doneButton animated:YES];
    
    UIBarButtonItem *deleteAllButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Delete All", @"ChatList - Button: delete all chats")
                                                      buttonType:kAUButtonTypeBarNormal 
                                                          target:self action:@selector(pressDeleteAll:)];
    [self.navigationItem setRightBarButtonItem:deleteAllButton animated:YES];

}

/*!
 @abstract adds or create a new chat
 */
- (void) pressAdd:(id)sender {
    SelectContactController *nextController = [[SelectContactController alloc] initWithTableStyle:UITableViewStylePlain type:kMPSelectContactTypeCreateChat viewContacts:nil];
    
    
    // Create nav controller to present modally
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:nextController];
    nextController.delegate = self;
    
    [AppUtility customizeNavigationController:navigationController];

    
    [self presentModalViewController:navigationController animated:YES];
    navigationController.delegate = self;
    [navigationController release];
    [nextController release];
}

/*!
 @abstract adds or create a new chat
 */
- (void) pressDeleteAll:(id)sender {
   
    
    UIActionSheet *aSheet;
	
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:NSLocalizedString(@"Are you sure you want to delete all chat histories?", @"Chat List - Alert: message to confirm if all chats should be deleted")
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel delete all chats")
               destructiveButtonTitle:NSLocalizedString(@"Delete All", @"Alert: Delete button")
               otherButtonTitles:nil];
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    aSheet.tag = DELETE_ALL_AS_TAG;
	
	[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];
    
}


/*!
 @abstract handle end of edit
 */
- (void)endEdit:(id)sender animated:(BOOL)newAnimated {
	
	// now it is ok to set editing
	//
	[self.tableView setEditing:NO animated:newAnimated];	
    
	[self setButtonsWithAnimation:newAnimated];
    
    // save core data
	//
    
    // show no item view if needed
    [self showNoItemView];
    
}

// handle end of edit
- (void)endEdit:(id)sender {
	[self endEdit:sender animated:YES];

}




#pragma mark - Action Sheet Methods

/*!
 @abstract respond to actionsheet selection
 */
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // if not cancel
    if (actionSheet.tag == DELETE_ALL_AS_TAG && buttonIndex != [actionSheet cancelButtonIndex]) {
        
		NSString *actionButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
		if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Delete All", nil)]) {
            
            DDLogInfo(@"CC-as: deleting all chats");
            
            // delete from data model
            NSMutableIndexSet *deleteIndexes = [[NSMutableIndexSet alloc] init];
            
            // delete from tableview
            NSMutableArray *deleteIPs = [[NSMutableArray alloc] init];

            // group chats - to request leave msg for
            NSMutableArray *groupChats = [[NSMutableArray alloc] init];
            
            // delete hidden chats
            if ([self shouldShowHiddenChats]) {
                for (CDChat *iChat in self.hiddenChats){
                    NSString *messageID = [[MPChatManager sharedMPChatManager] requestDeleteChat:iChat];
                    if ([messageID length] > 0) {
                        [self.pendingDeleteD setValue:iChat forKey:messageID];
                    }
                    else {
                        NSUInteger deleteIndex = [self.hiddenChats indexOfObject:iChat];
                        if (deleteIndex != NSNotFound) {
                            [deleteIndexes addIndex:deleteIndex];
                            [deleteIPs addObject:[NSIndexPath indexPathForRow:deleteIndex inSection:kCCSectionHidden]];
                        }
                    }
                }
                if ([deleteIndexes count] > 0) {
                    [self.hiddenChats removeObjectsAtIndexes:deleteIndexes];
                    [[self.tableGroups objectAtIndex:kCCSectionHidden] removeObjectsAtIndexes:deleteIndexes];
                }
                [deleteIndexes removeAllIndexes];
            }
            
            [groupChats removeAllObjects];
            // delete regular chats
            for (CDChat *iChat in self.regularChats){
                
                // prep delete
                // - separate out group chat
                // - get p2p chats that will be deleted soon
                //
                if ([iChat isGroupChat]) {
                    [groupChats addObject:iChat];
                }
                // p2p chats
                else {
                    NSUInteger deleteIndex = [self.regularChats indexOfObject:iChat];
                    if (deleteIndex != NSNotFound) {
                        [deleteIndexes addIndex:deleteIndex];
                        [deleteIPs addObject:[NSIndexPath indexPathForRow:deleteIndex inSection:kCCSectionRegular]];
                    }
                }
                
                /*NSString *messageID = [[MPChatManager sharedMPChatManager] requestDeleteChat:iChat];
                if ([messageID length] > 0) {
                    [self.pendingDeleteD setValue:iChat forKey:messageID];
                }
                else {
                    NSUInteger deleteIndex = [self.regularChats indexOfObject:iChat];
                    if (deleteIndex != NSNotFound) {
                        [deleteIndexes addIndex:deleteIndex];
                        [deleteIPs addObject:[NSIndexPath indexPathForRow:deleteIndex inSection:kCCSectionRegular]];
                    }
                }*/
            }
            
            // delete p2p chats
            [deleteIndexes enumerateIndexesUsingBlock:^(NSUInteger iIndex, BOOL *stop) {
                CDChat *p2pChat = [self.regularChats objectAtIndex:iIndex];
                [CDChat deleteChat:p2pChat];
                //[[MPChatManager sharedMPChatManager] deleteChat:p2pChat];
            }];
            if ([deleteIndexes count] > 0) {
                [self.regularChats removeObjectsAtIndexes:deleteIndexes];
                [[self.tableGroups objectAtIndex:kCCSectionRegular] removeObjectsAtIndexes:deleteIndexes];
            }
            [deleteIndexes release];
            // update table view
            if ([deleteIPs count] > 0) {
                [self.tableView deleteRowsAtIndexPaths:deleteIPs withRowAnimation:UITableViewRowAnimationFade];
            }
            [deleteIPs release];
            
            // send out group leave messages
            //
            for (CDChat *groupChat in groupChats) {
                NSString *messageID = [[MPChatManager sharedMPChatManager] requestDeleteChat:groupChat];
                if ([messageID length] > 0) {
                    [self.pendingDeleteD setValue:groupChat forKey:messageID];
                }
            }
            [groupChats release];
            
            [AppUtility cdSaveWithIDString:@"CC-as: deleting chats" quitOnFail:NO];
            [[MPChatManager sharedMPChatManager] updateChatBadgeCount]; 
            
            
            // P2P chats will delete quickly, if group chat, then start activity
            if ([self.pendingDeleteD count] > 0) {
                [AppUtility startActivityIndicator];
            }
            // if only P2P, end edit mode
            else {
                [self endEdit:nil animated:YES];
            }
            
        }
    }
    // Broadcast options
    //
    else if (actionSheet.tag == BROADCAST_AS_TAG && buttonIndex != [actionSheet cancelButtonIndex]) {
        
        NSString *actionButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        CCEditMode editMode = kCCEditModeBasic;
        BOOL useCamera = NO;
        
        // create text message
        //
        if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Text", nil)]) {
            editMode = kCCEditModeText; 
        }
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"<create sticker message>", nil)]) {
            editMode = kCCEditModeSticker;
        }
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Album", nil)]) {
            editMode = kCCEditModeImage;
        }
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Camera", nil)]) {
            editMode = kCCEditModeImage;
            useCamera = YES;
        }
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"<create letter message>", nil)]) {
            editMode = kCCEditModeLetter;
        }
        else if ([actionButtonTitle isEqualToString:NSLocalizedString(@"<create location message>", nil)]) {
            editMode = kCCEditModeLocation;
        }
        
        if (useCamera) {
            // startup camera
            //
            UIImagePickerController *imageController = [[UIImagePickerController alloc] init];
            //imageController.allowsEditing = YES;
            imageController.sourceType = UIImagePickerControllerSourceTypeCamera;
            if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
                imageController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            }
            imageController.delegate = self;
            if (self.selectController) {
                [self.selectController presentModalViewController:imageController animated:YES];
            }
            else {
                [self presentModalViewController:imageController animated:YES];
            }
            [imageController release];
            
        }
        // if just album
        else if (editMode == kCCEditModeImage) {
            
            // startup iOS album
            //
            UIImagePickerController *imageController = [[UIImagePickerController alloc] init];
            //imageController.allowsEditing = YES;
            imageController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imageController.delegate = self;
            if (self.selectController) {
                [self.selectController presentModalViewController:imageController animated:YES];
            }
            else {
                [self presentModalViewController:imageController animated:YES];
            }
            [imageController release];
            
            // single image picker
            //
            /*ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] initWithNibName:@"ELCAlbumPickerController" bundle:[NSBundle mainBundle]]; 
            albumController.onlySingleSelection = YES;
            
            ELCImagePickerController *imagePicker = [[ELCImagePickerController alloc] initWithRootViewController:albumController];
            [albumController setParent:imagePicker];
            [imagePicker setDelegate:self];
            
            [AppUtility customizeNavigationController:imagePicker];
            
            if (self.selectController) {
                [self.selectController presentModalViewController:imagePicker animated:YES];
            }
            else {
                [self presentModalViewController:imagePicker animated:YES];
            }
            [imagePicker release];
            [albumController release];
             */
            
        }
        // if letter message
        else if (editMode == kCCEditModeLetter) {
            
            // take snapshot of background image to use for letter view
            //
            UIImage *dialogBackView = [Utility imageFromUIView:self.view];
            
            LetterController *nextController = [[LetterController alloc] init];
            nextController.letterMode = kLCModeCreate;
            nextController.backImage = dialogBackView;
            nextController.delegate = self;
            
            if ([self.broadcastContacts count] == 1) {
                nextController.toName = [[self.broadcastContacts objectAtIndex:0] displayName];
            }
            
            // push letter VC on existing nav controller
            UIViewController *modalController = self.modalViewController;
            if ([modalController respondsToSelector:@selector(pushViewController:animated:)]) {
                [(UINavigationController *)modalController pushViewController:nextController animated:YES];
            }
            [nextController release];
            
            /*
            // Create nav controller to present modally
            UINavigationController *navigationController = [[UINavigationController alloc]
                                                            initWithRootViewController:nextController];            
            [AppUtility customizeNavigationController:navigationController];
            
            [self presentModalViewController:navigationController animated:YES];
            [navigationController release];
            [nextController release];*/
            
        }
        // if location message
        else if (editMode == kCCEditModeLocation) {
            
            LocationShareController *nextController = [[LocationShareController alloc] init];
            nextController.locationMode = kLSModeShare;
            nextController.delegate = self;
            
            // push letter VC on existing nav controller
            UIViewController *modalController = self.modalViewController;
            if ([modalController respondsToSelector:@selector(pushViewController:animated:)]) {
                [(UINavigationController *)modalController pushViewController:nextController animated:YES];
            }
            [nextController release];
            
        }
        else if (editMode != kCCEditModeBasic) {
            
            ComposerController *newController = [[ComposerController alloc] init];
            newController.toContacts = self.broadcastContacts;
            newController.editMode = editMode;
            newController.characterLimitMin = kMPParamChatMessageLengthMin;
            newController.characterLimitMax = kMPParamChatMessageLengthMax;
            newController.saveButtonTitle = NSLocalizedString(@"Send", @"Broadcast - button: send out broadcast msg"); 
            newController.title = NSLocalizedString(@"Broadcast", @"Broadcast - title: broadcast a message to multiple friends");
            
            newController.delegate = self;
            
            UIViewController *modalController = self.modalViewController;
            
            if ([modalController respondsToSelector:@selector(pushViewController:animated:)]) {
                [(UINavigationController *)modalController pushViewController:newController animated:YES];
            }
            [newController release];
            
            self.broadcastContacts = nil;
        }

    }
    else {
        DDLogVerbose(@"Actionsheet Cancelled");
    }

}


#pragma mark - UIAlertViewDelegate Methods
/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	NSInteger cancelIndex = [alertView cancelButtonIndex];
    
    // delete all chats
    if (buttonIndex != cancelIndex) {
        
        // delete from CD
        //
        NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
        for (CDChat *iChat in self.chats){
            [managedObjectContext deleteObject:iChat];
        }
        [self.chats removeAllObjects];
        NSArray *emptyArray = [[NSArray alloc] init];
        self.tableGroups = emptyArray;
        [emptyArray release];
        
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [AppUtility cdSaveWithIDString:@"CL: save delete all chats" quitOnFail:NO];
        [self endEdit:nil];
    }
    
}*/

#pragma mark - SelectContactsControllerDelegate


/*!
 @abstract open up chat dialog for selected contacts
 - create new chat with the selected contacts
 
 */
- (void)selectContactsController:(SelectContactController *)selectContactsController chatContacts:(NSArray *)contacts{
    
    //[self dismissModalViewControllerAnimated:YES];
    
    CDChat *chat = [CDChat chatWithCDContacts:contacts groupID:nil shouldSave:YES];
    
    
    BOOL isHCLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    
    // if hidden chat then ask for PIN unlock first
    if (isHCLocked && [chat.isHiddenChat boolValue] ) {
        self.pendingHiddenChat = chat;
        HiddenController *nextController = [[HiddenController alloc] initWithHCStatus:kHCViewStatusUnlockPIN];
        
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:nextController];
        [AppUtility customizeNavigationController:navigationController];
        nextController.delegate = self;
        [selectContactsController presentModalViewController:navigationController animated:YES];
        [navigationController release];
        [nextController release];
        
    }
    else {
        [self dismissModalViewControllerAnimated:YES];

        ChatDialogController *newController = [[ChatDialogController alloc] initWithCDChat:chat];
        newController.delegate = self;
        
        // only add if brand new chats
        //
        if (chat.isBrandNew) {
            chat.isBrandNew = NO;
            // add a add control message so we can add join noticies
            // - for group chat only
            // - no need for sent time - this will help maintain it as the first message
            //
            [[MPChatManager sharedMPChatManager] addGroupChatControlAddMessageForChat:chat shouldSend:NO];
            
        }
        
        [self.navigationController pushViewController:newController animated:YES];
        [newController release];
        
    }
}

/*!
 @abstract get selected contacts and create broadcast message view
 
 */
- (void)selectContactsController:(SelectContactController *)selectContactsController broadcastContacts:(NSArray *)contacts {
    
    self.broadcastContacts = contacts;
    self.selectController = selectContactsController;
    
    UIActionSheet *aSheet;
    
    aSheet	= [[UIActionSheet alloc]
               initWithTitle:nil // NSLocalizedString(@"Are you sure you want to delete all chat histories?", @"Chat List - Alert: message to confirm if all chats should be deleted")
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel delete all chats")
               destructiveButtonTitle:nil // NSLocalizedString(@"Delete All", @"Alert: Delete button")
               otherButtonTitles:NSLocalizedString(@"Text", @"TextEdit: text message"), 
               NSLocalizedString(@"<create sticker message>", @"ChatList: sticker message"),
               NSLocalizedString(@"Album", @"ChatList: image message"),
               NSLocalizedString(@"Camera", @"ChatList: image message"),
               NSLocalizedString(@"<create letter message>", @"ChatList: broadcast letter message"),
               NSLocalizedString(@"<create location message>", @"ChatList: broadcast location message"),
               nil];
    
    aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    aSheet.tag = BROADCAST_AS_TAG;
    //[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
    [aSheet showInView:[[UIApplication sharedApplication] keyWindow]];
    [aSheet release];
    
    /*
    if ([contacts count] > kMPParamBroadcastMax) {
        
        [Utility showAlertViewWithTitle:NSLocalizedString(@"Create Broadcast", @"ChatList - Alert: title for going over max contacts for broadcast") 
                                message:[NSString stringWithFormat:NSLocalizedString(@"Broadcast should be less than %d.", @"ChatList - Alert: group chat contacts has surpassed max limit"), kMPParamGroupChatMax]];
        
        
        [Utility showAlertViewWithTitle:NSLocalizedString(@"Broadcast Should Be Less Than 25", @"ChatList - Alert: broadcast chat contacts has surpassed max limit") message:nil];
    }
    else {
       
    }*/
    
}



/*!
 @abstract Notifiy parent controller of cancel
 */
- (void)selectContactsController:(SelectContactController *)selectContactsController didCancel:(BOOL)didCancel {
    
    /*[[AppUtility getAppDelegate].tabBarFacade pressedIndex:kMPTabIndexSetting];
    [[AppUtility getAppDelegate].tabBarFacade pressedIndex:kMPTabIndexChat];
    */
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark - ContactCellController

/*!
 @abstract Called when contact cell needs to be refreshed.
 
 We need to tell the table to refresh the cell if something changed like the headshot.
 The table will then:
 - figure out if this controller is visible
 - if visible then refresh it
 
 */
- (void)ChatCellController:(ChatCellController *)controller refreshChat:(CDChat *)chat {
    
    
    // find the index path
    NSInteger chatIndex = [self.regularChats indexOfObject:chat];
    
    if (chatIndex != NSNotFound) {
        NSIndexPath *chatIP = [NSIndexPath indexPathForRow:chatIndex inSection:kCCSectionRegular];
        
        // if IP visible then refresh it
        if ([Utility isIndexPath:chatIP inIndexPaths:[self.tableView indexPathsForVisibleRows]]) {
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:chatIP] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    else if ([self shouldShowHiddenChats]) {
        NSInteger hiddenIndex = [self.hiddenChats indexOfObject:chat];
        
        if (hiddenIndex != NSNotFound) {
            NSIndexPath *chatIP = [NSIndexPath indexPathForRow:hiddenIndex inSection:kCCSectionHidden];
            
            // if IP visible then refresh it
            if ([Utility isIndexPath:chatIP inIndexPaths:[self.tableView indexPathsForVisibleRows]]) {
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:chatIP] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}


/*!
 @abstract Inform delegate that cell was selected
 
 */
- (void)ChatCellController:(ChatCellController *)controller didSelectChat:(CDChat *)chat {
    
    NSUInteger viewCount = [self.navigationController.viewControllers count];
    
    // only push on top of root
    // - if there is another chat, don't push another
    // - this can happen if users tap very quickly on the tableview - more of a iOS bug
    //
    if (viewCount == 1) {
        ChatDialogController *newController = [[ChatDialogController alloc] initWithCDChat:chat];
        newController.delegate = self;
        [self.navigationController pushViewController:newController animated:YES];
        [newController release];
    }
    else {
        DDLogError(@"CC: double tap detected!");
    }
    
}


#pragma mark - NavigationController 

/*!
 @abstract forwards nav controller so app delelgate can customize it
 */
- (void)navigationController:(UINavigationController *)navigationController 
      willShowViewController:(UIViewController *)viewController 
					animated:(BOOL)animated {
	
    [[AppUtility getAppDelegate] navigationController:navigationController willShowViewController:viewController animated:animated];
	
}




#pragma mark - TKImagePicker Delegates

/*!
 @abstract Finished selecting images to send out
 
 */
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
	
    picker.delegate = nil;
	//[self dismissModalViewControllerAnimated:YES];
    
    DDLogVerbose(@"CD-ip: start - info %@", info);
    
    
    
    for(NSDictionary *dict in info) {
        
        NSString *mediaType = [dict objectForKey: UIImagePickerControllerMediaType];
        UIImage *originalImage, *editedImage, *imageToSave; //, *compressedImage;
        
        // Handle a still image capture
        if ([mediaType isEqualToString:ALAssetTypePhoto]){   //(CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
            
            editedImage = (UIImage *) [dict objectForKey:
                                       UIImagePickerControllerEditedImage];
            originalImage = (UIImage *) [dict objectForKey:
                                         UIImagePickerControllerOriginalImage];
            
            if (editedImage) {
                imageToSave = editedImage;
            } else {
                imageToSave = originalImage;
            }
            
            // send image to create schedule view
            // - push it onto the same stack
            //
            ComposerController *nextController = [[ComposerController alloc] init];
            nextController.toContacts = self.broadcastContacts;
            nextController.editMode = kCCEditModeImage;
            nextController.saveButtonTitle = NSLocalizedString(@"Send", @"Broadcast - button: send out broadcast msg"); 
            nextController.title = NSLocalizedString(@"Broadcast", @"Broadcast - title: broadcast a message to multiple friends");
            
            nextController.delegate = self;
            
            [nextController setImage:imageToSave];
            if (self.selectController.navigationController) {
                self.selectController.navigationController.toolbarHidden = YES;
                [self.selectController.navigationController pushViewController:nextController animated:NO];
            }
            [nextController release];
        }
        [picker dismissModalViewControllerAnimated:YES];
        
        // Handle a movie capture
        //if (CFStringCompare ((CFStringRef) mediaType, kUTTypeMovie, 0)
        //    == kCFCompareEqualTo) {
        /*if ([mediaType isEqualToString:ALAssetTypeVideo]){
         NSString *moviePath = [[dict objectForKey:
         UIImagePickerControllerMediaURL] path];
         
         if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
         UISaveVideoAtPathToSavedPhotosAlbum (
         moviePath, nil, nil, nil);
         }
         }*/
    }
    
    
    
    
    
    DDLogVerbose(@"CD-ip: Done sending images");
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    picker.delegate = nil;
	[self dismissModalViewControllerAnimated:YES];
}



#pragma mark - Image Picker Delegates


// For responding to the user tapping Cancel.
- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    [self dismissModalViewControllerAnimated:YES];    
}


// For responding to the user accepting a newly-captured picture or movie
- (void) imagePickerController: (UIImagePickerController *) picker
 didFinishPickingMediaWithInfo: (NSDictionary *) info {
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToSave;
    
    // Handle a still image capture
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0)
        == kCFCompareEqualTo) {
        
        // default is 320x320 image
        //
        editedImage = (UIImage *) [info objectForKey:
                                   UIImagePickerControllerEditedImage];
        originalImage = (UIImage *) [info objectForKey:
                                     UIImagePickerControllerOriginalImage];
        CGSize eSize = editedImage.size;
        //CGSize oSize = originalImage.size;
        
        DDLogInfo(@"Image size: %f %f", eSize.width, eSize.height);
        if (editedImage) {
            imageToSave = editedImage;
        } else {
            imageToSave = originalImage;
        }
        
        // save only for camera
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            // save image to album automatically
            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);
        }
        
        // present create view
        //
        ComposerController *nextController = [[ComposerController alloc] init];
        nextController.toContacts = self.broadcastContacts;
        nextController.editMode = kCCEditModeImage;
        nextController.saveButtonTitle = NSLocalizedString(@"Send", @"Broadcast - button: send out broadcast msg"); 
        nextController.title = NSLocalizedString(@"Broadcast", @"Broadcast - title: broadcast a message to multiple friends");
        nextController.delegate = self;
        
        [nextController setImage:imageToSave];
        
        if (self.selectController.navigationController) {
            self.selectController.navigationController.toolbarHidden = YES;
            [self.selectController.navigationController pushViewController:nextController animated:NO];
        }
        else {
            UINavigationController *navigationController = [[UINavigationController alloc]
                                                            initWithRootViewController:nextController];
            [AppUtility customizeNavigationController:navigationController];
            
            [self presentModalViewController:navigationController animated:YES];
            [navigationController release];
        }
        [nextController release];
    }
    [picker dismissModalViewControllerAnimated:NO];
}


#pragma mark - LetterController

/*!
 @abstract Call when letter creation is complete and ready to send
 - create letter message and send out
 */
- (void)LetterController:(LetterController *)view letterImage:(UIImage *)letterImage letterID:(NSString *)letterID {
    
    // present create view
    //
    ComposerController *nextController = [[ComposerController alloc] init];
    nextController.toContacts = self.broadcastContacts;
    nextController.editMode = kCCEditModeLetter;
    nextController.saveButtonTitle = NSLocalizedString(@"Send", @"Broadcast - button: send out broadcast msg"); 
    nextController.title = NSLocalizedString(@"Broadcast", @"Broadcast - title: broadcast a message to multiple friends");    
    nextController.delegate = self;
    
    [nextController setLetterImage:letterImage letterID:letterID];
    
    // if wizard stack already exist, keep pushing on to it
    //
    if (self.selectController.navigationController) {
        self.selectController.navigationController.toolbarHidden = YES;
        [self.selectController.navigationController pushViewController:nextController animated:YES];
    }
    else {
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:nextController];
        [AppUtility customizeNavigationController:navigationController];
        
        [self presentModalViewController:navigationController animated:YES];
        [navigationController release];
    }
    [nextController release];

    
    /*
    CDMessage *letterMessage = [CDMessage outCDMessageForChat:self.cdChat 
                                                  messageType:kCDMessageTypeLetter 
                                                         text:nil 
                                               attachmentData:letterImage 
                                                  isMulticast:NO 
                                           multicastParentMID:nil 
                                          multicastToContacts:nil 
                                                dateScheduled:nil 
                                                  hideMessage:NO 
                                                     typeInfo:letterID 
                                                   shouldSave:YES];
    
    // sends this message
    //
    [[MPChatManager sharedMPChatManager] sendCDMessage:letterMessage];
    */
    //[self dismissModalViewControllerAnimated:YES];
    
}


#pragma mark - Location 

/*!
 @abstract Call when user has selected a location to share 
 */
- (void)LocationShareController:(LocationShareController *)controller shareCoordinate:(CLLocationCoordinate2D)coordinate previewImage:(UIImage *)previewImage {
    
    // present create view
    //
    ComposerController *nextController = [[ComposerController alloc] init];
    nextController.toContacts = self.broadcastContacts;
    nextController.editMode = kCCEditModeLocation;
    nextController.saveButtonTitle = NSLocalizedString(@"Send", @"Broadcast - button: send out broadcast msg"); 
    nextController.title = NSLocalizedString(@"Broadcast", @"Broadcast - title: broadcast a message to multiple friends");    
    nextController.delegate = self;
    
    [nextController setLocationPreviewImage:previewImage coordinateText:[LocationShareController locationMessageTextForCoordinate:coordinate]];
         
    // if wizard stack already exist, keep pushing on to it
    //
    if (self.selectController.navigationController) {
        self.selectController.navigationController.toolbarHidden = YES;
        [self.selectController.navigationController pushViewController:nextController animated:YES];
    }
    else {
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:nextController];
        [AppUtility customizeNavigationController:navigationController];
        
        [self presentModalViewController:navigationController animated:YES];
        [navigationController release];
    }
    [nextController release];
    
}


#pragma mark - ComposerController Delegate

/*!
 @abstract User pressed saved with newly created Broadcast message 
 
 - Submit message to DS and wait for DS confirmation
 
 */
- (void)ComposerController:(ComposerController *)composerController 
                      text:(NSString *)text 
                  contacts:(NSArray *)contacts 
                     image:(UIImage *)image date:(NSDate *)date 
               letterImage:(UIImage *)letterImage 
                  letterID:(NSString *)letterID 
             locationImage:(UIImage *)locationImage 
              locationText:(NSString *)locationText {
    
    NSString *msgText = nil;
    CDMessageType msgType = kCDMessageTypeText;
    
    UIImage *msgImage = nil;
    
    switch (composerController.editMode) {
        case kCCEditModeText:
            msgText = text;
            break;
            
        case kCCEditModeSticker:
            msgText = text;
            msgType = kCDMessageTypeSticker;
            break;
            
        case kCCEditModeImage:
            msgType = kCDMessageTypeImage;
            msgImage = image;
            break;
            
        case kCCEditModeLetter:
            msgType = kCDMessageTypeLetter;
            msgImage = letterImage;
            break;
            
        case kCCEditModeLocation:
            msgType = kCDMessageTypeLocation;
            msgImage = locationImage;
            msgText = locationText;
            break;
            
        default:
            break;
    }
    
    // create broadcast message
    //
    CDMessage *newCDMessage = [CDMessage outCDMessageForChat:nil 
                                                 messageType:msgType 
                                                        text:msgText 
                                              attachmentData:msgImage 
                                                 isMulticast:YES 
                                          multicastParentMID:nil 
                                         multicastToContacts:[NSSet setWithArray:contacts] 
                                               dateScheduled:nil 
                                                 hideMessage:NO 
                                                    typeInfo:letterID                                     
                                                  shouldSave:YES];
    self.pendingMessageID = newCDMessage.mID;
    
    // listen for message confirmations
    // - know if DS accepted our message 
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processConfirmations:) name:MP_MESSAGECENTER_SENT_CONFIRMATION_NOTIFICATION object:nil];
    
    // listen for socket write failures
    // - to delete group chats
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processWriteTimeouts:) name:MP_SOCKETCENTER_WRITE_TIMEOUT_NOTIFICATION object:nil];
    
    // if message timeout
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processMessageTimeout:) name:MP_MESSAGECENTER_SENT_TIMEOUT_NOTIFICATION object:nil];
    
    // sends this message
    //
    [AppUtility startActivityIndicator];
    
    // send message requesting Sent confirmation
    //
    [[MPChatManager sharedMPChatManager] sendCDMessage:newCDMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:NO];
    
}


#pragma mark - TKRefreshTableViewController Button Overrides

/*!
 @abstract Show Cancel PIN button - to dismiss enter PIN mode
 
 */
- (void) navBarShowCancel
{
    
    // make sure we exit edit mode first
    //
	[self.tableView setEditing:NO animated:NO];
    // show no item view if needed
    [self showNoItemView];
    
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel", @"ChatList - Button: cancel HC PIN entry")
                                                           buttonType:kAUButtonTypeBarNormal 
                                                               target:self action:@selector(pressCancelPIN:)];
    [self.navigationItem setRightBarButtonItem:cancelButton animated:YES];
    
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];

}

/*!
 @abstract Restore to original navigation buttons
 
 */
- (void) navBarRestoreButtons
{
	[self setButtonsWithAnimation:YES];
    
    
}

/*!
 @abstract Exit PIN entry mode
 */
- (void) pressCancelPIN:(id)sender {
    [self dataSourceDidFinishLoadingNewDataAnimated:YES];
}


/*!
 @abstract Inform Chat that HC was unlocked
 
 */
- (void) hiddenDidUnlock
{
    [self constructTableGroups];
    if ([self.hiddenChats count] == 0) {
        [self showHiddenHeader];
    }
    [self.tableView reloadData];
    
}

/*!
 @abstract Inform Chat that HC was locked
 
 */
- (void) hiddenDidLockAnimated:(BOOL)animated
{
    
    NSUInteger preRegCount = [[self.tableGroups objectAtIndex:kCCSectionRegular] count];
    
    DDLogVerbose(@"CC-hdl: hid: %d  reg: %d", [[self.tableGroups objectAtIndex:kCCSectionHidden] count], preRegCount); 
    [self constructTableGroups];
    
    NSUInteger postRegCount = [[self.tableGroups objectAtIndex:kCCSectionRegular] count];

    DDLogVerbose(@"CC-hdl: hid: %d  reg: %d", [[self.tableGroups objectAtIndex:kCCSectionHidden] count], postRegCount); 
    
    if (animated) {
        /* hidden section should be empty so let's refresh it.  We are never sure what will happen
         With the regular section, so in case it changes reload the whole table */
        if (postRegCount != preRegCount) {
            DDLogVerbose(@"CC-hdl: table rows changed!");
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]
                          withRowAnimation:UITableViewRowAnimationFade];
        }
        else {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kCCSectionHidden] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    else {
        [self.tableView reloadData];
    }
    
    //NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)];
	//[self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - HiddenController

/*!
 @abstract pushes pending chat into view
 */
- (void) pushPendingChat {
    
    if (self.pendingHiddenChat) {
        ChatDialogController *newController = [[ChatDialogController alloc] initWithCDChat:self.pendingHiddenChat];
        newController.delegate = self;
        [self.navigationController pushViewController:newController animated:YES];
        [newController release];
    }
    // reset
    self.pendingHiddenChat = nil;
    self.shouldPushPendingChat = NO;
}

/*!
 @abstract Notifiy Delegate that unlock was successful
 - proceed to open hidden chat after unlocking
 
 Note:
 - don't push now since tabbar is not visiable yet.  
 - This will then preven nav delegate from calling and cause the tab bar not to hide!
 - Instead flag for the push to happen after viewdidappear is called!
 
 */
- (void)HiddenController:(HiddenController *)controller unlockDidSucceed:(BOOL)didSucceed {
    [self dismissModalViewControllerAnimated:YES];
    
    ChatDialogController *newController = [[ChatDialogController alloc] initWithCDChat:self.pendingHiddenChat];
    newController.delegate = self;
    [self.navigationController pushViewController:newController animated:YES];
    [newController release];
    
    // should push after view appears!
    //
    self.shouldPushPendingChat = YES;
    
}

#pragma mark - ChatDialogController 

/*!
 @abstract Informs delegate to show another chat
 
 - Swaps new chat onto nav stack
 
 */
- (void)ChatDialogController:(ChatDialogController *)controller showChat:(CDChat *)newChat {
    
    // Toggle tab indexes 
    // - incase low mem encountered
    // - makes sure views are refreshed properly otherwise a black view will be showing
    // - poping to root controller does call VWA or VDA properly
    //
    [[AppUtility getAppDelegate].tabBarFacade pressedIndex:kMPTabIndexSetting];
    [[AppUtility getAppDelegate].tabBarFacade pressedIndex:kMPTabIndexChat];

    [self.navigationController popToRootViewControllerAnimated:NO];    
    
    ChatDialogController *newController = [[ChatDialogController alloc] initWithCDChat:newChat];
    newController.delegate = self;
    [self.navigationController pushViewController:newController animated:NO];
    [newController release];
    
    [[AppUtility getAppDelegate].containerController dismissModalViewControllerAnimated:YES];
}

@end

