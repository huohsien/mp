//
//  FriendController.m
//  mp
//
//  Created by M Tsai on 11-9-8.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "ContactController.h"
#import "MPContactManager.h"
#import "CDContact.h"
#import "ContactCellController.h"
#import "AppUtility.h"
#import "MPFoundation.h"

#import "MyProfileController.h"
#import "AddFriendController.h"
#import "TKSpinButton.h"
#import "TextEmoticonView.h"
#import "TKImageLabel.h"
#import "HeadShotDisplayView.h"

#import "CDChat.h"

@interface ContactController (PrivateMethods)
- (void) setSearch;
- (void) setTableViewHeader;
- (void) updateMyProfileInHeader;

- (void) handleSyncStart;
- (void) handleSyncComplete;
- (void) pushPendingChat;

@end


@implementation ContactController

@synthesize contactManager;
@synthesize contactCellControllerD;
@synthesize searchBar;
@synthesize searchController;
@synthesize imageManager;
@synthesize pendingHiddenChat;
@synthesize shouldPushPendingChat;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.shouldPushPendingChat = NO;
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // clear out search delegates
    [self unloadSearch];
    
    [contactManager release];
    [contactCellControllerD release];
    [searchBar release];
    [searchController release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

#define SYNC_BTN_TAG            19001
//#define SUGGESTION_BADGE_TAG    19002
#define NO_ITEM_TAG             19003


/*!
 @abstract updates suggestion badge
 */
- (void) updateSuggestionBadge {
    
    /* Disable outside badge
    NSInteger count = [CDContact newSuggestedContactsCount];

    UIButton *badgeButton = (UIButton *)[self.navigationController.navigationBar viewWithTag:SUGGESTION_BADGE_TAG];
    NSString *numString = [NSString stringWithFormat:@"%d", count];
    [AppUtility setBadge:badgeButton text:numString];
    */
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Friends", @"View Title: Friends Listing");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    // apply standard table configurations
    [AppUtility configTableView:self.tableView];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    if (!self.contactManager) {
        MPContactManager *newCM = [[MPContactManager alloc] init];
        self.contactManager = newCM;
        [newCM release];
    }
    
    if (!self.contactCellControllerD) {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.contactCellControllerD = newD;
        [newD release];
    }
    
    // setup search if not already
	[self setSearch];
    
    // setup table header view - should come after search!
    [self setTableViewHeader];
    
    
    // Add Button
    UIButton *customButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 32.0, 32.0)];
    [customButton setBackgroundImage:[UIImage imageNamed:@"std_btn_add2_nor.png"] forState:UIControlStateNormal];
    [customButton setBackgroundImage:[UIImage imageNamed:@"std_btn_add2_prs.png"] forState:UIControlStateHighlighted];
    [customButton setEnabled:YES];
    
    customButton.backgroundColor = [UIColor clearColor];
    [customButton addTarget:self action:@selector(pressAdd:) forControlEvents:UIControlEventTouchUpInside];
    
    // add friend suggestion badge
    /*
    UIButton *sugBadge = [[UIButton alloc] initWithFrame:CGRectMake(15.0, -6.0, 20.0, 20.0)];
    [AppUtility configButton:sugBadge context:kAUButtonTypeBadgeYellow];
    sugBadge.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    sugBadge.hidden = YES;
    sugBadge.tag = SUGGESTION_BADGE_TAG;
    [customButton addSubview:sugBadge];
    [sugBadge release];    
    */
    
    UIBarButtonItem* barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    [customButton release];
    [self.navigationItem setRightBarButtonItem:barButtonItem animated:NO];
    //self.navigationItem.rightBarButtonItem = barButtonItem;
    [barButtonItem release];
    
    
    UIImage *norImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_green6_nor.png"] leftCapWidth:9.0 topCapHeight:15.0];
    
    UIImage *prsImage = [Utility resizableImage:[UIImage imageNamed:@"std_btn_green6_prs.png"] leftCapWidth:9.0 topCapHeight:15.0];
    
    TKSpinButton *spinButton = [[TKSpinButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 45.0, 32.0)
                                                       normalImage:norImage
                                                        pressImage:prsImage
                                                     disabledImage:nil
                                                     spinningImage:[UIImage imageNamed:@"friends_icon_sync.png"]];
    [spinButton addTarget:self action:@selector(pressSync:) forControlEvents:UIControlEventTouchUpInside];
    spinButton.tag = SYNC_BTN_TAG;
    
    UIBarButtonItem* syncBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinButton];
    [spinButton release];
    [self.navigationItem setLeftBarButtonItem:syncBarButtonItem animated:NO];
    [syncBarButtonItem release];
    

    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.contactManager = nil;
    self.contactCellControllerD = nil;
    
    [self unloadSearch];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"FR-vwa");

    [super viewWillAppear:animated];
    [self updateMyProfileInHeader];
    
    [self updateSuggestionBadge];
    
    // *** check memory of background CM
    BOOL isSyncRunning = [[AppUtility getBackgroundContactManager] isSyncRunning];
    
    // Update sync button text
    //
    // if syncn in progress
    //
    //if ([[MPSettingCenter sharedMPSettingCenter] isPhoneSyncRunning]) {
    if (isSyncRunning) {
        [self handleSyncStart];
    }
    // not running - get last sync time
    //
    else {
        [self handleSyncComplete];
    }
    
    // only show sync button if auto sync is on
    //
    NSNumber *isAutoSyncOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAddressBookIsAllowed];
    self.navigationItem.leftBarButtonItem.customView.hidden = ![isAutoSyncOn boolValue];
    
    
    // only need to refresh if view is visible
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadData:) name:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:nil];
    
    // after indexing is finished - so use new datamodel
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadTable:) name:MP_CONTACTMANAGER_RELOAD_TABLE_NOTIFICATION object:nil];
    
    // data model changed, so reindex
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(indexContacts:) name:MP_CONTACTMANAGER_INDEX_NOTIFICATION object:nil];
    
    // observe sync events
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleSyncStart) name:MP_CONTACTMANAGER_PHONESYNC_START_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(handleSyncComplete) name:MP_CONTACTMANAGER_PHONESYNC_COMPLETE_NOTIFICATION object:nil];
    
}

