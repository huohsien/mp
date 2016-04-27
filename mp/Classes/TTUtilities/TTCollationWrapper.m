//
//  TTLoclizedIndexedCollation.m
//  ContactBook
//
//  Created by M Tsai on 4/26/10.
//  Copyright 2010 TernTek. All rights reserved.
//

#import "TTCollationWrapper.h"
#import "Utility.h"
#import "TTLocalizedIndexedCollation.h"
#import "TKLog.h"



@implementation TTCollationWrapper

@dynamic sectionCount;
@dynamic sectionTitles;
@dynamic sectionIndexTitles;

@synthesize collation;
@synthesize addSearch;
@synthesize sectionsArray;

@synthesize prependSectionTitles;
@synthesize prependSectionIndexTitles;
@synthesize appendSectionTitles;
@synthesize appendSectionIndexTitles;

@synthesize splitSectionTitles;
@synthesize splitSectionIndexMap;

@synthesize loadSectionsArray;
@synthesize loadPrependSectionTitles;
@synthesize loadPrependSectionIndexTitles;
@synthesize loadAppendSectionTitles;
@synthesize loadAppendSectionIndexTitles;
@synthesize loadSplitSectionTitles;
@synthesize loadSplitSectionIndexMap;

@synthesize objectsRepository;
@synthesize numIDSelector;
@synthesize numIDToObjectSelector;

@synthesize collationSectionTitlesCache;
@synthesize parentOperation;

/*!
 @abstract Initialize Collation
 
 @param idSelector used to obtain ID from an object
 @param idToObjectSelector used to obtain an object give an ID
 
 */
- (id)initWithIDSelector:(SEL)newIDSelector idToObjectSelector:(SEL)newIDToObjectSelector
{
	if ((self = [super init])) {
		//collation = [[UILocalizedIndexedCollation currentCollation] retain];
		collation = [[TTLocalizedIndexedCollation alloc] init];
		
        // start with empty data model
        // - but make sure you load the data model before using this collation
        // - so set data model before you load in new section array
        //
        self.objectsRepository = nil;
		self.numIDSelector = newIDSelector;
		self.numIDToObjectSelector = newIDToObjectSelector;
		
		addSearch = NO;
		
		sectionsArray = [[NSMutableArray alloc] init];
		
		// Set up the sections array: elements are mutable arrays that will contain the Person objects for that section.
		for (NSString *iSection in [self sectionTitles]) {
			NSMutableArray *array = [[NSMutableArray alloc] init];
			[sectionsArray addObject:array];
			[array release];
		}
		
		prependSectionTitles = [[NSMutableArray alloc] init];
		prependSectionIndexTitles = [[NSMutableArray alloc] init];
		
		appendSectionTitles = [[NSMutableArray alloc] init];
		appendSectionIndexTitles = [[NSMutableArray alloc] init];
		
		splitSectionTitles = [[NSMutableArray alloc] init];
		splitSectionIndexMap = [[NSMutableArray alloc] init];
		
		loadPrependSectionTitles = [[NSMutableArray alloc] init];
		loadPrependSectionIndexTitles = [[NSMutableArray alloc] init];
		
		loadAppendSectionTitles = [[NSMutableArray alloc] init];
		loadAppendSectionIndexTitles = [[NSMutableArray alloc] init];
		
		loadSplitSectionTitles = [[NSMutableArray alloc] init];
		loadSplitSectionIndexMap = [[NSMutableArray alloc] init];
		
		self.collationSectionTitlesCache = nil;
		self.parentOperation = nil;
	}
	return self;
}

- (void)dealloc;
{
    [objectsRepository release];
	[collation release];
	[sectionsArray release];
	
	[prependSectionTitles release];
	[prependSectionIndexTitles release];
	
	[appendSectionTitles release];
	[appendSectionIndexTitles release];
	
	[splitSectionTitles release];
	[splitSectionIndexMap release];
	
	[loadSectionsArray release];
	[loadPrependSectionTitles release];
	[loadPrependSectionIndexTitles release];
	[loadAppendSectionTitles release];
	[loadAppendSectionIndexTitles release];
	[loadSplitSectionTitles release];
	[loadSplitSectionIndexMap release];
	
	[collationSectionTitlesCache release];
	[parentOperation release];
	[super dealloc];
}

#pragma mark - Setup Methods

