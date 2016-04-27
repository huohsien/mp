//
//  CDMPMessage.m
//  mp
//
//  Created by Min Tsai on 5/4/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "CDMPMessage.h"
#import "MPFoundation.h"


@implementation CDMPMessage

@dynamic mID;
@dynamic mType;
@dynamic toAddress;
@dynamic fromPreviousSession;


#pragma mark - Queries


/*!
 @abstract gets MPMessages that meets predicate requirements
 
 @param fetchLimit limits the number of fetches returned -1 means no limit
 
 @return success - array of resources, fail - nil no resource found
 
 */
+ (NSArray *) mpMessageForPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fetchLimit:(NSInteger)fetchLimit {
    
	NSManagedObjectContext *managedObjectContext = [AppUtility cdGetManagedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDMPMessage" 
											  inManagedObjectContext:managedObjectContext];
	
	// load resource if it already exists
    //
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    [fetchRequest setEntity:entity];
    
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
    if (sortDescriptors) {
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    if (fetchLimit > 0) {
        [fetchRequest setFetchLimit:fetchLimit];
    }
    
    // Then execute fetch it
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    return results;
}


/*!
 @abstract get all mpmessages
 
 @return success - array of mpmessages that still need to be sent out
 
 */
+ (NSArray *) allMPMessages {
    
    return [CDMPMessage mpMessageForPredicate:nil sortDescriptors:nil fetchLimit:-1];
    
}


/*!
 @abstract Mark all message as previous session
  
 */
+ (void) markAllMPMessagesAsPreviousSession {
    
    NSArray *allMsges = [CDMPMessage allMPMessages];
    
    DDLogInfo(@"CDMPM - mark as previous: %d", [allMsges count]);

    NSNumber *yesNumber = [NSNumber numberWithBool:YES];
    
    for (CDMPMessage *iMsg in allMsges) {
        iMsg.fromPreviousSession = yesNumber;
    }
    
    [AppUtility cdSaveWithIDString:@"set all CDMPMessage as previous" quitOnFail:NO];
}


/*!
 @abstract get messages from previous session
 
 @return success - array of mpmessages
 
 */
+ (NSArray *) mpMessagesFromPreviousSession {
    
    // include type match since resourceID may not be unique across types
    // - also make sure url is available
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"fromPreviousSession == %@", [NSNumber numberWithBool:YES]];
    
    return [CDMPMessage mpMessageForPredicate:pred sortDescriptors:nil fetchLimit:-1];
}



/*!
 @abstract get messages with mID and mType
 
 @return success - array of mpmessages
 
 */
+ (NSArray *) mpMessagesWithMID:(NSString *)mID mType:(NSString *)mType {
    
    // include type match since resourceID may not be unique across types
    // - also make sure url is available
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(mID == %@) AND (mType == %@)", mID, mType];
    
    return [CDMPMessage mpMessageForPredicate:pred sortDescriptors:nil fetchLimit:-1];
    
}


/*!
 @abstract find matching MPMessages and delete them
 
 */
+ (void) findAndDeleteMPMessagesWithMID:(NSString *)mID mType:(NSString *)mType {
    
    NSManagedObjectContext *moc = [AppUtility cdGetManagedObjectContext];
    
    NSArray *messages = [CDMPMessage mpMessagesWithMID:mID mType:mType];
    for (CDMPMessage *iMsg in messages) {
        [moc deleteObject:iMsg];
    }
    
    // non critical so it is ok not to save right away - save CPU
    // [AppUtility cdSaveWithIDString:@"Deleting MPMessage record" quitOnFail:NO];
    
}



/*!
 @abstract insert a new MPMessage
 
 */
+ (CDMPMessage *) createMPMessageWithMID:(NSString *)mID mType:(NSString *)mType toAddress:(NSString *)toAddress shouldSave:(BOOL)shouldSave {
    
    NSManagedObjectContext *moc = [AppUtility cdGetManagedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDMPMessage" 
											  inManagedObjectContext:moc];
	
    // create new Message
    //
    CDMPMessage *newMessage = [NSEntityDescription insertNewObjectForEntityForName:[entity name] 
                                                          inManagedObjectContext:moc]; 
    newMessage.mID = mID;
    newMessage.mType = mType;
    newMessage.toAddress = toAddress;
    
    if (shouldSave) {
        [AppUtility cdSaveWithIDString:@"save new MPMessage" quitOnFail:NO];
    }
    
    return newMessage;
}


@end
