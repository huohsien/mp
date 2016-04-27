//
//  ScheduleController.m
//  mp
//
//  Created by Min Tsai on 1/17/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "ScheduleController.h"
#import "CDChat.h"
#import "AppUtility.h"
#import "ChatDialogController.h"
#import "MPChatManager.h"
#import "CDMessage.h"
#import "MPFoundation.h"
#import "MPContactManager.h"
#import "ELCAlbumPickerController.h"
#import <MobileCoreServices/MobileCoreServices.h>  // for photo assets types

#import "ScheduleCellController.h"
#import "ScheduleInfoController.h"


// private methods
//
@interface ScheduleController () 

- (void) reloadMessages;
- (void)setButtonsWithAnimation:(BOOL)animation;
- (void)endEdit:(id)sender animated:(BOOL)newAnimated;

@end

@implementation ScheduleController

@synthesize scheduledMessages;
@synthesize pendingDeleteD;
@synthesize pendingMessageID;
@synthesize editButtonItem;

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
    [pendingDeleteD release];
    [scheduledMessages release];
    [editButtonItem release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set title to name of chat
    //
    self.title = NSLocalizedString(@"Schedule Message", @"Nav Title: Scheduled message listing");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // apply standard table configurations
    [AppUtility configTableView:self.tableView];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"SC-vwa");
    // make sure exit edit mode 
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(endEdit:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // Reload chat if contacts info was updated - new headshots in particular
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadMessages) name:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:nil];
    
    // after indexing is finished - so use new datamodel
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadMessages) name:MP_CONTACTMANAGER_RELOAD_TABLE_NOTIFICATION object:nil];
    
    // listen for new messages from the network!
    // - if new chat comes in reload this view
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadMessages) name:MP_CHATMANAGER_NEW_SCHEDULED_NOTIFICATION object:nil];
    
    
    
    // listen for message confirmations
    // - to delete messages
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processConfirmations:) name:MP_MESSAGECENTER_ACCEPT_CONFIRMATION_NOTIFICATION object:nil];
    
    // listen for message confirmations
    // - to delete group chats
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processReject:) name:MP_MESSAGECENTER_REJECT_CONFIRMATION_NOTIFICATION object:nil];
    
    
    // listen for socket write failures
    // - to delete group chats
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processWriteTimeouts:) name:MP_SOCKETCENTER_WRITE_TIMEOUT_NOTIFICATION object:nil];
    
    // if message timeout
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processMessageTimeout:) name:MP_MESSAGECENTER_SENT_TIMEOUT_NOTIFICATION object:nil];
    
    
    // refresh badge count
    // - epecially needed if coming back from creating a new SM
    [[MPChatManager sharedMPChatManager] updateScheduleBadgeCount];
    
    [self setButtonsWithAnimation:NO];
    [self reloadMessages];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    DDLogVerbose(@"CH-vda: view did appear");
    
    [super viewDidAppear:animated];
    //[self reloadChats];
    
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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
    //return YES;
}

#pragma mark - Generic Table Methods


/*!
 @abstract contruct data model for table
 */
- (void)constructTableGroups
{
	
    NSMutableArray *cells = [[NSMutableArray alloc] init];
    
    // query CD for all chats
    //
    if (!self.scheduledMessages) {
        NSMutableArray *mutArray = [[NSMutableArray alloc] init];
        self.scheduledMessages = mutArray;
        [mutArray release];
    }
    
    [self.scheduledMessages removeAllObjects];
    [self.scheduledMessages addObjectsFromArray:[CDMessage scheduledMessages]];
    
    // add existing chat messages
    //
    for (CDMessage *iMessage in self.scheduledMessages){
        ScheduleCellController *newCell = [[ScheduleCellController alloc] initWithCDMessage:iMessage];
        newCell.delegate = self;
        [cells addObject:newCell];
        [newCell release];
    }
    
    self.tableGroups = [NSArray arrayWithObjects:cells, nil];
    [cells release];
     
}

