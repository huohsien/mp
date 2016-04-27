//
//  SelectContactCellController.m
//  mp
//
//  Created by M Tsai on 11-12-10.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "SelectContactCellController.h"
#import "CDContact.h"
#import "AppUtility.h"
#import "MPFoundation.h"
#import "TextEmoticonView.h"

@implementation SelectContactCellController

@synthesize delegate;
@synthesize contact;
@synthesize isSelected;
@synthesize enableSelection;
@synthesize imageManager;

//
// init
//

/*!
 @abstract Init method for the object.

 @param enableSelection Should we allow user to select this cell?
 */
- (id)initWithContact:(CDContact *)newContact enableSelection:(BOOL)enable
{
	self = [super init];
	if (self != nil)
	{
        self.contact = newContact;
        self.isSelected = NO;
        self.enableSelection = enable;
    
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
	[contact release];
	[super dealloc];
}

#pragma mark -
#pragma mark tableView Methods




#define HEADSHOT_IMG_TAG        15000
#define NAME_LABEL_TAG          15001
#define STATUS_LABEL_TAG        15002
#define PRESENCE_LABEL_TAG      15003
#define RADIO_TAG               15004

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *selectCellID = @"SelectCell";
    static NSString *noSelectCellID = @"NoSelectCell";

    NSString *cellID = nil;
    if (self.enableSelection) {
        cellID = selectCellID;
    }
    else {
        cellID = noSelectCellID;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
		
        UIImageView *backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_row_prs.png"]];
        cell.selectedBackgroundView = backImageView;
        [backImageView release];
        
        // headshot
        UIImageView *headShot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_headshot_bear_black.png"]];
        headShot.tag = HEADSHOT_IMG_TAG;
        [cell.contentView addSubview:headShot];
        
		// name label
		UILabel *nLabel = [[UILabel alloc] init];
		nLabel.tag = NAME_LABEL_TAG;
		[cell.contentView addSubview:nLabel];
        
        // status label
		TextEmoticonView *sLabel = [[TextEmoticonView alloc] init];
		sLabel.tag = STATUS_LABEL_TAG;
		[cell.contentView addSubview:sLabel];
        
        // presence label
		UILabel *pLabel = [[UILabel alloc] init];
		pLabel.tag = PRESENCE_LABEL_TAG;
		[cell.contentView addSubview:pLabel];
        
        NSArray *labelArray = [NSArray arrayWithObjects:nLabel, sLabel, pLabel, nil];
        
        if (self.enableSelection) {
            [AppUtility setCellStyle:kAUCellStyleSelectContact labels:labelArray];
            headShot.frame = CGRectMake(40.0, 0.0, kMPParamTableRowHeight, kMPParamTableRowHeight);
            
            // create radio button
            // 
            const CGFloat iconSize = 30.0;
            UIImageView *radioView = [[UIImageView alloc] initWithFrame:CGRectMake(3.0, (kMPParamTableRowHeight-iconSize)/2.0, iconSize, iconSize)];
            
            radioView.tag = RADIO_TAG;
            [cell.contentView addSubview:radioView];
            [radioView release];
            
        }
        else {
            [AppUtility setCellStyle:kAUCellStyleNoSelectContact labels:labelArray];
            headShot.frame = CGRectMake(0.0, 0.0, kMPParamTableRowHeight, kMPParamTableRowHeight);
        }
        [headShot release];
		[nLabel release];
        [sLabel release];
        [pLabel release];
    
	}
	
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
    statusLabel.lineBreakMode = UILineBreakModeTailTruncation;
    [statusLabel setText:self.contact.statusMessage];
    
    UILabel *presenceLabel = (UILabel *)[cell.contentView viewWithTag:PRESENCE_LABEL_TAG];
	presenceLabel.text = [self.contact presenceString];
    
    
    if (self.enableSelection) {
        // setup radio button
        //
        UIImageView *radioImageView = (UIImageView *)[cell.contentView viewWithTag:RADIO_TAG];
        
        if (self.isSelected) {
            radioImageView.image = [UIImage imageNamed:@"std_icon_checkbox_prs.png"];
        }
        else {
            radioImageView.image = [UIImage imageNamed:@"std_icon_checkbox_nor.png"];
        }
    }
    
    return cell;
}

// respond to cell selection
//  * enable or disable this email address
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.enableSelection) {
        UITableViewCell *selectCell = [tableView cellForRowAtIndexPath:indexPath];
        
        // toggle enable state
        //
        UIImageView *radioImageView = (UIImageView *)[selectCell.contentView viewWithTag:RADIO_TAG];
        if (self.isSelected) {
            self.isSelected = NO;
            radioImageView.image = [UIImage imageNamed:@"std_icon_checkbox_nor.png"];
        }
        else {
            self.isSelected = YES;
            radioImageView.image = [UIImage imageNamed:@"std_icon_checkbox_prs.png"];
        }
	    
        // tell delegate that cell was selected
        if ([self.delegate respondsToSelector:@selector(SelectContactCellController:didSelect:)]){
            [self.delegate SelectContactCellController:self didSelect:self.isSelected];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

// 
// For some reason background color must be set right before cell is displayed
//
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
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
    
    
    
}




@end