//
//  FriendCellController.m
//  mp
//
//  Created by M Tsai on 11-9-8.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "ContactCellController.h"

#import "CDContact.h"
#import "CDChat.h"
#import "ChatDialogController.h"
#import "FriendInfoController.h"
#import "MPFoundation.h"
#import "TabBarFacade.h"
#import "TextEmoticonView.h"
#import "AppUtility.h"
#import "HeadShotDisplayView.h"




@implementation ContactCellController


@synthesize contact;
@synthesize parentController;
@synthesize imageManager;
@synthesize delegate;

//
// init
//
// Init method for the object.
//
- (id)initWithContact:(CDContact *)newContact
{
	self = [super init];
	if (self != nil)
	{
        self.contact = newContact;
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
    imageManager.delegate = nil;
    
    [imageManager release];
    [parentController release];
	[contact release];
	[super dealloc];
}

#pragma mark -
#pragma mark tableView Methods


#define DISCLOSURE_BTN_TAG		13000

- (UIButton *) getDetailDiscolosureButton
{  
	CGFloat buttonSize = 44.0;
	CGFloat buffer = (54.0-buttonSize)/2.0;
    CGFloat buttonStartX = 320.0-40.0; // -31.0 w/index
	
	UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(buttonStartX, buffer, buttonSize, buttonSize)] autorelease];
	button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	
	[button setBackgroundImage:[UIImage imageNamed:@"std_icon_disclosure_indicator_noalpha_nor.png"] forState:UIControlStateNormal];
	[button setBackgroundImage:[UIImage imageNamed:@"std_icon_disclosure_indicator_prs.png"] forState:UIControlStateHighlighted];
	button.opaque = YES;
	//button.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight]; //[UIColor clearColor];
	
	// ask parent to figure out which actual object's method to execute
	//  - because this cell may already be recycled
	/*[button addTarget:self.parentGenericTableViewController
			   action:@selector(pressAccessoryButton:event:) forControlEvents:UIControlEventTouchUpInside];
	*/
	button.tag = DISCLOSURE_BTN_TAG;
    return button;
} 

#define NAME_LABEL_TAG      15000
#define STATUS_LABEL_TAG    15001
#define PRESENCE_LABEL_TAG  15002
#define HEADSHOT_IMG_TAG    15003


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
		
        //CGRect testRect = cell.contentView.frame;
        
        UIImageView *backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_row_prs.png"]];
        cell.selectedBackgroundView = backImageView;
        [backImageView release];
        
        // white gloss effect bar - underneath the image
        UIView *whiteBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 0.5)];
        //whiteBar.backgroundColor = [UIColor whiteColor];
        whiteBar.backgroundColor = [UIColor colorWithRed:0.859 green:0.859 blue:0.859 alpha:1.0]; 

        [cell.contentView addSubview:whiteBar];
        [whiteBar release];
        
        // headshot
        //UIImageView *headShot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_headshot_bear_black.png"]];
        //headShot.frame = CGRectMake(0.0, 0.0, 54.0, 54.0);
        UIButton *headShotButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 54.0, 54.0)];
        //[headShotButton.imageView setContentMode:UIViewContentModeScaleToFill];
        //[headShotButton setImage:[UIImage imageNamed:@"profile_headshot_bear_black.png"] forState:UIControlStateNormal];
        headShotButton.tag = HEADSHOT_IMG_TAG;
        [cell.contentView addSubview:headShotButton];
        [headShotButton release];
        
        // presence label - added first so that is does not cover name or status - bottom layer
		UILabel *pLabel = [[UILabel alloc] init];
		pLabel.tag = PRESENCE_LABEL_TAG;
		[cell.contentView addSubview:pLabel];
        
		// name label
		UILabel *nLabel = [[UILabel alloc] init];
		nLabel.tag = NAME_LABEL_TAG;
		[cell.contentView addSubview:nLabel];
        
        // status label
		TextEmoticonView *sLabel = [[TextEmoticonView alloc] init];
		sLabel.tag = STATUS_LABEL_TAG;
		[cell.contentView addSubview:sLabel];

        
        NSArray *labelArray = [NSArray arrayWithObjects:nLabel, sLabel, pLabel, nil];
        
		[AppUtility setCellStyle:kAUCellStyleFriendList labels:labelArray];

		[nLabel release];
        [sLabel release];
        [pLabel release];
        		        
        // create detailed disclosure button
        //cell.accessoryView = [self getDetailDiscolosureButton];
        [cell.contentView insertSubview:[self getDetailDiscolosureButton] atIndex:0];
        

	}
	
    // if headshot exits, set the image
    //
    UIButton *headView = (UIButton *)[cell.contentView viewWithTag:HEADSHOT_IMG_TAG];
    UIImage *gotImage = [self.imageManager getImageForObject:self.contact context:kMPImageContextList];
	if (gotImage) {
        [headView setBackgroundImage:gotImage forState:UIControlStateNormal];
    }
    else {
        [headView setBackgroundImage:[UIImage imageNamed:@"profile_headshot_bear_black.png"] forState:UIControlStateNormal];
    }
    [headView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [headView addTarget:self action:@selector(pressHeadShot:) forControlEvents:UIControlEventTouchUpInside];
    
    
    // Set up the cell text
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_LABEL_TAG];
	nameLabel.text = [self.contact displayName];
    
    TextEmoticonView *statusLabel = (TextEmoticonView *)[cell.contentView viewWithTag:STATUS_LABEL_TAG];
	//statusLabel.text = self.contact.statusMessage;
    //[statusLabel setText:self.contact.statusMessage];
    [statusLabel setText:[self.contact oneLineStatusMessage]];

    
    UILabel *presenceLabel = (UILabel *)[cell.contentView viewWithTag:PRESENCE_LABEL_TAG];
	presenceLabel.text = [self.contact presenceString];
    
    
    
    // update to current target! - otherwise will point to wrong target and crash
    //
    UIButton *detDisclosureButton = (UIButton *)[cell.contentView viewWithTag:DISCLOSURE_BTN_TAG];   //cell.accessoryView;
    
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
	
    DDLogVerbose(@"CCC-dsr: pressed %@", self.contact);

    if ([self.delegate respondsToSelector:@selector(ContactCellController:startChatWithContact:)]) {
        [self.delegate ContactCellController:self startChatWithContact:self.contact];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    //DDLogVerbose(@"***CCC-dsr: test %@ %@", self.contact.displayName, self.contact.addFriendDate);

    
}

