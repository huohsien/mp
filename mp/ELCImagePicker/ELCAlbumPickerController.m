//
//  AlbumPickerController.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "ELCAssetTablePicker.h"
#import "AppUtility.h"
#import "Utility.h"
#import "TKLog.h"

#import "MPSettingCenter.h"


@implementation ELCAlbumPickerController

@synthesize parent, assetGroups;
@synthesize onlySingleSelection;
@synthesize isLoadingGroups;
@synthesize shouldReloadGroups;
@synthesize pendingSelectIndex;


#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}


- (void)dealloc 
{	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [assetGroups release];
    [library release];
    [super dealloc];
}


#pragma mark - View lifecycle


- (void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    if(hasError)[self.parent cancelImagePicker];
    
}


#define LOCATION_ALERT_TAG  14001
#define BEAR_IMAGE_TAG      14002
#define MAIN_LABEL_TAG      14003
#define SUB_LABEL_TAG       14004
#define PROCEED_BTN_TAG     14005


/*!
 @abstract handle notification about library change
 */
- (void) handleLibraryChange:(NSNotification *)notification {
    
    DDLogInfo(@"APC-hlc: recv library change notification");

    if (self.isLoadingGroups) {
        self.shouldReloadGroups = YES;
    }
    else {
        [self loadAlbums];
    }
    
}

/*!
 @abstract If app suspended leave photo album since 3GS tests show that refresh notification does not work
 
 */
- (void)handleDidEnterBackgroundNotification:(NSNotification *)notification {
    //[self.navigationController popViewControllerAnimated:NO];
    [self dismissModalViewControllerAnimated:NO];
}

/*!
 @abstract Loads photo albums
 */
