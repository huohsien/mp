//
//  mpAppDelegate.m
//  mp
//
//  Created by M Tsai on 11-8-26.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "mpAppDelegate.h"

#import "MPFoundation.h"
#import "TTContainerViewController.h"
#import "MPSocketCenter.h"

#import "TabBarFacade.h"
#import "TabBarItemController.h"

#import "ContactController.h"
#import "ChatController.h"
#import "SettingController.h"

#import "PhoneRegistrationController.h"
#import "PhoneRegistrationController2.h"
#import "EULAController.h"
#import "MPContactManager.h"
#import "MPChatManager.h"

#import "ChatDialogController.h"
#import "ChatSettingController.h"
#import "ChatNameController.h"
#import "MPResourceCenter.h"
#import "ResourceUpdateController.h"
#import "ScheduleController.h"

#import "ELCAlbumPickerController.h"
#import "ELCAssetTablePicker.h"
#import "SelectContactController.h"

#import "PhoneBookController.h"
#import "HiddenController.h"
#import "FriendSuggestionController.h"
#import "CDChat.h"
#import "CDContact.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

#import "EmoticonKeypad.h"


/*! notify of push registration results */
NSString* const MP_APPDELEGATE_REGISTER_PUSH_NOTIFICATION = @"MP_APPDELEGATE_REGISTER_PUSH_NOTIFICATION";



@interface mpAppDelegate (PrivateMethods)
- (void)sendProviderDeviceToken:(NSData *)devToken;
@end

// interval in which registration is considered fresh
//
CGFloat const kMPParamPushNotificationRegisterFreshInterval = 600000; // ~ 1 week

// How often to check for new resource updates
//
CGFloat const kMPParamCheckResourceInfoFreshInterval = 600.0;


@implementation mpAppDelegate


@synthesize window=_window;
@synthesize tabBarController, tabBarFacade;
@synthesize containerController;

@synthesize background_moc_queue;
@synthesize backgroundContactManager;

@synthesize backManagedObjectContext;
@synthesize isStartingFromScratch;
@synthesize didLastSessionGetLowMemoryWarning;

@synthesize fileLogger;
@synthesize emoticonKeypad;
@synthesize appNSCache;
@synthesize resetAppTaskID;

#pragma mark - GCD Methods


/*!
 @abstract getter for background MOC queue
 
 @discussion only execute background CD task here on this thread
 
 */