/*!
 @abstract VDA
 - start collation
 - query find info to get latest information (once per session)

 */
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    DDLogVerbose(@"FR-vda: view did appear");
    
    // only reindex if search is not active
    if (![self.searchDisplayController isActive])
    {
        // show list asap
        [self.contactManager startCollationIndexing];
        
        // get newest info this may also delete contacts
        [MPContactManager startFriendInfoQueryInBackGroundForceStart:NO];
    }
    
    // indicate user viewed friends - for new friend identification
    //
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingDidViewFriendInThisSession settingValue:[NSNumber numberWithBool:YES]];
    
    if (self.shouldPushPendingChat) {
        [self pushPendingChat];
    }
    
}



- (void)viewWillDisappear:(BOOL)animated
{
    // don't get UI notification when we are not visible
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // reset animation when leaving
    TKSpinButton *syncButton = (TKSpinButton *)self.navigationItem.leftBarButtonItem.customView;
    if ([syncButton respondsToSelector:@selector(viewWillDisappear)]) {
        [syncButton viewWillDisappear];
    }
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    // indicate user viewed friends - for new friend identification
    //
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingDidViewFriendInThisSession settingValue:[NSNumber numberWithBool:YES]];
    
    [super viewDidDisappear:animated];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Table Methods


/*!
 @abstract gets table cell associated with a particular contact
 */
- (ContactCellController *) cellControllerForContact:(CDContact *)contact {
    
    ContactCellController *cellController = [self.contactCellControllerD objectForKey:contact.userID];

    if (!cellController) {
        ContactCellController *newController = [[ContactCellController alloc] initWithContact:contact];
        newController.parentController = self;
        newController.delegate = self;
        
        // default key in case contact does not exists
        NSString *controllerKey = @"controllerKey";
        if (contact.userID) {
            controllerKey = contact.userID;
        }
        
        [self.contactCellControllerD setObject:newController forKey:controllerKey];
        [newController release];
        
        cellController = [self.contactCellControllerD objectForKey:controllerKey];
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
	
    ContactCellController *cellController = [self cellControllerForContact:cellContact];
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
	
    ContactCellController *cellController = [self cellControllerForContact:cellContact];
    [cellController tableView:tableView didSelectRowAtIndexPath:indexPath];
    	
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
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, 30.0, 15.0)];
		[AppUtility configLabel:titleLabel context:kAULabelTypeBlackMicroPlus];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = title;
		[sectionView addSubview:titleLabel];
		[titleLabel release];
	}
	return sectionView;
}