#define NO_ITEM_TAG 15001

- (void) showNoItemView {
    // Show no item label
    //
    UIView *noItemView = [self.tableView viewWithTag:NO_ITEM_TAG];
    
    NSUInteger totalItems = [self.scheduledMessages count];
    if (totalItems == 0 && noItemView == nil) {        
        CGSize headerSize = self.tableView.tableHeaderView.frame.size;
        UILabel *noItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, headerSize.height, self.tableView.frame.size.width-40.0, self.tableView.frame.size.height-headerSize.height)];
        [AppUtility configLabel:noItemLabel context:kAULabelTypeNoItem];
        noItemLabel.text = NSLocalizedString(@"Tap '+' to create a scheduled message.\n(5 minutes to 60 days)", @"Schedule - text: Inform users how to add new schedule message since there are none now");
        noItemLabel.tag = NO_ITEM_TAG;
        [self.tableView addSubview:noItemLabel];
        [noItemLabel release];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    else if (totalItems > 0) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [noItemView removeFromSuperview];
    }
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

/*!
 @abstract reload data model and tableview
 */
- (void) reloadMessages {
    
    [self constructTableGroups];
    [self.tableView reloadData];
    
    [self showNoItemView];
}

/*!     
 Background color MUST be set right before cell is displayed
 */
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
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


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
	
	// delete favorites from array
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        CDMessage *deleteMessage = [self.scheduledMessages objectAtIndex:row];
        
        [AppUtility startActivityIndicator];
        [self.pendingDeleteD setValue:deleteMessage forKey:deleteMessage.mID];
        
        // request deletion from CM
        [[MPChatManager sharedMPChatManager] requestDeleteScheduleMessage:deleteMessage];

    }
}

#pragma mark - Delete Scheduled Messages


- (void) dismissModalViewControllerAnimated {
    [self dismissModalViewControllerAnimated:YES]; 
    [AppUtility stopActivityIndicator];
}

/*!
 @abstract delete schedule message was successful
 
 */
- (void) processConfirmations:(NSNotification *)notification {
    
    
    NSString *messageID = [notification object];
    
    CDMessage *deleteMessage = [self.pendingDeleteD valueForKey:messageID];
    
    // if delete message is found
    if (deleteMessage) {
        DDLogInfo(@"SC-pc: deleting message pending:%d", [self.pendingDeleteD count]);
        // clear store
        [self.pendingDeleteD removeObjectForKey:messageID];
        
        NSUInteger deleteIndex = [self.scheduledMessages indexOfObject:deleteMessage];
        
        if (deleteIndex != NSNotFound) {
            [self.scheduledMessages removeObjectAtIndex:deleteIndex];
            [[self.tableGroups objectAtIndex:0] removeObjectAtIndex:deleteIndex];
            
            // delete from view
            NSIndexPath *deleteIP = [NSIndexPath indexPathForRow:deleteIndex inSection:0];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:deleteIP] withRowAnimation:UITableViewRowAnimationFade];
            
            [AppUtility cdDeleteManagedObject:deleteMessage];
            
            [AppUtility cdSaveWithIDString:@"SC-pc: deleting a scheduled message" quitOnFail:NO];
            [[MPChatManager sharedMPChatManager] updateScheduleBadgeCount]; 
        }     
        
        [AppUtility stopActivityIndicator];
        
        // end edit if nothing more to delete!
        if ([self.scheduledMessages count] == 0) {
            [self endEdit:nil animated:YES];
            [self reloadMessages]; // show no item label
        }
    }
    // DS got new SM message - so dismiss composer view
    //
    else if ([messageID isEqualToString:self.pendingMessageID]) {
        DDLogInfo(@"SC-pc: sm created successfully");

        // erase immediately so timeout will not find this mID laying around
        // - leave for reject to check
        self.pendingMessageID = nil;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        // add short delay so that DB can sync and SchM can show properly
        //
        [self performSelector:@selector(dismissModalViewControllerAnimated) withObject:nil afterDelay:0.5];
    }
}

