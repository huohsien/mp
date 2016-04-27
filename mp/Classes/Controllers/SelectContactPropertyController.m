//
//  SelectContactPropertyController.m
//  mp
//
//  Created by M Tsai on 11-12-1.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "SelectContactPropertyController.h"

#import "MPFoundation.h"
#import "TTCollationWrapper.h"
#import "ContactProperty.h"

#import "MPContactManager.h"
#import "AppUtility.h"


@interface SelectContactPropertyController (PrivateMethods)
- (void)loadDataInBackGround;
- (void)setSearch;
- (void)setTableViewHeader;
- (void)unloadSearch;
@end


@implementation SelectContactPropertyController

@synthesize delegate;
@synthesize propertyType;
@synthesize contactProperties;
@synthesize collation;
@synthesize idToPropertyD;
@synthesize filteredObjects;

@synthesize contactCellControllerD;
@synthesize searchBar;
@synthesize searchController;


- (id)initWithStyle:(UITableViewStyle)style type:(SelectContactPropertyType)newType
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.propertyType = newType;
        
        NSMutableArray *objects = [[NSMutableArray alloc] init];
        self.filteredObjects = objects;
        [objects release];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // clear search delegates
    [self unloadSearch];
    
    [contactProperties release];
    [collation release];
    [idToPropertyD release];
    [filteredObjects release];
    [contactCellControllerD release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Tools

/*!
 @abstract gets the contact properties that are selected
 
 */
- (NSArray *)selectedProperties {
    
    NSMutableArray *selectedProperties = [[[NSMutableArray alloc] init] autorelease];
    
    for (ContactProperty *iProperty in self.contactProperties) {
        if (iProperty.isSelected == YES) {
            [selectedProperties addObject:iProperty];
        }
    }
    return selectedProperties;
}

/*!
 @abstract Updates Title and Done button status
 
 */
- (void) updateViewUsingSelectCount {
    
    NSUInteger selectCount = [[self selectedProperties] count];
    
    // update title count
    if (selectCount > 0) {
        self.title = [NSString stringWithFormat:NSLocalizedString(@"Selected %d Contacts", @"SelectContacts - Title: informs users number of selected contacts"), selectCount];
    }
    else {
        self.title = NSLocalizedString(@"Select Contacts", @"SelectContacts - title:");
    }
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    // should done be enabled
    //
    BOOL enableDone = NO;
    if (selectCount > 0) {
        // check if under free remaining sms count
        if (self.propertyType == kSelectContactPropertyTypeFreeSMS) {
            NSNumber *freeNum = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingFreeSMSLeftNumber];
            if (selectCount <= [freeNum intValue]) {
                enableDone = YES;
            }
        }
        else {
            enableDone = YES;
        }
    }
    self.navigationItem.rightBarButtonItem.enabled = enableDone;
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];


    // apply standard table configurations
    [AppUtility configTableView:self.tableView];
    
    
    if (!self.contactCellControllerD) {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.contactCellControllerD = newD;
        [newD release];
    }
    
    // setup search if not already
	[self setSearch];
    
    
    UIBarButtonItem *doneButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Done", @"StatusEdit - button: saves status to server") 
                                                      buttonType:kAUButtonTypeBarHighlight 
                                                          target:self action:@selector(pressDone:)];
    doneButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = doneButton;
    
    // show back button instead
    /*self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel", @"StatusEdit - button: cancel status edit") 
                                                        buttonType:kAUButtonTypeBarNormal 
                                                            target:self action:@selector(pressCancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    */
    
    // TODO: update to actual icon button
    /*UIBarButtonItem *addButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"+", @"StatusEdit - button: saves status to server") 
                                                     buttonType:kAUButtonTypeBarHighlight 
                                                         target:self action:@selector(pressAdd:)];
    self.navigationItem.rightBarButtonItem = addButton;
    */
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.contactCellControllerD = nil;
    [self unloadSearch];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"SCPC-vwa");
    [super viewWillAppear:animated];

    // update title and done button
    // - put here in case we leave this page and change the free sms count some where else
    //   since it is available in settings and add friend menus
    //
    [self updateViewUsingSelectCount];

}

