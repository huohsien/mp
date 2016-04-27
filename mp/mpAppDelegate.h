//
//  mpAppDelegate.h
//  mp
//
//  Created by M Tsai on 11-8-26.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>
#import <CoreData/CoreData.h>
#import "TabBarFacade.h"


/*! notify of push registration results */
extern NSString* const MP_APPDELEGATE_REGISTER_PUSH_NOTIFICATION;


@interface UITabBarController (MyApp)
@end

@interface UINavigationController (MyApp)
@end


@class mpViewController;
@class TabBarFacade;
@class TTContainerViewController;
@class MPContactManager;
@class MPSocketCenter;
@class DDFileLogger;
@class EmoticonKeypad;


@interface mpAppDelegate : NSObject <UIApplicationDelegate, UINavigationControllerDelegate, TabBarFacadeDelegate> {

    UINavigationController *contactNavigationController;
    UINavigationController *phoneNavigationController;
    UINavigationController *chatNavigationController;
    UINavigationController *scheduledNavigationController;
    UINavigationController *settingNavigationController;

    
    UITabBarController *tabBarController;
	TabBarFacade *tabBarFacade;
    //TTContainerViewController *containerController;
    UIViewController *containerController;
    
    dispatch_queue_t background_moc_queue;
    MPContactManager *backgroundContactManager;
    
    dispatch_queue_t network_queue;
    MPSocketCenter *socketCenter;
    
    EmoticonKeypad *emoticonKeypad;
        
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectContext *backManagedOjectContext;
    
    BOOL isStartingFromScratch;
    BOOL didLastSessionGetLowMemoryWarning;
    
    DDFileLogger *fileLogger;
    NSCache *appNSCache;
    
    UIBackgroundTaskIdentifier resetAppTaskID;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;


// UI related attributes
//
@property (nonatomic, retain, readonly) UINavigationController *contactNavigationController;
@property (nonatomic, retain, readonly) UINavigationController *chatNavigationController;
@property (nonatomic, retain, readonly) UINavigationController *settingNavigationController;
@property (nonatomic, retain, readonly) UINavigationController *phoneNavigationController;
@property (nonatomic, retain, readonly) UINavigationController *scheduledNavigationController;


@property (nonatomic, retain) UITabBarController *tabBarController;
@property (nonatomic, retain) TabBarFacade *tabBarFacade;
@property (nonatomic, retain) UIViewController *containerController;

// Queue: process background processing and DB access
//
@property (readonly, assign) dispatch_queue_t background_moc_queue;
@property (readonly, assign) MPContactManager *backgroundContactManager;

// Queue: network processing and message passing
//
@property (readonly, assign) dispatch_queue_t network_queue;

/*! @abstract to establish tcp connectivity */
@property (readonly) MPSocketCenter *socketCenter;

/*! @abstract shared emoticon instance for chat dialogs */
@property (nonatomic, retain) EmoticonKeypad *emoticonKeypad;



// Core Data
//
@property (retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (retain, readonly) NSManagedObjectContext *backManagedObjectContext;

/*! hard reset is in progress, don't save to CD */
@property (assign) BOOL isStartingFromScratch; 

/*! 
 Detect if low mem occured last session 
 - if app is terminated than there is no previous session
 - used to see if we need to address iOS 5.x black screen bug
 */
@property (nonatomic, assign) BOOL didLastSessionGetLowMemoryWarning;

/*! logs to file */
@property (nonatomic, retain) DDFileLogger *fileLogger;


/*! cache used by application */
@property (nonatomic, retain) NSCache *appNSCache;


/*! @abstract reset application background task id - make sure we fin reset before suspending */
@property (assign) UIBackgroundTaskIdentifier resetAppTaskID;

- (void) startFromScratchWithFullSettingReset:(BOOL)fullSettingReset;
- (void) tryRegisterPushNotificationForceStart:(BOOL)forceStart enableAlertPopup:(BOOL)enableAlertPopup;
- (void) resetEmoticonKeypad;

- (id) sharedCacheObjectForKey:(NSString *)key;
- (void) sharedCacheSetObject:(id)object forKey:(NSString *)key;


@end