- (dispatch_queue_t) background_moc_queue {
    
    // if does not exists
    // - create it
    if (background_moc_queue == NULL){
        background_moc_queue = dispatch_queue_create([kMPQueueBackgroundMOC UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_retain(background_moc_queue);
    }
    return background_moc_queue;
}

/*!
 @abstract getter for background Contact Manager
 
 @discussion only execute background CD task here on this thread
 
 */
- (MPContactManager *) backgroundContactManager {
    
    // if does not exists
    // - create it
    if (backgroundContactManager == nil){
        backgroundContactManager = [[MPContactManager alloc] init];
    }
    return backgroundContactManager;
}


/*!
 @abstract getter for network data processing queue
 
 @discussion any processing of network data, message creation and distribution should
 happen here.  Do NOT access CoreData here at all!
 
 */
- (dispatch_queue_t) network_queue {
    
    // if does not exists
    // - create it
    if (network_queue == NULL){
        network_queue = dispatch_queue_create([kMPQueueNetwork UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_retain(network_queue);
    }
    return network_queue;
}


#pragma mark - Shared Instances


/*!
 @abstract create and get socket manager
 
 */

- (MPSocketCenter *) socketCenter {
	if (socketCenter != nil) {
		return socketCenter;
	}
    
    socketCenter = [[MPSocketCenter alloc] init];
    return socketCenter;
}

/*!
 @abstract shared emoticon keypad
 
 */

- (EmoticonKeypad *) emoticonKeypad {
	if (emoticonKeypad != nil) {
		return emoticonKeypad;
	}
    emoticonKeypad = [[EmoticonKeypad alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0) displayMode:kEKModeDefault];
    return emoticonKeypad;
}

/*!
 @abstract Release keypad so a new one can be created
 */

- (void) resetEmoticonKeypad {
	if (emoticonKeypad != nil) {
		self.emoticonKeypad = nil;
	}
}

/*!
 @abstract Shared NSCache for this application
 
 - thread safe access
 - however only put read-only objects that are thread safe
 - gets purged when low memory is encountered
 
 Use:
 - collation dictionaries: these are quite large 700k, so don't keep on reading them in from file.
 
 */
- (NSCache *) sharedCache {
	if (self.appNSCache != nil) {
		return self.appNSCache;
	}
    
    NSCache *newCache = [[NSCache alloc] init];
    self.appNSCache = newCache;
    [newCache release];
    
    return self.appNSCache;
}

/*!
 @abstract Get cached object
 
 */
- (id) sharedCacheObjectForKey:(NSString *)key {
    NSCache *cache = [self sharedCache];
    return [cache objectForKey:key];
}

/*!
 @abstract Get cached object
 
 */
- (void) sharedCacheSetObject:(id)object forKey:(NSString *)key {
    NSCache *cache = [self sharedCache];
    [cache setObject:object forKey:key];
}


#pragma mark - Core Data stack


/*!
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 
 Notes:
 - merge policy: external changes in store trumps in memory status
 + so that changes in background thread MOC will overwrite main thread changes! 
 - staleness set to 0 seconds so background updates will show up immediately
 - no need to undo manager - that wastes time recording actions that don't need to be undone
 
 */
- (NSManagedObjectContext *) managedObjectContext {
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");
    
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
		[managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
		[managedObjectContext setStalenessInterval:0.0];
		[managedObjectContext setUndoManager:nil];
		
    }
    
    // observe saves from this particular context
    //
    //[[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(didSaveMainMOC:) name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
    
    return managedObjectContext;
}

/*!
 Background thread's MOC
 - needs a separate MOC for each thread, so background threads should use this and set to nil when done
 
 Notes:
 - merge policy: memory overrides store value
 + so updates in background will propogate to other threads
 - staleness set to 30 seconds ~ this allow top contact refresh to work (every 60 seconds when TC is opened)
 - no need to undo manager - that wastes time recording actions that don't need to be undone
 
 Usage:
 - this should only be called by blocks running in the background_moc_queue
 
 */
- (NSManagedObjectContext *) backManagedObjectContext {
    NSAssert(dispatch_get_current_queue() == [AppUtility getBackgroundMOCQueue], @"Must be dispatched on backQueue");
    
    if (backManagedObjectContext != nil) {
        return backManagedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
		DDLogVerbose(@"AD-BMOC: creating new back MOC");
        backManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [backManagedObjectContext setPersistentStoreCoordinator: coordinator];
		[backManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
		//[backManagedObjectContext setStalenessInterval:50];
		[backManagedObjectContext setUndoManager:nil];
    }
    
    // observe saves from this particular context
    //
    [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(didSaveBackMOC:) name:NSManagedObjectContextDidSaveNotification object:backManagedOjectContext];
    
    
    return backManagedObjectContext;
}

/*!
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"mpModel" ofType:@"momd"];
    //NSURL *momURL = [NSURL fileURLWithPath:path];
    //managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    
	managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return managedObjectModel;
}


/*!
 @abstract Adds persistent store to PSC
 */
- (void)addPersistentStore {
    DDLogVerbose(@"AD-aps: Adding Persistent Store");
    
    NSError *error = nil;
    NSURL *storeUrl = [NSURL fileURLWithPath: [[Utility applicationDocumentsDirectory] stringByAppendingPathComponent: @"mpModel.sqlite"]];
    
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,nil];
    
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
                                                       configuration:nil 
                                                                 URL:storeUrl 
                                                             options:options 
                                                               error:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object model
		 Check the error message to determine what the actual problem was.
		 */
		DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
        
        // TODO: alert user here - reinstall!
        
    }  
}


/*!
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    
    // this may run from multiple queue, to prevent running concurrently
    static dispatch_once_t once;
	dispatch_once(&once, ^{
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] 
                                      initWithManagedObjectModel:[self managedObjectModel]];
        
        [self addPersistentStore];
	});
    
	
    return persistentStoreCoordinator;
}


/*!
 @abstract handles change in back MOC and merge with main MOC
 
 - Deprecated: main changes are not saved to the background queue only the other way around
 
 */
- (void) didSaveMainMOC:(NSNotification *)notification {
    //self.isMergingInProgress = YES;
    //DDLogVerbose(@"AD-dsm: merging Main to BackMOC");
    if (dispatch_get_current_queue() == [AppUtility getBackgroundMOCQueue]) {
        [AppUtility cdMergeChangesToContext:self.backManagedObjectContext saveNotification:notification];
    }
    else {
        dispatch_async([AppUtility getBackgroundMOCQueue], ^{
            [AppUtility cdMergeChangesToContext:self.backManagedObjectContext saveNotification:notification];
        });
    }
    //DDLogVerbose(@"AD-dsm: merging Done");
    //self.isMergingInProgress = NO;
}


/*!
 @abstract handles change in back MOC and merge with main MOC
 */
- (void) didSaveBackMOC:(NSNotification *)notification {
    
    // don't merge my own saves
    dispatch_queue_t currentQ = dispatch_get_current_queue();
    if (currentQ == dispatch_get_main_queue()) {
        NSManagedObjectContext *savedMOC = (NSManagedObjectContext *)[notification object];
        if (savedMOC == self.managedObjectContext) {
            return;
        }
    }
    
    //self.isMergingInProgress = YES;
    //DDLogVerbose(@"AD-dsb: merging Back to MainMOC");
    if (dispatch_get_current_queue() == dispatch_get_main_queue()) {
        [AppUtility cdMergeChangesToContext:self.managedObjectContext saveNotification:notification];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [AppUtility cdMergeChangesToContext:self.managedObjectContext saveNotification:notification];
        });
    }
    //DDLogVerbose(@"AD-dsb: merging Done");
    //self.isMergingInProgress = NO;
}

#pragma mark - Tab Controllers


/*!
 Getter methods for nav view controllers
 - allows for lazy loading
 
 Note:
 - only get after restore manager is created!.. or make restore lazy loading too!
 
 */

- (UINavigationController *) contactNavigationController {
	if (contactNavigationController != nil) {
		return contactNavigationController;
	}
    ContactController *contactController = [[ContactController alloc] initWithStyle:UITableViewStylePlain];
    contactNavigationController = [[UINavigationController alloc] initWithRootViewController:contactController];
    contactNavigationController.delegate = self;
    [AppUtility customizeNavigationController:contactNavigationController];
    [contactController release];
    return contactNavigationController;
}

/*!
 Getter methods for nav view controllers
 - allows for lazy loading
 
 Note:
 - only get after restore manager is created!.. or make restore lazy loading too!
 
 */

- (UINavigationController *) phoneNavigationController {
	if (phoneNavigationController != nil) {
		return phoneNavigationController;
	}
    PhoneBookController *phoneController = [[PhoneBookController alloc] initWithStyle:UITableViewStylePlain];
    phoneNavigationController = [[UINavigationController alloc] initWithRootViewController:phoneController];
    phoneNavigationController.delegate = self;
    [AppUtility customizeNavigationController:phoneNavigationController];
    [phoneController release];
    return phoneNavigationController;
}


/*!
 Getter methods for nav view controllers
 - allows for lazy loading
 
 Note:
 - only get after restore manager is created!.. or make restore lazy loading too!
 
 */

- (UINavigationController *) chatNavigationController {
	if (chatNavigationController != nil) {
		return chatNavigationController;
	}
	
    ChatController *chatController = [[ChatController alloc] initWithStyle:UITableViewStylePlain];
    chatNavigationController = [[UINavigationController alloc] initWithRootViewController:chatController];
    chatNavigationController.delegate = self;
    [AppUtility customizeNavigationController:chatNavigationController];
    [chatController release];
    return chatNavigationController;
}

/*!
 Getter methods for nav view controllers
 - allows for lazy loading
 
 Note:
 - only get after restore manager is created!.. or make restore lazy loading too!
 
 */

- (UINavigationController *) settingNavigationController {
	if (settingNavigationController != nil) {
		return settingNavigationController;
	}
	
    SettingController *settingController = [[SettingController alloc] init];
    settingNavigationController = [[UINavigationController alloc] initWithRootViewController:settingController];
    settingNavigationController.delegate = self;
    [AppUtility customizeNavigationController:settingNavigationController];
    [settingController release];
    return settingNavigationController;
}

/*!
 Getter methods for nav view controllers
 - allows for lazy loading
 
 Note:
 - only get after restore manager is created!.. or make restore lazy loading too!
 
 */

- (UINavigationController *) scheduledNavigationController {
	if (scheduledNavigationController != nil) {
		return scheduledNavigationController;
	}
	
    ScheduleController *scheduleController = [[ScheduleController alloc] initWithStyle:UITableViewStylePlain];
    scheduledNavigationController = [[UINavigationController alloc] initWithRootViewController:scheduleController];
    scheduledNavigationController.delegate = self;
    [AppUtility customizeNavigationController:scheduledNavigationController];
    [scheduleController release];
    return scheduledNavigationController;}

/*!
 
 */
- (void) setupTabBarController {
    
    DDLogVerbose(@"AD_TAB_01: start");
	// add individual subviews to tab controller
	UITabBarController *newTabController = [[UITabBarController alloc] init];
	self.tabBarController = newTabController;
    self.tabBarController.view.backgroundColor = [UIColor blackColor];
	[newTabController release];
	
	
	DDLogVerbose(@"AD_TAB_02: Fin launch fake");
	
	// load last saved view
	/*RestoreManager *restManager = [[RestoreManager alloc] init];
     self.restoreManager = restManager;
     [restManager release];
     DDLogVerbose(@"AD_TAB_03: After Restore alloc");
     */
	
	//DDLogVerbose(@"AFL06: After set view controller");
	self.tabBarController.view.frame = [[UIScreen mainScreen] applicationFrame]; //self.containerController.view.bounds;
	self.tabBarController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tabBarController.view.backgroundColor = [UIColor blackColor];
	//[self.containerController.view addSubview:self.tabBarController.view];
	//[self.containerController registerViewController:self.tabBarController];
    
	DDLogVerbose(@"AD_TAB_0X: After add backend tab controller");
	
	//***********************
	// Create Fake TabBar
	//***********************
    TabBarItemController *contactItemController = [[TabBarItemController alloc] initWithButtonTitle:NSLocalizedString(@"Friends",@"Tab: Contact tab title") 
                                                                                 notPressedFilename:@"std_tab_friends_nor.png"
                                                                                    pressedFilename:@"std_tab_friends_prs.png" 
                                                                       navigationControllerSelector:@selector(contactNavigationController)];
    
    TabBarItemController *phonebookItemController = [[TabBarItemController alloc] initWithButtonTitle:NSLocalizedString(@"Contacts",@"Tab: Phonebook tab title") 
                                                                                   notPressedFilename:@"std_tab_phonebook_nor.png"
                                                                                      pressedFilename:@"std_tab_phonebook_prs.png" 
                                                                         navigationControllerSelector:@selector(phoneNavigationController)];
    
	TabBarItemController *chatItemController = [[TabBarItemController alloc] initWithButtonTitle:NSLocalizedString(@"Chat",@"Tab: Chat tab title") 
                                                                              notPressedFilename:@"std_tab_chat_nor.png"
                                                                                 pressedFilename:@"std_tab_chat_prs.png" 
                                                                    navigationControllerSelector:@selector(chatNavigationController)];
    
    TabBarItemController *scheduleItemController = [[TabBarItemController alloc] initWithButtonTitle:NSLocalizedString(@"Schedule",@"Tab: Scheduled Message tab title") 
                                                                              notPressedFilename:@"std_tab_schedulemessage_nor.png"
                                                                                 pressedFilename:@"std_tab_schedulemessage_prs.png" 
                                                                    navigationControllerSelector:@selector(scheduledNavigationController)];
	
    TabBarItemController *settingItemController = [[TabBarItemController alloc] initWithButtonTitle:NSLocalizedString(@"Settings",@"Tab: Settings tab title") 
                                                                                 notPressedFilename:@"std_tab_setting_nor.png"
                                                                                    pressedFilename:@"std_tab_setting_prs.png" 
                                                                       navigationControllerSelector:@selector(settingNavigationController)];
    

    
	
	DDLogVerbose(@"AD_TAB_10: After tab item alloc");
	
	NSArray *itemControllers = [NSArray arrayWithObjects:contactItemController, phonebookItemController, chatItemController, scheduleItemController, settingItemController, nil];
    
    //NSArray *itemControllers = [NSArray arrayWithObjects:contactItemController, testItemController, chatItemController, scheduleItemController, settingItemController, nil];

    
    [contactItemController release];
    [phonebookItemController release];
    [chatItemController release];
    [scheduleItemController release];
    [settingItemController release];
    
	TabBarFacade *newTabBarFacade = [[TabBarFacade alloc] initWithTabBarController:self.tabBarController 
                                                             tabBarItemControllers:itemControllers];
	newTabBarFacade.delegate = self;
	
	DDLogVerbose(@"AD_TAB_06: After facade alloc");
	
	self.tabBarFacade = newTabBarFacade;
	// adjust position and add to view
    // - puts facacde at the bottom of the view
    //
	CGFloat facadeWidth = self.tabBarFacade.containerView.frame.size.width;
	CGFloat facadeHeight = self.tabBarFacade.containerView.frame.size.height;
	self.tabBarFacade.containerView.center = CGPointMake(facadeWidth/2., 
														 self.tabBarController.view.frame.size.height-(facadeHeight/2.0));
	[newTabBarFacade release];
	[self.tabBarController.view addSubview:self.tabBarFacade.containerView];
	self.tabBarController.view.contentMode = UIViewContentModeBottom;
	
	// restore to last used index
	/*NSUInteger lastTabIndex = [self.restoreManager getLastTabBarIndex];
     
     // restore tab appearance: disable the current pressed tab button
     if (lastTabIndex < [self.tabBarFacade.tabBarItemControllers count]) {
     TabBarItemController *pressedController = [self.tabBarFacade.tabBarItemControllers objectAtIndex:lastTabIndex];
     [self.tabBarFacade pressed:pressedController];
     }*/
	
    // TODO:  - TEST -  
    // warm up testing module
    [self.tabBarFacade pressedIndex:kMPTabIndexScheduled];
    //[self.tabBarFacade warmUpTabBarItem:kMPTabIndexScheduled];
    
    
    // set default to chat tab item
    [self.tabBarFacade pressedIndex:kMPTabIndexChat];
	
	
	DDLogVerbose(@"AD_TAB_06: After add facade subview");
}


#pragma mark - Tab Bar Facade

/*!
 @abstract Inform users tabbar will transition to another tab
 
 Use:
 - Delegate an react to changes in tab bar
 */
- (void)TabBarFacade:(TabBarFacade *)tabBarFacade didTransitionFromController:(UINavigationController *)fromController toController:(UINavigationController *)toController {
    
    // make sure friend list always goes to root after leaving it!
    //
    if (contactNavigationController) {
        if (fromController == self.contactNavigationController &&
            toController != self.contactNavigationController) {
            [self.contactNavigationController popToRootViewControllerAnimated:NO];
        }
    }
}





#pragma mark - App Tools





/*!
 @abstract APNS Register
 
 Use:
 - call when app becomes active
 - right after registration succeeds
 - change popup alert settings
 
 */
- (void) tryRegisterPushNotificationForceStart:(BOOL)forceStart enableAlertPopup:(BOOL)enableAlertPopup {
    
    BOOL isRegistered = [[MPHTTPCenter sharedMPHTTPCenter] isUserRegistered];
    
    // can't run if user is not registered
    if (!isRegistered) {
        return;
    }
    
    BOOL shouldStart = NO;
    
    if (forceStart) {
        shouldStart = YES;
    }
    else {
        NSDate *lastCompleteDate = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPushNotificationRegisterLastCompleteDate];
        
        // if no date, then use an old date to compare
        if (lastCompleteDate == nil) {
            lastCompleteDate = [NSDate dateWithTimeIntervalSince1970:0.0];
        }
        
        // neg to go into past 
        NSDate *checkDate = [[NSDate alloc] initWithTimeIntervalSinceNow:kMPParamPushNotificationRegisterFreshInterval*(-1.0f)]; 
        
        // if last reg was older than check date
        if ([lastCompleteDate compare:checkDate] == NSOrderedAscending) {
            shouldStart = YES;
        }
        [checkDate release];
        
        // check if language change occurred, then register to inform NS
        //
        NSString *currentLanguage = [AppUtility devicePreferredLanguageCode];
        NSString *lastLanguage = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingSystemLanguageLastUsed];
        
        if (![currentLanguage isEqualToString:lastLanguage]) {
            DDLogInfo(@"AD-push: lang change detected");
            shouldStart = YES;
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingSystemLanguageLastUsed settingValue:currentLanguage];
        }
    }
    
    if (shouldStart) {
        DDLogInfo(@"AD-push: start push registration");
        // testing ...[self sendProviderDeviceToken:(NSData *)@"xxx"];
        // try registering now for notification
        //
        
        // always enabled all alerts
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge;
        
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
    }
}


