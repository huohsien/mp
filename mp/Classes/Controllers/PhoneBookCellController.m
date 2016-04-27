//
//  PhoneBookCellController.m
//  mp
//
//  Created by Min Tsai on 1/27/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "PhoneBookCellController.h"
#import "CDContact.h"
#import "CDChat.h"
#import "FriendInfoController.h"
#import "MPFoundation.h"
#import "AppUtility.h"
#import "ContactProperty.h"
#import "OperatorInfoCenter.h"
#import "TKImageLabel.h"




@implementation PhoneBookCellController

@synthesize phoneProperty;
@synthesize operatorNumber;
@synthesize contact;
@synthesize delegate;


/*!
 @abstract
 
 @param contactProperty Phone number property for this cell
 @param newContact Contact associated to this phone number - optional
 */
- (id)initWithPhoneProperty:(ContactProperty *)contactProperty associatedContact:(CDContact *)newContact
{
	self = [super init];
	if (self != nil)
	{
        self.phoneProperty = contactProperty;
        
        // fetch contact 
        self.contact = newContact;
        //self.contact = [CDContact getContactWithABRecordID:self.phoneProperty.abRecordID];
        
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
    // in case object is deallocated before removing observer before hand
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [phoneProperty release];
    [operatorNumber release];
	[contact release];
	[super dealloc];
}

#pragma mark - Operator Tools

/*!
 @abstract getter for operator number
 
 - if not exists, then request for it
 
 */
- (NSNumber *) operatorNumber {
    
    if (operatorNumber) {
        return operatorNumber;
    }
    
    // request operator information
    //
    operatorNumber = [[OperatorInfoCenter sharedOperatorInfoCenter] requestOperatorForPhoneNumber:self.phoneProperty.value];
    
    if (operatorNumber) {
        [operatorNumber retain];
    }
    // if no local cache, listen for remote query results
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processOperatorInfo:) name:MP_OPERATORINFO_UPDATE_SINGLE_NOTIFICATION object:nil];
    }
    return operatorNumber;
}

/*!
 @abstract process operator information that was requested
 */
- (void) processOperatorInfo:(NSNotification *) notification {

    NSDictionary *operatorDictionary = [notification object];
    
    NSNumber *resultNumber = [operatorDictionary valueForKey:self.phoneProperty.value];
    
    // if got results then set operatorNumber and remove observer
    if (resultNumber) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [resultNumber retain];
        [operatorNumber release];
        operatorNumber = resultNumber;
        
        // tell table delegate to refresh me
        if ([self.delegate respondsToSelector:@selector(PhoneBookCellController:refreshProperty:)]) {
            [self.delegate PhoneBookCellController:self refreshProperty:self.phoneProperty];
        }
    }
    
    // otherwise, this notif was not for me - ignore it
}




#pragma mark - TableView Methods