/*!
 @abstract process write socket failures
 
 Use:
 - can cancel pending image updates
 
 */
- (void) processReject:(NSNotification *)notification {
    
    NSString *messageID = [notification object];
    NSDictionary *userInfo = [notification userInfo];
    
    CDMessage *deleteMessage = [self.pendingDeleteD valueForKey:messageID];
    
    // if delete message is found
    // - clear it from pendingD
    //
    if (deleteMessage) {
        NSString *causeString = [userInfo valueForKey:kMPMessageKeyCause];
        
        /*
         902 response means that the requested delete message was not found.
         So it is safe to delete it from the client even though this is a reject response
         */
        if ([causeString intValue] == kMPCauseTypeScheduleMessageNotFound) {
            [self processConfirmations:notification];
        }
        else {
            DDLogInfo (@"SC-pwt: cancel scheduled message delete:%d", [self.pendingDeleteD count]);
            // clear store
            [self.pendingDeleteD removeObjectForKey:messageID];
            
            [AppUtility stopActivityIndicator];
            [AppUtility showAlert:kAUAlertTypeScheduledDeleteReject]; 
        }
    }
    // create new was rejected
    //
    else if ([messageID isEqualToString:self.pendingMessageID]) {
        DDLogInfo (@"SC-pr: create SM rejected");
        
        // delete message in background
        // - otherwise messages are not successfully delete using the main thread
        //
        [[MPChatManager sharedMPChatManager] deleteCDMessage:self.pendingMessageID];
        //[CDMessage deleteMessageWithID:self.pendingMessageID];
        
        self.pendingMessageID = nil;
        
        [AppUtility stopActivityIndicator];
        [AppUtility showAlert:kAUAlertTypeScheduledCreateReject];
    }
}

/*!
 @abstract process write socket failures
 
 Use:
 - can cancel pending image updates
 
 */
