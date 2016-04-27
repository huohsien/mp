//
//  SelectContactController.m
//  mp
//
//  Created by M Tsai on 11-12-10.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "SelectContactController.h"

#import "MPContactManager.h"
#import "CDContact.h"
#import "CDChat.h"
#import "ContactCellController.h"
#import "AppUtility.h"
#import "MPFoundation.h"



@interface SelectContactController (PrivateMethods)
- (void)setSearch;
- (void)unloadSearch;
@end


@implementation SelectContactController

@synthesize delegate;
@synthesize contactManager;
@synthesize selectedUserIDs;
@synthesize contactCellControllerD;
@synthesize searchBar;
@synthesize searchController;

@synthesize viewType;
@synthesize viewContacts;

@synthesize chatButtonItem;
@synthesize broadcastButtonItem;

/*!
 @abstract initialize select view
 
 @param type view type that we should show - how should we modify view for selection
 @param object used to help configure the view
        - e.g. InviteGroup - provide a NSSet of current group members (will show at the top of list)
 
 */
- (id)initWithTableStyle:(UITableViewStyle)style type:(MPSelectContactType)type viewContacts:(NSSet *)contacts
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
        self.viewType = type;
        self.viewContacts = contacts;
        
        NSMutableSet *newSet =[[NSMutableSet alloc] init];
        self.selectedUserIDs = newSet;
        [newSet release];
        
        // remember which users are already selected
        if (self.viewType == kMPSelectContactTypeBasic && [self.viewContacts count] > 0) {
            for (CDContact *iContact in self.viewContacts) {
                [self.selectedUserIDs addObject:iContact.userID];
            }
        }
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // clear search delegates
    [self unloadSearch];
    
    self.delegate = nil;
    
    [viewContacts release];
    
    [contactManager release];
    [selectedUserIDs release];
    [contactCellControllerD release];
    
    [searchBar release];
    [searchController release];
    
    [chatButtonItem release];
    [broadcastButtonItem release];
    
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
    
    // apply standard table configurations
    [AppUtility configTableView:self.tableView];
    
    
    if (self.viewType == kMPSelectContactTypeReadOnly) {
        self.title = NSLocalizedString(@"Selected Friends", @"SelectFriends - Title: show selected friends");
    }
    else {
        self.title = NSLocalizedString(@"Select Friends", @"SelectFriends - Title: allow user to select friends");
    }
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // basic - gets pushed, so don't allow users to go back
    if (self.viewType == kMPSelectContactTypeBasic) {
        self.navigationItem.hidesBackButton = YES;    
    }
    
    if (!self.contactManager) {
        MPContactManager *newCM = [[MPContactManager alloc] init];
        self.contactManager = newCM;
        [newCM release];
        
        if ([self.viewContacts count] > 0) {
            // for invite group add members to the top
            if (self.viewType == kMPSelectContactTypeInviteGroup) {
                [self.contactManager setGroupMembers:self.viewContacts sectionTitle:NSLocalizedString(@"Current Members", @"Section title for group members") indexTitle:NSLocalizedString(@"Mem", @"Index Title: keep this short - represents members that are already part of a chat group")];
            }
            else if (self.viewType == kMPSelectContactTypeBasic) {
                [self.contactManager setGroupMembers:self.viewContacts sectionTitle:NSLocalizedString(@"Selected Members", @"Section title for group members") indexTitle:NSLocalizedString(@"Sel", @"Index Title: keep this short - represents members that are already part of a chat group")];
            }
            else if (self.viewType == kMPSelectContactTypeReadOnly) {
                [self.contactManager setGroupMembers:self.viewContacts sectionTitle:@"" indexTitle:@""];
            }
        }
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadData:) name:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:nil];
        
        // after indexing is finished - so use new datamodel
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadTable:) name:MP_CONTACTMANAGER_RELOAD_TABLE_NOTIFICATION object:nil];
        
        // data model changed, so reindex
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(indexContacts:) name:MP_CONTACTMANAGER_INDEX_NOTIFICATION object:nil];
    }
    
    if (!self.contactCellControllerD) {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.contactCellControllerD = newD;
        [newD release];
    }
    
    // setup search if not already
	[self setSearch];
    
    
    // Cancel nav button
    //
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel",  @"SelectFriends - Button: cancel select friends") 
                                                      buttonType:kAUButtonTypeBarNormal 
                                                          target:self action:@selector(pressCancel:)];
    
    

    // show toolbar only for create chat
    if (self.viewType == kMPSelectContactTypeCreateChat) {
        
        // single button - put on right
        [self.navigationItem setRightBarButtonItem:cancelButton animated:NO];

        
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        // Add Toolbar buttons
        UIBarButtonItem *broadcastButton = [[ UIBarButtonItem alloc ] initWithTitle: @""
                                                                              style: UIBarButtonItemStyleBordered
                                                                             target: self
                                                                             action: @selector( pressBroadcast: ) ];
        broadcastButton.width = 140.0;
        broadcastButton.enabled = NO;
        self.broadcastButtonItem = broadcastButton;
    
        
        UIBarButtonItem *chatButton = [[ UIBarButtonItem alloc ] initWithTitle: @""
                                                                         style: UIBarButtonItemStyleBordered
                                                                        target: self
                                                                        action: @selector( pressChat: ) ];
        chatButton.width = 140.0;
        chatButton.enabled = NO;
        self.chatButtonItem = chatButton;
        
        
        NSString *broadcastTitle = NSLocalizedString(@"Broadcast", @"SelectFriends - Button: send broadcast message with selected contacts");
        
        NSString *chatTitle = NSLocalizedString(@"Chat", @"SelectFriends - Button: start chat with selected contacts");
        
        [self.broadcastButtonItem setTitle:broadcastTitle];
        [self.chatButtonItem setTitle:chatTitle];
        
        
        
        self.toolbarItems = [ NSArray arrayWithObjects: flexibleSpace, chatButton, broadcastButton, flexibleSpace, nil ];
        [flexibleSpace release];
        [chatButton release];
        [broadcastButton release];
        
        // show toolbar
        self.navigationController.toolbarHidden = NO;
        self.navigationController.toolbar.barStyle = UIBarStyleBlack;
        
        
    }
    // show invite button
    else if (self.viewType == kMPSelectContactTypeInviteGroup) {
        [self.navigationItem setLeftBarButtonItem:cancelButton animated:NO];

        NSString *inviteTitle = NSLocalizedString(@"Invite",  @"SelectFriends - Button: invite to group chat");
        
        // add button each time since title can't be changed
        //
        UIBarButtonItem *inviteButton = [AppUtility barButtonWithTitle:inviteTitle
                                                            buttonType:kAUButtonTypeBarHighlight 
                                                                target:self action:@selector(pressChat:)];
        inviteButton.enabled = NO;
        [self.navigationItem setRightBarButtonItem:inviteButton animated:NO];
    
    }
    // show Done button
    else if (self.viewType == kMPSelectContactTypeBasic ) {
        
        [self.navigationItem setLeftBarButtonItem:cancelButton animated:NO];
        
        UIBarButtonItem *inviteButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Done",  @"SelectFriends - Button: done selecting contacts") 
                                                            buttonType:kAUButtonTypeBarHighlight 
                                                                target:self action:@selector(pressChat:)];
        // disable at first, only enable if people are selected
        inviteButton.enabled = NO;
        [self.navigationItem setRightBarButtonItem:inviteButton animated:NO];
    }
    // show Forward button
    else if (self.viewType == kMPSelectContactTypeForwardMessage) {
        
        [self.navigationItem setLeftBarButtonItem:cancelButton animated:NO];
        
        UIBarButtonItem *inviteButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Forward",  @"SelectFriends - Button: forward message to selected contact") 
                                                            buttonType:kAUButtonTypeBarHighlight 
                                                                target:self action:@selector(pressChat:)];
        // disable at first, only enable if people are selected
        inviteButton.enabled = NO;
        [self.navigationItem setRightBarButtonItem:inviteButton animated:NO];
    }

}