/*!
 @abstract APNS Register
 
 Use:
 - call when app becomes active
 
 */
- (void) tryCheckResourceInfoForceStart:(BOOL)forceStart {
    
    /*BOOL isRegistered = [[MPHTTPCenter sharedMPHTTPCenter] isUserRegistered];
    
    // can't run if user is not registered
    if (!isRegistered) {
        return;
    }*/
    
    BOOL shouldStart = NO;
    
    if (forceStart) {
        shouldStart = YES;
    }
    else {
        NSDate *lastCompleteDate = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingCheckResourceCompleteDate];
        
        // if no date, then use an old date to compare
        if (lastCompleteDate == nil) {
            lastCompleteDate = [NSDate dateWithTimeIntervalSince1970:0.0];
        }
        
        // neg to go into past 
        NSDate *checkDate = [[NSDate alloc] initWithTimeIntervalSinceNow:kMPParamCheckResourceInfoFreshInterval*(-1.0f)]; 
        
        // if last reg was older than check date
        if ([lastCompleteDate compare:checkDate] == NSOrderedAscending) {
            shouldStart = YES;
        }
        [checkDate release];
    }
        
    // get the resource meta-data
    if (shouldStart) {
        
        BOOL didLoadDefault = NO;
        
        // load default resource information for first try
        //
        if ([[MPSettingCenter sharedMPSettingCenter] didNotRunFirstStartTag:kMPSettingFirstStartTagLoadDefaultResourceInfo]) {
            [[MPHTTPCenter sharedMPHTTPCenter] getResourceDownloadInfoDefault];
            [[MPSettingCenter sharedMPSettingCenter] markFirstStartTagComplete:kMPSettingFirstStartTagLoadDefaultResourceInfo];
            
            // install default emoticons
            // emoticon_default_(mdpi|xhdpi).zip
            //
            [[MPResourceCenter sharedMPResourceCenter] installDefaultEmoticons];
            
            didLoadDefault = YES;
        }
        
        // if default was loaded, give some time for it to finish before performing the remote query
        if (didLoadDefault) {
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [[MPHTTPCenter sharedMPHTTPCenter] getResourceDownloadInfo];
            });
        }
        else {
            [[MPHTTPCenter sharedMPHTTPCenter] getResourceDownloadInfo];
        }
    }
}

