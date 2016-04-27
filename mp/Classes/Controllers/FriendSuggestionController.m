//
//  FriendSuggestionController.m
//  mp
//
//  Created by Min Tsai on 2/19/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "FriendSuggestionController.h"
#import "MPFoundation.h"
#import "CDContact.h"
#import "MPContactManager.h"

@interface FriendSuggestionController (Private)
- (void) reloadTable;
@end

@implementation FriendSuggestionController

@synthesize suggestedContacts;
@synthesize lastTappedIndexPath;
@synthesize selectedContactID;
@synthesize deleteRowTimer;
@synthesize isReloadPending;

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // clear cell controller delegates
    //
    if ([self.tableGroups count] > 0) {
        NSArray *cellControllers = [self.tableGroups objectAtIndex:0];
        for (SuggestCellController *iController in cellControllers) {
            iController.delegate = nil;
        }
    }
    
    [lastTappedIndexPath release];
    [suggestedContacts release];
    [selectedContactID release];
    [deleteRowTimer release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
        // only need to refresh if view is visible
        //
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadTable) name:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:nil];
        
        // data model changed, so reindex
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadTable) name:MP_CONTACTMANAGER_INDEX_NOTIFICATION object:nil];
        
    }
    return self;
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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.title = NSLocalizedString(@"Friend Suggestions", @"FriendSuggest - title: listing of friend suggestions users");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    
    self.tableView.rowHeight = kMPParamTableRowHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [AppUtility colorForContext:kAUColorTypeTableSeparator];
    self.tableView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    
    self.isReloadPending = NO;
    
}

- (void)viewDidUnload
{
        
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"FSC-vwa");
    [super viewWillAppear:animated];
    [self reloadTable];
}

- (void) testMethod {
    // get newest info this may also delete contacts
    [MPContactManager startFriendInfoQueryInBackGroundForceStart:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // indicate user viewed friend suggestion - for new friend identification
    //
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingDidViewFriendSuggestionInThisSession settingValue:[NSNumber numberWithBool:YES]];
    
    // @TEST - if press row and table refreshed, options should remain - below is too fast to test with
    //[self performSelector:@selector(testMethod) withObject:nil afterDelay:2.0];
    
    // get newest info this may also delete contacts
    [MPContactManager startFriendInfoQueryInBackGroundForceStart:YES];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // indicate user viewed friend suggestion - for new friend identification
    //
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingDidViewFriendSuggestionInThisSession settingValue:[NSNumber numberWithBool:YES]];
    
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Generic Table Methods

#define NO_ITEM_TAG 150001

- (void) showNoItemView {
    // Show no item label
    //
    UIView *noItemView = [self.tableView viewWithTag:NO_ITEM_TAG];
    
    NSUInteger totalItems = [self.suggestedContacts count];
    if (totalItems == 0 && noItemView == nil) {        
        CGSize headerSize = self.tableView.tableHeaderView.frame.size;
        UILabel *noItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, headerSize.height, self.tableView.frame.size.width-40.0, self.tableView.frame.size.height-headerSize.height)];
        [AppUtility configLabel:noItemLabel context:kAULabelTypeNoItem];
        noItemLabel.text = NSLocalizedString(@"No Friend Suggestions", @"FriendSuggest - text: Inform users that there are no friend suggestions right now");
        noItemLabel.tag = NO_ITEM_TAG;
        [self.tableView addSubview:noItemLabel];
        [noItemLabel release];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    else if (totalItems > 0) {
        [noItemView removeFromSuperview];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
}

/*!
 @abstract contruct data model for table
 */