- (void)viewDidUnload
{
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.contactManager = nil;
    self.contactCellControllerD = nil;
    
    [self unloadSearch];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void) startFriendQuery {
    
    DDLogInfo(@"SCC-vwa");

    // get newest info this may also delete contacts
    [MPContactManager startFriendInfoQueryInBackGroundForceStart:NO];   
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    
    // show list asap
    [self.contactManager startCollationIndexingExcludeHelper:YES];
    
    [self startFriendQuery];
    
    // for test [self performSelector:@selector(startFriendQuery) withObject:nil afterDelay:2.0];
    
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



#define NO_ITEM_TAG 15001

- (void) showNoItemView {
    // Show no item label
    //
    UIView *noItemView = [self.tableView viewWithTag:NO_ITEM_TAG];
    
    NSUInteger totalItems = [self.contactManager numberOfTotalContactsForMode:@"list"];
    if (totalItems == 0 && noItemView == nil) {        
        CGSize headerSize = self.tableView.tableHeaderView.frame.size;
        UILabel *noItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, headerSize.height, self.tableView.frame.size.width-40.0, self.tableView.frame.size.height-headerSize.height)];
        [AppUtility configLabel:noItemLabel context:kAULabelTypeNoItem];
        noItemLabel.text = NSLocalizedString(@"No Friends", @"SelectContact - text: Inform users that there are no friends available for selection");
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


#pragma mark - Table Methods


/*!
 @abstract gets table cell associated with a particular contact
 
 @param enableSelection Should allow user to select this contact?
 */
- (SelectContactCellController *) cellControllerForContact:(CDContact *)contact enableSelection:(BOOL)enable{
    
    SelectContactCellController *cellController = [self.contactCellControllerD objectForKey:contact.userID];
    
    if (!cellController) {
        SelectContactCellController *newController = [[SelectContactCellController alloc] initWithContact:contact enableSelection:enable];
        newController.delegate = self;
        if (contact.userID) {
            [self.contactCellControllerD setObject:newController forKey:contact.userID];
            cellController = [self.contactCellControllerD objectForKey:contact.userID];
            
            if ([self.selectedUserIDs containsObject:contact.userID]) {
                cellController.isSelected = YES;
            }
            
            // basic view set selected members to already selected
            /*if (self.viewType == kMPSelectContactTypeBasic && [self.viewContacts count] > 0) {
                if ([self.viewContacts containsObject:contact]) {
                    cellController.isSelected = YES;
                }
            }*/
        }
        // if no userID, empty controller 
        else {
            cellController = newController;
            [cellController autorelease];
        }
        [newController release];
    }
    return cellController;
    
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// it is possible that search will eliminate all sections
	// but always return 1 section that will hold empty data
	
	/*
     If the requesting table view is the search display controller's table view, 
	 return only one section, otherwise return the count of the main list.
     */
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return 1;
    }
    // only show readonly list of contacts at the top
    //
    else if (self.viewType == kMPSelectContactTypeReadOnly) {
        
        return 1;
    
    }
    else
    {
		// add one for # section
        return [self.contactManager numberOfSections]; //+1;
    }
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	/*
     If the requesting table view is the search display controller's table view, 
	 return only one section, otherwise return the count of the main list.
     */
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return [self.contactManager searchNumberOfRowsInSection:section];
    }
    else
    {
        return [self.contactManager numberOfRowsInSection:section];
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)newTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	//DDLogVerbose(@"MVCFR: ping");
    
	
	CDContact *cellContact = nil;
    
	// if the requesting tableview is from the search display controller, then use search data model objects
	//
    if (newTableView == self.searchDisplayController.searchResultsTableView)
    {
        cellContact =  [self.contactManager searchContactAtIndexPath:indexPath];
    }
    else
    {
        cellContact = [self.contactManager personAtIndexPath:indexPath];
    }
	
    // for basic and create chat - allow selection for all rows
    BOOL enableSelection = YES;
    
    // if invite to group and first section is current group members, then don't allow selection
    if (self.viewType == kMPSelectContactTypeInviteGroup && [indexPath section] == 0) {
        enableSelection = NO;
    }
    else if (self.viewType == kMPSelectContactTypeReadOnly ){
        enableSelection = NO;
    }
  
    
    SelectContactCellController *cellController = [self cellControllerForContact:cellContact enableSelection:enableSelection];
    UITableViewCell *cell = [cellController tableView:newTableView cellForRowAtIndexPath:indexPath];
    
    return cell;
}

