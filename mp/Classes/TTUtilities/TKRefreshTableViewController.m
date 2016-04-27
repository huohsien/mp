//
//  TTRefreshTableViewController.m
//  ContactBook
//
//  Created by M Tsai on 11-3-22.
//  Copyright 2011 TernTek. All rights reserved.
//

#import "TKRefreshTableViewController.h"
#import "Utility.h"
#import "MPFoundation.h"

// position to start animation
//
#define kAnimateYStart		-30.0f

// range after start to continue animation
//
#define kAnimateYDistance	-65.0f


// point after which view will open
//
#define kRefreshHeaderThreshold	-70.0f

// point after which view will close
//
#define kHeaderCloseThreshold	-85.0f

// how much of the refresh header is displayed
//
#define kRefreshHeaderHeight	145.0f

@implementation TKRefreshTableViewController

@synthesize reloadDelayTimer;
@synthesize refreshHeaderView;

@synthesize isLocked;
@synthesize insetOnReload;

#define HIDDENCHAT_TAG 14055


- (void) lockHiddenChat {
    DDLogInfo(@"RTV: locking chat");
    HiddenChatView *hiddenView = (HiddenChatView *)[self.tableView viewWithTag:HIDDENCHAT_TAG];
    [hiddenView pressLockNowNoAnimation:nil];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	HiddenChatView *newView = [[HiddenChatView alloc] initWithFrame:
						 CGRectMake(0.0f, 0.0f - self.view.bounds.size.height,
									320.0f, self.view.bounds.size.height) isAlignedToTop:NO];
    newView.delegate = self;
    newView.tag = HIDDENCHAT_TAG;
    self.refreshHeaderView = newView;
    [newView release];
    
	[self.tableView addSubview:self.refreshHeaderView];
	self.tableView.showsVerticalScrollIndicator = YES;
    
    
	// pre-load sounds
	/*psst1Sound = [[SoundEffect alloc] initWithContentsOfFile:
				  [[NSBundle mainBundle] pathForResource:@"psst1"
												  ofType:@"wav"]];
	psst2Sound  = [[SoundEffect alloc] initWithContentsOfFile:
				   [[NSBundle mainBundle] pathForResource:@"psst2"
												   ofType:@"wav"]];
	popSound  = [[SoundEffect alloc] initWithContentsOfFile:
				 [[NSBundle mainBundle] pathForResource:@"pop"
												 ofType:@"wav"]];
	*/
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    
    
    [super viewWillAppear:animated];
    
    self.isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];

                      
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
/*	[psst1Sound release];
	[psst2Sound release];
	[popSound release];*/
	
    
	[reloadDelayTimer release];
	[refreshHeaderView release];
    [super dealloc];
}

#pragma mark - Chat List Overrides

/*!
 @abstract Show Cancel PIN button - to dismiss enter PIN mode
 
 */
- (void) navBarShowCancel
{
	DDLogVerbose(@"Please override navBarShowCancel");
}

/*!
 @abstract Restore to original navigation buttons
 
 */
- (void) navBarRestoreButtons
{
	DDLogVerbose(@"Please override navBarRestoreButtons");
}


/*!
 @abstract Inform Chat that HC was unlocked
 
 */
- (void) hiddenDidUnlock
{
	DDLogVerbose(@"Please override hiddenDidUnlock");
}

/*!
 @abstract Inform Chat that HC was locked
 
 */
- (void) hiddenDidLockAnimated:(BOOL)animated
{
	DDLogVerbose(@"Please override hiddenDidLock");
}


#pragma mark - State Changes

/*!
 @abstract Starts reloading animation
 
 */
- (void) showReloadAnimationAnimated:(BOOL)animated
{
	reloading = YES;
    self.insetOnReload = YES;
	[self.refreshHeaderView toggleActivityView:YES];
	
	if (animated)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2];
		self.tableView.contentInset = UIEdgeInsetsMake([self.refreshHeaderView openViewHeight], 0.0f, 0.0f,
													   0.0f);
		[UIView commitAnimations];
	}
	else
	{
		self.tableView.contentInset = UIEdgeInsetsMake([self.refreshHeaderView openViewHeight], 0.0f, 0.0f,
													   0.0f);
	}
}

