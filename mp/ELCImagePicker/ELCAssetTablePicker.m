//
//  AssetTablePicker.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"
#import "AppUtility.h"
#import "TKLog.h"
#import "Utility.h"


NSUInteger const kMPParamSelectedPhotoMax = 10;
NSUInteger const kMPParamAssetPreload = 100;


@implementation ELCAssetTablePicker
{
    NSInteger start;
}

@synthesize parent;
@synthesize selectedAssetsLabel;

@synthesize assetsGroup, elcAssets;
@synthesize assetsGroupID;
@synthesize assetsLibrary;
@synthesize numberOfAssets;

@synthesize onlySingleSelection;
@synthesize lastSelectedAsset;
@synthesize selectedAssets;

#pragma mark - VC

- (void)dealloc 
{
    // not needed
    /*for (ELCAsset *iAsset in self.elcAssets) {
        iAsset.delegate = nil;
    }*/   
    
    [assetsGroup release];
    [assetsLibrary release];
    [assetsGroupID release];
    
    [lastSelectedAsset release];
    
    [createdCells release];
    [elcAssets release];
    
    [selectedAssetsLabel release];
    [selectedAssets release];
    
    [super dealloc];    
}


- (void) setAssetsGroup:(ALAssetsGroup *)aAssetGroup assetsLibrary:(ALAssetsLibrary *)aAssetLibrary {
    self.assetsGroup = aAssetGroup;
    self.assetsLibrary = aAssetLibrary;
    
    // save ID incase we need to reload
    if ([self.assetsLibrary respondsToSelector:@selector(groupForURL:resultBlock:failureBlock:)]) {
        self.assetsGroupID = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
    }
    else {
        self.assetsGroupID = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyPersistentID];
    }
    
    /* save this value so we don't need to call numberOfAssets method regularly.  
     This method is unreliable and can cause other parts of the code to crash */
    self.numberOfAssets = [self.assetsGroup numberOfAssets];
}



-(void)viewDidLoad {
    
	[self.tableView setSeparatorColor:[UIColor clearColor]];
	[self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
    [tempArray release];
	
    // setup array to store selected assets
    // - prevent interating through elcAssets which may cause crash when it is being mutated
    //
    NSMutableArray *selectArray = [[NSMutableArray alloc] initWithCapacity:kMPParamSelectedPhotoMax];
    self.selectedAssets = selectArray;
    [selectArray release];
    
    UIBarButtonItem *doneButtonItem = [AppUtility barButtonWithTitle:NSLocalizedString(@"Done", @"Album - button: cancel album selection") 
                                                          buttonType:kAUButtonTypeBarHighlight 
                                                              target:self action:@selector(doneAction:)];
    doneButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = doneButtonItem;

    [self setTitle:NSLocalizedString(@"Loading...", @"ImagePicker - title: images are loading")];
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    
    // load and display the first kMPParamAssetPreload assets
    //
    NSInteger count = self.assetsGroup.numberOfAssets;
    NSInteger startNumberOfAssets = kMPParamAssetPreload - 4 + count%4;
    
    // start for end of the list of assets
    // - if start is 0 than all photos will be loaded
    start = MAX(0, count-startNumberOfAssets);
    
    // Set up the first ~100 photos (if less than show all photos)
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(start, count > startNumberOfAssets ? startNumberOfAssets : count)];

    [self.assetsGroup enumerateAssetsAtIndexes:indexSet options:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result == nil) 
        {
            return;
        }
        ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
        elcAsset.delegate = self;
        [elcAsset setParent:self];
        elcAsset.tag = index;
        [self.elcAssets addObject:elcAsset];
        [elcAsset release];
        
    }];
    [self.tableView reloadData];
    
    // if more photos to load, then load them
    if (start > 0) {
        backgroundThread = [[NSThread alloc] initWithTarget: self selector: @selector(loadRemainingPhotos) object: NULL];
        if(backgroundThread)
        {
            [backgroundThread start];
        }
    }
    
    /*backgroundThread = [[NSThread alloc] initWithTarget: self selector: @selector(preparePhotos) object: NULL];
    if(backgroundThread)
    {
        [backgroundThread start];
    }*/
    
}


-(void) viewWillDisappear:(BOOL)animated {
    
    // if view goes away, cancel the background thread
    if(backgroundThread)
    {
        //DDLogVerbose( @"calling cancel on background thread" );
        [backgroundThread cancel];
    } else {
        //DDLogVerbose( @"no background thread to call cancel on");
    }
    
    
}


#pragma mark - Tools


