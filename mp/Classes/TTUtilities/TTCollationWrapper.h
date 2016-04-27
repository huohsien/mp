//
//  TTLoclizedIndexedCollation.h
//  ContactBook
//
//  Created by M Tsai on 4/26/10.
//  Copyright 2010 TernTek. All rights reserved.
//



#import <Foundation/Foundation.h>

@class TTLocalizedIndexedCollation;


/**
 Wrapper for UIlocalizedIndexedCollation
 - can handle slight customization to Apple's standard index
 - also encapsulates the objects to be displayed
   * so it acts like an object manager for a tableview
 
 Data Model:
 - is filled with recordID objects (string, numbers, etc.) that represent just the recordID of each object
 - makes saving to file easier
 
 Load Model:
 - is filled with actual objects used for collation (sorting)
 - when sync to DataModel only the recordID is copied over
 
 = Objects Respository (OR) & Main Thread =
 OR is like a library where you can check out objects give a recordID.  The OR should 
 be from the main thread and only be accessed in the main thread.  Before you load in new collation data
 after indexing, you should refresh the OR and assign it to the collation.  This should 
 minimize chance of not being in sync.  If by chance the OL does not have an objected listed
 in sectionsArray, then that row should show a blank cell and not crash!  So expect that objects can 
 possibly return nil! 
 
 
 = Usage =
 A table should get all objects to display from this collation object.  Cells should not keep 
 references to any objects in the collation and ask for data whenever it needs.  This will ensure
 that the newest data is alway displayed and that the view is in sync with the collation data model!.
 
 
 
 
 Used:
 - as direct replacement UILocalizedIndexCollation
 
 Attributes:
 collation					collation object for current locale
 
 
 objectsRepository          If you have a recordID, you can obtain the object you want by performing 
                            the idToObjectSelector on this respository.
 
 numIDSelector				selector used on object to get it's ID 
                            - gets the unique id of the object
							- id is used to make saving more light weight and decoupled from object state
							- also makes old and new data model comparison more efficient
 
 numIDToObjectSelector		selector on dataModelTarget to get an object using the ID
 
 addSearch					should we add a search icon
 
 sectionsArray				an array of section(arrays).  Each section holds recordIDs for that table section.
 
 prependSectionTitles		section titles to prepend to standard index
 prependSectionIndexTitles	section index titles to prepend to standard index

 appendXXX					similarly for section artificially appended to the end
 
 splitSectionTitles			titles if sections were split into sub sections
 splitSectionIndexMap		maps collation index to actual sectionArray index that
							it should point to.
 
 loadXXX					these are temporary attributes use to store new value
							before they are updated to the data model by the main thread
 
 collationSectionTitlesCache	caches the regional titles since this should not change
								- and is an expensive call that should be avoided
 
 parentOperation			If collation is called from an operations.
							- used to check if we should cancel while in the middle of indexing
 
 */
@interface TTCollationWrapper : NSObject <NSCoding> {
	TTLocalizedIndexedCollation *collation;
	
    id objectsRepository;
	SEL numIDSelector;
	SEL numIDToObjectSelector;
	
	BOOL addSearch;
	
	NSMutableArray *sectionsArray;
	
	NSMutableArray *prependSectionTitles;
	NSMutableArray *prependSectionIndexTitles;
	
	NSMutableArray *appendSectionTitles;
	NSMutableArray *appendSectionIndexTitles;
	
	NSMutableArray *splitSectionTitles;
	NSMutableArray *splitSectionIndexMap;
	
	
	NSMutableArray *loadSectionsArray;
	NSMutableArray *loadPrependSectionTitles;
	NSMutableArray *loadPrependSectionIndexTitles;
	NSMutableArray *loadAppendSectionTitles;
	NSMutableArray *loadAppendSectionIndexTitles;
	NSMutableArray *loadSplitSectionTitles;
	NSMutableArray *loadSplitSectionIndexMap;
	
	NSArray *collationSectionTitlesCache;
	
	NSOperation *parentOperation;
}

