//
//  StatusMessageController.m
//  mp
//
//  Created by M Tsai on 11-11-25.
//  Copyright (c) 2011年 TernTek. All rights reserved.
//

#import "StatusMessageController.h"
#import "MPFoundation.h"
#import "SelectCellController.h"
#import "TextEmoticonView.h"
#import "CDContact.h"

//#import "StatusEditController.h"

CGFloat const kSectionHeaderHeight = 23.0;
NSInteger const kMPParamStatusMessageMax = 60;


@interface StatusMessageController (PrivateMethods)
- (void) setupHeaderView;
- (void) loadPredefinedStatus;
- (void) updateStatusMessageInHeader:(NSString *)status;

@end


@implementation StatusMessageController

@synthesize predefinedStatusMessages;
@synthesize tempStatus;


- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [predefinedStatusMessages release];
    [tempStatus release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.title = NSLocalizedString(@"Status Message", @"StatusMessage - title: view to change status message");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];

    
    [self loadPredefinedStatus];
    [self setupHeaderView];
    self.view.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"SMC-vwa");
    [super viewWillAppear:animated];
    
    // make sure we always have current status at the top
    //
    NSString *status = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingStatus];
    [self updateStatusMessageInHeader:status];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Generic Table Methods

/*!
 @abstract contruct data model for table
 */
- (void)constructTableGroups
{
	NSMutableArray *statusCells = [[NSMutableArray alloc] init];
    
    for (NSString *iStatus in self.predefinedStatusMessages){
        SelectCellController *iCell = [[SelectCellController alloc] initWithObject:iStatus];
        iCell.delegate = self;
        [statusCells addObject:iCell];
    }
	
	self.tableGroups = [NSArray arrayWithObjects:statusCells, nil];
	[statusCells release];
	
	// set positions of cell controllers
	for (NSArray *iArray in self.tableGroups){
		NSInteger arrayCount = [iArray count];
		if (arrayCount == 1) {
			[[iArray objectAtIndex:0] setRowPosition:kRowPositionSingle];
		}
		else if (arrayCount > 1) {
			[[iArray objectAtIndex:0] setRowPosition:kRowPositionTop];
			[[iArray lastObject] setRowPosition:kRowPositionBottom];
		}
	}
}

#pragma mark - Table Methods



//
// Specify the space allocated IF a header is specified for the section
//
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    if (title) {
        return kSectionHeaderHeight;
    }
    return 0.0;
}

// return customized section
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
	UIView *sectionView = nil;
	
	// add Title
	NSString *title = [self tableView:tableView titleForHeaderInSection:section];

    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    sectionView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, kSectionHeaderHeight)] autorelease];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 2.0, 150.0, 21.0)];
    titleLabel.text = title;
    [AppUtility configLabel:titleLabel context:kAULabelTypeBackgroundText];
    
    [sectionView addSubview:titleLabel];
    [titleLabel release];

	return sectionView;
}


// show headers
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
    return NSLocalizedString(@"Predefined Status", @"StatusMessage - section title: lists predefined status messages that users can choose from");
}




#pragma mark - Support

/*!
 @abstract Loads Predefined Status Messages
 
 Bundle:
 The bundle should include a list of status messages in a plist that can be loaded into an array.  This file should be localized for the M+ target languages.
 
 Loading:
 We need to load a file from doc directory not from bundle, since we will need to update this data from the server in the future.
 
 Search order:
 1 - doc: status_<iso language code>.plist
 2 - doc: status.plist
 3 - bun: status.plist & copy it over as status.plist in doc.
 
 if user changes language setting:
 - try to find language specific status file
 - fails over to last created status.plist file
 
 Server update:
 - server should provide status files for all languages supported: e.g. status_zh_TW.plist, status_zh_CN.plist, status_ja.plist, status.plist (default file)
 - check if new version exists, if so then overwrite the file in the document directory
 
 */