- (void) processMessageTimeout:(NSNotification *)notification {
    
    NSString *messageID = [notification object];
    
    CDMessage *deleteMessage = [self.pendingDeleteD valueForKey:messageID];
    
    // if delete message is found
    // - clear it from pendingD
    //
    if (deleteMessage) {
        DDLogVerbose(@"SC-pwt: cancel scheduled message delete:%d", [self.pendingDeleteD count]);
        // clear store
        [self.pendingDeleteD removeObjectForKey:messageID];
        
        [AppUtility stopActivityIndicator];
        [AppUtility showAlert:kAUAlertTypeNetwork];
    }
    // DS message send timed out, so cancel headshot upload
    //
    else if ([messageID isEqualToString:self.pendingMessageID]) {
        
        DDLogVerbose(@"CS: send schedule message timeout");
        
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
    if (!fullMessageID) {
        return;
    }
    
    CDMessage *deleteMessage = [self.pendingDeleteD valueForKey:fullMessageID];
    
    // if delete chat is found
    // - clear it from pendingD
    //
    if (deleteMessage) {
        DDLogVerbose(@"SC-pwt: net failure - cancel scheduled message delete:%d", [self.pendingDeleteD count]);
        // clear store
        [self.pendingDeleteD removeObjectForKey:fullMessageID];
        
        [AppUtility stopActivityIndicator];
        [AppUtility showAlert:kAUAlertTypeNetwork];
    }    
    // network failure - while sending out new SM
    //
    else if ([self.pendingMessageID hasSuffix:tagString]) {
        DDLogVerbose(@"SC-pwt: schedule message net failure");
        
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
- (void) setButtonsWithAnimation:(BOOL)animation {
    
    
    // edit button
    //
    if (!self.editButtonItem) {
        UIBarButtonItem *editButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Edit",  @"ChatList - Button: edit chat list entries") 
                                                          buttonType:kAUButtonTypeBarNormal 
                                                              target:self action:@selector(pressEdit:)];
        self.editButtonItem = editButton;
    }
    NSUInteger totalItems = [self.scheduledMessages count];
    if (totalItems > 0) {
        [self.navigationItem setLeftBarButtonItem:self.editButtonItem animated:animation];
    }
    else {
        [self.navigationItem setLeftBarButtonItem:nil animated:animation];
    }
    
    // Add Button
    UIButton *customButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 32.0, 32.0)];
    [customButton setBackgroundImage:[UIImage imageNamed:@"std_btn_add2_nor.png"] forState:UIControlStateNormal];
    [customButton setBackgroundImage:[UIImage imageNamed:@"std_btn_add2_prs.png"] forState:UIControlStateHighlighted];
    [customButton setEnabled:YES];
    
    customButton.backgroundColor = [UIColor clearColor];
    [customButton addTarget:self action:@selector(pressAdd:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem* barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    [customButton release];
    [self.navigationItem setRightBarButtonItem:barButtonItem animated:animation];
    [barButtonItem release];
    
}

// handle edit button press event
- (void)pressEdit:(id)sender {
	
	// allow editing
	[self.tableView setEditing:YES animated:YES];
    
	// set button "Done" to end delete mode
    UIBarButtonItem *doneButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Done",  @"Scheduled - Button: done with edit mode") 
                                                      buttonType:kAUButtonTypeBarHighlight 
                                                          target:self action:@selector(endEdit:)];
    [self.navigationItem setLeftBarButtonItem:doneButton animated:YES];
    
    /*UIBarButtonItem *deleteAllButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Delete All", @"Scheduled - Button: delete all chats")
                                                           buttonType:kAUButtonTypeBarNormal 
                                                               target:self action:@selector(pressDeleteAll:)];
    [self.navigationItem setRightBarButtonItem:deleteAllButton animated:YES];*/
    
}

/*!
 @abstract adds or create a new chat
 */
- (void) pressAdd:(id)sender {
    
    
    UIActionSheet *aSheet;
	
	aSheet	= [[UIActionSheet alloc]
               initWithTitle:nil // NSLocalizedString(@"Are you sure you want to delete all chat histories?", @"Chat List - Alert: message to confirm if all chats should be deleted")
               delegate:self
               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel delete all chats")
               destructiveButtonTitle:nil // NSLocalizedString(@"Delete All", @"Alert: Delete button")
               otherButtonTitles:NSLocalizedString(@"Text", @"Schedule: text message"), 
               NSLocalizedString(@"<create sticker message>", @"Schedule: sticker message"),
               NSLocalizedString(@"Album", @"Schedule: image message"),
               NSLocalizedString(@"Camera", @"Schedule: image message"),
               NSLocalizedString(@"<create letter message>", @"Schedule: image message"),
               nil];
	
	aSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];
    
    
    /*
    SelectContactController *nextController = [[SelectContactController alloc] initWithTableStyle:UITableViewStylePlain type:kMPSelectContactTypeCreateChat object:sender];
    
    
    // Create nav controller to present modally
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:nextController];
    nextController.delegate = self;
    
    [AppUtility customizeNavigationController:navigationController];
    
    
    [self presentModalViewController:navigationController animated:YES];
    [navigationController release];
    [nextController release];
     */
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
	
	[aSheet showInView:[self.view.window.subviews objectAtIndex:0]];
	[aSheet release];
    
    
    
    /*NSString *detailedMessage = NSLocalizedString(@"Are you sure you want to delete all chat histories?", @"Chat List - Alert: message to confirm if all chats should be deleted");
     UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:nil
     message:detailedMessage
     delegate:nil
     cancelButtonTitle:NSLocalizedString(@"Cancel", @"Alert: Cancel button") 
     otherButtonTitles:NSLocalizedString(@"OK", @"Alert: OK button"), nil] autorelease];
     alert.delegate = self;
     [alert show];*/
    
    
}


/*!
 @abstract handle end of edit
 */