-(void) loadRemainingPhotos {
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"loadRemainingPhotos: enumerating photos");
    
    NSIndexSet *newIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, start)];
    [self.assetsGroup enumerateAssetsAtIndexes:newIndexSet options:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result == nil) 
        {
            return;
        }
        
        if(backgroundThread.isCancelled)
        {
            *stop = YES;
            return;
        } 
        else {
            ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
            elcAsset.delegate = self;
            [elcAsset setParent:self];
            elcAsset.tag = index;
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                [self.elcAssets addObject:elcAsset];
                
            });
            
            [elcAsset release];    
        }
    
    }];

    DDLogInfo(@"done enumerating photos");
	
    
    // give some time for view to appear 
    // - so the title does not get shifted by backbutton during willAppear and didAppear
    [NSThread sleepForTimeInterval:0.5];
    
    
    if(backgroundThread.isCancelled == NO)
    {
        //update UI
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // if title is still loading, reset it
            if ([self.title isEqualToString:NSLocalizedString(@"Loading...", nil)] )  {
                [self setTitle:NSLocalizedString(@"Select Photos", @"ImagePicker - title: select images")];
                [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
            }
            
            [self.tableView reloadData];
            
        });
    }
    
    [backgroundThread release];
    backgroundThread = NULL;
    [pool release];

}


- (void) doneAction:(id)sender {
	
    // after selecting
    // - pushed view should not come back here!
    //
    self.navigationItem.hidesBackButton = YES;
    
	NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] initWithCapacity:24];
    if(backgroundThread)
    {
        //DDLogVerbose( @"calling cancel on background thread" );
        [backgroundThread cancel];
    } else {
        //DDLogVerbose( @"no background thread to call cancel on");
    }

    // this may still be mutating, so use selectedAssets instead
	/*for(ELCAsset *elcAsset in self.elcAssets) 
    {		
		if([elcAsset selected]) {
			
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}*/
    for(ELCAsset *iAsset in self.selectedAssets) 
    {		
		if([iAsset selected]) {
			[selectedAssetsImages addObject:[iAsset asset]];
		}
	}
    
        
    [(ELCAlbumPickerController*)self.parent selectedAssets:selectedAssetsImages];
    
    [selectedAssetsImages release];
}

#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ceil(self.numberOfAssets/ 4.0);
}

// ugly
-(NSArray*)assetsForIndexPath:(NSIndexPath*)_indexPath {
    
	int index = (_indexPath.row*4);
	int maxIndex = (_indexPath.row*4+3);

    // 
	if(maxIndex < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				[self.elcAssets objectAtIndex:index+2],
				[self.elcAssets objectAtIndex:index+3],
				nil];
	}
    
	else if(maxIndex-1 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				[self.elcAssets objectAtIndex:index+2],
				nil];
	}
    
	else if(maxIndex-2 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				nil];
	}
    
	else if(maxIndex-3 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObject:[self.elcAssets objectAtIndex:index]];
	}
    else {
        DDLogInfo(@"ATP-afip: no assets returned");
    }
    
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) 
    {
        NSArray *cellAssets = [self assetsForIndexPath:indexPath];
        
        cell = [[[ELCAssetCell alloc] initWithAssets:cellAssets reuseIdentifier:CellIdentifier] autorelease];
        
        DDLogInfo( @"ROW %d brand new cell %p", indexPath.row, cell );

        cell.tag = indexPath.row;
        
        //[createdCells addObject: cell];
        //[cell release];
    }	
    else {
        DDLogInfo( @"ROW %d recycle cell %p", indexPath.row, cell );
        [cell setAssets:[self assetsForIndexPath:indexPath]];
        cell.tag = indexPath.row;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	return 79.0;
}

- (int)totalSelectedAssets {
    /*
    int count = 0;
    
    for(ELCAsset *asset in self.elcAssets) 
    {
		if([asset selected]) 
        {            
            count++;	
		}
	}
    
    return count;*/
    return [self.selectedAssets count];
}


/*!
 @abstract Call when asset is tapped
 
 @param YES if ok to select this item
 
 Use:
 - Asks for permission to select if there is a max limit
 
 */
- (BOOL)ELCAsset:(ELCAsset *)newAsset isAllowedToSelect:(BOOL)selected {
    
    NSUInteger selectCount = [self totalSelectedAssets];

    if (selected && selectCount >= kMPParamSelectedPhotoMax) {
        return NO;
    }
    return YES;
}


/*!
 @abstract Call when asset is tapped
 
 Use:
 - helps de-select old view is only single selection is allowed
 */
- (void)ELCAsset:(ELCAsset *)newAsset toggleSelection:(BOOL)selected {
    
    // if single selection
    // - deselect last one
    //
    if (self.onlySingleSelection && newAsset != self.lastSelectedAsset) {
        [self.lastSelectedAsset setSelected:NO];
        self.lastSelectedAsset = newAsset;
        
        [self.selectedAssets removeAllObjects];
        [self.selectedAssets addObject:newAsset];
        
    }
    else {
        // not already selected, add it
        //
        if ([self.selectedAssets indexOfObject:newAsset] == NSNotFound) {
            [self.selectedAssets addObject:newAsset];
        }
        // already selected, remove it
        //
        else {
            [self.selectedAssets removeObject:newAsset];
        }
    }
    
    NSUInteger selectCount = [self totalSelectedAssets];
    
    if (selectCount > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Selected %d Photos", @"ImagePicker - title: select images"), selectCount];
        [self setTitle:title];
        [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self setTitle:NSLocalizedString(@"Select Photos", @"ImagePicker - title: select images")];
        [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    }
}


@end