// do nothing for last count row selected
/*- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 // if the last index section: do nothing
 if ([self.memberManager isIndexAtCountSection:indexPath]) {
 return nil;
 }
 else {
 return indexPath;
 }
 
 }*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CDContact *cellContact = nil;
    
	// if the requesting tableview is from the search display controller, then use search data model objects
	//
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        cellContact =  [self.contactManager searchContactAtIndexPath:indexPath];
    }
    else
    {
        cellContact = [self.contactManager personAtIndexPath:indexPath];
    }
	
    BOOL enableSelection = YES;
    
    // if invite to group and first section is current group members, then don't allow selection
    if (self.viewType == kMPSelectContactTypeInviteGroup && [indexPath section] == 0) {
        enableSelection = NO;
    }
    
    SelectContactCellController *cellController = [self cellControllerForContact:cellContact enableSelection:enableSelection];
    [cellController tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    
}


/*!     
 Background color MUST be set right before cell is displayed
 */
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
}

// show headers
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	    
    
    // no header title during search
    if ([self.searchDisplayController isActive]) {
		return nil;
	}
	/* add instructions here instead??
	 if (section == 0) {
     NSString *sectionOneString = [NSString stringWithFormat:@"%@    %@",
     [self.memberManager titleForHeaderInSection:section],
     @"Add to Favorites"];
     return sectionOneString;
     }*/
    else if (self.viewType == kMPSelectContactTypeReadOnly) {
        return nil;
    }
	return [self.contactManager titleForHeaderInSection:section];
}