- (void)endEdit:(id)sender animated:(BOOL)newAnimated {
	
	// now it is ok to set editing
	//
	[self.tableView setEditing:NO animated:newAnimated];
	[self setButtonsWithAnimation:newAnimated];
    
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
    
    if (buttonIndex != [actionSheet cancelButtonIndex]) {
        
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
            [self presentModalViewController:imageController animated:YES];
            [imageController release];
            
        }
        else if (editMode == kCCEditModeImage) {
            
            // startup iOS album
            //
            UIImagePickerController *imageController = [[UIImagePickerController alloc] init];
            //imageController.allowsEditing = YES;
            imageController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imageController.delegate = self;
            [self presentModalViewController:imageController animated:YES];
            [imageController release];
            
            
            // single image picker
            //
            /*
             ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] initWithNibName:@"ELCAlbumPickerController" bundle:[NSBundle mainBundle]]; 
            albumController.onlySingleSelection = YES;
            
            ELCImagePickerController *imagePicker = [[ELCImagePickerController alloc] initWithRootViewController:albumController];
            [albumController setParent:imagePicker];
            [imagePicker setDelegate:self];
                        
            [AppUtility customizeNavigationController:imagePicker];

            [self presentModalViewController:imagePicker animated:YES];
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
            
            
            // Create nav controller to present modally
            UINavigationController *navigationController = [[UINavigationController alloc]
                                                            initWithRootViewController:nextController];            
            [AppUtility customizeNavigationController:navigationController];
            
            [self presentModalViewController:navigationController animated:YES];
            [navigationController release];
            [nextController release];
        }
        else if (editMode != kCCEditModeBasic) {
            
            ComposerController *nextController = [[ComposerController alloc] init];
            nextController.editMode = editMode;
            nextController.toContacts = [NSArray array];
            nextController.characterLimitMin = kMPParamChatMessageLengthMin;
            nextController.characterLimitMax = kMPParamChatMessageLengthMax;
            
            nextController.defaultTimeSinceNow = kMPParamScheduleDefaultTimeSinceNow;
            nextController.minimumTimeSinceNow = kMPParamScheduleMinimumTimeSinceNow;
            nextController.uiMinimumTimeSinceNow = kMPParamScheduleUIMinimumTimeSinceNow;
            
            nextController.delegate = self;
            
            nextController.title = NSLocalizedString(@"New Schedule", @"Schedule - title: view to edit status message");
            
            UINavigationController *navigationController = [[UINavigationController alloc]
                                                            initWithRootViewController:nextController];
            [AppUtility customizeNavigationController:navigationController];
            
            [self presentModalViewController:navigationController animated:YES];
            [navigationController release];
            [nextController release];
            
            
        }
        
    }
    else {
        DDLogVerbose(@"Create scheduled cancelled");
    }
    
    
    /*
    if (buttonIndex != [actionSheet cancelButtonIndex]) {
        
		NSString *actionButtonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
		if ([actionButtonTitle isEqualToString:NSLocalizedString(@"Delete All", nil)]) {
            
            
            // delete from data model
            NSMutableIndexSet *deleteIndexes = [[NSMutableIndexSet alloc] init];
            // delete from tableview
            NSMutableArray *deleteIPs = [[NSMutableArray alloc] init];
            
            for (CDChat *iChat in self.chats){
                NSString *messageID = [[MPChatManager sharedMPChatManager] requestDeleteChat:iChat];
                if ([messageID length] > 0) {
                    [self.pendingDeleteD setValue:iChat forKey:messageID];
                }
                else {
                    NSUInteger deleteIndex = [self.chats indexOfObject:iChat];
                    if (deleteIndex != NSNotFound) {
                        [deleteIndexes addIndex:deleteIndex];
                        [deleteIPs addObject:[NSIndexPath indexPathForRow:deleteIndex inSection:0]];
                    }
                }
            }
            if ([deleteIndexes count] > 0) {
                [self.chats removeObjectsAtIndexes:deleteIndexes];
                [[self.tableGroups objectAtIndex:0] removeObjectsAtIndexes:deleteIndexes];
            }
            [deleteIndexes release];
            if ([deleteIPs count] > 0) {
                [self.tableView deleteRowsAtIndexPaths:deleteIPs withRowAnimation:UITableViewRowAnimationFade];
            }
            [deleteIPs release];
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
    else {
        DDLogVerbose(@"Delete account cancelled");
    }*/
}

#pragma mark - ScheduleCellController

/*!
 @abstract Inform delegate that scheduled message was tapped
 
 */
- (void)ScheduleCellController:(ScheduleCellController *)controller tappedMessage:(CDMessage *)message {
    
    NSUInteger viewCount = [self.navigationController.viewControllers count];
    
    // only push on top of root
    // - if there is another chat, don't push another
    // - this can happen if users tap very quickly on the tableview - more of a iOS bug
    //
    if (viewCount == 1) {
        ScheduleInfoController *nextController = [[ScheduleInfoController alloc] initWithScheduledMessage:message];
        [self.navigationController pushViewController:nextController animated:YES];
        [nextController release];
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
    
    [self dismissModalViewControllerAnimated:YES];
    
    CDChat *chat = [CDChat chatWithCDContacts:contacts groupID:nil shouldSave:YES];
    
    ChatDialogController *newController = [[ChatDialogController alloc] initWithCDChat:chat];
    
    [self.navigationController pushViewController:newController animated:YES];
    [newController release];
}


#pragma mark - NavigationController 

/*!
 @abstract forwards nav controller so app delelgate can customize it
 */
- (void)navigationController:(UINavigationController *)navigationController 
      willShowViewController:(UIViewController *)viewController 
					animated:(BOOL)animated {
	/*
    [[AppUtility getAppDelegate] navigationController:navigationController willShowViewController:viewController animated:animated];
	*/
}




#pragma mark - TKImagePicker Delegates

/*!
 @abstract Finished selecting images to send out
 
 */
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
	
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
            
            nextController.editMode = kCCEditModeImage;
            nextController.toContacts = [NSArray array];
            
            nextController.defaultTimeSinceNow = kMPParamScheduleDefaultTimeSinceNow;
            nextController.minimumTimeSinceNow = kMPParamScheduleMinimumTimeSinceNow;
            nextController.uiMinimumTimeSinceNow = kMPParamScheduleUIMinimumTimeSinceNow;
            
            nextController.delegate = self;
            
            nextController.title = NSLocalizedString(@"New Schedule", @"Schedule - title: view to edit status message");
            [nextController setImage:imageToSave];
            [picker pushViewController:nextController animated:YES];
            [nextController release];
            
        }
        
        
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
    picker.delegate = nil;
    [self dismissModalViewControllerAnimated:YES];    
}