- (void)constructTableGroups
{
    
    // clear cell controller delegates
    // - otherwise delegate methods may still be called
    // - if table refresh, then this VC deallocated, then these controller.delegate never get niled out.
    // - otherwise crash is possible
    //
    if ([self.tableGroups count] > 0) {
        NSArray *cellControllers = [self.tableGroups objectAtIndex:0];
        for (SuggestCellController *iController in cellControllers) {
            iController.delegate = nil;
        }
    }
    
    
	NSMutableArray *cells = [[NSMutableArray alloc] init];
    
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    NSArray *dbContacts = [CDContact suggestedContacts];
    
    // make sure each person has a valid ID first
    // - in case we have some user with invalid id in DB
    for (CDContact *iContact in dbContacts) {
        if ([AppUtility isUserIDValid:iContact.userID]) {
            [contacts addObject:iContact];
        }
        else {
            DDLogWarn(@"FS-ctg: found invalid contact %@", iContact);
        }
    }
    
    self.suggestedContacts = contacts;
    [contacts release];
    
    for (CDContact *iContact in self.suggestedContacts){
        
        SuggestCellController *iCell = [[SuggestCellController alloc] initWithObject:iContact];
        iCell.delegate = self;
        [cells addObject:iCell];
        [iCell release];
    }
	
	self.tableGroups = [NSArray arrayWithObjects:cells, nil];
	[cells release];
    
    [self showNoItemView];

}

/*!
 @abstract show option button for selected contact
 */
- (void) showOptionsForSelectedContact {
    
    // find indexpath
    //
    BOOL didFind = NO;
    int row = 0;
    
    if (self.selectedContactID) {
        for (CDContact *iContact in self.suggestedContacts) {
            if ([self.selectedContactID isEqualToString:iContact.userID]) {
                didFind = YES;
                break;
            }
            row++;
        }
    }
    
    // show options
    //
    if (didFind) {
        NSIndexPath *selectedIP = [NSIndexPath indexPathForRow:row inSection:0];
        if ([self.tableGroups count] > 0) {
            SuggestCellController *cellController = [[self.tableGroups objectAtIndex:0] objectAtIndex:row];
            [cellController tableView:self.tableView showOptionsAtIndexPath:selectedIP animated:NO];
        }
    }
}




/*!
 @abstract Rebuilds datamodel and refresh tableview
 */
- (void) reloadTable {
    
    // don't reload if 
    // - we are about to delete a row
    // - we are waiting for a HC reply
    //
    if (![self.deleteRowTimer isValid] || [AppUtility isActivityIndicatorRunning]) {
        
        // stop indicator in case it is running
        [AppUtility stopActivityIndicator];

        //[self.contactManager refreshContacts];
        [self constructTableGroups];
        [self.tableView reloadData];
        
        [self showOptionsForSelectedContact];
    }
    // delay reload until we are done making changes
    else {
        self.isReloadPending = YES;
    }
}



#pragma mark - Table Methods


/*!
 @abstract Remove contact from table
 */
- (void) removeContactFromTable:(NSTimer *)timer {
    
    CDContact *removeContact = timer.userInfo;
    
    // remove from data models
    //
    NSMutableArray *controllers = [self.tableGroups objectAtIndex:0];
    SuggestCellController *removeController = nil;
    int i = 0;
    for (SuggestCellController *iController in controllers){
        if (iController.contact == removeContact) {
            removeController = iController;
            break;
        }
        i++;
    }
    if (removeController) {
        [controllers removeObject:removeController];
        [self.suggestedContacts removeObject:removeContact];
        
        NSIndexPath *removeIP = [NSIndexPath indexPathForRow:i inSection:0];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:removeIP] withRowAnimation:UITableViewRowAnimationFade];
        
        [self showNoItemView];
        
        // update last index if rows dissappear
        //
        if (self.lastTappedIndexPath) {
            NSUInteger lastRow = [self.lastTappedIndexPath row];
            if (lastRow > i) {
                lastRow--;
                self.lastTappedIndexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
            }
        }
        
    }
    // something went wrong
    else {
        DDLogVerbose(@"FS: remove contact - NO controller found %@", controllers);
    }
    
    // execute reload if pending
    if (self.isReloadPending) {
        self.isReloadPending = NO;
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(reloadTable) userInfo:nil repeats:NO];
    }
}



#pragma mark - SuggestCellController


/*!
 @abstract Called when contact cell needs to be refreshed.
 
 We need to tell the table to refresh the cell if something changed like the headshot.
 The table will then:
 - figure out if this controller is visible
 - if visible then refresh it
 
 */