/**
 Specify the space allocated IF a footer is specified for the section
 */
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    CGFloat footerHeight = 0.0;
    
	return footerHeight;
}

/**
 Add a small gap after top contacts section
 */
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	
	UIView *sectionView = nil;
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

// return customized section
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
	UIImageView *sectionView = nil;
	
	// add Title
	NSString *title = [self tableView:tableView titleForHeaderInSection:section];
	// if top contacts
	if (title) {
		sectionView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_indexbar_green.png"]] autorelease];
        
        CGFloat labelWidth = ([title length] < 4)?25.0:100.0;
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, labelWidth, 15.0)];
		[AppUtility configLabel:titleLabel context:kAULabelTypeBlackMicroPlus];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = title;
		[sectionView addSubview:titleLabel];
		[titleLabel release];
	}
	return sectionView;
    
}

// show index
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	
    // turn off index for now
    return nil;
    
    // hide index during search
    if ([self.searchDisplayController isActive]) {
		return nil;
	}
    else if (self.viewType == kMPSelectContactTypeReadOnly) {
        return nil;
    }
	return [self.contactManager sectionIndexTitlesForTableView];
}

// tell the table what to do when index is pressed, need to shift up of magnifying glass
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	NSInteger resultIndex = [self.contactManager tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
	// if magnifying glass
	if (resultIndex == NSNotFound) {
		[tableView setContentOffset:CGPointZero animated:NO];
		return NSNotFound;
	}
	else {
		return resultIndex;
	}
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

// Disable swipe-delete
- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
}




#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText
{
	//[self startActivityIndicator];
	[self.contactManager filterContentForSearchText:(NSString*)searchText];
	
	[self.searchController.searchResultsTableView reloadData];
	//[self stopActivityIndicator];
}