- (void)viewDidAppear:(BOOL)animated
{
    DDLogInfo(@"SCPC-vda");

    [super viewDidAppear:animated];
    
    // start property query in background
    //
    [AppUtility startActivityIndicatorBackgroundAlpha:0.0];
    [self loadDataInBackGround];

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


#define NO_ITEM_TAG 15001

- (void) showNoItemView {
    // Show no item label
    //
    UIView *noItemView = [self.tableView viewWithTag:NO_ITEM_TAG];
    
    NSUInteger totalItems = [self.contactProperties count];
    
    if (totalItems == 0 && noItemView == nil) {        
        CGSize headerSize = self.tableView.tableHeaderView.frame.size;
        UILabel *noItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, headerSize.height, self.tableView.frame.size.width-40.0, self.tableView.frame.size.height-headerSize.height)];
        [AppUtility configLabel:noItemLabel context:kAULabelTypeNoItem];
        
        if (self.propertyType == kSelectContactPropertyTypeEmail) {
            noItemLabel.text = NSLocalizedString(@"No Emails", @"SelectContactProperty - text: Inform users that there are no emails available for selection");
        }
        else {
            noItemLabel.text = NSLocalizedString(@"No Phone Numbers", @"SelectContactProperty - text: Inform users that there are no phone numbers available for selection");
        }
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


/**
 Update data model and tell tableview to reload
 */
/*- (void) updateDataModel {
 
 // update data and then save to archive for later use
 //
 [self.collation syncLoadedData];
 [self.collation saveToArchive:kIndexCacheContactManagerFileName];
 
 // stop inidcator and udpate data
 
 [self.memberController stopActivityIndicator];
 [self.memberController reloadController];
 
 
 [[NSNotificationCenter defaultCenter] postNotificationName:MP_CONTACTMANAGER_RELOAD_NOTIFICATION object:nil];
 }*/

/*
 @abstract indexes contacts using collation object to properly order contacts for display
 
 
 */
- (void) startCollationIndexing {
    
    // collate objects
    //
    DDLogVerbose(@"SCP-si: Indexing started");
    
    
    // Load the cached collation and data model from file
	// 
	//if ([self.collation loadFromArchive:kIndexCacheContactManagerFileName]) {
    // do nothing
	//}
    
    SEL idSelector = @selector(propertyID);
    SEL idToObjectSelector = @selector(objectForKey:);
    TTCollationWrapper *newCollation = [[TTCollationWrapper alloc] initWithIDSelector:idSelector idToObjectSelector:idToObjectSelector];
    [newCollation assignObjectRepository:self.idToPropertyD];

    self.collation = newCollation;
    [newCollation release];
    [self.collation addSearchIcon:YES];
    
    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    
    dispatch_async(back_queue, ^{
        
        // *** Generate an ordered array of property objects *** //
        // start with unsorted list
        NSArray *workingList = [self.contactProperties allObjects];
        
        DDLogVerbose(@"SCP-si: total contacts %d", [workingList count]);
		
		
        DDLogVerbose(@"SCP: index start");
        // if we have people to index or memberList to prepend
        // 
        if ([workingList count] > 0) {
            
            /******************************************************
             Setup sectionsArray according to localized index collation
             - new method
             *****************************************************/
            
            
            // define section segregation selector
            //
            SEL sectionSelector = @selector(name);
            
            // should each section be split up into sub sections?
            // - so section "new york" & "new jersey" will be separate sections under on index section "n"
            //
            BOOL splitSection = NO;
            
            // how should each section be sorted
            // * try to use "name" selector if possible
            SEL sectionSortSelector = @selector(name);
            
            // index objects
            //
            [self.collation setupSectionsArrayWithObjects:workingList 
                                          sectionSelector:sectionSelector 
                                             sortSelector:sectionSortSelector 
                                             splitSection:splitSection];
            
            DDLogVerbose(@"SCP-si: index done");
        }
        
        // update data model in main thread
        // - wait in order to handover objects for thread safety
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // stop activity
            [AppUtility stopActivityIndicator];

            
            // update data and then save to archive for later use
            //
            [self.collation syncLoadedData];
            //[self.collation saveToArchive:kIndexCacheContactManagerFileName];
            
            // stop inidcator and udpate data
            /*
             [self.memberController stopActivityIndicator];
             [self.memberController reloadController];
             */
            
            // reload table to show new data
            [self.tableView reloadData];
            
            // show no items if needed
            //
            [self showNoItemView];
            
        });
    });
	
	DDLogVerbose(@"SCP-si: Indexing finished");
}


