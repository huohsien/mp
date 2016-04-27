//
//  PhoneBookController.m
//  mp
//
//  Created by Min Tsai on 1/26/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "PhoneBookController.h"

#import "TTCollationWrapper.h"
#import "ContactProperty.h"

#import "MPContactManager.h"
#import "MPFoundation.h"
#import "OperatorInfoCenter.h"

#import "PhoneBookInfoController.h"
#import "CDContact.h"


#define NO_ITEM_TAG             150001
#define AUTO_SYNC_BTN_TAG       150003
#define AUTOSYNC_ALERT_TAG      150004
#define ACTIVITY_INDICATOR_TAG  150005

NSString* const kPBIndexCacheFilename = @"pb_index.cache";


@interface PhoneBookController (PrivateMethods)
- (void)loadDataInBackGround;
- (void)setSearch;
- (void)setTableViewHeader;
- (void) reloadData:(NSNotification *)notification;
@end


@implementation PhoneBookController

@synthesize contactProperties;
@synthesize collation;
@synthesize idToPropertyD;
@synthesize filteredObjects;

@synthesize contactCellControllerD;
@synthesize phoneToContactD;

@synthesize searchBar;
@synthesize searchController;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
        NSMutableArray *objects = [[NSMutableArray alloc] init];
        self.filteredObjects = objects;
        [objects release];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // clear out search delegates
    [self unloadSearch];
    
    [contactProperties release];
    [collation release];
    [idToPropertyD release];
    [filteredObjects release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Tool

/*!
 @abstract Gets last 6 characters or less
 
 @param string Input string
 @return nil if failed, substring if successful
 
 Use:
 - get phoneKey for use in dictionary
 
 */
- (NSString *) last6CharsOfString:(NSString *)string {
    
    NSInteger length = [string length];
    NSString *subString = nil;
    
    if (length > 0 ) {
        NSInteger startIndex = 0;
        if (length > 6) {
            startIndex = length - 6;
        }
        subString = [string substringFromIndex:startIndex];
    }
    return subString;
}



#pragma mark - Default Labels Methods


- (void) showNoItemView {
    // Show no item label
    //
    UILabel *noItemView = (UILabel *)[self.tableView viewWithTag:NO_ITEM_TAG];
    UIView *buttonView = [self.tableView viewWithTag:AUTO_SYNC_BTN_TAG];
    
    
    NSUInteger totalItems = [self.contactProperties count];
    if (totalItems == 0) {
        
        
        CGSize headerSize = self.tableView.tableHeaderView.frame.size;
        CGRect labelRect = CGRectMake(20.0, headerSize.height, 
                                      self.tableView.frame.size.width-40.0, self.tableView.frame.size.height-headerSize.height);
        NSString *labelText = NSLocalizedString(@"No Contacts", @"PhoneBook - text: Inform users that there are no phone contacts");
        
        // if auto sync is off
        NSNumber *isAutoSyncOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAddressBookIsAllowed];
        if (![isAutoSyncOn boolValue]) {
            labelRect = CGRectMake(20.0, floor(self.tableView.frame.size.height/2.0) - 30.0, 
                                   self.tableView.frame.size.width-40.0, 30.0);
            labelText = NSLocalizedString(@"Import Contacts", @"PhoneBook - text: Instruct users to import contacts if auto sync is off");
            
            if (buttonView == nil) {
                CGFloat buttonWidth = 90.0;
                CGFloat buttonHeight = 30.0;
                
                UIButton *startButton = [[UIButton alloc] initWithFrame:CGRectMake( (self.tableView.frame.size.width-buttonWidth)/2.0, floor(self.tableView.frame.size.height/2.0)+5.0, buttonWidth, buttonHeight)];
                
                [AppUtility configButton:startButton context:kAUButtonTypeGreen];
                
                [startButton setTitle:NSLocalizedString(@"Start", @"PhoneBook - button: Start import contacts") forState:UIControlStateNormal];
                [startButton addTarget:self action:@selector(pressAutoSync:) forControlEvents:UIControlEventTouchUpInside];
                startButton.tag = AUTO_SYNC_BTN_TAG;
                [self.tableView addSubview:startButton];
                [startButton release];
            }
        }
        else {
            [buttonView removeFromSuperview];
        }
        
        if (noItemView == nil) {
            UILabel *noItemLabel = [[UILabel alloc] initWithFrame:labelRect];
            [AppUtility configLabel:noItemLabel context:kAULabelTypeNoItem];
            noItemLabel.text = labelText;
            noItemLabel.tag = NO_ITEM_TAG;
            [self.tableView addSubview:noItemLabel];
            [noItemLabel release];
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        }
        // if view exists refresh it in case it change from "import contact" to "no contacts"
        else {
            noItemView.frame = labelRect;
            noItemView.text = labelText;
        }
    }
    else if (totalItems > 0) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [noItemView removeFromSuperview];
        [buttonView removeFromSuperview];
    }
}