- (void)SuggestCellController:(SuggestCellController *)controller refreshContact:(CDContact *)contact {
        
    NSInteger index = [self.suggestedContacts indexOfObject:contact];
    
    if (index != NSNotFound) {
        NSIndexPath *contactIP = [NSIndexPath indexPathForRow:index inSection:0];
        
        // if IP visible then refresh it
        if ([Utility isIndexPath:contactIP inIndexPaths:[self.tableView indexPathsForVisibleRows]]) {
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:contactIP] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    
}



/*!
 @abstract Called when cell is refreshed
 */
- (void)SuggestCellController:(SuggestCellController *)controller refreshedContact:(CDContact *)contact {
    
    // clear selected since it was off screen back and should not be considered selected any more
    //
    if ([self.selectedContactID isEqualToString:contact.userID]) {
        self.selectedContactID = nil;
    }
}

/*!
 @abstract Called when cell was tapped
 - table hide the options of the last selected cell if it is visible
 - save this indexpath
 
 */
- (void)SuggestCellController:(SuggestCellController *)controller didTapIndexPath:(NSIndexPath *)indexPath {
    
    // if selected, deselect
    if ([self.selectedContactID isEqualToString:controller.contact.userID]) {
        self.selectedContactID = nil;
    }
    else {
        self.selectedContactID = controller.contact.userID;
    }
    
    
    // hide all other row's buttons
    for (NSIndexPath *iIP in [self.tableView indexPathsForVisibleRows]) {
        if (![iIP isEqual:indexPath]) {
            SuggestCellController *cellC = [self cellControllerForIndexPath:iIP];
            [cellC tableView:self.tableView hideOptionsAtIndexPath:iIP showResult:NO];
        }
    }
    /*
    if (self.lastTappedIndexPath) {
        // if IP visible then refresh it
        if ([Utility isIndexPath:self.lastTappedIndexPath inIndexPaths:[self.tableView indexPathsForVisibleRows]]) {
            SuggestCellController *cellC = [self cellControllerForIndexPath:self.lastTappedIndexPath];
            [cellC tableView:self.tableView hideOptionsAtIndexPath:self.lastTappedIndexPath showResult:NO];
        }
    }*/
    self.lastTappedIndexPath = indexPath;
}


/*!
 @abstract Called if contact is blocked or added
 
 */
- (void)SuggestCellController:(SuggestCellController *)controller didChangeStateForContact:(CDContact *)contact {
    
    if (self.lastTappedIndexPath) {
        
        NSInteger index = [self.suggestedContacts indexOfObject:contact];
        if (index != NSNotFound) {
            NSIndexPath *contactIP = [NSIndexPath indexPathForRow:index inSection:0];
            
            // if IP visible then refresh it
            if ([Utility isIndexPath:contactIP inIndexPaths:[self.tableView indexPathsForVisibleRows]]) {
                [controller tableView:self.tableView hideOptionsAtIndexPath:contactIP showResult:YES];
            }
        }
        else {
            DDLogVerbose(@"FS: contact not found!");
        }
        
        // if IP visible then refresh it
        /*if ([Utility isIndexPath:self.lastTappedIndexPath inIndexPaths:[self.tableView indexPathsForVisibleRows]]) {
            SuggestCellController *cellC = [self cellControllerForIndexPath:self.lastTappedIndexPath];
            [cellC tableView:self.tableView hideOptionsAtIndexPath:self.lastTappedIndexPath showResult:YES];
        }
        else {
            DDLogVerbose(@"FS: last tapped on visible");
        }*/
    }
    self.lastTappedIndexPath = nil; 
    
    // remove row after 2 secs
    self.deleteRowTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(removeContactFromTable:) userInfo:contact repeats:NO];
    //[self performSelector:@selector(removeContactFromTable:) withObject:contact afterDelay:2.0];
}


/*!
 @abstract Notify tableview that a contact should be blocked
 */
- (void)SuggestCellController:(SuggestCellController *)controller blockContact:(CDContact *)contact {
    
}

/*!
 @abstract Notify tableview that a contact should be added as a friend
 */
- (void)SuggestCellController:(SuggestCellController *)controller addContact:(CDContact *)contact {
    
}






@end

