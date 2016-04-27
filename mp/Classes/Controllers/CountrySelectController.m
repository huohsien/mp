//
//  CountrySelectController.m
//  mp
//
//  Created by M Tsai on 11-10-17.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "CountrySelectController.h"
#import "AppUtility.h"
#import "TKLog.h"
#import "TTCollationWrapper.h"
#import "CountryInfo.h"


@implementation CountrySelectController

@synthesize delegate;
@synthesize isoCodeToCountryD;
@synthesize collation;
@synthesize filteredObjects;
@synthesize cellControllerD;

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
    
    // clear out search delegates
    [self unloadSearch];
    
    delegate = nil;
    
    [isoCodeToCountryD release];
    [collation release];
    [filteredObjects release];
    
    [cellControllerD release];
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Select Country", @"Select Country - title: view that ask users to select their cell provider country");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    //[AppUtility configTableView:self.tableView];    
    
    // add next navigation button
    //
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel",  @"Select Country - Button: cancel selection") 
                                                        buttonType:kAUButtonTypeBarNormal 
                                                            target:self action:@selector(pressCancel:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
        
    [self setSearch];
    
    
    if (!self.cellControllerD) {
        NSMutableDictionary *newD = [[NSMutableDictionary alloc] init];
        self.cellControllerD = newD;
        [newD release];
    }

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [self unloadSearch];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // start loading in data model
    //
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

/*!
 @abstract Reload table data model
 
 */
- (void) reloadData { 
    
    // update tables view
    //[self.contactCellControllerD removeAllObjects];
    [self.tableView reloadData];    
    
}

/*!
 @abstract create an array of countryinfo objects
 */
- (NSArray *) countryInfos {
    
    NSError *error = nil;
    
    // format of file:
    // country name, 2letter code, phone code
    //
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"CountryData" ofType:@"csv"];	
	NSString *readStrings = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
	
	NSArray *lines = [readStrings componentsSeparatedByString:@"\r\n"];
	NSLog(@"lines: %d %@", [lines	count], error);
    
    NSMutableArray *infos = [[[NSMutableArray alloc] init] autorelease];
    
    for (NSString *line in lines){
		
        NSArray *words = [line componentsSeparatedByString:@","];
        NSString *name = [words objectAtIndex:0];
        NSString *isoCode = [words objectAtIndex:1];
        NSString *phoneCode = [words objectAtIndex:2];
        
        CountryInfo *iCountryInfo = [[CountryInfo alloc] initWithName:name isoCode:isoCode phoneCountryCode:phoneCode];
        [infos addObject:iCountryInfo];
        [iCountryInfo release];
        
    }
    [readStrings release];
    
    return infos;
}

/*
 @abstract indexes contacts using collation object to properly order contacts for display
 
 
 */
