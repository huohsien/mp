//
//  SuggestCellController.m
//  mp
//
//  Created by Min Tsai on 2/19/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "SuggestCellController.h"
#import "AppUtility.h"
#import "MPFoundation.h"
#import "CDContact.h"
#import "TextEmoticonView.h"
#import "MPContactManager.h"
#import "HeadShotDisplayView.h"

@implementation SuggestCellController

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processGetUserInfo:) name:MP_HTTPCENTER_GETUSERINFO_ADD_NOTIFICATION object:nil];
        
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    imageManager.delegate = nil;

    [imageManager release];
	[contact release];
	[super dealloc];
}

#define kNameWidthFull          175.0
#define kNameWidthShort         100.0

#define NAME_LABEL_TAG          15000
#define HEADSHOT_IMG_TAG        15001
#define STATUS_LABEL_TAG        15002
#define RESULT_LABEL_TAG        15003
#define BLOCK_BTN_TAG           15004
#define ADD_BTN_TAG             15005

#pragma mark - Custom Methods

/*!
 @abstract Show option buttons
 */
- (void)tableView:(UITableView *)tableView showOptionsAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_LABEL_TAG];
    UILabel *statusLabel = (UILabel *)[cell.contentView viewWithTag:STATUS_LABEL_TAG];
    UILabel *resultLabel = (UILabel *)[cell.contentView viewWithTag:RESULT_LABEL_TAG];
    
    UIButton *blockButton = (UIButton *)[cell.contentView viewWithTag:BLOCK_BTN_TAG];
    UIButton *addButton = (UIButton *)[cell.contentView viewWithTag:ADD_BTN_TAG];

    // if hidden and status is not already defined
    // - show options
    if (blockButton.alpha == 0.0 && resultLabel.alpha == 0.0) {
        
        if (animated) {
            [UIView animateWithDuration:kMPParamAnimationStdDuration/2.0
                             animations:^{
                                 nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, 
                                                              nameLabel.frame.origin.y, 
                                                              kNameWidthShort, 
                                                              nameLabel.frame.size.height);
                                 statusLabel.alpha = 0.0;
                             } 
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     [UIView animateWithDuration:kMPParamAnimationStdDuration/2.0
                                                      animations:^{
                                                          blockButton.alpha = 1.0;
                                                          addButton.alpha = 1.0;
                                                      }];
                                 }
                             }];
        }
        else {
            nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, 
                                         nameLabel.frame.origin.y, 
                                         kNameWidthShort, 
                                         nameLabel.frame.size.height);
            statusLabel.alpha = 0.0;
            blockButton.alpha = 1.0;
            addButton.alpha = 1.0;
        }
        
    }
    else {
        
    }
}


/*!
 @abstract Hide option buttons
 */
- (void)tableView:(UITableView *)tableView hideOptionsAtIndexPath:(NSIndexPath *)indexPath showResult:(BOOL)showResult{
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_LABEL_TAG];    
    UILabel *statusLabel = (UILabel *)[cell.contentView viewWithTag:STATUS_LABEL_TAG];
    UILabel *resultLabel = (UILabel *)[cell.contentView viewWithTag:RESULT_LABEL_TAG];

    
    UIButton *blockButton = (UIButton *)[cell.contentView viewWithTag:BLOCK_BTN_TAG];
    UIButton *addButton = (UIButton *)[cell.contentView viewWithTag:ADD_BTN_TAG];
    
    if (!showResult && addButton.alpha == 0.0 && blockButton.alpha == 0.0) {
        addButton.alpha = 0.0;
        blockButton.alpha = 0.0;
        return;
    }
    
    if (YES /*blockButton.alpha == 1.0*/) {
        DDLogInfo(@"hide ip:%@ %f", indexPath, blockButton.alpha);
        [UIView animateWithDuration:kMPParamAnimationStdDuration/2.0
                         animations:^{
                             blockButton.alpha = 0.0;
                             addButton.alpha = 0.0;
                         } 
                         completion:^(BOOL finished) {
                             if (finished) {
                                 if (showResult) {
                                     if ([self.contact isFriend]) {
                                         resultLabel.text = NSLocalizedString(@"Added", @"Suggest - text: contact added as friend");
                                     }
                                     if ([self.contact isBlockedByMe]) {
                                         resultLabel.text = NSLocalizedString(@"Blocked", @"Suggest - text: contact has been blocked");
                                     }
                                     
                                     [UIView animateWithDuration:kMPParamAnimationStdDuration/2.0
                                                      animations:^{
                                                          nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, 
                                                                                       nameLabel.frame.origin.y, 
                                                                                       kNameWidthFull, 
                                                                                       nameLabel.frame.size.height);
                                                          if (showResult) {
                                                              resultLabel.alpha = 1.0;
                                                          }
                                                          else {
                                                              statusLabel.alpha = 1.0;
                                                          }
                                                      }];
                                     
                                 }
                             }
                         }];
    }
}


#pragma mark - tableView Methods


