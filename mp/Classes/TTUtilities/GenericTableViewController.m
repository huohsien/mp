//
//  GenericTableViewController.m
//
//  Created by Matt Gallagher on 27/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "GenericTableViewController.h"
#import "CellController.h"

@implementation GenericTableViewController

@synthesize tableGroups;


#pragma mark -
#pragma mark Data Model Methods
//
// constructTableGroups
//
// Creates/updates cell data. This method should only be invoked directly if
// a "reloadData" needs to be avoided. Otherwise, updateAndReload should be used.
//
- (void)constructTableGroups
{
	NSArray *tmpArray = [[NSArray alloc] init];
	self.tableGroups = tmpArray;
	[tmpArray release];
}

//
// clearTableGroups
//
// Releases the table group data (it will be recreated when next needed)
//
- (void)clearTableGroups
{
	self.tableGroups = nil;
}

//
// updateAndReload
//
// Performs all work needed to refresh the data and the associated display
//
- (void)updateAndReload
{
	[self clearTableGroups];
	[self constructTableGroups];
	[self.tableView reloadData];
}

/**
 Gets cell controller for specific index path
 */
- (id) cellControllerForIndexPath:(NSIndexPath *)indexPath {
	return [[self.tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}

/**
 Gets cell controllers for visible rows
 */
- (NSArray *) cellControllersForVisibleRows {
	NSArray *paths = [self.tableView indexPathsForVisibleRows];
	NSMutableArray *controllers = [[[NSMutableArray alloc] init] autorelease];
	for (NSIndexPath *iPath in paths){
		[controllers addObject:[self cellControllerForIndexPath:iPath]];
	}
	return controllers;
}

#pragma mark - TableView




#pragma mark - TableView Delegate

//
// numberOfSectionsInTableView:
//
// Return the number of sections for the table.
//
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (!self.tableGroups)
	{
		[self constructTableGroups];
	}
	
	return [self.tableGroups count];
}

//
// tableView:numberOfRowsInSection:
//
// Returns the number of rows in a given section.
//
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (!self.tableGroups)
	{
		[self constructTableGroups];
	}
	
	return [[self.tableGroups objectAtIndex:section] count];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!self.tableGroups)
	{
		[self constructTableGroups];
	}
	//DDLogVerbose(@"GTV: %@", indexPath);
	return [[[self.tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]
			tableView:(UITableView *)tableView
			cellForRowAtIndexPath:indexPath];
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!self.tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<CellController> *cellData =
		[[self.tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([cellData respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
	{
		[cellData tableView:tableView didSelectRowAtIndexPath:indexPath];
	}
}


// 
// take action just prior to cell display
//
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<CellController> *cellData =
		[[self.tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([cellData respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)])
	{
		[cellData tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
	}
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!self.tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<CellController> *cellData =
    [[self.tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([cellData respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)])
	{
		[cellData tableView:tableView willBeginEditingRowAtIndexPath:indexPath];
	}
}


//
// handle accesory button press
//
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	if (!self.tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<CellController> *cellData =
		[[self.tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([cellData respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)])
	{
		[cellData tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
	}
}

//
// conditional editing
//
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<CellController> *cellData =
		[[self.tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([cellData respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)])
	{
		return [cellData tableView:tableView canEditRowAtIndexPath:indexPath];
	}
	else {
		return NO;
	}
}


//
// Specify the mode of editing available
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<CellController> *cellData =
		[[self.tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([cellData respondsToSelector:@selector(tableView:editingStyleForRowAtIndexPath:)])
	{
		return [cellData tableView:aTableView editingStyleForRowAtIndexPath:indexPath];
	}
	else {
		return UITableViewCellEditingStyleNone;
	}

}

//
// Handle cell moves
// * no section mixing
//
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath 
	   toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	
	NSUInteger sourceSection = [sourceIndexPath section];
	NSUInteger proposedSection = [proposedDestinationIndexPath section];
	
	// don't allow section mixing by default
	if (sourceSection == proposedSection) {
		return proposedDestinationIndexPath;
	}
	else {
		return sourceIndexPath;
	}

	// should we check if row can be moved?? or is above sufficient?
	
	/*if (sourceSection == 0 && proposedSection == 0) {
		if (proposedDestinationIndexPath.row == 0 || proposedDestinationIndexPath.row == [self.groups count]+1) {
			return sourceIndexPath;
		}
		return	proposedDestinationIndexPath;
	}
	else if (sourceSection == 1 && proposedSection == 1) {
		return proposedDestinationIndexPath;
	}
	// Dont allow mixing of section rows
	else {
		return sourceIndexPath;
	}*/
}

//
// Can row be moved?
//
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<CellController> *cellData =
		[[self.tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([cellData respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)])
	{
		return [cellData tableView:tableView canMoveRowAtIndexPath:indexPath];
	}
	else {
		return NO;
	}

}






#pragma mark - Base

//
// didReceiveMemoryWarning
//
// Release any cache data.
//
- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

//
// dealloc
//
// Release instance memory
//
- (void)dealloc
{
	[self clearTableGroups];
    [super dealloc];
}

@end