- (void) loadPredefinedStatus {
    
    // Just read it from the bundle
    // - no plans to obtain from server yet
    // - this allows immediate langugage change
    //
    NSString *path = [[NSBundle mainBundle] pathForResource:@"status" ofType:@"plist"];
    
    if (path) {
        NSArray *tmp = [[NSArray alloc] initWithContentsOfFile:path];
        self.predefinedStatusMessages = tmp;
        //[tmp writeToFile:filePath atomically:YES];
        [tmp release];
    }
    
    /*
    NSString *fileName = [NSString stringWithFormat:@"status_%@.plist", [AppUtility devicePreferredLanguageCode]];
    NSString *filePath = [Utility documentFilePath:fileName];

    // check if doc: status_<iso language code>.plist file exists
    //
    if ([Utility fileExistsAtDocumentFilePath:fileName]){
        // read it directly
        NSArray *docArray = [[NSArray alloc] initWithContentsOfFile:filePath];
        self.predefinedStatusMessages = docArray;
        [docArray release];
        return;
    }
    
    fileName = @"status.plist";
    filePath = [Utility documentFilePath:fileName];
    // - for testing ... [Utility deleteFileAtPath:filePath];
    // check if doc: status_<iso language code>.plist file exists
    //
    if ([Utility fileExistsAtDocumentFilePath:fileName]){
        // read it directly
        NSArray *docArray = [[NSArray alloc] initWithContentsOfFile:filePath];
        self.predefinedStatusMessages = docArray;
        [docArray release];
        return;
    }
    // finally get from bundle as last option
    //
    else {
        // copy it over file bundle
        NSString *path = [[NSBundle mainBundle] pathForResource:@"status" ofType:@"plist"];
        
        if (path) {
            NSArray *tmp = [[NSArray alloc] initWithContentsOfFile:path];
            self.predefinedStatusMessages = tmp;
            [tmp writeToFile:filePath atomically:YES];
            [tmp release];
        }
    }*/
}

#define STATUS_BUTTON_TAG 13000
#define STATUS_LABEL_TAG  13001

/*!
 @abstract Creates header view
 */
- (void) setupHeaderView {
    
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    // background
    //
    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, 85.0)]; // 75.0
    backView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    
    
    // status description
    //
    UILabel *sdLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 4.0, 150.0, 21.0)];
    [AppUtility configLabel:sdLabel context:kAULabelTypeBackgroundText];
    sdLabel.text = NSLocalizedString(@"Current Status", @"StatusMessage - text: the current status message is displayed below.");
    [backView addSubview:sdLabel];
    [sdLabel release];
    
    // bear image
    //
    UIImageView *bearView = [[UIImageView alloc] initWithFrame:CGRectMake(8.0, 28.0, 50.0, 50.0)];
    bearView.image = [UIImage imageNamed:@"profile_headshot_bear.png"];
    [backView addSubview:bearView];
    
    MPImageManager *imageM = [[MPImageManager alloc] init];
    
    UIImage *headImage = [imageM getImageForObject:[CDContact mySelf] context:kMPImageContextList ignoreVersion:YES];
    
    [imageM release];
    // my photo exists, then add it
    if (headImage) {
        UIImageView *headShotView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 5.0, 40.0, 40.0)];
        headShotView.image = headImage;
        [bearView addSubview:headShotView];
        [headShotView release];
    }
    [bearView release];

    
    // status button
    //
    UIButton *statusButton = [[UIButton alloc] initWithFrame:CGRectMake(57.0, 25.0, 255, 57.0)]; // 47.0
    [AppUtility configButton:statusButton context:kAUButtonTypeStatus];
    [statusButton addTarget:self action:@selector(pressEdit:) forControlEvents:UIControlEventTouchUpInside];
    statusButton.tag = STATUS_BUTTON_TAG;
    [backView addSubview:statusButton];
    
    // create status text label
    TextEmoticonView *statusLabel = [[TextEmoticonView alloc] initWithFrame:CGRectMake(30.0, -1.0, 215.0, 55.0)];
    statusLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicroPlus];
    statusLabel.numberOfLines = 3;
    //statusLabel.verticalAlignment = TETextVerticalAlignmentTop;
    statusLabel.lineBreakMode = UILineBreakModeTailTruncation;
    statusLabel.tag = STATUS_LABEL_TAG;
    [statusButton addSubview:statusLabel];
    [statusLabel release];
    [statusButton release];
    
    
    self.tableView.tableHeaderView = backView;
    [backView release];
    
}

