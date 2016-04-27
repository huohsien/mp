//
//  BlockedCellController.m
//  mp
//
//  Created by M Tsai on 11-12-5.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//


#import "BlockedCellController.h"
#import "AppUtility.h"
#import "MPFoundation.h"
#import "CDContact.h"
#import "TextEmoticonView.h"

@implementation BlockedCellController

@synthesize delegate;
@synthesize contact;
@synthesize imageManager;

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
        self.contact = newObject;  
        
        MPImageManager *newIM = [[MPImageManager alloc] init];
        newIM.delegate = self;
        self.imageManager = newIM;
        [newIM release];
        
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
	[contact release];
	[super dealloc];
}

#pragma mark - tableView Methods


#define DISCLOSURE_BTN_TAG		13000

- (UIButton *) getDetailDiscolosureButton
{  
	CGFloat buttonWidth = 90.0;
    CGFloat buttonHeight = 30.0;
	CGFloat buffer = 10.0; //(44.0-buttonSize)/2.0;
	
	UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(320.0-buttonWidth-buffer, (kMPParamTableRowHeight-buttonHeight)/2.0, buttonWidth, buttonHeight)] autorelease];
    
    [AppUtility configButton:button context:kAUButtonTypeGreen];

	button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
	
    [button setTitle:NSLocalizedString(@"Unblock", @"BlockUser - button: unblock this blocked user") forState:UIControlStateNormal];
    
	button.tag = DISCLOSURE_BTN_TAG;
    return button;
} 

#define NAME_LABEL_TAG          15000
#define HEADSHOT_IMG_TAG        15001
#define STATUS_LABEL_TAG        15002

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"BlockCell";
	
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		
        UIImageView *backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_row_prs.png"]];
        cell.selectedBackgroundView = backImageView;
        [backImageView release];
        
        // white bar at top
        UIView *whiteBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 0.5)];
        whiteBar.backgroundColor = [UIColor whiteColor];
        [cell.contentView addSubview:whiteBar];
        [whiteBar release];
        
        
        // headshot
        UIImageView *headShot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_headshot_bear_black.png"]];
        headShot.frame = CGRectMake(0.0, 0.0, 54, 54.0);
        headShot.tag = HEADSHOT_IMG_TAG;
        [cell.contentView addSubview:headShot];
        [headShot release];
        
		// name label
		UILabel *nLabel = [[UILabel alloc] init];
		nLabel.tag = NAME_LABEL_TAG;
		[cell.contentView addSubview:nLabel];
        
        // status label
        /*TextEmoticonView *sLabel = [[TextEmoticonView alloc] init];
		sLabel.tag = STATUS_LABEL_TAG;
		[cell.contentView addSubview:sLabel];
        */
        //NSArray *labelArray = [NSArray arrayWithObjects:nLabel, sLabel, nil];
        
        NSArray *labelArray = [NSArray arrayWithObjects:nLabel, nil];

		[AppUtility setCellStyle:kAUCellStyleBlockList labels:labelArray];
		[nLabel release];
        //[sLabel release];
        
        // create detailed disclosure button
        [cell.contentView addSubview:[self getDetailDiscolosureButton]];
    }
	
    // if headshot exits, set the image
    //
    // if headshot exits, set the image
    //
    UIImageView *headView = (UIImageView *)[cell.contentView viewWithTag:HEADSHOT_IMG_TAG];
    UIImage *gotImage = [self.imageManager getImageForObject:self.contact context:kMPImageContextList];
	if (gotImage) {
        headView.image = gotImage;
    }
    else {
        headView.image = [UIImage imageNamed:@"profile_headshot_bear_black.png"];
    }
    

    // Set up the cell text
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_LABEL_TAG];
	nameLabel.text = [self.contact displayName];
    
    TextEmoticonView *statusLabel = (TextEmoticonView *)[cell.contentView viewWithTag:STATUS_LABEL_TAG];
    [statusLabel setText:self.contact.statusMessage];
    //testing - statusLabel.backgroundColor = [UIColor blueColor];
    
    
    // update to current target! - otherwise will point to wrong target and crash
    //
    UIButton *detDisclosureButton = (UIButton *)[cell.contentView viewWithTag:DISCLOSURE_BTN_TAG];
    
    [detDisclosureButton removeTarget:nil 
                               action:NULL 
                     forControlEvents:UIControlEventAllEvents]; 
    [detDisclosureButton addTarget:self action:@selector(pressDetailedDisclosureButton:) forControlEvents:UIControlEventTouchUpInside];
    
    /*
     [previewButton removeTarget:nil 
     action:NULL 
     forControlEvents:UIControlEventAllEvents]; 
     [previewButton addTarget:self action:@selector(pressPreviewButton:) forControlEvents:UIControlEventTouchUpInside];
     */
    return cell;
}

// respond to cell selection
//  * enable or disable this email address
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // nothing to do if press cell
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

// 
// For some reason background color must be set right before cell is displayed
//
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell.
    cell.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
}

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


#pragma mark - Buttons


/*!
 @abstract Pressed Detailed Button - unblock this contact
 */
- (void)pressDetailedDisclosureButton:(id)sender {
    
    // inform table that this row was tapped
    //
    if ([self.delegate respondsToSelector:@selector(blockedCellController:unblockContact:)]) {
        [self.delegate blockedCellController:self unblockContact:self.contact];
    }
    
}


/*!
 @abstract Called when data has completed loading and is ready to use.
 
 - find my cell and update the image!
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager finishLoadingImage:(UIImage *)image{
    
    // ask tableview to refresh if the cell is visible
    if ([self.delegate respondsToSelector:@selector(blockedCellController:refreshContact:)]) {
        [self.delegate blockedCellController:self refreshContact:self.contact];
    }
}


@end