/*!
 @abstract assign a new repository
 */
- (void) assignObjectRepository:(id)newLibraryTarget {
    
    self.objectsRepository = newLibraryTarget;
    
}

/**
 Reset the collation and remove any customization
 - clear the prepend attributes
 */
- (void) resetLoadAttributes {
	[self.loadSectionsArray removeAllObjects];
	[self.loadPrependSectionTitles removeAllObjects];
	[self.loadPrependSectionIndexTitles removeAllObjects];
	[self.loadAppendSectionTitles removeAllObjects];
	[self.loadAppendSectionIndexTitles removeAllObjects];
	[self.loadSplitSectionTitles removeAllObjects];
	[self.loadSplitSectionIndexMap removeAllObjects];
}

/**
 Copy load to currently used data model
 - loadSectionsArray objects are transformed to recordID for sectionsArray
 
 Usage:
 - run after completely finishing loading data model and making any additional changes
 
 Used:
 - executed in Main thread to for thread safety

 */
- (void) syncLoadedData {
	// copy section recordIDs
	//
	[self.sectionsArray removeAllObjects];
	for (NSMutableArray *iArray in self.loadSectionsArray){
		NSMutableArray *newArray = [[NSMutableArray alloc] init];
		for (id iObject in iArray){
			[newArray addObject:[iObject performSelector:self.numIDSelector]];
		}
		[self.sectionsArray addObject:newArray];
		[newArray release];
	}
	
	self.prependSectionTitles = self.loadPrependSectionTitles;
	self.prependSectionIndexTitles = self.loadPrependSectionIndexTitles;
	self.appendSectionTitles = self.loadAppendSectionTitles;
	self.appendSectionIndexTitles = self.loadAppendSectionIndexTitles;
	self.splitSectionTitles = self.loadSplitSectionTitles;
	self.splitSectionIndexMap = self.loadSplitSectionIndexMap;
	
	self.loadPrependSectionTitles = nil;
	self.loadPrependSectionIndexTitles = nil;
	self.loadAppendSectionTitles = nil;
	self.loadAppendSectionIndexTitles = nil;
	self.loadSplitSectionTitles = nil;
	self.loadSplitSectionIndexMap = nil;
	
	loadPrependSectionTitles = [[NSMutableArray alloc] init];
	loadPrependSectionIndexTitles = [[NSMutableArray alloc] init];
	loadAppendSectionTitles = [[NSMutableArray alloc] init];
	loadAppendSectionIndexTitles = [[NSMutableArray alloc] init];
	loadSplitSectionTitles = [[NSMutableArray alloc] init];
	loadSplitSectionIndexMap = [[NSMutableArray alloc] init];		
}

/*!
 @abstract setupSectionsArray
 - sort and populate the section array according to the arguments
 - resulting section array will reflect the organization of the tableview it supports
 
 Arguments:
 @param objects				array of objects to fill sectionsArray with
 @param sectionSelector		selector used on object to determine which section it belongs
 @param sortSelector		selector used to sort objects in each array
 @param sortDescriptors     defined if secondary sort needed (optional)
 
 @param splitSection			further splits each section unique sectionSelector results 
						will have it's own section.  This means:
						- section title will be these unqiue string and not from collation
						- more sections may exists than collation index entries
						* acts like splitting each section into sub section for each collation section
 

						
 */