// getters for readonly attributes
//
@property(nonatomic, readonly) NSUInteger sectionCount;
@property(nonatomic, readonly) NSArray *sectionTitles;
@property(nonatomic, readonly) NSArray *sectionIndexTitles;

@property(nonatomic, retain) id objectsRepository;
@property(nonatomic, assign) SEL numIDSelector;
@property(nonatomic, assign) SEL numIDToObjectSelector;

@property(nonatomic) BOOL addSearch;
@property(nonatomic, retain) NSMutableArray *sectionsArray;
@property(nonatomic, retain) TTLocalizedIndexedCollation *collation;

@property(nonatomic, retain) NSMutableArray *prependSectionTitles;
@property(nonatomic, retain) NSMutableArray *prependSectionIndexTitles;
@property(nonatomic, retain) NSMutableArray *appendSectionTitles;
@property(nonatomic, retain) NSMutableArray *appendSectionIndexTitles;

@property(nonatomic, retain) NSMutableArray *splitSectionTitles;
@property(nonatomic, retain) NSMutableArray *splitSectionIndexMap;


@property(nonatomic, retain) NSMutableArray *loadSectionsArray;
@property(nonatomic, retain) NSMutableArray *loadPrependSectionTitles;
@property(nonatomic, retain) NSMutableArray *loadPrependSectionIndexTitles;
@property(nonatomic, retain) NSMutableArray *loadAppendSectionTitles;
@property(nonatomic, retain) NSMutableArray *loadAppendSectionIndexTitles;
@property(nonatomic, retain) NSMutableArray *loadSplitSectionTitles;
@property(nonatomic, retain) NSMutableArray *loadSplitSectionIndexMap;

@property(nonatomic, retain) NSArray *collationSectionTitlesCache;
@property(nonatomic, retain) NSOperation *parentOperation;

// custom methods
- (void) prependSectionTitle:(NSString *)sectionTitle sectionIndexTitle:(NSString *)sectionIndexTitle objectArray:(NSArray *)objectArray;
- (void) appendSectionTitle:(NSString *)sectionTitle sectionIndexTitle:(NSString *)sectionIndexTitle objectArray:(NSArray *)objectArray;
- (void) resetLoadAttributes;
- (void) addSearchIcon:(BOOL)newAddSearch;


// setup 
- (id) initWithIDSelector:(SEL)newIDSelector idToObjectSelector:(SEL)newIDToObjectSelector;
- (void) assignObjectRepository:(id)newLibraryTarget;
- (void) syncLoadedData;

- (void) setupSectionsArrayWithObjects:(NSArray *)objects 
					   sectionSelector:(SEL)sectionSelector 
						  sortSelector:(SEL)sortSelector 
                       sortDescriptors:(NSArray *)sortDescriptors
						  splitSection:(BOOL)splitSection;

- (void) setupSectionsArrayWithObjects:(NSArray *)objects 
					   sectionSelector:(SEL)sectionSelector 
						  sortSelector:(SEL)sortSelector 
						  splitSection:(BOOL)splitSection;

// object management
- (void) deleteObject:(id)deleteOject;
- (NSMutableArray *) getAllObjects;

// table view methods
- (NSInteger) numberOfTotalObjects;
- (NSInteger) numberOfRowsInSection:(NSInteger)section;
- (id) objectAtIndexPath: (NSIndexPath *)indexPath;
- (NSIndexPath *) indexPathForObject:(id)object;
- (NSString *)titleForHeaderInSection:(NSInteger)section;

// standard collation methods
- (NSInteger)sectionForObject:(id)object collationStringSelector:(SEL)selector;
- (NSInteger)sectionForSectionIndexTitleAtIndex:(NSInteger)indexTitleIndex;
- (NSArray *)sortedArrayFromArray:(NSArray *)array collationStringSelector:(SEL)selector;

// query
- (BOOL) isFirstPrependSectionTitle:(NSString *)testTitle;

// archiving
- (BOOL) loadFromArchive: (NSString *)archiveFileName;
- (void) saveToArchive:(NSString *)archiveFileName;

@end