#define kButtonWidth        70.0
#define kButtonHeight       30.0
#define kButtonMarginEdge   10.0
#define kButtonMargin       10.0





- (UIButton *) getBlockButton
{  
	
    CGRect appFrame = [Utility appFrame];
    
	UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(appFrame.size.width-kButtonWidth*2.0-kButtonMargin-kButtonMarginEdge, (kMPParamTableRowHeight-kButtonHeight)/2.0, kButtonWidth, kButtonHeight)] autorelease];
    [AppUtility configButton:button context:kAUButtonTypeOrange2];
    [button setTitle:NSLocalizedString(@"Block", @"Suggest - button: block this user") forState:UIControlStateNormal];
    button.tag = BLOCK_BTN_TAG;
    return button;
} 



- (UIButton *) getAddButton
{  
	
    CGRect appFrame = [Utility appFrame];
    
	UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(appFrame.size.width-kButtonWidth-kButtonMarginEdge, (kMPParamTableRowHeight-kButtonHeight)/2.0, kButtonWidth, kButtonHeight)] autorelease];
    [AppUtility configButton:button context:kAUButtonTypeGreen3];
    [button setTitle:NSLocalizedString(@"Add", @"Suggest - button: add this user") forState:UIControlStateNormal];
    button.tag = ADD_BTN_TAG;
    return button;
    
} 



//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"SuggestCell";
    
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
        UIButton *headShotButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 54.0, 54.0)];
        headShotButton.tag = HEADSHOT_IMG_TAG;
        [cell.contentView addSubview:headShotButton];
        [headShotButton release];
        
        
        // result label - added first so that is does not cover name or status - bottom layer
		UILabel *rLabel = [[UILabel alloc] init];
		rLabel.tag = RESULT_LABEL_TAG;
		[cell.contentView addSubview:rLabel];
        
		// name label
		UILabel *nLabel = [[UILabel alloc] init];
		nLabel.tag = NAME_LABEL_TAG;
		[cell.contentView addSubview:nLabel];
        
        // status label
        TextEmoticonView *sLabel = [[TextEmoticonView alloc] init];
		sLabel.tag = STATUS_LABEL_TAG;
		[cell.contentView addSubview:sLabel];
        
        NSArray *labelArray = [NSArray arrayWithObjects:nLabel, sLabel, rLabel, nil];
        
		[AppUtility setCellStyle:kAUCellStyleSuggestList labels:labelArray];
		[nLabel release];
        [sLabel release];
        [rLabel release];
        
        UIButton *blockButton = [self getBlockButton];
        blockButton.alpha = 0.0;
        [cell.contentView addSubview:blockButton];
        
        UIButton *addButton = [self getAddButton];
        addButton.alpha = 0.0;
        [cell.contentView addSubview:addButton];   
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
    
    UILabel *statusLabel = (UILabel *)[cell.contentView viewWithTag:STATUS_LABEL_TAG];
	// disable for privacy
    // statusLabel.text = self.contact.statusMessage;
    
    // clear result text 
    UILabel *resultLabel = (UILabel *)[cell.contentView viewWithTag:RESULT_LABEL_TAG];
	resultLabel.text = @"";
    resultLabel.alpha = 0.0;
    
    // update to current target! - otherwise will point to wrong target and crash
    //
    UIButton *blockButton = (UIButton *)[cell.contentView viewWithTag:BLOCK_BTN_TAG];
    [blockButton removeTarget:nil 
                               action:NULL 
                     forControlEvents:UIControlEventAllEvents]; 
    [blockButton addTarget:self action:@selector(pressBlock:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *addButton = (UIButton *)[cell.contentView viewWithTag:ADD_BTN_TAG];
    [addButton removeTarget:nil 
                       action:NULL 
             forControlEvents:UIControlEventAllEvents]; 
    [addButton addTarget:self action:@selector(pressAdd:) forControlEvents:UIControlEventTouchUpInside];
    
    // reset view if the cell was showing options
    nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, 
                                 nameLabel.frame.origin.y, 
                                 kNameWidthFull, 
                                 nameLabel.frame.size.height);
    statusLabel.alpha = 1.0;
    blockButton.alpha = 0.0;
    addButton.alpha = 0.0;
    
    // tell table we just got refreshed
    // - so it can clear this contact if it was selected before
    //
    if ([self.delegate respondsToSelector:@selector(SuggestCellController:refreshedContact:)]) {
        [self.delegate SuggestCellController:self refreshedContact:self.contact];
    }
    
    return cell;
}