/*!
 @abstract Method usually goes out and gets new data to load in
 
 */
- (void) reloadTableViewDataSource
{
	DDLogVerbose(@"Please override reloadTableViewDataSource");
}


/*!
 @abstract Hide header view since data has just finished loading
 */
- (void)dataSourceDidFinishLoadingNewDataAnimated:(BOOL)animated
{
	reloading = NO;
	//[refreshHeaderView flipImageAnimated:NO];
    
    if (animated) {
        [UIView animateWithDuration:kMPParamAnimationStdDuration 
                         animations:^{
                             [self.tableView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
                             [self.refreshHeaderView setStatus:kHCViewStatusClose];
                             [self.refreshHeaderView toggleActivityView:NO];
                         }];
    }
    else {
        [self.tableView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
        [self.refreshHeaderView setStatus:kHCViewStatusClose];
        [self.refreshHeaderView toggleActivityView:NO];
    }
    
    [self navBarRestoreButtons];
	//[Utility audioPlayEffect:@"tt-pop.caf"];
}





#pragma mark - Scrolling Delegates

/**
 
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	if (!reloading)
	{
		checkForRefresh = YES;  //  only check offset when dragging
	}
}



/**
 React to user directly dragging the table UI
 
 - Execute flip animation if scroll pass threshold
 
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    

    /*
     Since we pushed our content in by using contentInset
     - The tableheader views also gets pushed down, so they can never slide up to the top.
     - So instead try to make the contentInset exactly match the about of the refresh view that is showing
     - This is only needed for locked state since unlock does not have table headers (self.isLocked)
     - Only needed after insets have been expanded (reloading)
     */
    if (reloading && !self.isLocked) {
        if (scrollView.contentOffset.y > -[self.refreshHeaderView openViewHeight] && scrollView.contentOffset.y < 0.0 && self.insetOnReload) {
            [self.tableView setContentInset:UIEdgeInsetsMake(-scrollView.contentOffset.y, 0.0, 0.0, 0.0)];
        }
        else if (scrollView.contentOffset.y >= 0.0 && self.insetOnReload) {
            [self.tableView setContentInset:UIEdgeInsetsZero];
            // don't inset after closing up
            self.insetOnReload = NO;
        }
        return;
    }
    
	if (checkForRefresh) {
		
        
        
		// not pass the reload threadhold
		// - update animation
		/*if (scrollView.contentOffset.y < kAnimateYStart && scrollView.contentOffset.y > (kAnimateYStart+kAnimateYDistance) ) {
			
			CGFloat position = (scrollView.contentOffset.y - kAnimateYStart)/(kAnimateYDistance);
			[refreshHeaderView moveImage:position animated:YES];
			
		}*/
		
		// if pulled down
		// - play sound and change status
        // - just starting to pull down
        //
		if (scrollView.contentOffset.y < 0.0f && scrollView.contentOffset.y > (kAnimateYStart+kAnimateYDistance)) {
			
			if (refreshHeaderView.viewStatus == kHCViewStatusClose ) {
				//[Utility audioPlayEffect:@"tt-pull.caf"];
			}
			[refreshHeaderView setStatus:kTableStatusPullToReload];
		}
        // pull past threshold
        //
		else if(scrollView.contentOffset.y < (kAnimateYStart+kAnimateYDistance) && 
				refreshHeaderView.viewStatus == kTableStatusPullToReload){
			
			[refreshHeaderView setStatus:kTableStatusReleaseToReload];
		}
		

		
		/*
		if (refreshHeaderView.isFlipped
			&& scrollView.contentOffset.y > -65.0f
			&& scrollView.contentOffset.y < 0.0f
			&& !reloading) {
			
			CGFloat position = (scrollView.contentOffset.y)/(-65.0f);
			
			//[refreshHeaderView flipImageAnimated:YES];
			[refreshHeaderView moveImage:position];
			[refreshHeaderView setStatus:kTableStatusPullToReload];
			//[popSound play];
			
		} 
		// passed the reload threshold
		//
		else if (!refreshHeaderView.isFlipped
				   && scrollView.contentOffset.y < -65.0f ) {
			//[refreshHeaderView flipImageAnimated:YES];
			[refreshHeaderView setStatus:kTableStatusReleaseToReload];
			//[psst1Sound play];
		}
		 */
	}
}

/*!
 @abstract close header view if it is hidden
 
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    /*if (reloading) {
        // cancel if scroll up and header has disappeared
		// - cancel process
		//
		if (scrollView.contentOffset.y >= 0.0f){
            [self dataSourceDidFinishLoadingNewData];
		}
	}*/
}