// For responding to the user accepting a newly-captured picture or movie
- (void) imagePickerController: (UIImagePickerController *) picker
 didFinishPickingMediaWithInfo: (NSDictionary *) info {
    
    // get info now since picker will be deallocated after being dismissed
    BOOL isCamera = (picker.sourceType == UIImagePickerControllerSourceTypeCamera)?YES:NO;
    
    // don't animate transition so a new modal view can appear right away
    [self dismissModalViewControllerAnimated:NO];

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
        if (isCamera) {
            // save image to album automatically
            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);
        }

        
        // present create view
        //
        ComposerController *nextController = [[ComposerController alloc] init];
        nextController.editMode = kCCEditModeImage;
        nextController.toContacts = [NSArray array];
        
        nextController.defaultTimeSinceNow = kMPParamScheduleDefaultTimeSinceNow;
        nextController.minimumTimeSinceNow = kMPParamScheduleMinimumTimeSinceNow;
        nextController.uiMinimumTimeSinceNow = kMPParamScheduleUIMinimumTimeSinceNow;
        
        nextController.delegate = self;

        nextController.title = NSLocalizedString(@"New Schedule", @"Schedule - title: view to edit status message");
        [nextController setImage:imageToSave];
        
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:nextController];
        [AppUtility customizeNavigationController:navigationController];
        
        [self presentModalViewController:navigationController animated:YES];
        [navigationController release];
        [nextController release];
    }
    
}