// 
// For some reason background color must be set right before cell is displayed
//
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // highlight new friends - set background color
    //
    if ([self.contact isNewFriend]) {
        cell.backgroundColor = [AppUtility colorForContext:kAUColorTypeTableSelected];
		cell.contentView.backgroundColor = [AppUtility colorForContext:kAUColorTypeTableSelected];
        cell.backgroundColor = [AppUtility colorForContext:kAUColorTypeTableSelected];
        for (UIView *iView in cell.contentView.subviews){
            if ([iView respondsToSelector:@selector(setText:)]) {
                iView.backgroundColor = [AppUtility colorForContext:kAUColorTypeTableSelected];
            }
        }
        
        UIButton *disclosureButton = (UIButton *)[cell.contentView viewWithTag:DISCLOSURE_BTN_TAG];
        [disclosureButton setBackgroundImage:[UIImage imageNamed:@"std_icon_disclosure_indicator_nor.png"] forState:UIControlStateNormal];
        
    }
    else {
        if (cell.backgroundColor != [AppUtility colorForContext:kAUColorTypeBackgroundLight]) {
            cell.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            cell.contentView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            for (UIView *iView in cell.contentView.subviews){
                if ([iView respondsToSelector:@selector(setText:)]) {
                    iView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];

                }
            }
        }
    }
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
 @abstract Pressed HeadShot
 */
- (void)pressHeadShot:(id)sender {

    //NSString *url = [self.contact imageURLForContext:nil ignoreVersion:NO];
    
    // only show if there is a file to download
    if (YES /*url*/) {
        CGRect appFrame = [Utility appFrame];
        
        //CGRect letterRect = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height);
        
        HeadShotDisplayView *headShotView = [[HeadShotDisplayView alloc] initWithFrame:appFrame contact:self.contact];
        
        UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
        
        [containerVC.view addSubview:headShotView];
        [headShotView release];
    }
}

/*!
 @abstract Pressed Detailed Button - show detailed friend view
 */
- (void)pressDetailedDisclosureButton:(id)sender {
    
    
    FriendInfoController *nextController = [[FriendInfoController alloc] initWithContact:self.contact];
    [self.parentController.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    
}


#pragma mark - Image 

/*!
 @abstract Called when data has completed loading and is ready to use.
 
 - find my cell and update the image!
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager finishLoadingImage:(UIImage *)image{
    
    // ask tableview to refresh if the cell is visible
    if ([self.delegate respondsToSelector:@selector(ContactCellController:refreshContact:)]) {
        [self.delegate ContactCellController:self refreshContact:self.contact];
    }

}






@end