/*!
 @abstract update status message in header view
 */
- (void) updateStatusMessageInHeader:(NSString *)status {
    
    TextEmoticonView *statusLabel = (TextEmoticonView *)[self.tableView.tableHeaderView viewWithTag:STATUS_LABEL_TAG];
    [statusLabel setText:status];
}

/*!
 @abstract send candidate status to server to save
 */
- (void) submitStatusToPresenceServer {
    
    [AppUtility startActivityIndicator];
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(processUpdateStatus:) name:MP_HTTPCENTER_UPDATE_STATUS_NOTIFICATION object:nil];
    [[MPHTTPCenter sharedMPHTTPCenter] updateStatus:self.tempStatus];

}


#pragma mark - SelectCellDelegate

/*!
 @abstract notified by that cell was selected
 
 Psuedo code:
 - start activity indicator
 - submit status udpate
 - wait for reply
 
 */
- (void)selectCellController:(SelectCellController *)selectCellController tappedObject:(id)tappedObject {
    
    self.tempStatus = tappedObject;
    [self submitStatusToPresenceServer];
}

/*!
 @abstract process udpate status results
 */
- (void) processUpdateStatus:(NSNotification *)notification {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [AppUtility stopActivityIndicator];
    
    NSDictionary *responseD = [notification object];
        
    NSString *title = NSLocalizedString(@"Update Status", @"StatusMessage - alert title:");
    
    NSString *detMessage = nil;
    
    // ok to update status!
    if ([MPHTTPCenter getCauseForResponseDictionary:responseD] == kMPCauseTypeSuccess) {
        
        [[MPSettingCenter sharedMPSettingCenter] setMyStatusMessage:self.tempStatus];
        
        [self updateStatusMessageInHeader:self.tempStatus];
        //detMessage = [NSString stringWithFormat:NSLocalizedString(@"Your M+ ID '%@' is created. Now people can find you with this ID", @"CreateID - alert: inform of success"), self.tempMPID];
        
        // if edit status view, then pop it
        UIViewController *visibleController = [self.navigationController visibleViewController];
        if ([visibleController isKindOfClass:[ComposerController class]]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    // did not succeed
    else {
        detMessage = NSLocalizedString(@"Status update failed. Try again.", @"StatusMessage - alert: inform of failure");
    }
    if (detMessage) {
        [Utility showAlertViewWithTitle:title message:detMessage];
    }
}

#pragma mark - Button

/*!
 @abstract edit current status
 */
- (void)pressEdit:(id)sender {
    NSString *status = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingStatus];

    ComposerController *nextController = [[ComposerController alloc] init];
    nextController.tempText = status;
    nextController.characterLimitMax = kMPParamStatusMessageMax;
    nextController.title = NSLocalizedString(@"Edit Status", @"StatusEdit - title: view to edit status message");
    nextController.delegate = self;
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];

    /*
    StatusEditController *nextController = [[StatusEditController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
    [nextController release];
    */
}

#pragma mark - ComposerController

/*!
 @abstract User pressed saved with new text string
 */
- (void)ComposerController:(ComposerController *)composerController didSaveWithText:(NSString *)text {
    
    self.tempStatus = [Utility trimWhiteSpace:text];
    [self submitStatusToPresenceServer];
    
}

@end