#pragma mark - LetterController

/*!
 @abstract Call when letter creation is complete and ready to send
 - create letter message and send out
 */
- (void)LetterController:(LetterController *)letterController letterImage:(UIImage *)letterImage letterID:(NSString *)letterID {
    
    // present create view
    //
    ComposerController *nextController = [[ComposerController alloc] init];
    nextController.editMode = kCCEditModeLetter;
    nextController.toContacts = [NSArray array];
    
    nextController.defaultTimeSinceNow = kMPParamScheduleDefaultTimeSinceNow;
    nextController.minimumTimeSinceNow = kMPParamScheduleMinimumTimeSinceNow;
    nextController.uiMinimumTimeSinceNow = kMPParamScheduleUIMinimumTimeSinceNow;
        
    nextController.title = NSLocalizedString(@"New Schedule", @"Schedule - title: view to edit status message");
    nextController.delegate = self;
    
    [nextController setLetterImage:letterImage letterID:letterID];
    
    // if wizard stack already exist, keep pushing on to it
    //
    if (letterController.navigationController) {
        letterController.navigationController.toolbarHidden = YES;
        [letterController.navigationController pushViewController:nextController animated:YES];
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
 @abstract User pressed saved with new message information
 
 - Submit scheduled message to DS and wait for DS confirmation
 
 */
- (void)ComposerController:(ComposerController *)composerController text:(NSString *)text contacts:(NSArray *)contacts image:(UIImage *)image date:(NSDate *)date letterImage:(UIImage *)letterImage letterID:(NSString *)letterID locationImage:(UIImage *)locationImage locationText:(NSString *)locationText {
    
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
            
        default:
            break;
    }
    
    // convert CDMessageType
    
    CDMessage *newCDMessage = [CDMessage outCDMessageForChat:nil 
                                                 messageType:msgType 
                                                        text:msgText 
                                              attachmentData:msgImage 
                                                 isMulticast:YES 
                                          multicastParentMID:nil 
                                         multicastToContacts:[NSSet setWithArray:contacts] 
                                               dateScheduled:date 
                                                 hideMessage:YES 
                                                    typeInfo:letterID                                            
                                                  shouldSave:YES];
    self.pendingMessageID = newCDMessage.mID;
    
    // DS accepted our request to crate
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processConfirmations:) name:MP_MESSAGECENTER_ACCEPT_CONFIRMATION_NOTIFICATION object:nil];
    
    // DS rejected our request to create - usually b/c time is in past or not within 60 days
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processReject:) name:MP_MESSAGECENTER_REJECT_CONFIRMATION_NOTIFICATION object:nil];
    
    // ** use accept notification instead now
    // listen for message confirmations
    // - know if DS accepted our message 
    // - get this from chat manager instead of MC
    // - since message state is saved already and list view will show new SM
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processConfirmations:) name:MP_CHATMANAGER_UPDATE_SCHEDULE_NOTIFICATION object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processConfirmations:) name:MP_MESSAGECENTER_SENT_CONFIRMATION_NOTIFICATION object:nil];
    
    // listen for socket write failures
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processWriteTimeouts:) name:MP_SOCKETCENTER_WRITE_TIMEOUT_NOTIFICATION object:nil];
    
    // if message timeout
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processMessageTimeout:) name:MP_MESSAGECENTER_SENT_TIMEOUT_NOTIFICATION object:nil];
    
    // sends this message
    //
    [AppUtility startActivityIndicator];
    
    /*
     SM messages gets:
      - Sent response after it it sent to the DS
      - Reject response if the date is not acceptable
      - But no Accept response.. this means we never know if it is really accepted or not
      - disable accept/reject confirmation for now
     */
    [[MPChatManager sharedMPChatManager] sendCDMessage:newCDMessage requireSentConfirmation:YES enableAcceptRejectConfirmation:YES];
    
}



@end