// respond to cell selection
//  - animate and shows option
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    [self tableView:tableView showOptionsAtIndexPath:indexPath animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(SuggestCellController:didTapIndexPath:)]) {
        [self.delegate SuggestCellController:self didTapIndexPath:indexPath];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

// 
// For some reason background color must be set right before cell is displayed
//
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell.
    //cell.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
    
    
    // highlight new friends - set background color
    //
    if ([self.contact isNewFriendSuggestion]) {
        cell.backgroundColor = [AppUtility colorForContext:kAUColorTypeTableSelected];
		cell.contentView.backgroundColor = [AppUtility colorForContext:kAUColorTypeTableSelected];
        cell.backgroundColor = [AppUtility colorForContext:kAUColorTypeTableSelected];
        for (UIView *iView in cell.contentView.subviews){
            if ([iView respondsToSelector:@selector(setText:)]) {
                iView.backgroundColor = [AppUtility colorForContext:kAUColorTypeTableSelected];
            }
        }
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
 @abstract Pressed HeadShot
 */
- (void)pressHeadShot:(id)sender {
    
    //NSString *url = [self.contact imageURLForContext:nil ignoreVersion:NO];
    
    // only show if there is a file to download
    if (YES /*url*/) {
        CGRect appFrame = [Utility appFrame];
                
        HeadShotDisplayView *headShotView = [[HeadShotDisplayView alloc] initWithFrame:appFrame contact:self.contact];
        UIViewController *containerVC = [[AppUtility getAppDelegate] containerController];
        [containerVC.view addSubview:headShotView];
        [headShotView release];
    }
}


/*!
 @abstract block friend
 */
- (void)pressBlock:(id)sender {
    
    // observe block events
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processBlock:) name:MP_HTTPCENTER_BLOCK_NOTIFICATION object:nil];
    
    [AppUtility startActivityIndicator];
    [[MPHTTPCenter sharedMPHTTPCenter] blockUser:self.contact.userID];

}


/*!
 @abstract pressed add - add this found user as a friend!
 
 Submit presence query server first
 
 */
- (void)pressAdd:(id) sender {
    

    
    [AppUtility startActivityIndicator];
    
    // userID to tag this request
    // - so we can identify if response is for us
    [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:[NSArray arrayWithObject:self.contact.userID] action:kMPHCQueryTagAdd idTag:self.contact.userID itemType:kMPHCItemTypeUserID];
    
}


#pragma mark - Process Responses


/*!
 @abstract process block response
 
 Successful case
 <Block>
 <cause>0</cause>
 </Block>
 
 Exception case
 <Block>
 <cause>602</cause>
 <text>invalid USERID!</text>
 </Block>
 
 */
- (void) processBlock:(NSNotification *)notification {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [AppUtility stopActivityIndicator];
    NSDictionary *responseD = [notification object];
    
    // go ahead and block user
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {

        
       
        
        NSManagedObjectID *blockUserObjectID = [self.contact objectID];
        
        // block user
        //
        dispatch_async([AppUtility getBackgroundMOCQueue], ^{
            
            CDContact *blockContact = (CDContact *)[[AppUtility cdGetManagedObjectContext] objectWithID:blockUserObjectID];
            
            [blockContact blockUser];
            [AppUtility cdSaveWithIDString:@"block friend suggestion" quitOnFail:NO];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // inform table to animate changes
                //
                if ([self.delegate respondsToSelector:@selector(SuggestCellController:didChangeStateForContact:)]) {
                    [self.delegate SuggestCellController:self didChangeStateForContact:self.contact];
                }
                
            });
        });
        
        
    }
    // ask to confirm
    else {
        
        NSString *title = NSLocalizedString(@"Block Contact", @"Suggest - alert title:");
        NSString *detMessage = NSLocalizedString(@"Block failed. Try again later.", @"Suggest - alert: Inform of failure");
        
        [Utility showAlertViewWithTitle:title message:detMessage];
        
    }
}


- (void) showFailureAlert {
    
    NSString *title = NSLocalizedString(@"Add Friend", @"FindID - alert title:");
    NSString *detMessage = NSLocalizedString(@"Add friend failed. Try again later.", @"FindID - alert: Inform of failure");
    
    [Utility showAlertViewWithTitle:title message:detMessage];
    
}

/*!
 @abstract Did add friend process succeed for the M+ ID friend?
 
 If successful, then add this person as a friend in the DB, update new friend badge
 
 // notification object
 //
 NSMutableDictionary *newD = [[NSMutableDictionary alloc] initWithDictionary:responseDictionary];
 [newD setValue:presenceArray forKey:@"array"];
 
 */
- (void) processGetUserInfo:(NSNotification *)notification {
    
    if (self.contact) {
        
        BOOL didAdd = [MPContactManager processAddFriendNotification:notification contactToAdd:self.contact];
        
        if (didAdd) {
            
            // inform table to animate changes
            //
            if ([self.delegate respondsToSelector:@selector(SuggestCellController:didChangeStateForContact:)]) {
                [self.delegate SuggestCellController:self didChangeStateForContact:self.contact];
            }
        }
    }
    
}





#pragma mark - Image 

/*!
 @abstract Called when data has completed loading and is ready to use.
 
 - find my cell and update the image!
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager finishLoadingImage:(UIImage *)image{
    
    // ask tableview to refresh if the cell is visible
    if ([self.delegate respondsToSelector:@selector(SuggestCellController:refreshContact:)]) {
        [self.delegate SuggestCellController:self refreshContact:self.contact];
    }
    
}


@end