/*!
 @abstract Tries to authenticate and checks if user is registered.
 
 If user is not registered, then display registration view.
 
 */
- (void) checkRegistration {
    
    DDLogInfo(@"AD: check registration - start AALogin");
    BOOL isRegistered = [[MPHTTPCenter sharedMPHTTPCenter] authenticateAndLogin];
    NSString *name = [[MPSettingCenter sharedMPSettingCenter] getNickName];
    
    // if not registered or name not yet defined, show registration view
    if (!isRegistered || [name length] == 0) {

        //old EULA view EULAController *nextViewController = [[EULAController alloc] init];
        PhoneRegistrationController2 *nextViewController = [[PhoneRegistrationController2 alloc] init];
        
        // Create nav controller to present modally
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:nextViewController];
        navigationController.navigationBar.barStyle = UIBarStyleBlack;
        [AppUtility customizeNavigationController:navigationController];
        
        [self.containerController presentModalViewController:navigationController animated:NO];
        [navigationController release];
        [nextViewController release];
        
        // also show friends list underneath
        //
        TabBarItemController *pressedController = [self.tabBarFacade.tabBarItemControllers objectAtIndex:kMPTabIndexFriend];
        [self.tabBarFacade pressed:pressedController];
        
        // get new resource information immediate if not registered
        //
        [self tryCheckResourceInfoForceStart:YES];
    }
}



/*!
 @abstract Reset all views
 
 Use:
 - after deleting account, unload views if needed
 
 */
- (void) resetViews {
    
    // remove all old controllers
    [self.tabBarController setViewControllers:[NSArray array] animated:NO];
    
    // clear old views
    //
    [contactNavigationController release];
    contactNavigationController = nil;
    
    [phoneNavigationController release];
    phoneNavigationController = nil;
    
    [chatNavigationController release];
    chatNavigationController = nil;
    
    [scheduledNavigationController release];
    scheduledNavigationController = nil;
    
    [settingNavigationController release];
    settingNavigationController = nil;
    
    // recreate views
    //
	[self setupTabBarController];
	self.containerController = self.tabBarController;
    self.window.rootViewController = self.containerController;
    self.window.backgroundColor = [UIColor blackColor];
	[self.window makeKeyAndVisible];
    
    
    // reset badge counts
    [[MPChatManager sharedMPChatManager] updateChatBadgeCount];
    [[MPChatManager sharedMPChatManager] updateScheduleBadgeCount];
    [MPContactManager updateFriendBadgeCount];
    
    // show registration again - settings should be reset already
    [self checkRegistration];
    
}


/*!
 @abstract Completely deletes and reset everything!
 
 @param fullSettingReset - skip EULA and initial reset
 
 @discussion This needs to be coordinated for an organized reset, otherwise crash is likely
 - turn off network
 - remove store
 - reset MOC and objects
 - reset settings
 - reset views
 
 Use:
 - user deletes the account
 - user registers on another device
 
 */
- (void) startFromScratchWithFullSettingReset:(BOOL)fullSettingReset {
    //self.isMergingInProgress = YES;
    DDLogInfo(@"AD-sfs1: start & DELETING CORE DATA");
    
    self.resetAppTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.resetAppTaskID];
        self.resetAppTaskID = UIBackgroundTaskInvalid;
    }];
    
    // send delete request for all scheduled messasges
    // - best effort, don't wait for response
    // - disabled: Cancel account API request will also delete this for us
    //
    // [[MPChatManager sharedMPChatManager] requestDeleteForAllScheduleMessage];
    
    // disable msg processing
    // - so incoming messages don't have conflict with missing chats from delete process below
    //
    [[MPChatManager sharedMPChatManager] shutdownMessageProcessing];
    
    // delete all chats before logging out
    // - send leave messages to group chats: best effort basis
    // - clear files
    [CDChat deleteAllChats];
    
    // prevent CD from saving new data
    self.isStartingFromScratch = YES;
    
    // shutdown connection
    // - don't want to accidentally reuse this connection
    //
    [[AppUtility getSocketCenter] logoutAndDisconnect]; 
    
    // allow app to suspend
    if (self.resetAppTaskID != UIBackgroundTaskInvalid) {
        DDLogInfo(@"AD-sfs1: allow reset app task to end");
        // tell app that we are done!
        [[UIApplication sharedApplication] endBackgroundTask:self.resetAppTaskID];
        self.resetAppTaskID = UIBackgroundTaskInvalid;
    }
    
    // continue after two seconds
    //
    [self performSelector:@selector(startFromScratchPartTwo) withObject:nil afterDelay:5.0];
    
    DDLogInfo(@"AD-sfs1: end");
}

