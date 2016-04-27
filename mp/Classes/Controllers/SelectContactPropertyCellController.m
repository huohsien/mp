//
//  SelectContactPropertyCellController.m
//  mp
//
//  Created by M Tsai on 11-12-2.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//


#import "SelectContactPropertyCellController.h"

#import "MPFoundation.h"
#import "ContactProperty.h"
#import "AppUtility.h"


@implementation SelectContactPropertyCellController

@synthesize delegate;
@synthesize property;

//
// init
//
// Init method for the object.
//
- (id)initWithContactProperty:(ContactProperty *)newProperty;
{
	self = [super init];
	if (self != nil)
	{
        self.property = newProperty;
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
	[property release];
	[super dealloc];
}

#pragma mark -
#pragma mark tableView Methods


#define DISCLOSURE_BTN_TAG		13000

- (UIButton *) getDetailDiscolosureButton
{  
	float buttonSize = 44.0;
	float buffer = 0.0; //(44.0-buttonSize)/2.0;
	
	UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(320.0-44.0, buffer, buttonSize, buttonSize)] autorelease];
	button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	
	[button setBackgroundImage:[UIImage imageNamed:@"btn-tbl-detailed_disclosure.png"] forState:UIControlStateNormal];
	[button setBackgroundImage:[UIImage imageNamed:@"btn-tbl-detailed_disclosure-pressed.png"] forState:UIControlStateHighlighted];
	button.opaque = NO;
	button.backgroundColor = [UIColor clearColor];
	
	// ask parent to figure out which actual object's method to execute
	//  - because this cell may already be recycled
	/*[button addTarget:self.parentGenericTableViewController
     action:@selector(pressAccessoryButton:event:) forControlEvents:UIControlEventTouchUpInside];
     */
	button.tag = DISCLOSURE_BTN_TAG;
    return button;
} 


#define NAME_LABEL_TAG      15000
#define VALUE_LABEL_TAG     15001
#define RADIO_TAG           15002

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"ContactCell";
	
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		
		// name label
		UILabel *nLabel = [[UILabel alloc] init];
		nLabel.tag = NAME_LABEL_TAG;
		[cell.contentView addSubview:nLabel];
        
        // value label
		UILabel *vLabel = [[UILabel alloc] init];
		vLabel.tag = VALUE_LABEL_TAG;
		[cell.contentView addSubview:vLabel];
        
        NSArray *labelArray = [NSArray arrayWithObjects:nLabel, vLabel, nil];
        
		[AppUtility setCellStyle:kAUCellStyleSelectProperty labels:labelArray];
		[nLabel release];
        [vLabel release];
        
		// create radio button
		// 
		const CGFloat iconSize = 30.0;
		UIImageView *radioView = [[UIImageView alloc] initWithFrame:CGRectMake(3.0, (kMPParamTableRowHeight-iconSize)/2.0, iconSize, iconSize)];
        
		radioView.tag = RADIO_TAG;
		[cell.contentView addSubview:radioView];
		[radioView release];
	}
	
    // Set up the cell text
	UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_LABEL_TAG];
	nameLabel.text = self.property.name;
    
    UILabel *valueLabel = (UILabel *)[cell.contentView viewWithTag:VALUE_LABEL_TAG];
    // if possible use iOS formatting
    if (self.property.valueString) {
        valueLabel.text = self.property.valueString;
    }
    else {
        valueLabel.text = self.property.value;
    }
    
    // send message to this person?
	//
	UIImageView *radioImageView = (UIImageView *)[cell.contentView viewWithTag:RADIO_TAG];
	
	if (self.property.isSelected) {
		radioImageView.image = [UIImage imageNamed:@"std_icon_checkbox_prs.png"];
	}
	else {
		radioImageView.image = [UIImage imageNamed:@"std_icon_checkbox_nor.png"];
	}
    
    return cell;
}

// respond to cell selection
//  * enable or disable this email address
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCell *selectCell = [tableView cellForRowAtIndexPath:indexPath];
	
	// toggle enable state
	//
	UIImageView *radioImageView = (UIImageView *)[selectCell.contentView viewWithTag:RADIO_TAG];
	if (self.property.isSelected) {
		self.property.isSelected = NO;
		radioImageView.image = [UIImage imageNamed:@"std_icon_checkbox_nor.png"];
	}
	else {
		self.property.isSelected = YES;
		radioImageView.image = [UIImage imageNamed:@"std_icon_checkbox_prs.png"];
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // tell delegate that cell was selected
    if ([self.delegate respondsToSelector:@selector(SelectContactPropertyCellController:didSelect:)]){
        [self.delegate SelectContactPropertyCellController:self didSelect:self.property.isSelected];
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
	if (aTableView.editing) {
		return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellEditingStyleNone;
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
	return NO;
}


#pragma mark - Buttons


/*!
 @abstract Pressed Detailed Button - show detailed friend view
 */
- (void)pressDetailedDisclosureButton:(id)sender {
    
    
    
    
}

@end