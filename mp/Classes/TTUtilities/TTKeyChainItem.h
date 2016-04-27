//
//  TTKeyChainItem.h
//  ContactBook
//
//  Created by M Tsai on 11-4-11.
//  Copyright 2011 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>


/*
 From Apple's GenericKeyChain sample
 
 Usage:
 
 TTKeyChainItem *passItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"Password" accessGroup:nil];
 TTKeyChainItem *accountItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"Account Number" accessGroup:@"YOUR_APP_ID_HERE.com.yourcompany.GenericKeychainSuite"];
 
 // get and set keychain items
 [accountItem objectForKey:<someKey>
 [accountItem setObject:<someObj> forKey:<someKey>];
 
 
 The KeychainItemWrapper class is an abstraction layer for the iPhone Keychain communication. It is merely a 
 simple wrapper to provide a distinct barrier between all the idiosyncracies involved with the Keychain
 CF/NS container objects.
 */

@interface TTKeyChainItem : NSObject
{
    NSMutableDictionary *keychainItemData;      // The actual keychain item data backing store.
    NSMutableDictionary *genericPasswordQuery;  // A placeholder for the generic keychain item query used to locate the item.
}

@property (nonatomic, retain) NSMutableDictionary *keychainItemData;
@property (nonatomic, retain) NSMutableDictionary *genericPasswordQuery;

// Designated initializer.
- (id)initWithIdentifier: (NSString *)identifier accessGroup:(NSString *) accessGroup;
- (void)setObject:(id)inObject forKey:(id)key;
- (id)objectForKey:(id)key;


// Initializes and resets the default generic keychain item data.
- (void)resetKeychainItem;

@end