/*!
 @abstract Part II of reset
 
 */
- (void) startFromScratchPartTwo {
    
    DDLogInfo(@"AD-sfs2: start");

    // force disconnect
    //
    [[AppUtility getSocketCenter] disconnect];
    
    // We only have one store, so get it and erase
    NSPersistentStore *store = [self.persistentStoreCoordinator.persistentStores lastObject];
    NSError *error = nil;
    NSURL *storeURL = store.URL;
    [self.persistentStoreCoordinator removePersistentStore:store error:&error];
    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
    
    //Make new persistent store for future saves 
    [self addPersistentStore];
    
    // flush old objects and reset MOC
    // - blocking
    [self.managedObjectContext reset];
    
    // also make sure addressbook is flushed
    [self.backgroundContactManager markAddressBookAsChangedFromABCallBack:NO];
    
    dispatch_sync([AppUtility getBackgroundMOCQueue], ^{
        
        // release all old objects
        [self.backgroundContactManager flushState];
        
        // invalidate all objects
        [self.backManagedObjectContext reset];
        
    });
    
    // ask friend list to reload
    [[NSNotificationCenter defaultCenter] postNotificationName:MP_CONTACTMANAGER_INDEX_NOTIFICATION object:nil];
    
    // reset settings
    [[MPSettingCenter sharedMPSettingCenter] resetAllSettingsWithFullReset:YES];
    
    // skip EULA & initial reset
    // 
    // - don't skip, always show EULA again
    //
    //[[MPSettingCenter sharedMPSettingCenter] agreedToEULA];
    
    // reset to Phone Registration View
    //
    [self resetViews];
    
    // allow CD saves again
    self.isStartingFromScratch = NO;
    
    // allow message processing again
    [[MPChatManager sharedMPChatManager] startupMessageProcessing];
    
    [AppUtility stopActivityIndicator];
    DDLogInfo(@"AD-sfs2: end");

}


-(void) testCode {
    /*
     NSDateFormatter *df = [[NSDateFormatter alloc] init];
     [df setDateStyle:NSDateFormatterShortStyle];
     [df setTimeStyle:NSDateFormatterShortStyle];
     
     
     NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
     NSLocale *gbLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh"];
     
     NSString *dateFormat;
     NSString *dateComponents = @"yMdEEEE";
     
     dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:usLocale];
     [df setDateFormat:dateFormat];
     NSString *sString = [df stringFromDate:[NSDate dateWithTimeIntervalSinceNow:-920000.0]];
     DDLogVerbose(@"sString: %@", sString);
     
     //DDLogVerbose(@"Date format for %@: %@",
     //     [usLocale displayNameForKey:NSLocaleIdentifier value:[usLocale localeIdentifier]], dateFormat);
     
     dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:gbLocale];
     [df setDateFormat:dateFormat];
     sString = [df stringFromDate:[NSDate dateWithTimeIntervalSinceNow:-920000.0]];
     DDLogVerbose(@"sString: %@", sString);
     //DDLogVerbose(@"Date format for %@: %@",
     //      [gbLocale displayNameForKey:NSLocaleIdentifier value:[gbLocale localeIdentifier]], dateFormat);
     */
    
    /*
     NSDateFormatter *df = [[NSDateFormatter alloc] init];
     [df setGeneratesCalendarDates:YES];
     [df setDateStyle:NSDateFormatterShortStyle];
     [df setTimeStyle:NSDateFormatterShortStyle];
     
     NSString *sString = [df stringFromDate:[NSDate date]];
     DDLogVerbose(@"sString: %@", sString);
     
     [df setDateStyle:NSDateFormatterMediumStyle];
     [df setTimeStyle:NSDateFormatterMediumStyle];
     
     NSString *mString = [df stringFromDate:[NSDate date]];
     DDLogVerbose(@"mString: %@", mString);
     
     [df setDateStyle:NSDateFormatterLongStyle];
     [df setTimeStyle:NSDateFormatterLongStyle];
     
     NSString *lString = [df stringFromDate:[NSDate date]];
     DDLogVerbose(@"lString: %@", lString);
     */
    
}



#pragma mark - Application Events

/*!
 @abstract Handles push notification
 */
- (void) handlePushWithUserInfo:(NSDictionary *)userInfo {

    
    
    if (![[MPHTTPCenter sharedMPHTTPCenter] isRegistrationComplete]) {
        DDLogWarn(@"AD-hp: push ignored - not registerd yet!");
        return;
    }
    
    if (userInfo == nil) {
        DDLogWarn(@"AD-hp: push ignored - userInfo == nil");
        return;
    }
    
    
    
    // find the right chat and show it
    //
    NSArray *contacts = nil;
    CDChat *pushChat = nil;
    
    NSString *userID = [userInfo valueForKey:@"userID"];
    NSString *groupID = [userInfo valueForKey:@"groupID"];
    
    // check for group first
    // 
    if ([groupID length] > 0) {
        // group: don't create chat if it does not exists
        pushChat = [CDChat chatWithCDContacts:nil groupID:groupID checkForNewGroupInvites:NO shouldCreate:NO shouldSave:NO shouldTouch:NO];
    }
    // then check if from user ID for p2p
    //
    else if ([AppUtility isUserIDValid:userID]) {
        CDContact *p2pContact = [CDContact getContactWithUserID:userID];
        if (p2pContact) {
            contacts = [NSArray arrayWithObject:p2pContact];
        }
        
        // p2p: don't create - only open existing chats
        pushChat = [CDChat chatWithCDContacts:contacts groupID:nil checkForNewGroupInvites:NO shouldCreate:NO shouldSave:YES shouldTouch:NO];
    }
    
    // remove any modal controllers
    //
    [self.containerController dismissModalViewControllerAnimated:NO];
    [self.contactNavigationController dismissModalViewControllerAnimated:NO];
    [self.phoneNavigationController dismissModalViewControllerAnimated:NO];
    [self.chatNavigationController dismissModalViewControllerAnimated:NO];
    [self.scheduledNavigationController dismissModalViewControllerAnimated:NO];
    [self.settingNavigationController dismissModalViewControllerAnimated:NO];
    
    // Push the chat if it is an existing one
    //
    
    // make sure tab is usable first
    [self.tabBarFacade warmUpTabBarItem:kMPTabIndexChat];
    
    NSString *myID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    // don't show hidden chats!
    if ([pushChat.isHiddenChat boolValue] == YES) {
        DDLogInfo(@"AD-hp: push ignored - hidden chat msg!");
        pushChat = nil;
    }
    // don't show schedule message dialogs - userID will be yourself
    else if ([myID isEqualToString:userID]) {
        DDLogInfo(@"AD-hp: push ignored - schedule message(my userID)!");
        pushChat = nil;
    }
    
    
    // if chat exists
    // - then push it on nav controller
    //
    if (pushChat) {
        
        // if the chat we want already showing?
        //
        BOOL chatAlreadyShowing = NO;
        UIViewController *topController = [self.chatNavigationController visibleViewController];
        if ([topController isKindOfClass:[ChatDialogController class]]) {
            if ( [[(ChatDialogController *)topController cdChat] isEqualToChat:pushChat] ) {
                chatAlreadyShowing = YES;
                DDLogVerbose(@"AD-hp: push - chat already on top");
            }
        }
        
        if (!chatAlreadyShowing) {
            DDLogVerbose(@"AD-hp: push - starting new chat dialog");
            [self.chatNavigationController popToRootViewControllerAnimated:NO];
            
            ChatDialogController *newController = [[ChatDialogController alloc] initWithCDChat:pushChat];
            [self.chatNavigationController pushViewController:newController animated:NO];
            
            // set delegate to root chat list
            newController.delegate = [[self.chatNavigationController viewControllers] objectAtIndex:0];
            [newController release];
        }
    }
    // if no chat defined, just show chat list
    //
    else {
        DDLogWarn(@"AD-hp: push - chat does not exist");
        [self.chatNavigationController popToRootViewControllerAnimated:NO];
        
        // make sure nav bar is showing, since it could have been hidden in chat dialog landscape mode
        // - also make sure it is in portrait
        if ([[UIApplication sharedApplication] statusBarOrientation] != UIInterfaceOrientationPortrait) {
            // trick to make sure orientation is portrait
            UIViewController *c = [[UIViewController alloc]init];
            [self.chatNavigationController.topViewController presentModalViewController:c animated:NO];
            [self.chatNavigationController.topViewController dismissModalViewControllerAnimated:NO];
            [c release];
        }
        
        // if previous view was chat dialog in landscape mode, poping back to root view does not properly show the facade
        // - make sure we show it here
        self.tabBarFacade.containerView.alpha = 1.0;
    }
    
    [self.chatNavigationController setNavigationBarHidden:NO animated:NO];
    [self.tabBarFacade pressedIndex:kMPTabIndexChat];   
    
    
}