/**
 Filter based on current search object status
 - does not require arguments
 */
- (void)filterContent {
	DDLogVerbose(@"FR-fc: filter content - fire: %@", self.searchBar.text);
	[self filterContentForSearchText:self.searchBar.text];
}




#pragma mark -
#pragma mark Search and UISearchDisplayController Delegate Methods

/**
 unload search objects
 
 Usage:
 - help remove old search objects that are no longer needed
 - if not done, then old search controllers showup when view is reloaded
 */
- (void)unloadSearch {
	DDLogInfo(@"SC-us: unloading search items");
	
	[self.contactManager removeAllfilteredContacts];
	
	/*
     // don't deactivate
     // - if you call this while search controller not on rootview controller, then crash
     //   ~ search, then double tap to go to root view, simulate mem warning, crash
     //
     //[self.searchController setActive:NO animated:NO];
	 */
	
	/*
	 Need to remove search components in case of memory warning
	 - after mem warn, theses old search components will not work properly (search controller view will be missing!)
	 - so delete them and create new ones later
	 */
	// set delegates to nil before deallocating
	self.searchBar.delegate = nil;
	self.searchController.delegate = nil;
	self.searchController.searchResultsDataSource = nil;
	self.searchController.searchResultsDelegate = nil;
	
	self.searchBar = nil;
	self.searchController = nil;
	
}

/**
 Sets up all elements related to search function
 */
- (void)setSearch {
	
	// if search exists then do nothing
	if (searchBar && searchController) {
		DDLogInfo(@"SC-SS: search already exists, do nothing");
		return;
	}
	DDLogInfo(@"SC-SS: setting up search");
	
	// add search bar to top
	CGRect searchRect = CGRectMake(0, 0, 320, 40);
	
	UISearchBar *sBar = [[UISearchBar alloc] initWithFrame:searchRect];
	self.searchBar = sBar;
	[sBar release];
	self.searchBar.placeholder = NSLocalizedString(@"Search", @"Search Placeholder: prompts user to enter search string");
	self.searchBar.showsCancelButton = NO;
	self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.searchBar.delegate = self;    
	
	//DDLogVerbose(@"MV-SS: after search bar setup");
	//self.tableView.tableHeaderView = self.searchBar;
	
	//DDLogVerbose(@"MV-SS: after search bar add to header");
	// add search controller
	UISearchDisplayController *sController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
	self.searchController = sController;
	[sController release];
	self.searchController.delegate = self;
	self.searchController.searchResultsDataSource = self;
	self.searchController.searchResultsDelegate = self;
	
	
	// for dark background
	//self.searchBar.barStyle = UIBarStyleDefault;
	self.searchBar.tintColor = [AppUtility colorForContext:kAUColorTypeSearchBar];
	self.searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.searchController.searchResultsTableView.backgroundColor = [UIColor whiteColor];
}

#define kSearchTimer	1.0

/**
 Search string just changed
 */
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	// reset table colors here
	// - it seems that a new table is sometimes created, so we need to reapply color here
	//
	self.searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.searchController.searchResultsTableView.backgroundColor = [UIColor whiteColor];
	
	// if search string is empty
	// - stop search and indicator
	if ([searchString length] == 0) {
		//[self stopActivityIndicator];
		//[self.searchTimer invalidate];
	}
	else {
        [self filterContent];
		//[self startActivityIndicator];
		
		// invalidate old timer and create a new one
		//[self.searchTimer invalidate];
		//self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:kSearchTimer target:self selector:@selector(filterContent) userInfo:nil repeats:NO];
	}
    
	
    // Return YES to cause the search result table view to be reloaded.
	// Return NO for asynchronous search, reload search tableview at a later time
    return NO;
}


/**
 Search Ended
 - scroll to the last person
 */
- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
	
	// reload to refresh that status of each row's radio buttons
	// ** don't reload - causes an annoying flash
	[self.tableView reloadData];
	
}