/*!
@abstract
*/
- (void) loadDataInBackGround {
    
    
    //[AppUtility startActivityIndicator:self.navigationController];
    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    
    dispatch_async(back_queue, ^{
        
        // load data from AB
        //
        MPContactManager *backCM = [AppUtility getBackgroundContactManager];
        if (self.propertyType == kSelectContactPropertyTypeEmail) {
            self.contactProperties = [NSSet setWithSet:[backCM getABEmailProperties]];
        }
        else {
            // for TW - restrict to only mobile numbers
            //
            self.contactProperties = [NSSet setWithSet:[backCM getABPhonePropertiesTWMobileOnly:[AppUtility isTWCountryCode]]];
        }
        
        // update in main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // create dictionary for objects
            //
            NSMutableDictionary *tempD = [[NSMutableDictionary alloc] init];
            
            for (ContactProperty *iProperty in self.contactProperties){
                [tempD setObject:iProperty forKey:iProperty.propertyID];
            }
            self.idToPropertyD = [NSDictionary dictionaryWithDictionary:tempD];
            [tempD release];
            
            // start collation
            //
            [self startCollationIndexing];
            
        });
        
    });
}






#pragma mark - Table Methods


/*!
 @abstract gets table cell associated with a particular contact
 */
- (SelectContactPropertyCellController *) cellControllerForContactProperty:(ContactProperty *)property {
    
    SelectContactPropertyCellController *cellController = [self.contactCellControllerD objectForKey:property.propertyID];
    
    if (!cellController) {
        SelectContactPropertyCellController *newController = [[SelectContactPropertyCellController alloc] initWithContactProperty:property];
        newController.delegate = self;
        
        [self.contactCellControllerD setObject:newController forKey:property.propertyID];
        [newController release];
        
        cellController = [self.contactCellControllerD objectForKey:property.propertyID];
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
        NSUInteger count = [self.collation sectionCount];
        return (count > 0) ? count : 1;
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
        return [self.filteredObjects count];
    }
    else
    {
        return [self.collation numberOfRowsInSection:section];
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)newTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	
	ContactProperty *cellObject = nil;
    
	// if the requesting tableview is from the search display controller, then use search data model objects
	//
    if (newTableView == self.searchDisplayController.searchResultsTableView)
    {
        NSUInteger row = [indexPath row];
        cellObject = [self.filteredObjects objectAtIndex:row];
    }
    else
    {
        cellObject = [self.collation objectAtIndexPath:indexPath];
    }
    
    SelectContactPropertyCellController *cellController = [self cellControllerForContactProperty:cellObject];
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

- (void)tableView:(UITableView *)newTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    ContactProperty *cellObject = nil;
    
	// if the requesting tableview is from the search display controller, then use search data model objects
	//
    if (newTableView == self.searchDisplayController.searchResultsTableView)
    {
        NSUInteger row = [indexPath row];
        cellObject = [self.filteredObjects objectAtIndex:row];
    }
    else
    {
        cellObject = [self.collation objectAtIndexPath:indexPath];
    }
    
    SelectContactPropertyCellController *cellController = [self cellControllerForContactProperty:cellObject];
    [cellController tableView:newTableView didSelectRowAtIndexPath:indexPath];
    
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
    return [self.collation titleForHeaderInSection:section];
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


// show index
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	
    // hide index during search
    if ([self.searchDisplayController isActive]) {
		return nil;
	}
    return [self.collation sectionIndexTitles];
}