/*!
 @abstract Check if there are any routines that should be run for new version that was just installed
 
 */
- (void) updateVersion {
		
	NSString *thisVersion = [AppUtility getAppVersion];
	
	NSString *lastVersion = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingLastInstalledAppVersion];
	
    // if there was previously installed
    // - then check version update
    //
    if ([lastVersion length] > 0) {
        
        /*
         Older than 1.0.2
         - Enable telephony warnings
         */
        if ([@"1.0.2" compare:lastVersion options:NSNumericSearch] == NSOrderedDescending){
            DDLogInfo(@"AD-updateVersion: verison %@ < 1.0.2 -- enable invite sms warnings", thisVersion);
            
            // telelphony warnings
            [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingEnablePayInviteWarning settingValue:[NSNumber numberWithBool:YES]];
        }
        
    }
    
    // update last installed version
    if (![lastVersion isEqualToString:thisVersion]) {
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingLastInstalledAppVersion 
                                                  settingValue:thisVersion];
    }
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    
    // Initialize logging
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 15; // 15 min rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 3;  // 3x
    [DDLog addLogger:fileLogger];
    
    
    //[self testCode];
    //NSSet *notifyMessages = [[NSSet setWithObject:@"a"] setByAddingObjectsFromSet:[NSSet setWithObject:@"b"]];

    DDLogVerbose(@"AD-adfl: App fin launching - start");
    
    // no bg task yet
    self.resetAppTaskID = UIBackgroundTaskInvalid;
    
    // no last session since starting from fresh launch
    self.didLastSessionGetLowMemoryWarning = NO;
    
	// run version updates
	[self updateVersion];
	
    DDLogInfo(@"AD-adfl: resetting app icon badge count");
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    
	//window.frame = [[UIScreen mainScreen] applicationFrame];
	
	// create container controller that holds everything
	// 
	/*TTContainerViewController *newController = [[TTContainerViewController alloc] init];
	newController.view.frame = [[UIScreen mainScreen] applicationFrame];
	newController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.containerController = newController;
    [newController release];*/
	//self.containerController.view.backgroundColor = [AppUtility darkCharcoalColor];
	
	// setups tabbarcontroller
	[self setupTabBarController];
	self.containerController = self.tabBarController;
    
    // add indicator and message label
	//
	//[self setupMessageViews];
    
	// only show container view after registered tabbar controller above
	// - so it can pass xAppear methods to sub controllers
	//
    self.window.rootViewController = self.containerController;	
	[self.window makeKeyAndVisible];
    
    
    // show the correct chat if notification was sent
    
    /*UILocalNotification *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
     
     if (localNotif) {
     NSString *itemName = [localNotif.userInfo objectForKey:ToDoItemKey];
     [viewController displayItem:itemName];  // custom method
     application.applicationIconBadgeNumber = localNotif.applicationIconBadgeNumber-1;
     }
     [window addSubview:viewController.view];
     [window makeKeyAndVisible];
     return YES;
     
     
     The implementation for a remote notification would be similar, except that you would use a specially declared constant in each platform as a key to access the notification payload:
     
     In iOS, the delegate, in its implementation of the application:didFinishLaunchingWithOptions: method, uses the UIApplicationLaunchOptionsRemoteNotificationKey key to access the payload from the launch-options dictionary.
     */
    
    // get push notif info
    //
    NSDictionary *userInfo = [launchOptions objectForKey: UIApplicationLaunchOptionsRemoteNotificationKey];
    DDLogInfo(@"AD-adfl: launch - push userInfo: %@", userInfo);
    
    // show chat dialog or list
    [self handlePushWithUserInfo:userInfo];
    
    
    // check if user is registered, if not show registration wizard
    //
    [self checkRegistration];
    
    // update SM badge count
    // - chat badge show since it is default view
    // - N update badge shows after login
    // - friend badge shows if new friends are detected, should be none to begin with
    //
    [[MPChatManager sharedMPChatManager] updateScheduleBadgeCount];

    
    // setup audio
    NSError *audioError = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    // session.delegate = self;
    // request ambient
    [session setCategory:AVAudioSessionCategoryAmbient error:&audioError];
    // set active
    [session setActive:YES error:&audioError];
    
    
    // Make sure to register notification after each launch
    // reset the date in case launch attempt fails, the become active can keep trying until it suceeds
    //
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingPushNotificationRegisterLastCompleteDate settingValue:[NSDate dateWithTimeIntervalSince1970:0.0]];

    
    // @TEST
    //[self tryRegisterPushNotificationForceStart:YES enableAlertPopup:popOn];
    
    
    // testing
    //
    //NSString *cc = [Utility currentLocalCountryCode];
    //DDLogVerbose(@"%@", cc);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    DDLogInfo(@"AD: APP will resign active");
        
    // if hidden chat is in the nav stack then pop it off so we can secure it
    //
    BOOL isShowingHiddenChat = NO;
    for (UIViewController *iController in self.chatNavigationController.viewControllers) {
        if ([iController respondsToSelector:@selector(isShowingHiddenChat)]) {
            isShowingHiddenChat = (BOOL)[iController performSelector:@selector(isShowingHiddenChat)];
            if (isShowingHiddenChat) {
                [self.chatNavigationController dismissModalViewControllerAnimated:NO];
                [self.chatNavigationController popToRootViewControllerAnimated:NO];
            }
        }
    }
    
    // lock hidden chat
    ChatController *chatList = [self.chatNavigationController.viewControllers objectAtIndex:0];
    [chatList lockHiddenChat];
    
    // Update New Friend Settings
    // - if friend is currently showing, then consider new friends as viewed
    //
    UIViewController *currentVC = [self.tabBarFacade currentVisibleViewController];
    BOOL showingFriendVC = ([currentVC isKindOfClass:[ContactController class]]);
    
    // clear out new friends if friend list was viewed
    NSNumber *didViewFriend = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingDidViewFriendInThisSession];
    
    if (showingFriendVC || [didViewFriend boolValue]) {
        // clear out friend badge
        //
        [MPContactManager clearFriendBadgeCount];
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingAppResignActiveAfterViewingFriendDate settingValue:[NSDate date]];
        // reset view indicator
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingDidViewFriendInThisSession settingValue:[NSNumber numberWithBool:NO]];
    }
    
    
    // Update new friend suggestion settings
    //
    BOOL showingFriendSuggestionVC = ([currentVC isKindOfClass:[FriendSuggestionController class]]);
    
    // clear out new friend suggestions if friend list was viewed
    NSNumber *didViewFriendSuggestion = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingDidViewFriendSuggestionInThisSession];
    
    if (showingFriendSuggestionVC || [didViewFriendSuggestion boolValue]) {
        // clear out friend badge
        //
        [MPContactManager clearFriendBadgeCount];
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingAppEnterBackgroundAfterViewingFriendSuggestionDate settingValue:[NSDate date]];
        // reset view indicator
        [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingDidViewFriendSuggestionInThisSession settingValue:[NSNumber numberWithBool:NO]];
    }
    
    dispatch_sync([AppUtility getBackgroundMOCQueue], ^{
        
        // don't use self.  It is ok that this object is still nil, don't want to spend cpu instatiating
        //
        [backgroundContactManager flushState];
        
    });
    
    // clear downloads and try again next time
    //
    [[MPResourceCenter sharedMPResourceCenter] clearDownloadQueue];
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    
    DDLogInfo(@"AD: APP did enter background");
    
}