/*!
 @abstract Remove import contact and button if address book access is not available
 
 Use:
 - check when data starts to load
 
 */
- (void) removeNoItemViewIfAddressBookAvailable {
    // Show no item label
    //
    UILabel *noItemView = (UILabel *)[self.tableView viewWithTag:NO_ITEM_TAG];
    UIView *buttonView = [self.tableView viewWithTag:AUTO_SYNC_BTN_TAG];
    
    
    // if auto sync is off, then remove button and label
    NSNumber *isAutoSyncOn = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAddressBookIsAllowed];
    if ([isAutoSyncOn boolValue] && buttonView) {
        [noItemView removeFromSuperview];
        [buttonView removeFromSuperview];
    }
}


/*!
 @abstract Alert switch 
 */
- (void) pressAutoSync:(id) sender {
    
    [AppUtility askAddressBookAccessPermissionAlertDelegate:self alertTag:AUTOSYNC_ALERT_TAG];
    
}




#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	NSInteger cancelIndex = [alertView cancelButtonIndex];
    
    if (alertView.tag == AUTOSYNC_ALERT_TAG) {        
        // - reload Phonebook view
        if (buttonIndex != cancelIndex) {
            
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingAddressBookIsAllowed settingValue:[NSNumber numberWithBool:YES]];
            
            // start loading phonebook
            [self loadDataInBackGround];
            
            // also sync friend list as well
            [MPContactManager tryStartingPhoneBookSyncForceStart:YES delayed:NO];
            
        }
    }
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Phonebook", @"SelectContacts - title:");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    [AppUtility configTableView:self.tableView];    
    
    
    if (!self.contactCellControllerD) {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.contactCellControllerD = newD;
        [newD release];
    }
    
    // setup search if not already
	[self setSearch];
    
    
    // loading indicator
    UIActivityIndicatorView *loadingActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    loadingActivityIndicator.hidesWhenStopped = YES;
    loadingActivityIndicator.tag = ACTIVITY_INDICATOR_TAG;
    [self.tableView addSubview:loadingActivityIndicator];
    [loadingActivityIndicator release];
    
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
    DDLogInfo(@"PBC-vwa");

    [super viewWillAppear:animated];
    
    // check if view is entering foreground and this view is already visible
    // - reload AB property data, so newest phonebook changes are reflected
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadDataInBackGround)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    
    // reload operator info if a fresh query is made
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData:) name:MP_OPERATORINFO_UPDATE_ALL_NOTIFICATION object:nil];
    
    // reload if M+ contacts are updated
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(reloadData:) name:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:nil];
    


    // creates contact dictionary
    // - key: last 6 digits or less
    // - value: CDContact
    // - refreshed everytime we enter this view
    //
    if (!self.phoneToContactD) {
        
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.phoneToContactD = newD;
        [newD release];
        NSArray *allContacts = [CDContact allContacts];
        for (CDContact *iContact in allContacts) {
            NSString *last6Phone = [self last6CharsOfString:iContact.registeredPhone];
            NSString *recordID = [iContact.abRecordID stringValue];
            
            if ([last6Phone length] > 0 && [recordID length] > 0) {
                NSString *phoneKey = [NSString stringWithFormat:@"%@%@", last6Phone, recordID];
                if ([phoneKey length] > 0) {
                    [self.phoneToContactD setValue:iContact forKey:phoneKey];
                }
            }
            
        }
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // start property query in background
    //
    [self loadDataInBackGround];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // don't observer if we are not visible
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
}


