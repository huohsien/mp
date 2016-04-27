//
//  CountryCellController.m
//  mp
//
//  Created by M Tsai on 11-10-17.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "CountryCellController.h"
#import "AppUtility.h"
#import "TKLog.h"
#import "CountryInfo.h"


@implementation CountryCellController

@synthesize delegate;
@synthesize countryInfo;


//
// init
//
// Init method for the object.
//
- (id)initWithCountryInfo:(CountryInfo *)aCountryInfo
{
	self = [super init];
	if (self != nil)
	{
        self.countryInfo = aCountryInfo;
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
    delegate = nil;
	[countryInfo release];
	[super dealloc];
}

#pragma mark -
#pragma mark tableView Methods


#define NAME_LABEL_TAG	15000
#define PHONE_LABEL_TAG 15001

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
        
        // phone code label
		UILabel *pLabel = [[UILabel alloc] init];
		pLabel.tag = PHONE_LABEL_TAG;
		[cell.contentView addSubview:pLabel];
        
        NSArray *labels = [NSArray arrayWithObjects:nLabel, pLabel, nil];
        [nLabel release];
        [pLabel release];
        
		[AppUtility setCellStyle:kAUCellStyleSelectCountry labels:labels];

		// set background color
		cell.backgroundColor = [UIColor whiteColor];
	}
	
	
    // Set up the cell text
	UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:NAME_LABEL_TAG];
	nameLabel.text = self.countryInfo.name;
    
    UILabel *phoneLabel = (UILabel *)[cell.contentView viewWithTag:PHONE_LABEL_TAG];
	phoneLabel.text = self.countryInfo.phoneCountryCode;
    
    return cell;
}

// respond to cell selection
//  * enable or disable this email address
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    DDLogVerbose(@"CCC-dsr: pressed %@", self.countryInfo);
    
    if([self.delegate respondsToSelector:@selector(countryCellController:selectedCountryCode:)]) {
        [self.delegate countryCellController:self selectedCountryCode:self.countryInfo.isoCode];
    }
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
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