- (void) loadAlbums {
    
    DDLogInfo(@"APC-la: loading albums");
    
    self.isLoadingGroups = YES;

    if (!self.assetGroups) {
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        self.assetGroups = tempArray;
        [tempArray release];
    }
    else {
        [self.assetGroups removeAllObjects];
    }
    
    if (!library) {
        library = [[ALAssetsLibrary alloc] init];      
    }
    
    // Group enumerator Block
    //
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop){
        
        // if reload is requested
        // - stop this one and start another
        //
        if (self.shouldReloadGroups) {
            DDLogInfo(@"APC-la: ending current load and reload again");
            *stop = YES;
            self.shouldReloadGroups = NO;
            [self loadAlbums];
            return;
        }
        
        // nil means we are done enumerating
        // - can use this information to know when we are done
        if(group == nil) {
            self.isLoadingGroups = NO;
            DDLogInfo(@"APC-la: loading done");
            
            // Update UI
            [self reloadTableView];
            
            // loading is complete, so respond to user touch
            if (self.pendingSelectIndex != NSNotFound) {
                NSUInteger selectRow = self.pendingSelectIndex;
                DDLogInfo(@"APC-la: select pending row: %d", self.pendingSelectIndex);
                self.pendingSelectIndex = NSNotFound;
                [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:selectRow inSection:0]];
            }
            return;
        }
        
        // update data model
        [self.assetGroups addObject:group];
        
        // Keep this line!  w/o it the asset count is broken for some reason.  Makes no sense
        //[group numberOfAssets];
        //DDLogInfo(@"count: %d", [group numberOfAssets]);
        //DDLogInfo(@"group: %@",group);
        
    };
    
    
    // Group Enumerator Failure Block
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error){
        
        self.isLoadingGroups = NO;
        
        NSString *title = NSLocalizedString(@"Send Multiple Photos", @"ImagePicker: enable location to access photos");
        
        if (error.code == ALAssetsLibraryAccessGloballyDeniedError ||
            error.code == ALAssetsLibraryAccessUserDeniedError) {
            
            NSString *message = NSLocalizedString(@"Enable 'Location Services' in Settings app to send multiple photos." , @"ImagePicker: Enable location to access photots");
            
            [Utility showAlertViewWithTitle:title message:message delegate:self tag:LOCATION_ALERT_TAG];
            
        }
        // don't dismiss automatically
        else {
            
            NSString *message = [NSString stringWithFormat:@"Album Error: %@", [error description]];
            [Utility showAlertViewWithTitle:title message:message delegate:self tag:LOCATION_ALERT_TAG];
            
            //hasError = TRUE;
        }
        
        DDLogError(@"A problem occured %@", [error description]);
    };	
    
    // Enumerate Albums
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
                           usingBlock:listGroupBlock 
                         failureBlock:failureBlock];

    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isLoadingGroups = NO;
    self.shouldReloadGroups = NO;
    self.pendingSelectIndex = NSNotFound;
    
	//self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    [self setTitle:NSLocalizedString(@"Loading...", @"Album - title: albums are loading")];
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    [AppUtility configTableView:self.tableView];
    
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel", @"Album - button: cancel album selection") 
                                                        buttonType:kAUButtonTypeBarNormal 
                                                            target:self.parent action:@selector(cancelImagePicker)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    if ( [[MPSettingCenter sharedMPSettingCenter] didNotRunFirstStartTag:kMPSettingFirstStartTagLoadPhotoAlbum]) {
        
        // first start, load images to tell users about why GPS is needed
    
        // load image
        //
        UIImageView *bearView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_icon_share_multi_img.png"]];
        CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
        CGSize imageSize = bearView.frame.size;
        bearView.frame = CGRectMake( (appFrame.size.width - imageSize.width)/2.0 , 20.0, imageSize.width, imageSize.height);
        bearView.tag = BEAR_IMAGE_TAG;
        [self.view addSubview:bearView];
        
        // blue label
        //
        UILabel *mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, bearView.frame.origin.y + bearView.frame.size.height, appFrame.size.width, 25.0)];
        [AppUtility configLabel:mainLabel context:kAULabelTypeBlue3];
        mainLabel.text = NSLocalizedString(@"Share Multiple Images with Ease", @"Album - MainLabel: Encourage users to enable GPS to access photo album");
        mainLabel.tag = MAIN_LABEL_TAG;
        [self.view addSubview:mainLabel];
        
        
        // gray label
        //
        UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(25.0, mainLabel.frame.origin.y + mainLabel.frame.size.height, appFrame.size.width - 50, 35.0)];
        [AppUtility configLabel:subLabel context:kAULabelTypeGrayMicroPlus];
        subLabel.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
        subLabel.textAlignment = UITextAlignmentCenter;
        subLabel.text = NSLocalizedString(@"Enable 'Location Services' to send multiple photos.", @"Album - SubLabel: Encourage users to enable GPS to access photo album");
        subLabel.numberOfLines = 2;
        subLabel.tag = SUB_LABEL_TAG;
        [self.view addSubview:subLabel];
        
        // proceed button
        //
        UIButton *proceedButton = [[UIButton alloc] initWithFrame:CGRectMake((appFrame.size.width - 90)/2.0, 
                                                                            subLabel.frame.origin.y + subLabel.frame.size.height+20.0, 90.0, 30.0)];
        [AppUtility configButton:proceedButton context:kAUButtonTypeGreen];
        [proceedButton addTarget:self action:@selector(pressProceed:) forControlEvents:UIControlEventTouchUpInside];
        [proceedButton setTitle:NSLocalizedString(@"OK", @"Album - button: proceed to enable location services") forState:UIControlStateNormal];
        proceedButton.tag = PROCEED_BTN_TAG;
        [self.view addSubview:proceedButton];
        [proceedButton release];
        
        [bearView release];
        [mainLabel release];
        [subLabel release];
        
    }
    else {
        [self loadAlbums];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLibraryChange:) name:ALAssetsLibraryChangedNotification object:nil];
    
    // make sure exit edit mode 
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidEnterBackgroundNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
}


#pragma mark - Button


/*!
 @abstract Proceed with loading album
 */
- (void) pressProceed:(id)sender {
    
    UIView *bearView = [self.view viewWithTag:BEAR_IMAGE_TAG];
    UIView *mainLabel = [self.view viewWithTag:MAIN_LABEL_TAG];
    UIView *subLabel = [self.view viewWithTag:SUB_LABEL_TAG];
    UIView *proceedButton = [self.view viewWithTag:PROCEED_BTN_TAG];

    [UIView animateWithDuration:0.5 animations:^{
        bearView.alpha = 0.0;
        mainLabel.alpha = 0.0;
        subLabel.alpha = 0.0;
        proceedButton.alpha = 0.0;
    }];
    
    // mark as shown, to the welcome message will not show up again
    //
    [[MPSettingCenter sharedMPSettingCenter] markFirstStartTagComplete:kMPSettingFirstStartTagLoadPhotoAlbum];
    
    [self loadAlbums];
}


