//
//  ChatCellController.m
//  mp
//
//  Created by M Tsai on 11-9-26.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "ChatCellController.h"
#import "CDChat.h"
#import "ChatDialogController.h"
#import "CDMessage.h"
#import "AppUtility.h"
#import "Utility.h"
#import "TextEmoticonView.h"
#import "TKLog.h"
#import "ChatCell.h"


@implementation ChatCellController

@synthesize cdChat;
@synthesize imageManager;
@synthesize delegate;




/*!
 @abstract initialized cell controller with related CDMessage
 
 if CDMessage is not available, then this is an blank message where user 
 can write a new message.
 
 */
- (id)initWithCDChat:(CDChat *)newCDChat
{
	self = [super init];
	if (self != nil)
	{
        self.cdChat = newCDChat;
        
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
    [cdChat release];
    [super dealloc];
}





#pragma mark - tableView Methods

#define HEADSHOT_IMG_TAG    12001
#define ARROW_IMG_TAG       12002
#define ALERT_IMG_TAG       12003
#define LOCK_IMG_TAG        12004


#define NAME_LABEL_TAG      14000
#define DATE_LABEL_TAG      14001
#define MESSAGE_LABEL_TAG     14003
#define BADGE_IMAGE_TAG     14006
#define GROUP_BADGE_TAG     14008



CGFloat const kOtherBubbleStartX = 45.0;
CGFloat const kMyBubbleEndX = 50.0;
CGFloat const kBubbleStartY = 20.0;
CGFloat const kBubbleHeight = 22.0;
CGFloat const kBadgeSize = 20.0;
CGFloat const kEditShift = 10.0;

CGFloat const kHeadshotSize = 54.0;
CGFloat const kLockSize = 18.0;





/*!
 @abstract Update Chat Data
 */
- (void) updateChatInformationForArrowView:(UIView *)arrowView 
                                 alertView:(UIView *)alertView 
                              messageLabel:(TextEmoticonView *)messageLabel 
                                 dateLabel:(UILabel *)dateLabel 
                               badgeButton:(UIButton *)badgeButton 
                                 tableView:(UITableView *)tableview {
    
    if (self.cdChat.lastMsgIsFromMe) {
        // prefix arrow symbol
        //
        //messageLabel.frame = CGRectMake(76.0, 32.0, 165.0, 15.0);
        
        if (self.cdChat.lastMsgDidFail) {
            arrowView.hidden = YES;
            alertView.hidden = NO;
        }
        else {
            arrowView.hidden = NO;
            alertView.hidden = YES;
        }
        
    }
    // message from other user
    else {
        //messageLabel.frame = CGRectMake(60.0, 32.0, 165.0, 15.0);
        arrowView.hidden = YES;
        alertView.hidden = YES;
    }
    
    // allow space for arrow or alert
    CGFloat messageIndent = 0.0;
    if (arrowView.hidden == NO || alertView.hidden == NO) {
        messageIndent = 16.0;
    }
    
    // add shift if editing
    CGFloat editIndent = 0.0;
    if (tableview.editing) {
        editIndent = 10.0;
    }

    
    // set last chat message
    //messageLabel.text = lastMessage.text;
    //[messageLabel setText:[self.cdChat lastMessageText]];
    //[messageLabel setText:[self.cdChat lastMessageTextUsingDB]];
    
    [messageLabel setText:self.cdChat.lastMsgText];
    messageLabel.frame = CGRectMake(60.0+messageIndent+editIndent, 30.0, 170.0, 20.0);
    
    // set date to sent time of last message
    //
    // - not chat mod date .. NSDate *lastDate = self.cdChat.lastUpdateDate;
    if (self.cdChat.lastMsgDateString) {
        dateLabel.text = self.cdChat.lastMsgDateString;
    }
    else {
        dateLabel.text = @"";
    }
    
    // badge - check unread messages
    //
    [AppUtility setBadge:badgeButton text:[NSString stringWithFormat:@"%d", self.cdChat.unreadMsgNumber]];
    
}


//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"ChatCell";
    
    CGRect headRect = CGRectMake(0.0, 0.0, kHeadshotSize, kHeadshotSize);    
    CGRect arrowRect = CGRectMake(60.0, 34.0, 15.0, 10.0);
    CGRect alertRect = CGRectMake(60.0, 34.0, 15.0, 15.0);

    //BOOL didCreateCell = NO;
    
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
    
        //didCreateCell = YES;
    
        cell = [[[ChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		
        UIImageView *backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_row_prs.png"]];
        cell.selectedBackgroundView = backImageView;
        [backImageView release];
        
        // white bar at top
        UIView *whiteBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 0.5)];
        whiteBar.backgroundColor = [UIColor whiteColor];
        [cell.contentView addSubview:whiteBar];
        [whiteBar release];
        
        // headshot
        UIImageView *headShot = [[UIImageView alloc] initWithFrame:headRect];
        headShot.tag = HEADSHOT_IMG_TAG;
        [cell.contentView addSubview:headShot];
        
        // hidden chat lock
        UIImageView *lockView = [[UIImageView alloc] initWithFrame:CGRectMake(kHeadshotSize-kLockSize, kHeadshotSize-kLockSize - 2.0, kLockSize, kLockSize)];
        lockView.image = [UIImage imageNamed:@"chat_icon_lock.png"];
        lockView.hidden = YES;
        lockView.tag = LOCK_IMG_TAG;
        [headShot addSubview:lockView];
        [headShot release];
        [lockView release];
        
        
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
        groupButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
        groupButton.userInteractionEnabled = NO;
        groupButton.hidden = YES;
        groupButton.tag = GROUP_BADGE_TAG;
        [cell.contentView addSubview:groupButton];
        [groupButton release];
        
        // arrow image
        //
        UIImageView *arrowView = [[UIImageView alloc] initWithFrame:arrowRect];
        arrowView.image = [UIImage imageNamed:@"chat_icon_from.png"];
        arrowView.tag = ARROW_IMG_TAG;
        arrowView.hidden = YES;
        [cell.contentView addSubview:arrowView];
        [arrowView release];
        
        // alert image
        //
        UIImageView *alertView = [[UIImageView alloc] initWithFrame:alertRect];
        alertView.image = [UIImage imageNamed:@"std_icon_alert.png"];
        alertView.tag = ALERT_IMG_TAG;
        alertView.hidden = YES;
        [cell.contentView addSubview:alertView];
        [alertView release];
        
        // message label
        //
        TextEmoticonView *messageLabel = [[TextEmoticonView alloc] init];
        messageLabel.tag = MESSAGE_LABEL_TAG;
        [cell.contentView addSubview:messageLabel];
        
        
        // sent date label
        //
        UILabel *dLabel = [[UILabel alloc] init];
        dLabel.tag = DATE_LABEL_TAG;
        [cell.contentView addSubview:dLabel];
        
        
        /*// my message label
        //
        UILabel *myLabel = [[UILabel alloc] init];
        myLabel.backgroundColor = [UIColor clearColor];
        [AppUtility configLabel:myLabel context:kAULabelTypeTableMainText];
        myLabel.tag = MY_LABEL_TAG;
        [myBubbleView addSubview:myLabel];
        [myLabel release];
        [myBubbleView release];*/
        
        
        // unread badge icon
        //
        UIButton *badgeButton = [[UIButton alloc] initWithFrame:CGRectMake(290.0, 21.0, kBadgeSize, kBadgeSize)];
        [AppUtility configButton:badgeButton context:kAUButtonTypeBadgeRed];
        badgeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        badgeButton.hidden = YES;
        badgeButton.tag = BADGE_IMAGE_TAG;
        
        [cell.contentView addSubview:badgeButton];  
        [badgeButton release];
        
        
        NSArray *labelArray = [NSArray arrayWithObjects:nLabel, messageLabel, dLabel, nil];
        
		[AppUtility setCellStyle:kAUCellStyleChatList labels:labelArray];
        
        
		[nLabel release];
        [messageLabel release];
        [dLabel release];
        

        
        // separator at the bottom - use table's built in separator
        /*UIView *separatorBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 54.0, 320.0, 1.0)];
        separatorBar.backgroundColor = [AppUtility colorForContext:kAUColorTypeTableSeparator];
        [cell.contentView addSubview:separatorBar];
        [separatorBar release];*/
        
	}
        
    // get components
    UIImageView *headShotView = (UIImageView *)[cell.contentView viewWithTag:HEADSHOT_IMG_TAG];
    UIImageView *lockView = (UIImageView *)[cell.contentView viewWithTag:LOCK_IMG_TAG];
    UIImageView *arrowView = (UIImageView *)[cell.contentView viewWithTag:ARROW_IMG_TAG];
    UIImageView *alertView = (UIImageView *)[cell.contentView viewWithTag:ALERT_IMG_TAG];

    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_LABEL_TAG];
    UILabel *dateLabel = (UILabel *)[cell.contentView viewWithTag:DATE_LABEL_TAG];
    TextEmoticonView *messageLabel = (TextEmoticonView *)[cell.contentView viewWithTag:MESSAGE_LABEL_TAG];
    UIButton *badgeButton = (UIButton *)[cell.contentView viewWithTag:BADGE_IMAGE_TAG];
    UIButton *groupBadgeButton = (UIButton *)[cell.contentView viewWithTag:GROUP_BADGE_TAG];
    
    
    // headshot update
    //
    headShotView.image = [UIImage imageNamed:@"profile_headshot_bear_black.png"];
    
    if ([self.cdChat isGroupChat]){
        headShotView.image = [UIImage imageNamed:@"chat_icon_groupchat.png"];
    }
    else {
        CDContact *chatFriend = [cdChat.participants anyObject];
        UIImage *gotImage = [self.imageManager getImageForObject:chatFriend context:kMPImageContextList];
        if (gotImage) {
            headShotView.image = gotImage;
        }
        else {
            headShotView.image = [UIImage imageNamed:@"profile_headshot_bear_black.png"];
        }
    }
    
    if ([indexPath section] == 0) {
        lockView.hidden = NO;
    }
    else {
        lockView.hidden = YES;
    }
    
    nameLabel.text = [self.cdChat displayNameStyle:kCDChatNameStyleFull];

    // move group button to right location
    if ([self.cdChat isGroupChat]) {
        groupBadgeButton.hidden = NO;
        NSString *groupCount = [NSString stringWithFormat:@"%d", [self.cdChat totalParticipantCount]];
        [groupBadgeButton setTitle:groupCount forState:UIControlStateNormal];
    }
    else {
        groupBadgeButton.hidden = YES;
    }
    
    // update first with cached data
    [self updateChatInformationForArrowView:arrowView alertView:alertView messageLabel:messageLabel dateLabel:dateLabel badgeButton:badgeButton tableView:tableView];
    
    NSManagedObjectID *chatObjectID = [self.cdChat objectID];
    
    dispatch_async([AppUtility getBackgroundMOCQueue], ^{
    
        CDChat *chatCopy = (CDChat *)[[AppUtility cdGetManagedObjectContext] objectWithID:chatObjectID];
        
        // Configure last message information
        // - @WARN if sequence is changed, last message will not be accurate
        // - however using this is faster performance
        //
        // get 2 last messages
        NSArray *lastMessages = [CDMessage messagesForChat:self.cdChat acending:NO limit:2];
        
        /*for (CDMessage *iMsg in lastMessages) {
            DDLogInfo(@"CC-cfr: msg text %@", iMsg.text);
        }*/
        
        CDMessage *lastMessage = ([lastMessages count] > 0)?[lastMessages objectAtIndex:0]:nil; //[self.cdChat lastMessageFromDB];  //self.cdChat.lastMessage;
        
        /*self.lastMsgIsFromMe = [lastMessage isFromSelf];
        self.lastMsgDidFail = [lastMessage getStateValue] == kCDMessageStateOutFailed;
        self.lastMsgText = [self.cdChat lastMessageTextForLast2Messages:lastMessages];
        self.lastMsgDateString = [Utility terseDateString:lastMessage.sentDate];
        self.unreadMsgNumber = [self.cdChat numberOfUnreadMessages];
        */
        
        BOOL isFromMe = [lastMessage isFromSelf];
        BOOL didFail = [lastMessage getStateValue] == kCDMessageStateOutFailed;
        NSString *msgText = [chatCopy lastMessageTextForLast2Messages:lastMessages];
        NSString *dateString = [Utility terseDateString:lastMessage.sentDate];
        NSUInteger badgeNumber = [chatCopy numberOfUnreadMessages];
        //chatCopy.unreadMsgNumber = badgeNumber;
        
        // update after we get up-to-date info
        dispatch_async(dispatch_get_main_queue(), ^{
        
            self.cdChat.lastMsgIsFromMe = isFromMe;
            self.cdChat.lastMsgDidFail = didFail;
            self.cdChat.lastMsgText = msgText;
            self.cdChat.lastMsgDateString = dateString;
            self.cdChat.unreadMsgNumber = badgeNumber;
            
            if ([Utility isIndexPath:indexPath inIndexPaths:[tableView indexPathsForVisibleRows]]) {
                [self updateChatInformationForArrowView:arrowView alertView:alertView messageLabel:messageLabel dateLabel:dateLabel badgeButton:badgeButton tableView:tableView];
            }

        });
    });
    return cell;
}




// respond to cell selection
//  * enable or disable this email address
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    DDLogVerbose(@"CCC-dsr: pressed %@", self.cdChat);
    
    if ([self.delegate respondsToSelector:@selector(ChatCellController:didSelectChat:)]) {
        [self.delegate ChatCellController:self didSelectChat:self.cdChat];
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
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


- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"test");
}



#pragma mark - Image 

/*!
 @abstract Called when data has completed loading and is ready to use.
 
 - find my cell and update the image!
 
 */
- (void)MPImageManager:(MPImageManager *)imageManager finishLoadingImage:(UIImage *)image{
    
    // ask tableview to refresh if the cell is visible
    if ([self.delegate respondsToSelector:@selector(ChatCellController:refreshChat:)]) {
        [self.delegate ChatCellController:self refreshChat:self.cdChat];
    }
}


@end
