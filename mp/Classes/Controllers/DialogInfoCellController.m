//
//  DialogMessageCellController.m
//  mp
//
//  Created by Min Tsai on 3/6/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "DialogInfoCellController.h"
#import "MPFoundation.h"

@implementation DialogInfoCellController

@synthesize infoType;
@synthesize infoString;


/*!
 @abstract initialized cell controller with related CDMessage
 
 if CDMessage is not available, then this is an blank message where user 
 can write a new message.
 
 */
- (id)initWithInfo:(NSString *)info messageType:(DInfoType)type 
{
	self = [super init];
	if (self != nil)
	{
        self.infoString = info;
        self.infoType = type;
	}
	return self;
}

- (void)dealloc {
    [infoString release];
    [super dealloc];
}





#pragma mark - TableView Methods

#define INFO_LABEL_TAG      12001
#define BACK_VIEW_TAG       12002


#define kInfoWidth  170.0
#define kInfoHeight 20.0

#define kInfoWidthMargin 10.0
#define kInfoHeightMargin 5.0



//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"InfoCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGFloat cellWidth = cell.frame.size.width;
        
        // background view
        //
        UIView *backView = [[UIView alloc] initWithFrame:CGRectMake( (cellWidth-(kInfoWidth+kInfoWidthMargin*2.0))/2.0 , kInfoHeightMargin, kInfoWidth+kInfoWidthMargin*2.0, kInfoHeight)];
        [backView addRoundedCornerRadius:10.0];
        backView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        backView.tag = BACK_VIEW_TAG;
        
        // label view
        //
        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(kInfoWidthMargin, 0.0, kInfoWidth, kInfoHeight)];
        infoLabel.backgroundColor = [UIColor clearColor];
        infoLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
        infoLabel.textColor = [UIColor whiteColor];
        infoLabel.textAlignment = UITextAlignmentCenter;
		infoLabel.tag = INFO_LABEL_TAG;
		[backView addSubview:infoLabel];
        [infoLabel release];
        
        [cell.contentView addSubview:backView];
        [backView release];
	}
    
    // get components
    UIView *backView = [cell.contentView viewWithTag:BACK_VIEW_TAG];
    UILabel *infoLabel = (UILabel *)[cell.contentView viewWithTag:INFO_LABEL_TAG];
    
    
    switch (self.infoType) {
        case kDInfoTypeJoin:
            // yellow
            backView.backgroundColor = [UIColor colorWithRed:1.0 green:0.92 blue:0.24 alpha:0.5];
            break;
            
        case kDInfoTypeLeave:
            // red
            backView.backgroundColor = [UIColor colorWithRed:1.0 green:0.28 blue:0.28 alpha:0.5];
            break;
            
        default:
            backView.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:0.5];
            break;
    }
    
    infoLabel.text = self.infoString;    
    
    return cell;
}

/*!
 @abstract Informs table of row height
 */
- (CGFloat)rowHeightForTableWidth:(CGFloat)tableWidth {
    return kInfoHeightMargin+kInfoHeight;
}


// respond to cell selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // can't press this 
    
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
	return NO;
}

// Which style to show for editing
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
	return NO;
}

@end