// Run after coming back from background only
//
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    DDLogInfo(@"AD: APP will enter foreground");   
    
    DDLogInfo(@"AD-awef: resetting app icon badge count");
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    /*
     iOS 5.x Bug
     
     If a modal view is displayed then:
      - get mem warning - before and during background
      - app goes into background
      - dismiss modal
     
     Then the underlying VC is black.  So we need to change the tab index to reload the view properly!
     Always run since we can't detect low mem while suspended
     
     */
    if (YES) { //self.didLastSessionGetLowMemoryWarning) {
        NSString *sysVersion = [[ UIDevice currentDevice ] systemVersion];
        if ([sysVersion hasPrefix:@"5."]) {
            NSUInteger currentIndex = [[AppUtility getAppDelegate].tabBarFacade currentIndex];
            
            [[AppUtility getAppDelegate].tabBarFacade pressedIndex:kMPTabIndexSetting];
            [[AppUtility getAppDelegate].tabBarFacade pressedIndex:currentIndex];
        }
    }
    self.didLastSessionGetLowMemoryWarning = NO;
    
    DDLogInfo(@"AD: APP foreground - end");

}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    // app was already in the foreground
    // - so ignore this push!
    if ( application.applicationState == UIApplicationStateActive ) {
        DDLogInfo(@"AD: push in foreground userInfo: %@", userInfo);
        return;
    }
    
    // app was just brought from background to foreground
    DDLogInfo(@"AD: push from background userInfo: %@", userInfo);
    
    // show chat dialog or list
    [self handlePushWithUserInfo:userInfo];
    
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    
    self.didLastSessionGetLowMemoryWarning = YES;
    
}

/*!
 @abstract run friend query 
 */
- (void) startFriendInfoQuery {
    // get newest info this may also delete contacts
    [MPContactManager startFriendInfoQueryInBackGroundForceStart:NO];
}

/*!
 @abstract try starting phone book sync 
 */
- (void) startPhoneBookSync {
    [MPContactManager tryStartingPhoneBookSyncForceStart:NO delayed:YES];
}

// Run after initial launch and entering foreground
//
- (void)applicationDidBecomeActive:(UIApplication *)application
{ 
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    DDLogInfo(@"AD: APP did become active - start");
    
 
    // lock hidden chat
    //
    [[MPSettingCenter sharedMPSettingCenter] lockHiddenChat:YES];
    
    
    // reset session tags
    //
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingSessionActionsCompletedTags settingValue:@""];
    
    
    // update chat count whenever we show this app
    //
    [[MPChatManager sharedMPChatManager] updateChatBadgeCount];
    
    
    // update new friends badge count
    //
    [MPContactManager updateFriendBadgeCount];
    
    
    // refresh friend list if it is available
    // - make sure new friend indication are updated
    [[NSNotificationCenter defaultCenter] postNotificationName:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:nil];
    
    
    // always check if we need to start phonebook sync
    // - delay so that AB change notification can be detected first
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogInfo(@"AD-adba: delegate try phone sync");
        [self startPhoneBookSync];
        //[self performSelector:@selector(startPhoneBookSync) withObject:nil afterDelay:1.5];
    });
    
    

    
    // are there pending downloads?
    //
    BOOL shouldDownload = [[MPResourceCenter sharedMPResourceCenter] shouldStartDownload];
    
    // show download view and download progress
    //
    if (shouldDownload) {
        [[MPResourceCenter sharedMPResourceCenter] startDownloadWithDelegate:nil];
        
        /*ResourceUpdateController *newController = [[ResourceUpdateController alloc] init];
         [[MPResourceCenter sharedMPResourceCenter] startDownloadWithDelegate:newController];
         
         [self.containerController presentModalViewController:newController animated:NO];
         [newController release];*/
    }
    
    // @TEST: Force DOWNLOAD RESOURCE - also change last update time in HTTPC
    //[self tryCheckResourceInfoForceStart:YES];
    
    
    // always update all contact info at least once each session
    // - several views will depend on this info
    //
    [self performSelector:@selector(startFriendInfoQuery) withObject:nil afterDelay:5.0];

    // @DISABLE - wait until after login
    // try to register push notification
    //
    //BOOL popOn = [[[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPushPopUpIsOn] boolValue];
    //[self tryRegisterPushNotificationForceStart:NO enableAlertPopup:popOn];
    
    
    DDLogInfo(@"AD: APP did become active - end");

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)dealloc
{
    
    dispatch_release(background_moc_queue);
    [_window release];
    
    [backgroundContactManager release];
    
    [fileLogger release];
    
    [super dealloc];
    
}

#pragma mark - Notification Delegates

/*!
 Send our notification service device tokens
 */
