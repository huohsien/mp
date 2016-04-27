//
//  SelectCellController.m
//  mp
//
//  Created by M Tsai on 11-11-26.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "SelectCellController.h"
#import "AppUtility.h"
#import "TKLog.h"


@implementation SelectCellController

@synthesize delegate;
@synthesize cellObject;
@synthesize rowPosition;

//
// init
//
// Init method for the object.
//
- (id)initWithObject:(id)newObject;
{
	self = [super init];
	if (self != nil)
	{
        self.cellObject = newObject;
        self.rowPosition = kRowPositionMiddle;
        
	}
	return self;
}


//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[cellObject release];
	[super dealloc];
}

#pragma mark -
#pragma mark tableView Methods




#define NAME_LABEL_TAG	15000
#define RADIO_TAG       15001

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"SelectCell";
	
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		
		// name label
		UILabel *nLabel = [[UILabel alloc] init];
		nLabel.tag = NAME_LABEL_TAG;
		[cell.contentView addSubview:nLabel];
        
		[AppUtility setCellStyle:kAUCellStyleBasic labels:[NSArray arrayWithObject:nLabel]];
		[nLabel release];
                
		// set background color
		cell.backgroundColor = [UIColor whiteColor];
	}
	
    // Set up the cell text
	UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_LABEL_TAG];
	nameLabel.text = [self.cellObject description];
    
    // set cell background image
	//
	if (self.rowPosition == kRowPositionTop) {
		UIImageView *prsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_statusfield_top_prs"]];
		cell.selectedBackgroundView = prsView;
        [prsView release];
        UIImageView *rowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_statusfield_top_nor"]];
		cell.backgroundView = rowView;
		[rowView release];
	}
	else if (self.rowPosition == kRowPositionBottom) {
		UIImageView *prsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_statusfield_bottom_prs"]];
		cell.selectedBackgroundView = prsView;
        [prsView release];
        UIImageView *rowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_statusfield_bottom_nor"]];
		cell.backgroundView = rowView;
		[rowView release];
	}
    // TODO: if only one row possible, we need a custom image here!
	else if (self.rowPosition == kRowPositionSingle) {
		UIImageView *prsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_statusfield_center_prs"]];
		cell.selectedBackgroundView = prsView;
        [prsView release];
        UIImageView *rowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_statusfield_center_nor"]];
		cell.backgroundView = rowView;
		[rowView release];
	}
	else {
        UIImageView *prsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_statusfield_center_prs"]];
		cell.selectedBackgroundView = prsView;
        [prsView release];
        UIImageView *rowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_statusfield_center_nor"]];
		cell.backgroundView = rowView;
		[rowView release];
	}
    
    return cell;
}

// respond to cell selection
//  * enable or disable this email address
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    DDLogVerbose(@"CCC-dsr: pressed %@", self.cellObject);
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // inform table that this row was tapped
    //
    if ([self.delegate respondsToSelector:@selector(selectCellController:tappedObject:)]) {
        [self.delegate selectCellController:self tappedObject:self.cellObject];
    }
}

// 
// For some reason background color must be set right before cell is displayed
//
/*- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
 // Configure the cell.
 
 
 Group *cellGroup = self.groupObject;
 if (cellGroup.backgroundColor && ![cellGroup.backgroundColor isEqual:[UIColor whiteColor]]) {
 cell.backgroundColor = cellGroup.backgroundColor;
 cell.textLabel.textColor = [UIColor whiteColor];
 }
 else {
 cell.backgroundColor = [UIColor whiteColor];
 cell.textLabel.textColor = [UIColor darkTextColor];
 }
 }*/

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
	return YES;
}


// Which style to show for editing
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	// don't allow swipe delete - only delete in editing mode
	/*if (aTableView.editing) {
		return UITableViewCellEditingStyleDelete;
	}*/
	return UITableViewCellEditingStyleNone;
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
	return NO;
}

@end