/*!
 @abstract Respond when user just stops dragging
 
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
				  willDecelerate:(BOOL)decelerate
{
	if (reloading) {

        // close if scroll up past threshold
		//
		if (scrollView.contentOffset.y >= kHeaderCloseThreshold ){
            [self dataSourceDidFinishLoadingNewDataAnimated:YES];
		}
        
	}
	else {
		// if scroll beyond threshold
		// - start action
		//
        if (scrollView.contentOffset.y <= [self.refreshHeaderView openViewThreshold]) {
            
            [self.refreshHeaderView setStatus:kHCViewStatusOpen];
            
			if([self.tableView.dataSource respondsToSelector:
				@selector(reloadTableViewDataSource)]){
				[self showReloadAnimationAnimated:YES];
				//[Utility audioPlayEffect:@"tt-release.caf"];
				
				// delay reload
				//self.reloadDelayTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(reloadTableViewDataSource) userInfo:nil repeats:NO];
				//[self reloadTableViewDataSource];
			}
		}
		// pulling down, but not far enough
		//
		else if(scrollView.contentOffset.y > [self.refreshHeaderView openViewThreshold] && scrollView.contentOffset.y < 0.0) {
			//[self dataSourceDidFinishLoadingNewData];
		}
	}
	checkForRefresh = NO;
}

#pragma mark - HiddenChatView

/*!
 @abstract Call when header view wants to close itself
 */
- (void)HiddenChatView:(HiddenChatView *)view closeWithAnimation:(BOOL)animated {
    
    [self dataSourceDidFinishLoadingNewDataAnimated:animated];
    
}

/*!
 @abstract Call when PIN display should be shown
 */
- (void)HiddenChatView:(HiddenChatView *)view showPINDisplayWithHeight:(CGFloat)height {
        
    CGFloat totalHeight = [self.refreshHeaderView openViewHeight]+height;
    [self.tableView setContentOffset:CGPointMake(0.0, -totalHeight) animated:NO];
    self.tableView.contentInset = UIEdgeInsetsMake(totalHeight, 0.0f, 0.0f,
                                                   0.0f);
    
	//[Utility audioPlayEffect:@"tt-pop.caf"];
}

/*!
 @abstract Notifiy Delegate that unlock was successful
 - Chat List should refresh 
 - lets us know lock state, provide proper inset & scrolling behavior
 */
- (void)HiddenChatView:(HiddenChatView *)view unlockDidSucceed:(BOOL)didSucceed {
    self.isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    [self hiddenDidUnlock];
}

/*!
 @abstract Notifiy Delegate that lock was successful
 - lets us know lock state, provide proper inset & scrolling behavior
 */
- (void)HiddenChatView:(HiddenChatView *)view lockDidSucceed:(BOOL)didSucceed animated:(BOOL)animated {
    self.isLocked = [[MPSettingCenter sharedMPSettingCenter] isHiddenChatLocked];
    [self hiddenDidLockAnimated:animated];
}


/*!
 @abstract Call when pin animation is completed
 @discussion Used to show cancel button in integrated view's navbar
 */
- (void)HiddenChatView:(HiddenChatView *)view showPINDisplayAnimationDidComplete:(BOOL)didComplete{
    [self navBarShowCancel];  // show cancel button to exit out of this mode
}



@end