- (void) startCollationIndexing {
    
    // collate objects
    //
    DDLogVerbose(@"CS-si: Indexing started");
    
    SEL idSelector = @selector(isoCode);
    SEL idToObjectSelector = @selector(objectForKey:);
    TTCollationWrapper *newCollation = [[TTCollationWrapper alloc] initWithIDSelector:idSelector idToObjectSelector:idToObjectSelector];
    [newCollation assignObjectRepository:self.isoCodeToCountryD];
    
    
    [newCollation addSearchIcon:YES];
    
    // Load the cached collation and data model from file
	// 
	/*if ([newCollation loadFromArchive:kPBIndexCacheFilename]) {
        // do nothing
	}*/

    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    
    dispatch_async(back_queue, ^{
        
        // *** Generate an ordered array of property objects *** //
        // start with unsorted list
        NSArray *workingList = [self countryInfos];
        
        DDLogVerbose(@"CS-si: total countries %d", [workingList count]);
		
		
        DDLogVerbose(@"CS: index start");
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
            [newCollation setupSectionsArrayWithObjects:workingList 
                                        sectionSelector:sectionSelector 
                                           sortSelector:sectionSortSelector 
                                        sortDescriptors:nil 
                                           splitSection:splitSection];
            
            // prepend initial list of countries
            /*
             Taiwan
             HongKong
             China
             Singapore
             Korea
             Japan
             */
            CountryInfo *infoTW =  [newCollation.objectsRepository objectForKey:@"TW"];
            CountryInfo *infoHK =  [newCollation.objectsRepository objectForKey:@"HK"];
            CountryInfo *infoCN =  [newCollation.objectsRepository objectForKey:@"CN"];
            CountryInfo *infoSG =  [newCollation.objectsRepository objectForKey:@"SG"];
            CountryInfo *infoKR =  [newCollation.objectsRepository objectForKey:@"KR"];
            CountryInfo *infoJP =  [newCollation.objectsRepository objectForKey:@"JP"];
            
            NSArray *preCountries = [NSArray arrayWithObjects:infoTW, infoHK, infoCN, infoSG, infoKR, infoJP, nil];
            [newCollation prependSectionTitle:@"" sectionIndexTitle:@"★" objectArray:preCountries];
            
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
            //[newCollation saveToArchive:kPBIndexCacheFilename];
            self.collation = newCollation;
            [newCollation release];
            //[self.collation syncLoadedData];
            //[self.collation saveToArchive:kPBIndexCacheFilename];
            
            // reload table to show new data
            [self reloadData];
        });
    });
	
	DDLogVerbose(@"CS-si: Indexing finished");
}


/*!
 @abstract
 */
