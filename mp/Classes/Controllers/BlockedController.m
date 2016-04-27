//
//  BlockedController.m
//  mp
//
//  Created by M Tsai on 11-12-5.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "BlockedController.h"
#import "MPFoundation.h"
#import "CDContact.h"


@interface BlockedController (Private)
- (void) reloadTable;
@end


@implementation BlockedController

@synthesize blockedContacts;
@synthesize unblockCandidate;


- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [blockedContacts release];
    [unblockCandidate release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
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
    
    self.title = NSLocalizedString(@"Blocked Users", @"BlockedUsers - title: listing of blocked users");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    
    self.tableView.rowHeight = kMPParamTableRowHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [AppUtility colorForContext:kAUColorTypeTableSeparator];
    self.tableView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    
    // observe block events
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleUnBlock:) name:MP_HTTPCENTER_UNBLOCK_NOTIFICATION object:nil];
    
}

- (void)viewDidUnload
{
        
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"BC-vwa");
    [super viewWillAppear:animated];
    
    [self reloadTable];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
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


#pragma mark - Generic Table Methods

/*!
 @abstract contruct data model for table
 */
- (void)constructTableGroups
{
	NSMutableArray *cells = [[NSMutableArray alloc] init];
    
    
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    NSArray *dbContacts = [CDContact blockedContacts];
    if ([dbContacts count] > 0) {
        [contacts addObjectsFromArray:dbContacts];
    }
    self.blockedContacts = contacts;
    [contacts release];
    
    for (CDContact *iContact in self.blockedContacts){
        
        BlockedCellController *iCell = [[BlockedCellController alloc] initWithObject:iContact];
        iCell.delegate = self;
        [cells addObject:iCell];
    }
	
	self.tableGroups = [NSArray arrayWithObjects:cells, nil];
	[cells release];

    
}

#define NO_ITEM_TAG 150001

- (void) showNoItemView {
    // Show no item label
    //
    UIView *noItemView = [self.tableView viewWithTag:NO_ITEM_TAG];
    
    NSUInteger totalItems = [self.blockedContacts count];
    if (totalItems == 0 && noItemView == nil) {        
        CGSize headerSize = self.tableView.tableHeaderView.frame.size;
        UILabel *noItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, headerSize.height, self.tableView.frame.size.width-40.0, self.tableView.frame.size.height-headerSize.height)];
        [AppUtility configLabel:noItemLabel context:kAULabelTypeNoItem];
        noItemLabel.text = NSLocalizedString(@"No Blocked Contacts", @"Blocked - text: Inform users that there are no blocked contacts");
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
 @abstract Rebuilds datamodel and refresh tableview
 */
- (void) reloadTable {
    
    //[self.contactManager refreshContacts];
    [self constructTableGroups];
    [self.tableView reloadData];
    
    [self showNoItemView];
}






#pragma mark - BlockedCellControllerDelegate

/*!
 @abstract cell has press unblocked
 */
- (void)blockedCellController:(BlockedCellController *)blockedCellController unblockContact:(CDContact *)contact {
    
    [[MPHTTPCenter sharedMPHTTPCenter] unBlockUser:contact.userID];
    self.unblockCandidate = contact;
    
}


#pragma mark - Handle Response

/*!
 @abstract process block response
 
 Successful case
 <UnBlock>
 <cause>0</cause>
 </UnBlock>
 
 Exception case
 <UnBlock>
 <cause>602</cause>
 <text>invalid USERID!</text>
 </UnBlock>
 
 */
- (void) handleUnBlock:(NSNotification *)notification {
    //[AppUtility stopActivityIndicator:self.navigationController];
    
    // do nothing if no candiate available
    if (!self.unblockCandidate) {
        return;
    }
    
    NSDictionary *responseD = [notification object];
    
    
    // go ahead and block user
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        NSManagedObjectID *blockUserObjectID = [self.unblockCandidate objectID];
        
        // unblock user
        //
        dispatch_async([AppUtility getBackgroundMOCQueue], ^{
            
            CDContact *blockContact = (CDContact *)[[AppUtility cdGetManagedObjectContext] objectWithID:blockUserObjectID];
            
            [blockContact unBlockUser];
            [AppUtility cdSaveWithIDString:@"unblock user" quitOnFail:NO];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // remove from data models
                //
                NSMutableArray *controllers = [self.tableGroups objectAtIndex:0];
                BlockedCellController *removeController = nil;
                int i = 0;
                for (BlockedCellController *iController in controllers){
                    if (iController.contact == self.unblockCandidate) {
                        removeController = iController;
                        break;
                    }
                    i++;
                }
                if (removeController) {
                    [controllers removeObject:removeController];
                    [self.blockedContacts removeObject:self.unblockCandidate];
                    
                    NSIndexPath *removeIP = [NSIndexPath indexPathForRow:i inSection:0];
                    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:removeIP] withRowAnimation:UITableViewRowAnimationFade];
                }
                
                [self showNoItemView];
                
            });
        });
        
    }
    // ask to confirm
    else {
        
        NSString *alertTitle = NSLocalizedString(@"Unblock Friend", @"BlockedUser - alert title:");
        NSString *alertMessage = NSLocalizedString(@"Unblock failed. Try again later.", @"BlockUser - alert: Inform of failure");
        
        [Utility showAlertViewWithTitle:alertTitle message:alertMessage];
    }
}

/*!
 @abstract Notify tableview to refresh row - usually headshot was updated
 */
- (void)blockedCellController:(BlockedCellController *)blockedCellController refreshContact:(CDContact *)contact {
    
    NSInteger index = [self.blockedContacts indexOfObject:contact];
    
    if (index != NSNotFound) {
        NSIndexPath *contactIP = [NSIndexPath indexPathForRow:index inSection:0];
        
        // if IP visible then refresh it
        if ([Utility isIndexPath:contactIP inIndexPaths:[self.tableView indexPathsForVisibleRows]]) {
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:contactIP] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

@end
