//
//  TTBlankCellController.m
//  ContactBook
//
//  Created by M Tsai on 11-2-14.
//  Copyright 2011 TernTek. All rights reserved.
//


#import "TTBlankCellController.h"

@implementation TTBlankCellController

@synthesize backgroundColor;

//
// init
//
// Init method for the object.
//
- (id)initWithColor:(UIColor *)backColor
{
	self = [super init];
	if (self != nil)
	{
		self.backgroundColor = backColor;
	}
	return self;
}

- (void) dealloc {
	[backgroundColor release];
	[super dealloc];
}

#pragma mark -
#pragma mark tableView Methods

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	
	static NSString *CellIdentifier = @"BlankCell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, tableView.rowHeight)];
		// supress highlight on purpose, since it serves has a blank cell for favorites view
		backView.backgroundColor = self.backgroundColor;
		cell.selectedBackgroundView = backView;
		[backView release];
		cell.backgroundColor = self.backgroundColor;
	}
	
    return cell;
}

// respond to cell selection
//  * enable or disable this email address
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
		
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}




@end