#pragma mark - Data Model



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
    DDLogVerbose(@"PB-si: Indexing started");
    
    
    SEL idSelector = @selector(propertyID);
    SEL idToObjectSelector = @selector(objectForKey:);
    TTCollationWrapper *newCollation = [[TTCollationWrapper alloc] initWithIDSelector:idSelector idToObjectSelector:idToObjectSelector];
    [newCollation assignObjectRepository:self.idToPropertyD];
    
    
    [newCollation addSearchIcon:YES];
    
    // Load the cached collation and data model from file
	// 
	if ([newCollation loadFromArchive:kPBIndexCacheFilename]) {
        // do nothing
	}
    
    /* Don't modify collation yet since we need to process this in the background thread and this is not safe.
       Instead process the collation and assign it in the main thread when we are done.*/
    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    
    dispatch_async(back_queue, ^{
        
        // *** Generate an ordered array of property objects *** //
        // start with unsorted list
        NSArray *workingList = [self.contactProperties allObjects];
        
        DDLogVerbose(@"PB-si: total contacts %d", [workingList count]);
		
		
        DDLogVerbose(@"PB: index start");
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
            SEL sectionSortSelector = NULL; // @selector(name);
            
            // actually sort by name and then the value of the property
            NSSortDescriptor *nameSort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
            NSSortDescriptor *secondSort = [[NSSortDescriptor alloc] initWithKey:@"value" ascending:YES];
            
            NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:nameSort, secondSort, nil];
            [nameSort release];
            [secondSort release];
            
            // index objects
            //
            [newCollation setupSectionsArrayWithObjects:workingList 
                                          sectionSelector:sectionSelector 
                                             sortSelector:sectionSortSelector 
                                          sortDescriptors:sortDescriptors 
                                             splitSection:splitSection];
            [sortDescriptors release];
            
            DDLogVerbose(@"PB-si: index done");
        }
        
        // update data model in main thread
        // - wait in order to handover objects for thread safety
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // stop activity
            //[AppUtility stopActivityIndicator];
            
            
            // update data and then save to archive for later use
            //
            [newCollation syncLoadedData];
            [newCollation saveToArchive:kPBIndexCacheFilename];
            self.collation = newCollation;
            [newCollation release];
            
            // reload table to show new data
            [self reloadData:nil];
            
            UIActivityIndicatorView *loadingActivityIndicator = (UIActivityIndicatorView *)[self.tableView viewWithTag:ACTIVITY_INDICATOR_TAG];
            [loadingActivityIndicator stopAnimating];
            
        });
    });
	
	DDLogVerbose(@"PB-si: Indexing finished");
}


/*!
 @abstract
 */