/*
//
// Specify the space allocated IF a header is specified for the section
//
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    if (title) {
        return 20.0;
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
		sectionView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_indexbar.png"]] autorelease];
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 2.0, 150, 18.0)];
		titleLabel.text = title;
        [AppUtility configLabel:titleLabel context:kAULabelTypeGrayMicroPlus];
		//titleLabel.shadowColor = [UIColor darkGrayColor];
		//titleLabel.shadowOffset = CGSizeMake(-1, -1);
		titleLabel.backgroundColor = [UIColor clearColor];
		[sectionView addSubview:titleLabel];
		[titleLabel release];
	}
	return sectionView;
}*/

// show index
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	// disable index ~ for cleaner cell layout
    return nil;
    
    // hide index during search
    if ([self.searchDisplayController isActive]) {
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


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
	
    ContactCellController *cellController = [self cellControllerForContact:cellContact];
    [cellController tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    
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
	DDLogInfo(@"FR-us: unloading search items");
	
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
		DDLogInfo(@"FR-SS: search already exists, do nothing");
		return;
	}
	DDLogInfo(@"FR-SS: setting up search");
	
	// add search bar to top
	CGRect searchRect = CGRectMake(0, 0, 320, 44);
	
	UISearchBar *sBar = [[UISearchBar alloc] initWithFrame:searchRect];
	self.searchBar = sBar;
	[sBar release];
	self.searchBar.placeholder = NSLocalizedString(@"Search Display Name", @"Search Placeholder: prompts user to search in friend list");
	self.searchBar.showsCancelButton = NO;
	self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.searchBar.delegate = self;    
    // 51.0	80.0	92.0	
    UIColor *searchBarColor = [UIColor colorWithRed:0.56 green:0.82 blue:0.94 alpha:1.0]; //[UIColor colorWithRed:130.0/255.0 green:204.0/255.0 blue:234.0/255.0 alpha:1.0];
    
    self.searchBar.tintColor = searchBarColor; // [AppUtility colorForContext:kAUColorTypeSearchBar];

    // ios5.0 can customize easliy
    if ([self.searchBar respondsToSelector:@selector(setSearchFieldBackgroundImage:forState:)]) {
        [self.searchBar setSearchFieldBackgroundImage:[UIImage imageNamed:@"std_icon_searchbar.png"] forState:UIControlStateNormal];
        [self.searchBar setBackgroundImage:[UIImage imageNamed:@"std_icon_searchback.png"]];
    }
    else {
        // Cover black line with this line here
        //
        UIColor *searchLineColor = [UIColor colorWithRed:0.50 green:0.79 blue:0.93 alpha:1.0];
        CGRect rect = self.searchBar.frame;
        UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(0, rect.size.height-2,rect.size.width, 2)];
        lineView.backgroundColor = searchLineColor;
        [self.searchBar addSubview:lineView];
        [lineView release];
        
        // for testing - not yet figured out how to skin 4.x properly
        /*
        UIView *sBackView = nil;
        UITextField *sTextField = nil;
        for (UIView *iView in self.searchBar.subviews)
        {
            if ([iView isKindOfClass:NSClassFromString(@"UISearchBarBackground")])
            {
                sBackView = iView;
            }
            else if ([iView isKindOfClass:[UITextField class]]){
                sTextField = (UITextField *)iView;
            }
        }
        
        UIImage *sBarImage = [Utility resizableImage:[UIImage imageNamed:@"friend_banner.png"] leftCapWidth:25.0 topCapHeight:22.0];
        //CGRect test = sTextField.bounds;
        UIImageView *sView = [[UIImageView alloc] initWithImage:sBarImage];
        
        [sBackView removeFromSuperview];
        //sTextField.background = [UIImage imageNamed:@"friend_banner.png"];
        [sTextField addSubview:sView];
         */
        
        /*
        UIImage *sBarImage = [Utility resizableImage:[UIImage imageNamed:@"std_icon_searchbar.png"] leftCapWidth:310.0 topCapHeight:22.0];
        UIImageView *sView = [[UIImageView alloc] initWithImage:sBarImage];
        [self.searchBar insertSubview:sView atIndex:1];
        [sView release];
        */
        
    }


    
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

}

