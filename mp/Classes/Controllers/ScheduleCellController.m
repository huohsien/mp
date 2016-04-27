//
//  ScheduleCellController.m
//  mp
//
//  Created by Min Tsai on 1/20/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "ScheduleCellController.h"
#import "CDMessage.h"
#import "AppUtility.h"
#import "Utility.h"
#import "TextEmoticonView.h"
#import "ScheduleCell.h"

@implementation ScheduleCellController

@synthesize cdMessage;
@synthesize imageManager;
@synthesize delegate;


/*!
 @abstract initialized cell controller with related scheduled CDMessage
 
 */
- (id)initWithCDMessage:(CDMessage *)newCDMessage
{
	self = [super init];
	if (self != nil)
	{
        self.cdMessage = newCDMessage;
        
        MPImageManager *newIM = [[MPImageManager alloc] init];
        newIM.delegate = self;
        self.imageManager = newIM;
        [newIM release];
        
	}
	return self;
}

- (void)dealloc {
    imageManager.delegate = nil;
    
    [imageManager release];
    [parentController release];
    [cdMessage release];
    [super dealloc];
}





#pragma mark -
#pragma mark tableView Methods

#define HEADSHOT_IMG_TAG    12001
#define NAME_LABEL_TAG      14000
#define DATE_LABEL_TAG      14001
#define MESSAGE_LABEL_TAG   14003
#define GROUP_BADGE_TAG     14008
    

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"ScheduleCell";
    
    
    ScheduleCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        
        
        cell = [[[ScheduleCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		
        cell.contentView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
        
        UIImageView *backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_row_prs.png"]];
        cell.selectedBackgroundView = backImageView;
        [backImageView release];
        
        UIView *whiteBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 0.5)];
        whiteBar.backgroundColor = [UIColor whiteColor];
        [cell.contentView addSubview:whiteBar];
        [whiteBar release];
        
        // headshot
        UIImageView *headShot = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 54.0, 54.0)];
        headShot.tag = HEADSHOT_IMG_TAG;
        [cell.contentView addSubview:headShot];
        [headShot release];
        
        
        // sent date label
        // - add first so it is at the bottom and does not cover name
        //
        UILabel *dLabel = [[UILabel alloc] init];
        dLabel.tag = DATE_LABEL_TAG;
        [cell.contentView addSubview:dLabel];
        
        
		// name label
		UILabel *nLabel = [[UILabel alloc] init];
		nLabel.tag = NAME_LABEL_TAG;
		[cell.contentView addSubview:nLabel];
        
        // group badge button
        //
        UIButton *groupButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 18.0, 18.0)];
        [groupButton setBackgroundImage:[UIImage imageNamed:@"chat_badge_group.png"] forState:UIControlStateNormal];
        [groupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        groupButton.titleEdgeInsets = UIEdgeInsetsMake(1.0, 0.0, 0.0, 0.0);
        groupButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicroPlus];
        groupButton.userInteractionEnabled = NO;
        groupButton.hidden = YES;
        groupButton.tag = GROUP_BADGE_TAG;
        [cell.contentView addSubview:groupButton];
        [groupButton release];
        
        
        // message label
        //
        TextEmoticonView *messageLabel = [[TextEmoticonView alloc] init];
        messageLabel.lineBreakMode = UILineBreakModeTailTruncation;
        messageLabel.tag = MESSAGE_LABEL_TAG;
        [messageLabel setBackgroundColor:[UIColor redColor]];
        [cell.contentView addSubview:messageLabel];
        

        
        
        /*// my message label
         //
         UILabel *myLabel = [[UILabel alloc] init];
         myLabel.backgroundColor = [UIColor clearColor];
         [AppUtility configLabel:myLabel context:kAULabelTypeTableMainText];
         myLabel.tag = MY_LABEL_TAG;
         [myBubbleView addSubview:myLabel];
         [myLabel release];
         [myBubbleView release];*/
        
        
        NSArray *labelArray = [NSArray arrayWithObjects:nLabel, messageLabel, dLabel, nil];
        
		[AppUtility setCellStyle:kAUCellStyleScheduleList labels:labelArray]; //kAUCellStyleScheduleList
		[nLabel release];
        [messageLabel release];
        [dLabel release];
        

        
	}
    
    // get components
    UIImageView *headShotView = (UIImageView *)[cell.contentView viewWithTag:HEADSHOT_IMG_TAG];
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_LABEL_TAG];
    UILabel *dateLabel = (UILabel *)[cell.contentView viewWithTag:DATE_LABEL_TAG];
    TextEmoticonView *messageLabel = (TextEmoticonView *)[cell.contentView viewWithTag:MESSAGE_LABEL_TAG];
    UIButton *groupBadgeButton = (UIButton *)[cell.contentView viewWithTag:GROUP_BADGE_TAG];

    
    // headshot update
    //
    headShotView.image = [UIImage imageNamed:@"profile_headshot_bear_black.png"];
    
    if ([self.cdMessage.contactsTo count] > 1){
        headShotView.image = [UIImage imageNamed:@"schedulemessage_icon_multi.png"];
    }
    else {
        CDContact *chatFriend = [self.cdMessage.contactsTo anyObject];
        UIImage *gotImage = [self.imageManager getImageForObject:chatFriend context:kMPImageContextList];
        if (gotImage) {
            headShotView.image = gotImage;
        }
        else {
            headShotView.image = [UIImage imageNamed:@"profile_headshot_bear_black.png"];
        }
    }
    
    nameLabel.text =  [self.cdMessage displayName];
    
    if (self.cdMessage.dateScheduled) {
        //dateLabel.text = [Utility shortStyleTimeDate:self.cdMessage.dateScheduled];  //
        dateLabel.text = [Utility terseDateString:self.cdMessage.dateScheduled];
    }
    else {
        dateLabel.text = @"";
    }
    
    
    // if broadcasting to more than 1 person
    //
    NSUInteger broadcastCount = [self.cdMessage.contactsTo count];
    if (broadcastCount > 1) {
        groupBadgeButton.hidden = NO;
        NSString *groupCount = [NSString stringWithFormat:@"%d", broadcastCount];
        [groupBadgeButton setTitle:groupCount forState:UIControlStateNormal];
        
        /*
         CGSize nameSize = [nameLabel sizeThatFits:nameLabel.frame.size];
         CGRect newFrame = groupBadgeButton.frame;
         newFrame.origin.x = nameLabel.frame.origin.x + MIN(nameSize.width + 10.0, 170.0);
         newFrame.origin.y = nameLabel.frame.origin.y + (nameLabel.frame.size.height-newFrame.size.height)/2.0;
         groupBadgeButton.frame = newFrame;
         */
    }
    else {
        groupBadgeButton.hidden = YES;
    }
    
    
    [messageLabel setText:[self.cdMessage getDescriptionString]];
    return cell;
}




// respond to cell selection
//  * enable or disable this email address
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if ([self.delegate respondsToSelector:@selector(ScheduleCellController:tappedMessage:)]) {
        [self.delegate ScheduleCellController:self tappedMessage:self.cdMessage];
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// 
// For some reason background color must be set right before cell is displayed
//
/*
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
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

#pragma mark - Image 

/*!
 @abstract Called when data has completed loading and is ready to use.
 
 - find my cell and update the image!
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager finishLoadingImage:(UIImage *)image{
    
    /*
    // ask tableview to refresh if the cell is visible
    if ([self.delegate respondsToSelector:@selector(ChatCellController:refreshChat:)]) {
        [self.delegate ChatCellController:self refreshChat:self.cdChat];
    }
     */
}


@end