- (void) loadDataInBackGround {
    
    UIActivityIndicatorView *loadingActivityIndicator = (UIActivityIndicatorView *)[self.tableView viewWithTag:ACTIVITY_INDICATOR_TAG];
    loadingActivityIndicator.center = self.tableView.center;
    [loadingActivityIndicator startAnimating];

    [self removeNoItemViewIfAddressBookAvailable];
    
    //[AppUtility startActivityIndicator:self.navigationController];
    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    
    dispatch_async(back_queue, ^{
        
        // load data from AB
        //
        MPContactManager *backCM = [AppUtility getBackgroundContactManager];
        self.contactProperties = [NSSet setWithSet:[backCM getABPhonePropertiesTWMobileOnly:NO]];
        
        //@TEST no item
        //self.contactProperties = [NSSet set];
        
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
- (PhoneBookCellController *) cellControllerForContactProperty:(ContactProperty *)property {
    
    PhoneBookCellController *cellController = [self.contactCellControllerD objectForKey:property.propertyID];
    
    if (!cellController) {
        // get associated contact first
        //
        NSString *last6Phone = [self last6CharsOfString:property.value];
        NSString *recordID = [property.abRecordID stringValue];
        NSString *phoneKey = [NSString stringWithFormat:@"%@%@", last6Phone, recordID];

        CDContact *associatedContact = [self.phoneToContactD valueForKey:phoneKey];
        
        // don't associate cancelled accounts
        if ([associatedContact isUserAccountedCanceled]) {
            associatedContact = nil;
        }
        
        PhoneBookCellController *newController = [[PhoneBookCellController alloc] initWithPhoneProperty:property associatedContact:associatedContact];
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
	//DDLogVerbose(@"MVCFR: ping");
    
	
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
    
    PhoneBookCellController *cellController = [self cellControllerForContactProperty:cellObject];
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
    
    PhoneBookCellController *cellController = [self cellControllerForContactProperty:cellObject];
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




#pragma mark - Generic Table Methods

/*!
 @abstract Reload contact data
 
 If friend data was updated:
 - refresh the rows for these contacts
 
 */
- (void) reloadData:(NSNotification *)notification {
    
    //[self constructTableGroups];
    //NSSet *contactIDs = [notification object];
    
    // clear contact dictionary
    self.phoneToContactD = nil;
    
    NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
    self.phoneToContactD = newD;
    [newD release];
    NSArray *allContacts = [CDContact allContacts];
    for (CDContact *iContact in allContacts) {
        NSString *last6Phone = [self last6CharsOfString:iContact.registeredPhone];
        NSString *recordID = [iContact.abRecordID stringValue];
        
        if ([last6Phone length] > 0 && [recordID length] > 0) {
            NSString *phoneKey = [NSString stringWithFormat:@"%@%@", last6Phone, recordID];
            if ([phoneKey length] > 0) {
                [self.phoneToContactD setValue:iContact forKey:phoneKey];
            }
        }
        
    }

    [self.contactCellControllerD removeAllObjects];
    [self.tableView reloadData];    
    
    [self showNoItemView];
}



#pragma mark - Content Filtering

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



#pragma mark - Search and UISearchDisplayController Delegate Methods

/**
 unload search objects
 
 Usage:
 - help remove old search objects that are no longer needed
 - if not done, then old search controllers showup when view is reloaded
 */
- (void)unloadSearch {
	DDLogInfo(@"PB-US: unloading search items");
	
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
		DDLogInfo(@"PB-SS: search already exists, do nothing");
		return;
	}
	DDLogInfo(@"PB-SS: setting up search");
	
	// add search bar to top
	CGRect searchRect = CGRectMake(0, 0, 320, 40);
	
	UISearchBar *sBar = [[UISearchBar alloc] initWithFrame:searchRect];
	self.searchBar = sBar;
	[sBar release];
	self.searchBar.placeholder = NSLocalizedString(@"Search Contacts", @"Search Placeholder: prompts user to enter search string for phonebook contacts");
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

#pragma mark - PhoneBookCellController


/*!
 @abstract Called when contact cell needs to be refreshed.
 
 Refresh needed when:
 - operator info updated
 - presence info updated
 - etc.
 
 The table will then:
 - figure out if this controller is visible
 - if visible then refresh it
 
 */
- (void)PhoneBookCellController:(PhoneBookCellController *)controller refreshProperty:(ContactProperty *)property {
    
    NSIndexPath *propertyIP = nil;
    
    // find the index path
    if (self.tableView == self.searchDisplayController.searchResultsTableView)
    {
        NSInteger rowLocation = [self.filteredObjects indexOfObject:property];
        if (rowLocation != NSNotFound) {
            propertyIP = [NSIndexPath indexPathForRow:rowLocation inSection:0];
        }
    }
    else
    {
        propertyIP = [self.collation indexPathForObject:property];
    }
    
    // if IP visible then refresh it
    if ([Utility isIndexPath:propertyIP inIndexPaths:[self.tableView indexPathsForVisibleRows]]) {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:propertyIP] withRowAnimation:UITableViewRowAnimationNone];
    }
    
}


/*!
 @abstract Call when contact property is tapped
 - Table should push this contact's info on to navigation stack
 
 */
- (void)PhoneBookCellController:(PhoneBookCellController *)controller tappedContactProperty:(ContactProperty *)property contact:(CDContact *)contact operatorNumber:(NSNumber *)operatorNumber {
    
    NSUInteger viewCount = [self.navigationController.viewControllers count];
    
    // only push on top of root
    // - if there is another chat, don't push another
    // - this can happen if users tap very quickly on the tableview - more of a iOS bug
    //
    if (viewCount == 1) {
        PhoneBookInfoController *nextController = [[PhoneBookInfoController alloc] initWithPhoneProperty:property operatorNumber:operatorNumber mpContact:contact];
        [self.navigationController pushViewController:nextController animated:YES];
        [nextController release];
    }
    
}


@end

