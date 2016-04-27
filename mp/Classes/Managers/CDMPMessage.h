//
//  CDMPMessage.h
//  mp
//
//  Created by Min Tsai on 5/4/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDMPMessage : NSManagedObject

@property (nonatomic, retain) NSString * mID;
@property (nonatomic, retain) NSString * mType;
@property (nonatomic, retain) NSString * toAddress;

/* Should only send out messages from a previous session - default NO */
@property (nonatomic, retain) NSNumber * fromPreviousSession;



+ (NSArray *) mpMessageForPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fetchLimit:(NSInteger)fetchLimit;

+ (NSArray *) allMPMessages;
+ (void) markAllMPMessagesAsPreviousSession;
+ (NSArray *) mpMessagesFromPreviousSession;
+ (NSArray *) mpMessagesWithMID:(NSString *)mID mType:(NSString *)mType;

+ (void) findAndDeleteMPMessagesWithMID:(NSString *)mID mType:(NSString *)mType;
+ (CDMPMessage *) createMPMessageWithMID:(NSString *)mID mType:(NSString *)mType toAddress:(NSString *)toAddress shouldSave:(BOOL)shouldSave;

@end