#define NAME_LABEL_TAG          15000
#define PROPERTY_LABEL_TAG      15001
#define PRESENCE_LABEL_TAG      15002
#define OPERATOR_VIEW_TAG       15003
#define OPERATOR_LABEL_TAG      15004

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = nil;
    
    BOOL isOperatorAvailable = [[OperatorInfoCenter sharedOperatorInfoCenter] isOperatorInfoAvailable];

    if (isOperatorAvailable) {
        CellIdentifier = @"PhoneBookCellTW";
    }
    else {
        CellIdentifier = @"PhoneBookCell";
    }
	  
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		
        //CGRect testRect = cell.contentView.frame;
        
        UIImageView *backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_row_prs.png"]];
        cell.selectedBackgroundView = backImageView;
        [backImageView release];
        
        UIView *whiteBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 0.5)];
        whiteBar.backgroundColor = [UIColor whiteColor];
        [cell.contentView addSubview:whiteBar];
        [whiteBar release];
        
        // presence label - added first so that is does not cover name or status - bottom layer
		UILabel *pLabel = [[UILabel alloc] init];
		pLabel.tag = PRESENCE_LABEL_TAG;
		[cell.contentView addSubview:pLabel];
        
		// name label
		UILabel *nLabel = [[UILabel alloc] init];
		nLabel.tag = NAME_LABEL_TAG;
		[cell.contentView addSubview:nLabel];
        
        // property label
		UILabel *proLabel = [[UILabel alloc] init];
		proLabel.tag = PROPERTY_LABEL_TAG;
		[cell.contentView addSubview:proLabel];
        
        
        NSArray *labelArray = [NSArray arrayWithObjects:nLabel, proLabel, pLabel, nil];
                
        if (isOperatorAvailable) {
            [AppUtility setCellStyle:kAUCellStylePhoneBookTW labels:labelArray];
            
            // add operator image and label
            //
            /*TKImageLabel *operatorBadge = [[TKImageLabel alloc] initWithFrame:CGRectMake(273.0, 3.0, 47.0, 28.0)];
            operatorBadge.font = [AppUtility fontPreferenceWithContext:kAUFontSystemTiny];
            operatorBadge.textColor = [UIColor blackColor];
            operatorBadge.textEdgeInsets = UIEdgeInsetsMake(7.0, 9.0, 0.0, 9.0);
            operatorBadge.backgroundColor = [UIColor clearColor];
            operatorBadge.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
            operatorBadge.tag = OPERATOR_VIEW_TAG;
            [cell.contentView addSubview:operatorBadge];
            [operatorBadge release];*/
            
            //UIButton *operatorButton = [[UIButton alloc] initWithFrame:CGRectMake(273.0, 3.0, 47.0, 28.0)];
            UIButton *operatorButton = [[UIButton alloc] initWithFrame:CGRectMake(233.0, 3.0, 87.0, 28.0)];
            [AppUtility configButton:operatorButton context:kAUButtonTypeOperator];
            operatorButton.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
            operatorButton.opaque = YES;
            operatorButton.tag = OPERATOR_VIEW_TAG;
            [cell.contentView addSubview:operatorButton];  
            [operatorButton release];
            
        }
        else {
            [AppUtility setCellStyle:kAUCellStylePhoneBook labels:labelArray];
        }
		[nLabel release];
        [proLabel release];
        [pLabel release];
        

	}
	
    // Cell is refreshed, so no need to observe operator requests
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
    // Set up the cell text
	UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_LABEL_TAG];
	nameLabel.text = self.phoneProperty.name;
    
    /*NSString *cc = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPhoneCountryCode];
    NSString *phoneString = [Utility formatPhoneNumber:self.phoneProperty.value countryCode:cc showCountryCode:NO];
    */
    
    UILabel *valueLabel = (UILabel *)[cell.contentView viewWithTag:PROPERTY_LABEL_TAG];
	valueLabel.text = self.phoneProperty.valueString; //phoneString;
    
    UILabel *presenceLabel = (UILabel *)[cell.contentView viewWithTag:PRESENCE_LABEL_TAG];
	presenceLabel.text = [self.contact presenceString];
    
    // setup operator image
    //
    UIButton *opView = (UIButton *)[cell.contentView viewWithTag:OPERATOR_VIEW_TAG];
    if (opView) {
        UIImage *backImage = [[OperatorInfoCenter sharedOperatorInfoCenter] backImageForOperatorNumber:self.operatorNumber];
        NSString *textString = [[OperatorInfoCenter sharedOperatorInfoCenter] nameForOperatorNumber:self.operatorNumber];
        
        [opView setBackgroundImage:backImage forState:UIControlStateNormal];
        [opView setTitle:textString forState:UIControlStateNormal];
        
    }
    
    return cell;
}

// respond to cell selection
//  * enable or disable this email address
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    DDLogVerbose(@"PBC-dsr: pressed %@", self.phoneProperty.name);
    
    if ([self.delegate respondsToSelector:@selector(PhoneBookCellController:tappedContactProperty:contact:operatorNumber:)]) {
        [self.delegate PhoneBookCellController:self tappedContactProperty:self.phoneProperty contact:self.contact operatorNumber:self.operatorNumber];
    }
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