#define kSearchTimer	1.0

/*!
 @abstract Search string just changed
 */
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	// reset table colors here
	// - it seems that a new table is sometimes created, so we need to reapply color here
	//
    self.searchController.searchResultsTableView.rowHeight = kMPParamTableRowHeight;
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


/*!
 @abstract Search Ended
 - scroll to the last person
 */
- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
	
	// reload to refresh that status of each row's radio buttons
	// ** don't reload - causes an annoying flash
	[self.tableView reloadData];
	
}

/*!
 @abstract Run after search controller is cancelled
 
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

#pragma mark - Table Header Creation

#define MY_PHOTO_IMAGE_TAG  16000
#define MY_NAME_LABEL_TAG   16001
#define MY_STATUS_LABEL_TAG 16002

/*!
 @abstract Updates your profile info to header view
 
 Use:
 - for first use.
 - after getting notified that my profile has changed
 */
- (void) updateMyProfileInHeader {
    
    //UIImageView *photoView = (UIImageView *)[self.tableView.tableHeaderView viewWithTag:MY_PHOTO_IMAGE_TAG];
    UILabel *nameLabel = (UILabel *)[self.tableView.tableHeaderView viewWithTag:MY_NAME_LABEL_TAG];
    TextEmoticonView *statusLabel = (TextEmoticonView *)[self.tableView.tableHeaderView viewWithTag:MY_STATUS_LABEL_TAG];

    nameLabel.text = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingNickName];
    NSString *myStatus = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingStatus];
    NSString *oneLineStatus = [myStatus stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    [statusLabel setText:oneLineStatus];
    
    if (!self.imageManager) {
        MPImageManager *imageM = [[MPImageManager alloc] init];
        imageM.delegate = self;
        self.imageManager = imageM;
        [imageM release];
    }
    
    // photo
    UIImage *gotImage = [self.imageManager getImageForObject:[CDContact mySelf] context:kMPImageContextList ignoreVersion:NO];
    if (gotImage) {
        UIButton *myPhotoView = (UIButton *)[self.tableView.tableHeaderView viewWithTag:MY_PHOTO_IMAGE_TAG];
        [myPhotoView setBackgroundImage:gotImage forState:UIControlStateNormal];
    }
    
}

/*!
 @abstract construct table header views
 */
- (void) setTableViewHeader {
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    /*UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, 100.0)];
    headerView.backgroundColor = [UIColor lightGrayColor];
    [headerView addSubview:self.searchBar];
    */
    
    CGFloat searchBarHeight = self.searchBar.frame.size.height;
    
    UIButton *headerView = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, searchBarHeight+67.0)];
    headerView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    [headerView addTarget:self action:@selector(pressMyProfile:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:self.searchBar];

    // set back image
    UIImageView *backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"friend_banner.png"]];
    backImageView.frame = CGRectMake(0.0, searchBarHeight, appFrame.size.width, 67.0);
    [headerView addSubview:backImageView];
    [backImageView release];
     
    // add photo paper image
    //
    UIImageView *photoBackImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"friend_heatshot_base.png"]];
    photoBackImageView.frame = CGRectMake(9.0, searchBarHeight, 62.0, 64.0);
    photoBackImageView.backgroundColor = [UIColor clearColor];
    photoBackImageView.userInteractionEnabled = YES;
    [headerView addSubview:photoBackImageView];
    
    // add photo image
    //
    UIButton *myHeadShotButton = [[UIButton alloc] initWithFrame:CGRectMake(4.0, 4.0, 54.0, 54.0)];
    //[myHeadShotButton.imageView setContentMode:UIViewContentModeScaleToFill];
    myHeadShotButton.backgroundColor = [UIColor blueColor];
    [myHeadShotButton setBackgroundImage:[UIImage imageNamed:@"friend_headshot_nophoto.png"] forState:UIControlStateNormal];
    myHeadShotButton.tag = MY_PHOTO_IMAGE_TAG;
    [myHeadShotButton addTarget:self action:@selector(pressMyHeadShot:) forControlEvents:UIControlEventTouchUpInside];
    [photoBackImageView addSubview:myHeadShotButton];
    [myHeadShotButton release];
    [photoBackImageView release];

    
    // add status background image
    //
    UIImageView *statusBackImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_statusfield2_nor.png"]];
    statusBackImageView.frame = CGRectMake(72.0, searchBarHeight, 240.0, 47.0);
    statusBackImageView.backgroundColor = [UIColor clearColor];
    [headerView addSubview:statusBackImageView];
    
    // add name label
    //
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(29.0, 3.0, 180.0, 21.0)];
    [AppUtility configLabel:nameLabel context:kAULabelTypeGreenStandardPlus];
    nameLabel.tag = MY_NAME_LABEL_TAG;
    [statusBackImageView addSubview:nameLabel];
    [nameLabel release];
    
    // add status label
    //
    TextEmoticonView *statusLabel = [[TextEmoticonView alloc] initWithFrame:CGRectMake(29.0, 25.0, 180.0, 20.0)];
    [AppUtility configLabel:(UILabel *)statusLabel context:kAULabelTypeGrayMicroPlus];
    statusLabel.backgroundColor = [UIColor whiteColor];
    statusLabel.numberOfLines = 1;
    statusLabel.lineBreakMode = UILineBreakModeTailTruncation;
    statusLabel.tag = MY_STATUS_LABEL_TAG;
    [statusBackImageView addSubview:statusLabel];
    [statusLabel release];
    
    // edit icon
    //
    UIImageView *editImageView = [[UIImageView alloc] initWithFrame:CGRectMake(217.0, 25.0, 15.0, 15.0)]; 
    //CGRectMake(232.0, 25.0, 15.0, 15.0)]; // w/index CGRectMake(217.0, 25.0, 15.0, 15.0)
    editImageView.image = [UIImage imageNamed:@"std_icon_editpen.png"];
    editImageView.backgroundColor = [UIColor whiteColor];
    [statusBackImageView addSubview:editImageView];
    [editImageView release];
    [statusBackImageView release];

    
    
    self.tableView.tableHeaderView = headerView;
    [headerView release];
}