// tell the table what to do when index is pressed, need to shift up of magnifying glass
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    
	NSInteger resultIndex = [self.collation sectionForSectionIndexTitleAtIndex:index];
 
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
    
    /*
     Update the filtered array based on the search text and scope.
     */
    
    [self.filteredObjects removeAllObjects]; // First clear the filtered array.
    
	NSArray *allObjects = [self.collation getAllObjects];
	
	if ([allObjects count] > 0){
		
		// for small lists, query built-in DB
		
		for (ContactProperty *iProperty in allObjects){
            
			NSString *searchString = [iProperty name];
			
			if (searchString) {
				if ([searchString rangeOfString:searchText
										options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)].location != NSNotFound)
				{
					[self.filteredObjects addObject:iProperty];
				}
			}
		}
	}
	
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
	DDLogInfo(@"SCP-US: unloading search items");
	
	[self.filteredObjects removeAllObjects];
	
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
		DDLogInfo(@"SCP-SS: search already exists, do nothing");
		return;
	}
	DDLogInfo(@"SCP-SS: setting up search");
	
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
	self.tableView.tableHeaderView = self.searchBar;
	
	//DDLogVerbose(@"MV-SS: after search bar add to header");
	// add search controller
	UISearchDisplayController *sController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
	self.searchController = sController;
	[sController release];
	self.searchController.delegate = self;
	self.searchController.searchResultsDataSource = self;
	self.searchController.searchResultsDelegate = self;
	
	
    // search bar appearance
	self.searchBar.tintColor = [AppUtility colorForContext:kAUColorTypeSearchBar];
	self.searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.searchController.searchResultsTableView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
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
    self.searchController.searchResultsTableView.rowHeight = kMPParamTableRowHeight;
	self.searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.searchController.searchResultsTableView.separatorColor =  [AppUtility colorForContext:kAUColorTypeTableSeparator];
	self.searchController.searchResultsTableView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
	
	// if search string is empty
	// - stop search and indicator
	if ([searchString length] == 0) {
        //[AppUtility stopActivityIndicator:self.navigationController];
		//[self.searchTimer invalidate];
	}
	else {
        //[AppUtility startActivityIndicator:self.navigationController];

        // parse in worker threads
        //
        NSString *searchString = [NSString stringWithString:self.searchBar.text];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

            DDLogVerbose(@"filter content - fire: %@", searchString);
            [self filterContentForSearchText:searchString];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //[AppUtility stopActivityIndicator:self.navigationController];
                [self.searchController.searchResultsTableView reloadData];
            });
        });
		
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
 @abstract Send results to delegate
 */
-(void)pressDone:(id)sender {
 
    if ([self.delegate respondsToSelector:@selector(SelectContactPropertyController:selectedProperties:propertyType:)]){
        
        // get selected properties
        NSArray *selected = [self selectedProperties];
        
        [self.delegate SelectContactPropertyController:self selectedProperties:selected propertyType:self.propertyType];        
    }
}

/*!
 @abstract Send results to delegate
 */
-(void)pressCancel:(id)sender {
    // if presented modally, we need to present done button
    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        [self dismissModalViewControllerAnimated:YES];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - SelectContactPropertyCellController




/*! respond to user selection */
- (void)SelectContactPropertyCellController:(SelectContactPropertyCellController *)controller didSelect:(BOOL)selected{
    
    [self updateViewUsingSelectCount];
    
    
    /*BOOL currentState = self.navigationItem.rightBarButtonItem.enabled;

    // enable and disable Done button
    //
    if (selected && currentState == NO) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else if(!selected && currentState == YES) {
        
        BOOL anyEnabled = NO;
        for (ContactProperty *iProperty in self.contactProperties){
            if (iProperty.isSelected == YES) {
                anyEnabled = YES;
                break;
            }
        }
        
        if (anyEnabled == NO) {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    }*/
}



@end