#pragma mark - UIAlertView

/*!
 @abstract Dismiss if error encountered
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == LOCATION_ALERT_TAG) {
        [self.parent failedLocationDenied];
        [self dismissModalViewControllerAnimated:YES];
    }
}



#pragma mark - Generic Table Methods

#define NO_ITEM_TAG 150001

- (void) showNoItemView {
    // Show no item label
    //
    UIView *noItemView = [self.tableView viewWithTag:NO_ITEM_TAG];
    
    NSUInteger totalItems = [assetGroups count];
    if (totalItems == 0 && noItemView == nil) {        
        CGSize headerSize = self.tableView.tableHeaderView.frame.size;
        UILabel *noItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, headerSize.height, self.tableView.frame.size.width-40.0, self.tableView.frame.size.height-headerSize.height)];
        [AppUtility configLabel:noItemLabel context:kAULabelTypeNoItem];
        noItemLabel.text = NSLocalizedString(@"No Photos", @"ImagePicker - text: Inform users that there are no photo albums available");
        noItemLabel.tag = NO_ITEM_TAG;
        [self.tableView addSubview:noItemLabel];
        [noItemLabel release];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    else if (totalItems > 0) {
        [noItemView removeFromSuperview];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
}


-(void)reloadTableView {
	
	[self.tableView reloadData];
    [self setTitle:NSLocalizedString(@"Select Album", @"Album - title: users should select an photo album")];
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    [self showNoItemView];
}

-(void)selectedAssets:(NSArray*)_assets {
	
	[(ELCImagePickerController*)parent selectedAssets:_assets];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [assetGroups count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
        UIImageView *backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"std_row_prs.png"]];
        cell.selectedBackgroundView = backImageView;
        [backImageView release];
        
        UIView *whiteBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 0.5)];
        whiteBar.backgroundColor = [UIColor whiteColor];
        [cell.contentView addSubview:whiteBar];
        [whiteBar release];
        
    }
    
    if (indexPath.row < [assetGroups count]) {
        ALAssetsGroup *g = (ALAssetsGroup*)[assetGroups objectAtIndex:indexPath.row];
        
        [g setAssetsFilter:[ALAssetsFilter allPhotos]];
        NSInteger gCount = [g numberOfAssets];
        
        cell.textLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemStandardPlus];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)",[g valueForProperty:ALAssetsGroupPropertyName], gCount];
        [cell.imageView setImage:[UIImage imageWithCGImage:[g posterImage]]];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    else {
        cell.textLabel.text = @"";
        [cell.imageView setImage:nil];
    }
	
    return cell;
}

/*!     
 Background color MUST be set right before cell is displayed
 */
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackgroundLight];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // only allow select if we are still the top view
    // - this prevents next view from being pushed multiple times onto stack
    //
    if (self.navigationController.topViewController == self) {
        NSUInteger selectedRow = indexPath.row;
        
        // if loading, wait until loading is done
        if (self.isLoadingGroups) {
            self.pendingSelectIndex = selectedRow;
        }
        // make sure assetGroups object is available before selection
        // 
        else if (selectedRow < [assetGroups count]) {
            ELCAssetTablePicker *picker = [[ELCAssetTablePicker alloc] initWithNibName:@"ELCAssetTablePicker" bundle:[NSBundle mainBundle]];
            picker.onlySingleSelection = self.onlySingleSelection;
            picker.parent = self;
            
            // Move me    
            [picker setAssetsGroup:[assetGroups objectAtIndex:indexPath.row] assetsLibrary:library];
            [picker.assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
            
            [self.navigationController pushViewController:picker animated:YES];
            [picker release];
        }
        else {
            DDLogWarn(@"APC-dsr: could not found asset group that at row: %d", selectedRow);
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return 57;
}



@end