- (void) loadDataInBackGround {
    
    //[AppUtility startActivityIndicator:self.navigationController];
        
    dispatch_async(dispatch_get_current_queue(), ^{
        
        // load data from AB
        //
        NSArray *countryInfos = [self countryInfos];
        
        // update in main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // create dictionary for objects
            //
            NSMutableDictionary *tempD = [[NSMutableDictionary alloc] init];
            
            for (CountryInfo *iInfo in countryInfos){
                [tempD setObject:iInfo forKey:iInfo.isoCode];
            }
            self.isoCodeToCountryD = [NSDictionary dictionaryWithDictionary:tempD];
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
- (CountryCellController *) cellControllerForCountryInfo:(CountryInfo *)countryInfo {
    
    CountryCellController *cellController = [self.cellControllerD objectForKey:countryInfo.isoCode];
    
    if (!cellController) {
        
        CountryCellController *newController = [[CountryCellController alloc] initWithCountryInfo:countryInfo];
        newController.delegate = self;
        
        [self.cellControllerD setObject:newController forKey:countryInfo.isoCode];
        [newController release];
        
        cellController = [cellControllerD objectForKey:countryInfo.isoCode];
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
    if (tableView == self.searchController.searchResultsTableView)
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
    if (tableView == self.searchController.searchResultsTableView)
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
    
	CountryInfo *cellObject = nil;
    
	// if the requesting tableview is from the search display controller, then use search data model objects
	//
    if (newTableView == self.searchController.searchResultsTableView)
    {
        NSUInteger row = [indexPath row];
        cellObject = [self.filteredObjects objectAtIndex:row];
    }
    else
    {
        cellObject = [self.collation objectAtIndexPath:indexPath];
    }
    
    CountryCellController *cellController = [self cellControllerForCountryInfo:cellObject];
    UITableViewCell *cell = [cellController tableView:newTableView cellForRowAtIndexPath:indexPath];
    
    return cell;
}


- (void)tableView:(UITableView *)newTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CountryInfo *cellObject = nil;
    
	// if the requesting tableview is from the search display controller, then use search data model objects
	//
    if (newTableView == self.searchController.searchResultsTableView)
    {
        NSUInteger row = [indexPath row];
        cellObject = [self.filteredObjects objectAtIndex:row];
    }
    else
    {
        cellObject = [self.collation objectAtIndexPath:indexPath];
    }
    
    CountryCellController *cellController = [self cellControllerForCountryInfo:cellObject];
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
    if ([self.searchController isActive]) {
		return nil;
	}
    return [self.collation titleForHeaderInSection:section];
}


/**
 Specify the space allocated IF a footer is specified for the section
 */
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 0.0;
}

/**
 Add a small gap after top contacts section
 */
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

//
// Specify the space allocated IF a header is specified for the section
//
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    if ([title length] > 0) {
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
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, 150, 15.0)];
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
    if ([self.searchController isActive]) {
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


#pragma mark - Buttons

/*!
 @abstract cancel selection
 */
- (void) pressCancel:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark - CountryCellController Delegate

/*!
 @abstract after country selection, dismiss this view and send back results
 */
- (void)countryCellController:(CountryCellController *)cellController selectedCountryCode:(NSString *)countryCode {
    
    if([self.delegate respondsToSelector:@selector(countrySelectController:selectedCountryIsoCode:)]) {
        [self.delegate countrySelectController:self selectedCountryIsoCode:countryCode];
    }
}


#pragma mark - Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText
{
    /*
     Update the filtered array based on the search text and scope.
     */
    
    [self.filteredObjects removeAllObjects]; // First clear the filtered array.
    
    // strip out prepend countries
    //
    NSArray *allAndPrepend = [self.collation getAllObjects];
	NSArray *allObjects = [allAndPrepend subarrayWithRange:NSMakeRange(6, [allAndPrepend count] - 6)];
	
	if ([allObjects count] > 0){
		
		// for small lists, query built-in DB
		
		for (CountryInfo *iInfo in allObjects){
            
			NSString *searchString = iInfo.name;
			
			if (searchString) {
				if ([searchString rangeOfString:searchText
										options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)].location != NSNotFound)
				{
					[self.filteredObjects addObject:iInfo];
				}
			}
		}
	}
	
}



#pragma mark - Search and UISearchDisplayController Delegate Methods

/*!
 unload search objects
 
 Usage:
 - help remove old search objects that are no longer needed
 - if not done, then old search controllers showup when view is reloaded
 */
- (void) unloadSearch {
	DDLogInfo(@"CS-US: unloading search items");
	
	//[self.memberManager removeAllFilteredPersons];
	
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
- (void) setSearch {
	
	// if search exists then do nothing
	if (searchBar && searchController) {
		DDLogInfo(@"CS-SS: search already exists, do nothing");
		return;
	}
	DDLogInfo(@"CS-SS: setting up search");
	
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
	
	
	// adjust visuals
    self.searchBar.tintColor = [AppUtility colorForContext:kAUColorTypeSearchBar];
	self.searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	//self.searchController.searchResultsTableView.backgroundColor = [AppUtility darkCharcoalColor];
}


/**
 Search string just changed
 */
- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	// reset table colors here
	// - it seems that a new table is sometimes created, so we need to reapply color here
	//
	self.searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	//self.searchController.searchResultsTableView.backgroundColor = [AppUtility darkCharcoalColor];
	
    [self filterContentForSearchText:searchString];
    
    /*
	// if search string is empty
	// - stop search and indicator
	if ([searchString length] == 0) {
		[self stopActivityIndicator];
		[self.searchTimer invalidate];
	}
	else {
		[self startActivityIndicator];
		
		// invalidate old timer and create a new one
		[self.searchTimer invalidate];
		self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:kSearchTimer target:self selector:@selector(filterContent) userInfo:nil repeats:NO];
	}
    */
    
	//[self filterContent];
	
	//[self filterContentForSearchText:searchString scope:
	// [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
	
    // Return YES to cause the search result table view to be reloaded.
	// Return NO for asynchronous search, reload search tableview at a later time
    return YES;
}

/**
 Search Ended
 - scroll to the last person
 */
- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
	
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
- (void) searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
	if(self.navigationController.navigationBar.hidden == YES){
		[self.navigationController setNavigationBarHidden:NO animated:YES];
	}
}



@end