- (void)sendProviderDeviceToken:(NSData *)devToken {
    
    //const void *devTokenBytes = [devToken bytes];
    // register to NS server here
    
    // @TEST for testing ... 
    /*NSString *userID = [[MPSettingCenter sharedMPSettingCenter] getUserID];
    [Utility showAlertViewWithTitle:@"Got APNS Token" message:[NSString stringWithFormat:@"user:%@ token:%@", userID,[Utility stringWithHexFromData:devToken]]];
    */
    
    
    NSString *p2pTone = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPushP2PRingTone];
    NSString *groupTone = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingPushGroupRingTone];
    
    // submit to NS server
    //
    [[MPHTTPCenter sharedMPHTTPCenter] setPushTokenID:devToken p2pTone:p2pTone groupTone:groupTone];
}

/*!
 Receive and upload device token
 */
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    DDLogInfo(@"AD-DRN: APNS - Registration successful");
    
    //self.registered = YES;
    [self sendProviderDeviceToken:devToken]; // custom method
    
    //NSString *debug = [NSString stringWithFormat:@"Got Token: %@", devToken];
    
    // yes did succeed
    [[NSNotificationCenter defaultCenter] postNotificationName:MP_APPDELEGATE_REGISTER_PUSH_NOTIFICATION object:[NSNumber numberWithBool:YES] userInfo:nil];
}

/*!
 If error is received from APN when registering
 */
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    DDLogError(@"AD-DFR: APNS - Error in notification registration. Error: %@", [err localizedDescription]);
    
    // no failed
    [[NSNotificationCenter defaultCenter] postNotificationName:MP_APPDELEGATE_REGISTER_PUSH_NOTIFICATION object:[NSNumber numberWithBool:NO] userInfo:nil];
}


#pragma mark - Navigation Controller Delegate

/*
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    DDLogVerbose(@"Nav didShow");
}*/

/**
 Performs actions when a particular view shows up on the navigation stack
 */
- (void)navigationController:(UINavigationController *)navigationController 
      willShowViewController:(UIViewController *)viewController 
					animated:(BOOL)animated {
	
    
    // replace back view with custom view
    // - disable for now
    /*if(NO && [navigationController.viewControllers count ] > 1) {
        
        NSString *previousTitle = nil;
        NSInteger viewIndex = [navigationController.viewControllers indexOfObject:viewController];
        if (viewIndex != NSNotFound) {
            UIViewController *previousVC = [navigationController.viewControllers objectAtIndex:(viewIndex-1)];
            previousTitle = previousVC.title;
            // try looking at nav item title too
            if (!previousTitle) {
                previousTitle = viewController.navigationItem.title;
            }
        }
        if (previousTitle && viewController.navigationItem.hidesBackButton == NO) {
            
            UIImage *norImage = [[UIImage imageNamed:@"std_btn_arrow2_nor.png"] stretchableImageWithLeftCapWidth:15.0 topCapHeight:16.0];
            
            UIImage *prsImage = [[UIImage imageNamed:@"std_btn_arrow2_prs.png"] stretchableImageWithLeftCapWidth:15.0 topCapHeight:16.0];
            
            
            UIButton *myBackButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
            [myBackButton setBackgroundImage:norImage forState:UIControlStateNormal];
            [myBackButton setBackgroundImage:prsImage forState:UIControlStateHighlighted];
            [myBackButton setEnabled:YES];
            
            
            myBackButton.backgroundColor = [UIColor clearColor];
            //[myBackButton setTitleColor:[AppUtility colorForContext:kAUColorTypeGreen1] forState:UIControlStateNormal];
            [myBackButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            myBackButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.43];
            myBackButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
            myBackButton.titleLabel.font = [AppUtility fontPreferenceWithContext:kAUFontSystemMicro];
            
            [myBackButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [myBackButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [myBackButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 11.0, 0.0, 0.0)];
            
            CGFloat labelWidth = [previousTitle sizeWithFont:myBackButton.titleLabel.font].width;
            if (labelWidth > 90.0) {
                labelWidth = 90.0;
            }
            [myBackButton setFrame:CGRectMake(0,0,labelWidth+18.0,32.0)];
            
            [myBackButton setTitle:previousTitle forState:UIControlStateNormal];
            
            [myBackButton addTarget:viewController.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
            UIBarButtonItem* backButton = [[UIBarButtonItem alloc] initWithCustomView:myBackButton];
            viewController.navigationItem.leftBarButtonItem = backButton;
            //viewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:norImage style:UIBarButtonItemStylePlain target:viewController.navigationController action:@selector(popViewControllerAnimated:)];
            [myBackButton release];
            [backButton release];
            
        }
    }*/
    
    
    
	/*
	 Checks if this naughty view shows up
	 - if so we need to hide our fake tabbar so it does not cover the bottom of this view
	 - old method: checked the title == "Add Field" but you will have to translate for each language :(
	 - new method: checks class name -- but this is a little risky since class is not official API
	 */
    
	// for debug
	//DDLogVerbose(@"Found Controller: %@", controllerClassString);
    
	
	// start animation
	if (animated) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2];
	}
	
    //NSString *classString = [[viewController class] description];
    //DDLogVerbose(@"Nav class: %@", classString);
	
    
    // Hides Tab bar for all Chat dialog related views
	//
	if ([viewController isMemberOfClass:[ChatDialogController class]] ||
        [viewController isMemberOfClass:[ChatSettingController class]] ||
        [viewController isMemberOfClass:[ChatNameController class]] ){
		
		DDLogVerbose(@"NCD: hide tab facade");
		self.tabBarFacade.containerView.alpha = 0.0;

	}
    else if ([self.tabBarController.viewControllers indexOfObject:navigationController] == NSNotFound) {
        // nav contorller presented modally
        // - Thus tab bar is NOT visible, so do nothing
    }
    // ignore Modal Views since they are not affected by the Tabbar and should not interfer with it's presentation
    // - photo selection views & Hidden chat views, etc.
    /* Above is a more elgant solution
     NSRange rangeImagePicker = [classString rangeOfString:@"PLUICameraV" options:(NSAnchoredSearch)];    

     else if ([viewController isMemberOfClass:[ELCAlbumPickerController class]] ||
             [viewController isMemberOfClass:[ELCAssetTablePicker class]] || 
             [viewController isMemberOfClass:[SelectContactController class]] ||
             [viewController isMemberOfClass:[HiddenController class]] || 
             rangeImagePicker.location == 0 ){
            // do nothing
    }*/
	// otherwise show the tabBar!
	else {
		self.tabBarFacade.containerView.alpha = 1.0;
    }
    
    DDLogVerbose(@"AD: showing viewcontroller of class:%@",[viewController class]);
    
	if (animated) {
		// end animation
		[UIView commitAnimations];
	}
	
	// After any navigation controller is loaded, preload all person records from AB
	//  - this takes about 0.7 secs for 2k persons
	//
	/*if (navigationController == self.groupsNavigationController){
     AddressBookTool *abTool = [AppUtility getABTool];
     // access person records and load cache if not done already
     [abTool preLoadDataInOperation];
     }*/
	
}

@end


#pragma mark - Categories

// helps with autorotation
//
@implementation UITabBarController (MyApp)
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return [self.selectedViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
    //return YES;
}
@end