/**
 Run after search controller is cancelled
 
 Use:
 - make sure that navigationBar is showing after search has ended
 ~ this happens if you start search in "Groups", then go to different tab, memory warning, go back to Groups to cancel search
 ~ then the navigationBar is gone!
 
 */
- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
	if(self.navigationController.navigationBar.hidden == YES){
		[self.navigationController setNavigationBarHidden:NO animated:YES];
	}
}



#pragma mark - Button


/*!
 @abstract cancel selection
 */
- (void) pressCancel:(id)sender {
    
    // if presented modally, we need to present done button
    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        
        if ([self.delegate respondsToSelector:@selector(selectContactsController:didCancel:)]) {
            [self.delegate selectContactsController:self didCancel:YES];
        }
        else {
             [self dismissModalViewControllerAnimated:YES];
        }       
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

/*!
 @abstract gets the contacts that are selected
 
 - get all contacts from CM
 - get all cells and check if they are selected
 
 */
- (NSArray *)selectedContacts {
    
    NSMutableArray *selectedContacts = [[[NSMutableArray alloc] init] autorelease];
    
    NSArray *allDisplayedContacts = [self.contactManager getCollationContacts];
    
    for (CDContact *iContact in allDisplayedContacts) {
        
        SelectContactCellController *iController = [self cellControllerForContact:iContact enableSelection:YES];
        if (iController.isSelected) {
            [selectedContacts addObject:iContact];
        }
    }
    
    return selectedContacts;
}

/*!
 @abstract sends selected contact info back to parent view and also dismiss view
 
 */
- (void) pressChat:(id)sender {
	
    /*
     Added to avoid users holding down the chat button while removing contacts
     - this will cause a "no member" chat to be created
     */
    
    // disable button if needed
    NSUInteger numSelected = [[self selectedContacts] count];
    
    if (numSelected > 0) {
        // Want to dismiss it's parent
        // - call delegate if it exists
        if ([delegate respondsToSelector:@selector(selectContactsController:chatContacts:)]) {
            [delegate selectContactsController:self chatContacts:[self selectedContacts]];
        }
        // otherwise just dismiss this view
        else {
            [self dismissModalViewControllerAnimated:YES];
        }
    }
    else {
        for (UIBarButtonItem *iButton in self.toolbarItems){
            iButton.enabled = NO;
        }
    }
}

/*!
 @abstract sends selected contact info back to parent view and also dismiss view
 
 */
- (void) pressBroadcast:(id)sender {
	
    // Want to dismiss it's parent
    // - call delegate if it exists
    if ([delegate respondsToSelector:@selector(selectContactsController:broadcastContacts:)]) {
        [delegate selectContactsController:self broadcastContacts:[self selectedContacts]];
    }
    // otherwise just dismiss this view
    else {
        [self dismissModalViewControllerAnimated:YES];
    }    
    
}



#pragma mark - Refresh Methods


/*
 Full reset: index, reload data, reload table
 */
- (void) indexContacts:(NSNotification *)notification {
    
    [self.contactManager startCollationIndexingExcludeHelper:YES];
}

/*
 If DB was update, update contact manager & refresh this table
 */
- (void) reloadData:(NSNotification *)notification {
    
    //[self constructTableGroups];
    
    // refresh objects in CM from DB
    [self.contactManager reloadContacts];
    
    // update tables view
    [self.contactCellControllerD removeAllObjects];
    [self.tableView reloadData];    
}

/*
 If CM indexing has finished, reload table
 */
- (void) reloadTable:(NSNotification *)notification {
    
    // update table view
    [self.contactCellControllerD removeAllObjects];
    [self.tableView reloadData];
    
    if ([self.searchController isActive]) {
        [self filterContent];
    }
    else {
        [self showNoItemView];
    }
    
}


#pragma mark - SelectContactCellControllerDelegate

/*!
 @abstract Set the appropriate button enabled states
 
 */
- (void) setButtonState {
    
    NSUInteger selectCount = [[self selectedContacts] count];

    //NSString *selectString = [NSString stringWithFormat:@"%d"
    
    
    // update title count
    if (self.viewType == kMPSelectContactTypeReadOnly) {
        self.title = NSLocalizedString(@"Selected Friends", @"SelectFriends - Title: show selected friends");
    }
    else {
        if (selectCount > 0) {
            self.title = [NSString stringWithFormat:NSLocalizedString(@"Selected %d Friends", @"SelectFriends - Title: informs users number of selected friends"), selectCount];
        }
        else {
            self.title = NSLocalizedString(@"Select Friends", @"SelectFriends - Title: allow user to select friends");
        }
    }
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    
    if (self.viewType == kMPSelectContactTypeCreateChat) {
        NSInteger broadcastInt = kMPParamBroadcastMax - selectCount;
        NSInteger chatInt = kMPParamGroupChatMax - selectCount;
        
        // only enable if within limit
        self.broadcastButtonItem.enabled = (broadcastInt < kMPParamBroadcastMax && broadcastInt > -1)?YES:NO;
        self.chatButtonItem.enabled = (chatInt < kMPParamGroupChatMax && chatInt > -1)?YES:NO;
    }
    else if (self.viewType == kMPSelectContactTypeInviteGroup) {
        NSUInteger totalCount = [self.viewContacts count] + selectCount;
        NSInteger inviteInt = kMPParamGroupChatMax-totalCount;
        

        // disable at first, only enable if people are selected
        self.navigationItem.rightBarButtonItem.enabled = (inviteInt < kMPParamGroupChatMax-[self.viewContacts count] && inviteInt > -1)?YES:NO;
        
        
        //self.navigationItem.rightBarButtonItem.title = inviteTitle;
        //self.navigationItem.rightBarButtonItem.enabled = (inviteInt < kMPParamGroupChatMax-[self.viewContacts count] && inviteInt > -1)?YES:NO;
    }
    else if (self.viewType == kMPSelectContactTypeBasic) {
        NSInteger slotsLeft = kMPParamBroadcastMax-selectCount;
        
        // disable at first, only enable if people are selected
        self.navigationItem.rightBarButtonItem.enabled = (slotsLeft > -1)?YES:NO;
    }
}

/*!
 @abstract a row was just tapped.  Use this to udpate button enabled state.
 
 Forward
 - if select - find last select and deselect it
 
 */
- (void)SelectContactCellController:(SelectContactCellController *)controller didSelect:(BOOL)selected{
    
    NSArray *selectedCons = [self selectedContacts];
    NSUInteger numSelected = [selectedCons count];
    
    BOOL enableButton = NO;
    // enable buttons
    if (numSelected > 0) {
        enableButton = YES;
    }
    
    if (self.viewType == kMPSelectContactTypeBasic || self.viewType == kMPSelectContactTypeForwardMessage) {
        self.navigationItem.rightBarButtonItem.enabled = enableButton;
    }
    [self setButtonState];
    
    // if select - deselect previous contact
    if (self.viewType == kMPSelectContactTypeForwardMessage && selected) {
        
        CDContact *lastContact = nil;
        for (CDContact *iContact in selectedCons) {
            if (![iContact isEqual:controller.contact]) {
                lastContact = iContact;
                break;
            }
        }
        
        // get IP for last selected
        if (lastContact) {
            NSIndexPath *lastIP = [self.contactManager indexPathForPerson:lastContact];
            SelectContactCellController *lastCC = [self cellControllerForContact:lastContact enableSelection:YES];
            if (lastIP && lastCC) {
                [lastCC tableView:self.tableView didSelectRowAtIndexPath:lastIP];
                // get updated selected
                selectedCons = [self selectedContacts];
            }
        }
    }

    
    [self.selectedUserIDs removeAllObjects];
    for (CDContact *iContact in selectedCons) {
        [self.selectedUserIDs addObject:iContact.userID];
    }
}

@end