#pragma mark - Button

/*!
 @abstract Pressed HeadShot
 */
- (void)pressMyHeadShot:(id)sender {
    
    //NSString *url = [self.contact imageURLForContext:nil ignoreVersion:NO];
    
    // only show if there is a file to download
    if (YES /*url*/) {
        CGRect appFrame = [Utility appFrame];
        
        //CGRect letterRect = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height);
        
        HeadShotDisplayView *headShotView = [[HeadShotDisplayView alloc] initWithFrame:appFrame contact:[CDContact mySelf]];
        
        UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
        
        [containerVC.view addSubview:headShotView];
        [headShotView release];
    }
}

/*!
 @abstact push my profile on the stack
 */
- (void) pressMyProfile:(id)sender {
    
    MyProfileController *nextController = [[MyProfileController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];

}

/*!
 @abstact press add friend button
 */
- (void) pressAdd:(id)sender {
    
    AddFriendController *nextController = [[AddFriendController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    
}

#pragma mark - Generic Table Methods


/*!
 @abstract contruct data model for table
 */
/*
- (void)constructTableGroups
{
	
    NSMutableArray *contactCells = [[NSMutableArray alloc] init];
    
    for (CDContact *iContact in self.contactManager.contacts){
        ContactCellController *newCell = [[ContactCellController alloc] initWithContact:iContact];
        newCell.parentController = self;
        [contactCells addObject:newCell];
        [newCell release];
    }
    
    self.tableGroups = [NSArray arrayWithObjects:contactCells, nil];
    [contactCells release];
}
*/

/*
 Full reset: index, reload data, reload table
 */
- (void) indexContacts:(NSNotification *)notification {
        
    // more suggestions may have came in
    //
    [self updateSuggestionBadge];
    [self.contactManager startCollationIndexing];
}



- (void) showNoItemView {
    // Show no item label
    //
    UIView *noItemView = [self.tableView viewWithTag:NO_ITEM_TAG];
    
    NSUInteger totalItems = [self.contactManager numberOfTotalContactsForMode:@"list"];
    if (totalItems == 0 && noItemView == nil) {        
        CGSize headerSize = self.tableView.tableHeaderView.frame.size;
        UILabel *noItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, headerSize.height, self.tableView.frame.size.width-40.0, self.tableView.frame.size.height-headerSize.height)];
        [AppUtility configLabel:noItemLabel context:kAULabelTypeNoItem];
        noItemLabel.text = NSLocalizedString(@"Tap the '+' button to add friends.", @"FriendList - text: Inform users how to add friends since there are none initially");
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

/*
 If DB was update, update contact manager & refresh this table
 */
- (void) reloadData:(NSNotification *)notification {
    
    //[self constructTableGroups];
    
    // refresh objects in CM from DB
    [self.contactManager reloadContacts];
    
    // update tables view
    [self reloadTable:nil]; 
}



#pragma mark - PB Sync

/*!
 @abstract starts phone sync
 */
- (void) pressSync:(id)sender {
    [MPContactManager tryStartingPhoneBookSyncForceStart:YES delayed:NO];
}

/*!
 @abstract updates sync button for sync start
 */
- (void)handleSyncStart {
    
    TKSpinButton *syncButton = (TKSpinButton *)self.navigationItem.leftBarButtonItem.customView;
    
    // disables sync button
    //
    syncButton.enabled = NO;
    [syncButton startSpinning];
}


/*!
 @abstract updates sync button for sync complete
 */
- (void)handleSyncComplete {

    TKSpinButton *syncButton = (TKSpinButton *)self.navigationItem.leftBarButtonItem.customView;
    
    // disables sync button
    //
    syncButton.enabled = YES;
    [syncButton stopSpinning];
}


#pragma mark - ContactCellController

/*!
 @abstract Called when contact cell needs to be refreshed.
 
 We need to tell the table to refresh the cell if something changed like the headshot.
 The table will then:
 - figure out if this controller is visible
 - if visible then refresh it
 
 */
- (void)ContactCellController:(ContactCellController *)controller refreshContact:(CDContact *)contact {
    
    NSIndexPath *contactIP = nil;
    
    // find the index path
    if (self.tableView == self.searchDisplayController.searchResultsTableView)
    {
        contactIP = [self.contactManager searchIndexPathForPerson:contact];
    }
    else
    {
        contactIP = [self.contactManager indexPathForPerson:contact];
    }
    
    // if IP visible then refresh it
    if ([Utility isIndexPath:contactIP inIndexPaths:[self.tableView indexPathsForVisibleRows]]) {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:contactIP] withRowAnimation:UITableViewRowAnimationFade];
    }
}

/*!
 @abstract Called when cell is tapped and chat should be initiated
 
 */
- (void)ContactCellController:(ContactCellController *)controller startChatWithContact:(CDContact *)contact {
    
    CDChat *chat = [CDChat chatWithCDContacts:[NSArray arrayWithObject:contact] groupID:nil shouldSave:YES];
    
    BOOL isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    
    // if hidden chat then ask for PIN unlock first
    if (isLocked && [chat.isHiddenChat boolValue] ) {
        self.pendingHiddenChat = chat;
        HiddenController *nextController = [[HiddenController alloc] initWithHCStatus:kHCViewStatusUnlockPIN];
        
        //nextController.title = NSLocalizedString(@"New Schedule", @"Schedule - title: view to edit status message");            
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:nextController];
        [AppUtility customizeNavigationController:navigationController];
        nextController.delegate = self;
        [self presentModalViewController:navigationController animated:YES];
        [navigationController release];
        [nextController release];
    }
    else {
        [AppUtility pushNewChat:chat];
    }

}

#pragma mark - HiddenController

/*!
 @abstract pushes pending chat into view
 */
- (void) pushPendingChat {
    
    if (self.pendingHiddenChat) {
        [AppUtility pushNewChat:self.pendingHiddenChat];
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
 - This will then prevent nav delegate from calling and cause the tab bar not to hide!
 - Instead flag for the push to happen after viewdidappear is called!
 
 */
- (void)HiddenController:(HiddenController *)controller unlockDidSucceed:(BOOL)didSucceed {

    // should push after view appears!
    //
    self.shouldPushPendingChat = YES;

}

#pragma mark - Image - Headshot downloaded

/*!
 @abstract Called my head shot has finished downloading
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager finishLoadingImage:(UIImage *)image{
    
    if (image) {
        UIButton *myPhotoView = (UIButton *)[self.tableView.tableHeaderView viewWithTag:MY_PHOTO_IMAGE_TAG];
        [myPhotoView setBackgroundImage:image forState:UIControlStateNormal];
    }

}




@end