- (void) setupSectionsArrayWithObjects:(NSArray *)objects 
					   sectionSelector:(SEL)sectionSelector 
						  sortSelector:(SEL)sortSelector 
                       sortDescriptors:(NSArray *)sortDescriptors
						  splitSection:(BOOL)splitSection 
{
	DDLogVerbose(@"CW-ss: start");
	
	// init and reset
	//
	NSMutableArray *naArray = [[NSMutableArray alloc] init];
	[self resetLoadAttributes];
	// clears titles cache
	self.collationSectionTitlesCache = nil;
	// clears collation cache in case language changes
	[self.collation resetCache];
	
	// generate sectionsArray
	//
	NSInteger index, sectionTitlesCount = [self.collationSectionTitlesCache count];
	//NSInteger indexTitleCount = [[self.collation sectionIndexTitles] count];
	//DDLogVerbose(@"%@", [self.collation sectionTitles]);
	NSMutableArray *newSectionsArray = [[NSMutableArray alloc] init];
	
	// Set up the sections array: elements are mutable arrays that will contain the Person objects for that section.
	for (index = 0; index < sectionTitlesCount; index++) {
		NSMutableArray *array = [[NSMutableArray alloc] init];
		[newSectionsArray addObject:array];
		[array release];
	}
	
	
	DDLogVerbose(@"CW-ss: setup fin");
	// separate into collation sections with section selector
	// - if split also provide a NA section for orphan objects that dont belong to any section
	//
	for (id iObject in objects) {
		
		BOOL sortObject = YES;
		
		// check if selector value is "" then we add it to the NA section
		// NA only used for split mode
		//
		if (splitSection){
			NSString *sectionString = [iObject performSelector:sectionSelector];
			// if no valid string value 
			if ( [sectionString length] == 0 ) {
				[naArray addObject:iObject];
				sortObject = NO;
			}
		}
		
		if (sortObject) {
			// Ask the collation which section number the object belongs in, based on its locale name.
			NSInteger sectionNumber = [self.collation sectionForObject:iObject collationStringSelector:sectionSelector];
			
			// if collation is messed up
			if (sectionNumber >= [newSectionsArray count]){
				[naArray addObject:iObject];
				DDLogVerbose(@"CW-ss - WARN: Add to NA - Got an invalid section no:%d for %@", sectionNumber, [iObject performSelector:sectionSelector]);
			}
			// normal
			else {
				// Get the array for the section.
				NSMutableArray *collationSection = [newSectionsArray objectAtIndex:sectionNumber];
				
				//  Add the object to the section.
				[collationSection addObject:iObject];
			}
		}
	}
	DDLogVerbose(@"CW-ss: populate section fin");
	
	if ([self.parentOperation isCancelled]) {
		DDLogVerbose(@"CW-ss: Cancelled");
		[newSectionsArray release];
		[naArray release];
		return;
	}
	
	// if split
	// - split each collaction section into subsections and generate split titles and indexmap
	//
	if (splitSection) {
		
		NSMutableArray *splitSectionsArray = [[NSMutableArray alloc] init];
		
		// split section into dictionary
		// - key:	section title string
		// - value: array of objects that belong to this sub section
		//
		NSUInteger splitSectionIndex = 0;		// section title index
		for (NSMutableArray *iSection in newSectionsArray){
			NSMutableDictionary *subSectionD = [[NSMutableDictionary alloc] init];
			
			for (id iObject in iSection){
				NSString *sectionString = [iObject performSelector:sectionSelector];
				// does key already exists
				NSMutableArray *splitObjectArray = [subSectionD objectForKey:sectionString];
				if (splitObjectArray) {
					[splitObjectArray addObject:iObject];
				}
				// otherwise add a new array
				else {
					NSMutableArray *newObjectArray = [[NSMutableArray alloc] init];
					[newObjectArray addObject:iObject];
					[subSectionD setObject:newObjectArray forKey:sectionString];
					[newObjectArray release];
				}
			}
			
			NSArray *keys = [subSectionD allKeys];
			// sub section found
			if ([keys count] > 0) {
				
				// sort keys
				NSMutableArray *sortedSectionKeys = [[keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];
				
				// add current index to index map
				[self.loadSplitSectionIndexMap addObject:[NSNumber numberWithInt:splitSectionIndex]];
				splitSectionIndex = splitSectionIndex + [sortedSectionKeys count];
				 
				// add keys to section titles
				[self.loadSplitSectionTitles addObjectsFromArray:sortedSectionKeys];
				
				// add object arrays to sectionsArray
				for (NSString *iKey in sortedSectionKeys){
					[splitSectionsArray addObject:[subSectionD objectForKey:iKey]];
				}
				[sortedSectionKeys release];
			}
			// empty section: add empty section
			else {
				[self.loadSplitSectionIndexMap addObject:[NSNumber numberWithInt:splitSectionIndex]];
				splitSectionIndex++;
				[self.loadSplitSectionTitles addObject:@""];
				NSMutableArray *emptyArray = [[NSMutableArray alloc] init];
				[splitSectionsArray addObject:emptyArray];
				[emptyArray release];
			}
			[subSectionD release];
		}
		// set sectionsArray
		self.loadSectionsArray = splitSectionsArray;
		[splitSectionsArray release];
		
		if ([self.parentOperation isCancelled]) {
			DDLogVerbose(@"CW-ss: Cancelled");
			[newSectionsArray release];
			[naArray release];
			return;
		}
	}
	// if normal collation
	else {
		self.loadSectionsArray = newSectionsArray;
	}
	[newSectionsArray release];

	DDLogVerbose(@"CW-ss: split section fin");
	
	// if NA section exists
	// - append it
	if ([naArray count] > 0) {
		[self appendSectionTitle:NSLocalizedString(@"NA", @"Section Title: for objects without data") 
			   sectionIndexTitle:NSLocalizedString(@"na", @"Index Title: for objects without data") 
					 objectArray:naArray];
	}
	[naArray release];
	
	
	// sort each section by sort selector
	//
	// Now that all the data's in place, each section array needs to be sorted.
	NSMutableArray *sortedArray = [[NSMutableArray alloc] init];
	for (NSMutableArray *iObjectArray in self.loadSectionsArray) {
		
		// If the table view or its contents were editable, you would make a mutable copy here.
		NSArray *sortedArrayForSection = nil;
        
        // if fine grain sort needed
        if (sortDescriptors) {
            sortedArrayForSection = [iObjectArray sortedArrayUsingDescriptors:sortDescriptors];
        }
        else if (sortSelector) {
            sortedArrayForSection = [self.collation sortedArrayFromArray:iObjectArray collationStringSelector:sortSelector];
        }
        
		//NSArray *sortedArrayForSection = [iObjectArray sortedArrayUsingSelector:sortSelector];
		if (sortedArrayForSection) {
            [sortedArray addObject:sortedArrayForSection];
        }
	}
	self.loadSectionsArray = sortedArray;
	[sortedArray release];
	
	DDLogVerbose(@"CW-ss: sort fin - all done");
}

- (void) setupSectionsArrayWithObjects:(NSArray *)objects 
					   sectionSelector:(SEL)sectionSelector 
						  sortSelector:(SEL)sortSelector 
						  splitSection:(BOOL)splitSection {
    
    [self setupSectionsArrayWithObjects:objects sectionSelector:sectionSelector sortSelector:sortSelector sortDescriptors:nil splitSection:splitSection];
}

/**
 Adds a custom section to the start of the index
 
 Usage:
 - use this after main sectionsArray is setup, since setup will reset all related data
 - affects only loaded data, which is used to sync to real data model at a later time
 */
- (void) prependSectionTitle:(NSString *)sectionTitle sectionIndexTitle:(NSString *)sectionIndexTitle objectArray:(NSArray *)objectArray {
    
    NSAssert(sectionTitle && sectionIndexTitle && objectArray, @"Invalid values for prependSectionTitle");
    
	[self.loadPrependSectionTitles insertObject:sectionTitle atIndex:0];
	[self.loadPrependSectionIndexTitles insertObject:sectionIndexTitle atIndex:0];
	
	[self.loadSectionsArray insertObject:objectArray atIndex:0];
}

/**
 Adds a custom section to the end of the index
 
 Usage:
 - use this after main sectionsArray is setup, since setup will reset all related data
 - affects only loaded data, which is used to sync to real data model at a later time
 */
- (void) appendSectionTitle:(NSString *)sectionTitle sectionIndexTitle:(NSString *)sectionIndexTitle objectArray:(NSArray *)objectArray {
	[self.loadAppendSectionTitles addObject:sectionTitle];
	[self.loadAppendSectionIndexTitles addObject:sectionIndexTitle];
	
	[self.loadSectionsArray addObject:objectArray];
}



/**
 Specify if this collation should add the search icon
 */

- (void) addSearchIcon:(BOOL)newAddSearch {
	self.addSearch = newAddSearch;
}


#pragma mark -
#pragma mark Manage Object Methods

/**
 Deletes all instances of this object from sectionsArray
 
 */
- (void) deleteObject:(id)deleteOject {
	id recordID = [deleteOject performSelector:self.numIDSelector];
	
	for (NSMutableArray *sectionArray in self.sectionsArray) {
		[sectionArray removeObject:recordID];
	}
	// TODO: may be a good idea to save to Archive here
	// so next startup will have a more accurate cache
}

/**
 Returns a array of all current objects!
 - exclude "Top Contacts" section
 
 Used:
 - get list of Persons for group email controller
 - get an unfiltered list to search from
 
 */
- (NSMutableArray *) getAllObjects {
	NSMutableArray *idArray = [[NSMutableArray alloc] init];
	
	BOOL skipFirstSection = NO;
	NSArray *secTitles = [self sectionTitles];
	if ( [secTitles count] > 0 && [[secTitles objectAtIndex:0] isEqualToString:NSLocalizedString(@"Top Contacts",nil)]) {
		skipFirstSection = YES;
	}
	for (NSArray *sectionArray in self.sectionsArray){
		if (!skipFirstSection) {
			[idArray addObjectsFromArray:sectionArray];
		}
		skipFirstSection = NO;
	}
	NSMutableArray *objectArray = [[[NSMutableArray alloc] init] autorelease];
	for (id iRecordID in idArray){
		id iObject = [self.objectsRepository performSelector:self.numIDToObjectSelector withObject:iRecordID];
		// don't add if nil
		// - this may occur if base list has IDs of contacts that were deleted!
		if (iObject){
			[objectArray addObject:iObject];
		}
	}
	[idArray release];
	
	return objectArray;
}

#pragma mark -
#pragma mark TableView related methods

/**
 Gets the total number of objects in sectionsArray
 - exclude "Top Contacts" section
 */
- (NSInteger) numberOfTotalObjects {
	BOOL skipFirstSection = NO;
	NSUInteger totalCount = 0;
	
	NSArray *secTitles = [self sectionTitles];
	if ( [secTitles count] > 0 && [[secTitles objectAtIndex:0] isEqualToString:NSLocalizedString(@"Top Contacts",nil)]) {
		skipFirstSection = YES;
	}
	for (NSArray *sectionArray in self.sectionsArray){
		if (!skipFirstSection) {
			totalCount = totalCount + [sectionArray count];
		}
		skipFirstSection = NO;
	}

	return totalCount;
}


/**
 Get Number of rows in each section
 
 */
- (NSInteger) numberOfRowsInSection:(NSInteger)section {
	NSUInteger sectionArrays = [self.sectionsArray count];
	if (section < sectionArrays) {
		return [[self.sectionsArray objectAtIndex:section] count];
	}
	// section request is larger than actual data model
	else {
		return 0;
	}
}

/*!
 @abstract Given indexPath, return the what should be shown in the table cell
  - if indexing: use cache index
  - if indexed: used new index data
 
 Note:
 - nil may be returned if request if made for an unknown IP
 - caused by race condition? - update data model and UI request for row before table is completely reloaded
 
 */
- (id) objectAtIndexPath: (NSIndexPath *)indexPath {
    
	NSUInteger row = [indexPath row];
	NSUInteger section = [indexPath section];
	
    // only return object if it exists
    if (section < [self.sectionsArray count]) {
        NSArray *secArray = [self.sectionsArray objectAtIndex:section];
        
        if (row < [secArray count]) {
            id recordID = [secArray objectAtIndex:row];
            return [self.objectsRepository performSelector:self.numIDToObjectSelector withObject:recordID];
        }
        else {
            DDLogError(@"CW-oaip: Row not found - rows_cnt: %d", [secArray count]);
        }
    }
    else {
        DDLogError(@"CW-oaip: Section not found - secs_cnt: %d", [self.sectionsArray count]);
    }
    return nil;
}

/**
 Given the object get index path that the object's recordID is at
 
 Used:
 - find index of object, so app can auto scroll to that location
 
 Return:
 - nil if not found
 
 */
- (NSIndexPath *) indexPathForObject:(id)object {
	
	id recordID = [object performSelector:self.numIDSelector];
	
	//NSUInteger row = 0;
	NSUInteger section = 0;
	
	for (section = 0; section < [self.sectionsArray count]; section++) {
		
		NSArray *secArray = [self.sectionsArray objectAtIndex:section];
		
		NSInteger foundRow = [secArray indexOfObject:recordID];
		if (foundRow != NSNotFound) {
			NSIndexPath *resIP = [NSIndexPath indexPathForRow:foundRow inSection:section];
			DDLogVerbose(@"CW-ipfo: found indexpath %@", resIP);
			return resIP;
		}
		/*
		for (row = 0; row < [secArray count]; row++) {
			NSNumber *secNumber = [secArray objectAtIndex:row];
			if ([secNumber isEqualToNumber:recordID]) {
				return [NSIndexPath indexPathForRow:row inSection:section];
			}
		}*/
	}
	
	DDLogVerbose(@"CW-ipfo: Can't find object!!! id: %@ IN %@", recordID, self.sectionsArray);
	return nil;
}



/*!
 @abstract Gets the title for a given section
 
 @return nil if no title should be shown
 */
- (NSString *)titleForHeaderInSection:(NSInteger)section {
    
    NSUInteger sectionCount = [self sectionCount];
	if (sectionCount == 0 || sectionCount == section)
		return nil;
    
	NSString *key = nil;
	// only show title if there are items under that section
	if ([self numberOfRowsInSection:section] > 0 ) {
		key = [[self sectionTitles] objectAtIndex:section];
	}
	return key;
}



#pragma mark -
#pragma mark Standard Collation Methods

/**
 Return the section that this object belongs to
 
 Used:
 - to sort objects into sections
 
 */
- (NSInteger)sectionForObject:(id)object collationStringSelector:(SEL)selector
{
	NSUInteger offset = [self.prependSectionTitles count];
	return [self.collation sectionForObject:object collationStringSelector:selector] + offset;
}

/**
 Returns the actual section position to scroll to for a given index position that the users touches
 
 Return:
 NSNotFound		if search icon index or others -- tableview should scroll to the top
 
 */
- (NSInteger) sectionForSectionIndexTitleAtIndex:(NSInteger)indexTitleIndex
{
	NSUInteger adjustedIndex = indexTitleIndex;
	NSUInteger resultValue = NSNotFound;
	// if search use an offset for indexes and return not found if asking for search index
	if (self.addSearch) {
		if(indexTitleIndex == 0) { 
			return NSNotFound;
		}
		// ignore the magnifying glass
		adjustedIndex = adjustedIndex - 1;
	}
	
	// number of standard index titles
	// - used to determine which algorithm to count section index
	NSUInteger prependCount = [self.prependSectionIndexTitles count];
	NSUInteger mainCount = [[self.collation sectionIndexTitles] count];
	NSUInteger appendCount = [self.appendSectionIndexTitles count];
	
	//DDLogVerbose(@"COUNTS: ad:%d pre:%d main:%d app:%d", adjustedIndex, prependCount, mainCount, appendCount);
	//DDLogVerbose(@"SIT: %@", [self.collation sectionTitles]);
	
	// if within prepend count
	// - use the index number since they are one to one
	if (adjustedIndex < prependCount) {
		return adjustedIndex;
	}
	// if within main sections
	if (adjustedIndex < (prependCount + mainCount)) {
		// adjusted should strip out preprend indexes to get the right mapping from "standard collation sectionForSe.."
		//
		adjustedIndex = adjustedIndex - prependCount;
		if ([self.splitSectionIndexMap count] > 0) {
			resultValue = prependCount + [[self.splitSectionIndexMap objectAtIndex:adjustedIndex] intValue];
			return resultValue;
		}
		else {

			NSUInteger useIndex = adjustedIndex;
			
			// if buggy version:
			// - if last index used then crash occurs!!
			// - reset to previous index result ~ which should be the end
			//
			/* This is not needed since 1.2.0 because we don't use our own custom index from TTLocalizedIndexedCollation
			   - Apple's collation is verfified for zh-Hant for 4.1 & 4.2..
			 
			 NSString *iosVersion = [[UIDevice currentDevice] systemVersion];
			 NSString *preferredLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
			 //DDLogVerbose(@"ver:%@ lang:%@", iosVersion, preferredLanguage);
			 
			 if ([iosVersion isEqualToString:@"4.1"] && [preferredLanguage isEqualToString:@"zh-Hant"] && adjustedIndex == 26) {
				useIndex = adjustedIndex - 1;
			}*/

			
			resultValue = prependCount + [self.collation sectionForSectionIndexTitleAtIndex:useIndex];
			

			// TODO: should add sanity check value before returning?
			//DDLogVerbose(@"res: %d ad:%d main:%d", resultValue, adjustedIndex, mainCount);

			return resultValue;
		}
	}
	// if in append section
	if (adjustedIndex < (prependCount + mainCount + appendCount)) {
		if ([self.splitSectionIndexMap count] > 0) {
			// which append item does this index respond to
			// - calc index position to find this
			NSUInteger appendNumber = adjustedIndex - prependCount - mainCount;
			
			// number of sections
			NSUInteger mainSectionCount = [[self sectionTitles] count];
			return prependCount + mainSectionCount + appendNumber;
		}
		else {
			return adjustedIndex;
		}
	}
	
	// error
	DDLogVerbose(@"CW-sfsi: ERROR - could not calc section for index number");
	return 0;
}

/**
 Sorts an array by using the given selector
 
 Used:
 - to sort each section of tableview's sectionsArray
 
 */
- (NSArray *)sortedArrayFromArray:(NSArray *)array collationStringSelector:(SEL)selector
{
	return [self.collation sortedArrayFromArray:array collationStringSelector:selector];
}

#pragma mark -
#pragma mark Accessors

/**
 Getter for cache of section titles
 */
- (NSArray *) collationSectionTitlesCache {
	
	// Cache collation sectionTitles
	// - this may be slow and will slow down scrolling speed
	// - this will not changed for the entire run of app
	//
	
	if (!collationSectionTitlesCache) {
		collationSectionTitlesCache = [self.collation sectionTitles];
		[collationSectionTitlesCache retain];
	}
	return collationSectionTitlesCache;
}

/**
 Returns the number of sections
 - faster than creating array above and counting the elements
 
 */
- (NSUInteger) sectionCount {
	
	NSUInteger count = [self.prependSectionTitles count];
	
	// if split exists - use it
	//
	NSUInteger splitCount = [self.splitSectionTitles count];
	
	if ( splitCount > 0) {
		count = count + splitCount;
	}
	else {
		count = count + [self.collationSectionTitlesCache count];
	}
	count = count + [self.appendSectionTitles count];

	return count;
}

/**
 Returns the array filled with section titles
 */
- (NSArray *)sectionTitles;
{
	
	NSMutableArray *titles = [[[NSMutableArray alloc] init] autorelease];
	[titles addObjectsFromArray:self.prependSectionTitles];
	
	// if split exists - use it
	//
	if ([self.splitSectionTitles count] > 0) {
		[titles addObjectsFromArray:self.splitSectionTitles];
	}
	else {
		[titles addObjectsFromArray:self.collationSectionTitlesCache];
	}
	[titles addObjectsFromArray:self.appendSectionTitles];
	
	return titles;
}

/**
 Return an array filled with index titles
 */

- (NSArray *)sectionIndexTitles;
{
	NSMutableArray *titles = [[[NSMutableArray alloc] init] autorelease];
	
	// add search icon if required
	if (self.addSearch) {
		[titles	addObject:UITableViewIndexSearch];
	}
	[titles addObjectsFromArray:self.prependSectionIndexTitles];
	[titles addObjectsFromArray:[self.collation sectionIndexTitles]];
	[titles addObjectsFromArray:self.appendSectionIndexTitles];
	
	return titles;
}

#pragma mark -
#pragma mark Query Methods

/**
 Checks if first prepend title is a particular string
 
 Usage:
 - used to check if the first section is top contact
 */
- (BOOL) isFirstPrependSectionTitle:(NSString *)testTitle {
	if ([self.prependSectionTitles count] > 0) {
		if ([testTitle isEqualToString:[self.prependSectionTitles objectAtIndex:0]]) {
			return YES;
		}
	}
	return NO;
}


#pragma mark -
#pragma mark NSCoding and Archiving Methods

#define kKeyTTCollationWrapper			@"TTCollationWrapper"
#define kKeyAddSearch					@"addSearch"
#define kKeySectionArray				@"sectionArray"
#define kKeyPrependSectionTitles		@"preSecTitles"
#define kKeyPrependSectionIndexTitles	@"preIndexTitles"
#define kKeyAppendSectionTitles			@"appSecTitles"
#define kKeyAppendSectionIndexTitles	@"appIndexTitles"
#define kKeySplitSectionTitles			@"splitTitles"
#define kKeySplitSectionIndexMap		@"splitIndexMap"

/**
 Loads archive from file
 
 Return:
 success		YES
 fail			NO
 */
- (BOOL) loadFromArchive: (NSString *)archiveFileName {
	NSString *cacheFilePath = [Utility documentFilePath:archiveFileName];
	DDLogVerbose(@"CW-lfa: load from %@", cacheFilePath);
	
	// if saved file exists 
	if ([Utility fileExistsAtDocumentFilePath:archiveFileName]){
		
		NSData *data = [[NSMutableData alloc]
						initWithContentsOfFile:cacheFilePath];
		TTCollationWrapper *archiveCollation = nil;
		@try {
			NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
			archiveCollation = [unarchiver decodeObjectForKey:kKeyTTCollationWrapper];
			[unarchiver finishDecoding];
			[unarchiver release];
		}
		@catch (NSException *exception) {
			DDLogVerbose(@"CW-lfa:: loadFromArchive Caught %@: %@", [exception name], [exception reason]);
			return NO;
		}
		@finally {
			[data release];
		}
		
		
		if (archiveCollation) {
			// copy values
			self.addSearch = archiveCollation.addSearch;
			
			NSMutableArray *sa = [archiveCollation.sectionsArray mutableCopy];
			self.sectionsArray = sa;
			[sa release];
			
			NSMutableArray *pst = [archiveCollation.prependSectionTitles mutableCopy];
			self.prependSectionTitles = pst;
			[pst release];
			
			NSMutableArray *psit = [archiveCollation.prependSectionIndexTitles mutableCopy];
			self.prependSectionIndexTitles = psit;
			[psit release];
			
			NSMutableArray *ast = [archiveCollation.appendSectionTitles mutableCopy];
			self.appendSectionTitles = ast;
			[ast release];
			
			NSMutableArray *asit = [archiveCollation.appendSectionIndexTitles mutableCopy];
			self.appendSectionIndexTitles = asit;
			[asit release];
			
			NSMutableArray *sst = [archiveCollation.splitSectionTitles mutableCopy];
			self.splitSectionTitles = sst;
			[sst release];
			
			NSMutableArray *sim = [archiveCollation.splitSectionIndexMap mutableCopy];
			self.splitSectionIndexMap = sim;
			[sim release];
			return YES;
		}
		
	}
	// load failed	
	return NO;
}




/**
 Used to save a cache copy to quickly launch this app
 - only attributes that are important to data model are saved and loaded
 */
- (void) saveToArchive:(NSString *)archiveFileName {
	DDLogVerbose(@"CW-sta: saving view data to file: %@", archiveFileName);
	NSString *cacheFilePath = [Utility documentFilePath:archiveFileName];
	
	NSMutableData *data = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] 
								 initForWritingWithMutableData:data];
	[archiver encodeObject:self forKey:kKeyTTCollationWrapper];
	[archiver finishEncoding];
	[data writeToFile:cacheFilePath atomically:YES];
	
	[archiver release];
	[data release];
	
	
}



- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeBool:self.addSearch forKey:kKeyAddSearch];
	[encoder encodeObject:self.sectionsArray forKey:kKeySectionArray];
	[encoder encodeObject:self.prependSectionTitles forKey:kKeyPrependSectionTitles];
	[encoder encodeObject:self.prependSectionIndexTitles forKey:kKeyPrependSectionIndexTitles];
	[encoder encodeObject:self.appendSectionTitles forKey:kKeyAppendSectionTitles];
	[encoder encodeObject:self.appendSectionIndexTitles forKey:kKeyAppendSectionIndexTitles];
	[encoder encodeObject:self.splitSectionTitles forKey:kKeySplitSectionTitles];
	[encoder encodeObject:self.splitSectionIndexMap	forKey:kKeySplitSectionIndexMap];
}

- (id)initWithCoder:(NSCoder *)decoder {
	if ((self = [super init])) {
		self.addSearch = [decoder decodeBoolForKey:kKeyAddSearch];
		self.sectionsArray = [decoder decodeObjectForKey:kKeySectionArray];
		self.prependSectionTitles = [decoder decodeObjectForKey:kKeyPrependSectionTitles];
		self.prependSectionIndexTitles = [decoder decodeObjectForKey:kKeyPrependSectionIndexTitles];
		self.appendSectionTitles = [decoder decodeObjectForKey:kKeyAppendSectionTitles];
		self.appendSectionIndexTitles = [decoder decodeObjectForKey:kKeyAppendSectionIndexTitles];
		self.splitSectionTitles = [decoder decodeObjectForKey:kKeySplitSectionTitles];
		self.splitSectionIndexMap = [decoder decodeObjectForKey:kKeySplitSectionIndexMap];
	}
	return self;
}

@end
