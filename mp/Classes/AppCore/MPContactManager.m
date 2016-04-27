//
//  MPContactManager.m
//  mp
//
//  Created by M Tsai on 11-9-7.
//  Copyright 2011年 TernTek. All rights reserved.
//

#import "MPContactManager.h"
#import "MPFoundation.h"
#import "CDContact.h"
#import "TTCollationWrapper.h"
#import "ContactProperty.h"

NSString* const MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION = @"MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION";
NSString* const MP_CONTACTMANAGER_RELOAD_TABLE_NOTIFICATION = @"MP_CONTACTMANAGER_RELOAD_TABLE_NOTIFICATION";
NSString* const MP_CONTACTMANAGER_INDEX_NOTIFICATION = @"MP_CONTACTMANAGER_INDEX_NOTIFICATION";

NSString* const MP_CONTACTMANAGER_PHONESYNC_START_NOTIFICATION = @"MP_CONTACTMANAGER_PHONESYNC_START_NOTIFICATION";
NSString* const MP_CONTACTMANAGER_PHONESYNC_COMPLETE_NOTIFICATION = @"MP_CONTACTMANAGER_PHONESYNC_COMPLETE_NOTIFICATION";
NSString* const MP_CONTACTMANAGER_BLOCKED_RECOVERED_NOTIFICATION = @"MP_CONTACTMANAGER_BLOCKED_RECOVERED_NOTIFICATION";



NSString* const kABNameKey = @"kABNameKey";
NSString* const kABPhoneKey = @"kABPhoneKey";
NSString* const kABPhoneStringKey = @"kABPhoneStringKey";
NSString* const kABEmailKey = @"kABEmailKey";
NSString* const kABRecordIDKey = @"kABRecodIDKey";

NSString* const kIndexCacheContactManagerFileName = @"kIndexCacheContactManagerFileName";
NSString* const kContactManagerABDictionaryCacheFilename = @"abstore.cache";


// parameters
NSInteger const kCMParamMaxSyncCount = 200; // 5k contacts - 100:8sec, 200:5sec
CGFloat const kCMParamStartPhoneSyncDelay = 2.0;
CGFloat const kCMParamPhoneSyncAutoRefreshSecs = 86400.0; // should be longer - 1 day.
CGFloat const kCMParamAddressBookCallBackRefershSecs = -30.0; // supress recent call backs



@implementation MPContactManager

@synthesize addressBook;
@synthesize addressBookDictionary;
@synthesize sortedRecordIDKeys;
@synthesize lastSyncContacts;
@synthesize contacts;
@synthesize isSyncRunning;
@synthesize isSyncPending;

@synthesize collation;
@synthesize filteredContacts; 
@synthesize userIDToContactsD;

@synthesize currentGroupMemberIDs;
@synthesize currentGroupMemberSectionTitle;
@synthesize currentGroupMemberIndexTitle;
@synthesize numberOfPhonesInAddressBook;
@synthesize didAddressBookChange;
@synthesize shouldCheckForAddressBookChangeManually;
@synthesize lastABCallBackDate;

- (void) dealloc {
    
    
    if (addressBook != NULL) {
        ABAddressBookUnregisterExternalChangeCallback(addressBook, addressBookChanged, self);
        CFRelease(addressBook);
    }
    
    [addressBookDictionary release];
    [sortedRecordIDKeys release];
    [lastSyncContacts release];
    [contacts release];
    [collation release];
    [filteredContacts release];
    
    [userIDToContactsD release];
    
    [currentGroupMemberIDs release];
    [currentGroupMemberSectionTitle release];
    [currentGroupMemberIndexTitle release];
    
    [super dealloc];
}




- (id)init
{
    self = [super init];
    if (self) {

        // start with empty search result list
        NSMutableArray *filterArray = [[NSMutableArray alloc] init];
        self.filteredContacts = filterArray;
        [filterArray release];
        self.numberOfPhonesInAddressBook = 0;
        self.didAddressBookChange = NO;
        self.shouldCheckForAddressBookChangeManually = NO;
        
        self.lastABCallBackDate = nil;

    }
    return self;
}

/*!
 @abstract flush state of CM whenever app is suspended
 */
- (void) flushState {
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getBackgroundMOCQueue], @"Must be dispatched on backQueue");
    
    // reset
    //
    self.isSyncRunning = NO;
    self.isSyncPending = NO;
    
    // the AB may change in the next session, so flush
    // - keep cached, only flush if change detected
    //self.addressBookDictionary = nil;
    //self.sortedRecordIDKeys = nil;
    
    // also flush contact cache
    self.contacts = nil;
    
    // main thread attributes
    dispatch_async(dispatch_get_main_queue(), ^{
        self.userIDToContactsD = nil;
        self.collation = nil;
        self.didAddressBookChange = NO;
        self.lastABCallBackDate = nil;
    });

    self.numberOfPhonesInAddressBook = 0;
    self.shouldCheckForAddressBookChangeManually = NO;
    

}


#pragma mark - PhoneBook Methods

/*!
 @abstract Creates and caches a character set
 - expensive
 */
+ (NSCharacterSet *)stripPhoneCharacterSet
{
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSCharacterSet *extraSet = [dictionary objectForKey:@"ContactManagerStripPhoneCharacterSet"];
    
    if (!extraSet)
    {
        extraSet = [NSCharacterSet characterSetWithCharactersInString:@"()-. "];
        [dictionary setObject:extraSet forKey:@"ContactManagerStripPhoneCharacterSet"];
    }
    return extraSet;
}

/*!
 @abstract Merges "merge" person dictionaries into a "base" dictionary
 
 */
- (NSDictionary *) personDictionaryForRecordID:(NSNumber *)recordID {
    return [self.addressBookDictionary objectForKey:recordID];
}

/*!
 @abstract Merges "merge" person dictionaries into a "base" dictionary
 
 */
- (NSDictionary *) personDictionaryForRecordIDString:(NSString *)recordID {
    return [self.addressBookDictionary objectForKey:recordID];
}


/*!
 @abstract Merges "merge" person dictionaries into a "base" dictionary
 
 */
- (void) mergePersonDictionary:(NSDictionary *)mergeDictionary intoPersonDictionary:(NSMutableDictionary *)baseDictionary {
    
    // merge values
    NSArray *phones = [mergeDictionary valueForKey:kABPhoneKey];
    NSArray *pStrings = [mergeDictionary valueForKey:kABPhoneStringKey];
    NSArray *emails = [mergeDictionary valueForKey:kABEmailKey];

    // base values
    NSMutableArray *phonesBase = [baseDictionary valueForKey:kABPhoneKey];
    NSMutableArray *pStringsBase = [baseDictionary valueForKey:kABPhoneStringKey];
    NSMutableArray *emailsBase = [baseDictionary valueForKey:kABEmailKey];
    
    // merge phone numbers
    NSUInteger i = 0;
    for (NSString *iPhone in phones) {
        if ([phonesBase indexOfObject:iPhone] == NSNotFound) {
            [phonesBase addObject:iPhone];
            if ([pStrings count] > i) {
                [pStringsBase addObject:[pStrings objectAtIndex:i]];
            }
        }
        i++;
    }
    
    // merge emails
    for (NSString *iEmail in emails) {
        if ([emailsBase indexOfObject:iEmail] == NSNotFound) {
            [emailsBase addObject:iEmail];
        }
    }
}

/*!
 @abstract copy addressbook data into memory
 
 Populates the addressBookDictionary: 2 level dictionary
 
 - key: recordID value: personDictionary
 * key: kABNameKey       value: Name of person (string)
 * key: kABPhoneKey      value: Array of phone numbers (strings)
 * key: kABEmailKey      value: Array of email addresses
 * key: kABRecordIDKey   value: RecordID 
 
 */
- (NSMutableDictionary *) personDictionaryForPersonRef:(ABRecordRef)personRecordRef {
    
    NSCharacterSet *extraSet = [MPContactManager stripPhoneCharacterSet];
    
    NSNumber *recordID = [NSNumber numberWithInt:(int)ABRecordGetRecordID(personRecordRef) ];
    NSString *nameString = (NSString *)ABRecordCopyCompositeName(personRecordRef);
    
    // get phone numbers

    NSString *value;
    NSString *label;
    
    ABMultiValueRef multi = ABRecordCopyValue(personRecordRef, kABPersonPhoneProperty);
    CFIndex multiIndex = ABMultiValueGetCount(multi);
    NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
    NSMutableArray *phoneStrings = [[NSMutableArray alloc] init]; // formatted phone numbers
    
    for (CFIndex k = 0; k < multiIndex; k++) {
        
        label = (NSString *) ABMultiValueCopyLabelAtIndex(multi, k);
        value = (NSString *) ABMultiValueCopyValueAtIndex(multi, k);
        
        // only check potential SMS devices
        // also check home, work or pager?
        //
        /*if ([label isEqualToString:(NSString *)kABPersonPhoneMobileLabel] || [label isEqualToString:(NSString *)kABPersonPhoneIPhoneLabel] ||
         [label isEqualToString:(NSString *)kABPersonPhoneMainLabel]) {
         
         // strip out unecessary chars
         //
         NSString *strippedString = [[value componentsSeparatedByCharactersInSet:extraSet] componentsJoinedByString:@""];
         
         [phoneNumbers addObject:strippedString];
         }*/
        
        // Get all Numbers!
        // - strip out unecessary chars
        //
        NSString *strippedString = [[value componentsSeparatedByCharactersInSet:extraSet] componentsJoinedByString:@""];
        [phoneNumbers addObject:strippedString];
        [phoneStrings addObject:value];
        
        // release copy values
        [label release];
        [value release];
    }
    if (multi != NULL) {
        CFRelease(multi);
    }
    
    // add to total number of phones
    self.numberOfPhonesInAddressBook += [phoneNumbers count];
    
    // get emails
    multi = ABRecordCopyValue(personRecordRef, kABPersonEmailProperty);
    multiIndex = ABMultiValueGetCount(multi);
    NSMutableArray *emails = [[NSMutableArray alloc] init];
    for (CFIndex j = 0; j < multiIndex; j++) {
        
        //ABMultiValueGetIdentifierAtIndex(multi, j);
        //label = (NSString *) ABMultiValueCopyLabelAtIndex(multi, j);
        value = (NSString *) ABMultiValueCopyValueAtIndex(multi, j);
        
        [emails addObject:value];
        
        // release copy values
        //[label release];
        [value release];
    }
    if (multi != NULL) {
        CFRelease(multi);
    }        
    
    // populate dictionary: name and phone numbers
    NSMutableDictionary *personDictionary = [[[NSMutableDictionary alloc] initWithCapacity:4] autorelease];
    
    if (nameString) {
        [personDictionary setObject:nameString forKey:kABNameKey];
    }
    if ([phoneNumbers count]) {
        [personDictionary setObject:phoneNumbers forKey:kABPhoneKey];
    }
    if ([phoneStrings count]) {
        [personDictionary setObject:phoneStrings forKey:kABPhoneStringKey];
    }
    if ([emails count]) {
        [personDictionary setObject:emails forKey:kABEmailKey];
    }
    [personDictionary setObject:recordID forKey:kABRecordIDKey];
    
    
    [nameString release];
    [phoneNumbers release];
    [phoneStrings release];
    [emails release];
    
    return personDictionary;
}


/*!
 @abstract Check addressbook change and reset it
 
 Use:
 - check if we should start PB sync
 
 */
- (BOOL) didAddressBookChangeAndReset
{
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");
    
    BOOL didChange = self.didAddressBookChange;
    self.didAddressBookChange = NO;
    return didChange;
    
}

/*!
 @abstract Check addressbook change and reset it
 
 */
- (void) markAddressBookAsChangedFromABCallBack:(BOOL)fromABCallBack
{
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");
    
    // filter out duplicate call backs
    // - date gets reset to nil at the end of each session
    // - so allow the first call but susequent close calls will be suppressed
    //
    if (fromABCallBack) {
        if (self.lastABCallBackDate && [self.lastABCallBackDate timeIntervalSinceNow] > kCMParamAddressBookCallBackRefershSecs) {
            DDLogInfo(@"CM-mabac: resetting AB cancelled - duplicate");
            return;
        }
        self.lastABCallBackDate = [NSDate date];
    }
    
    self.didAddressBookChange = YES;
    
    // also make sure we start sync all over again
    [[MPSettingCenter sharedMPSettingCenter] setPhoneSyncLastRecordID:[NSNumber numberWithInt:-1]];
    
    dispatch_async([AppUtility getBackgroundMOCQueue], ^{
        
        DDLogInfo(@"CM-mabac: resetting AB and sorted records");
        
        // flush Addressboook cached information
        // - this needs to be reloaded from the addressbook
        //
        self.addressBookDictionary = nil;
        self.sortedRecordIDKeys = nil;
    });
    
    // start phone sync process
    [MPContactManager tryStartingPhoneBookSyncForceStart:YES delayed:YES];
}

/*!
 @abstract Callback method if we received a addressbook change notification 
 */
void addressBookChanged(ABAddressBookRef reference, 
                        CFDictionaryRef dictionary, 
                        void *context) 
{

    DDLogCInfo(@"CM: AB changed notification");
    
    [[AppUtility getBackgroundContactManager] markAddressBookAsChangedFromABCallBack:YES];
    
}

/*!
 @abstract copy addressbook data into memory
 
 Populates the addressBookDictionary: 2 level dictionary
 
  - key: recordID value: personDictionary
    * key: kABNameKey       value: Name of person (string)
    * key: kABPhoneKey      value: Array of phone numbers (strings)
    * key: kABEmailKey      value: Array of email addresses
    * key: kABRecordIDKey   value: RecordID 
 
 
 */
- (void) syncABData {
    
    BOOL addressBookIsAllowed = [[[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAddressBookIsAllowed] boolValue];
    
    if (!addressBookIsAllowed) {
        return;
    }
    
    NSAssert(dispatch_get_current_queue() == [AppUtility getBackgroundMOCQueue], @"Must be dispatched on backQueue");
    
    // strip out non-functional characters - '+' is left in, so that we can recognize it as a international number
    //
    //NSCharacterSet *extraSet = [NSCharacterSet characterSetWithCharactersInString:@"()-. "];
    
    // recover dictionary from file for non-multitask devices
    // - only if no changes detected, other wise rebuild dictionary
    //
    /* 
     Can't save to file - non-multitask must read in AB every time to check if there is a change!
     
     if (![Utility isMultitaskSupported] && !self.didAddressBookChange) {
        
        // if saved file exists 
        if ([Utility fileExistsAtDocumentFilePath:kContactManagerABDictionaryCacheFilename]){
            
            DDLogInfo(@"CM-sabd: load cache - start");

            // save cache of dictionary to load next time
            NSString *cacheFilePath = [Utility documentFilePath:kContactManagerABDictionaryCacheFilename];
            
            self.addressBookDictionary = [NSDictionary dictionaryWithContentsOfFile:cacheFilePath];
            
            // sort array of recordID keys
            //
            NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:[self.addressBookDictionary count]];
            for (NSString *iKey in [self.addressBookDictionary allKeys]) {
                [keys addObject:[NSNumber numberWithInt:[iKey intValue]]];
            }
            
            
            NSArray *sortedKeys = [keys sortedArrayUsingComparator:^(NSNumber *a, NSNumber *b){
                return [a compare:b];
            }];
            [keys release];
            self.sortedRecordIDKeys = sortedKeys;   
            
            DDLogInfo(@"CM-sabd: load cache - end");

            // all done
            return;
        }
    }*/
    
    
    // create addressbook
    //
    if (!addressBook){
		DDLogInfo(@"CM-sabd: Addressbook creation start");
        
        // Request authorization to Address Book
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                if (granted) {
                    // First time access has been granted, add the contact
                } else {
                    // User denied access
                    // Display an alert telling user the contact could not be added
                }
            });
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            // The user has previously given access, add the contact
        }
        else {
            // The user has previously denied access
            // Send an alert telling user to change privacy setting in settings app
        }
		DDLogInfo(@"CM-sabd: Addressbook creation done");
        
        // get notification on main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            DDLogInfo(@"CM-sabd: Addressbook register callback");
            ABAddressBookRegisterExternalChangeCallback(addressBook, addressBookChanged, nil);
        });
        
	}
    else {
        // get the latest updates
        // - no need since addressbook is dicarded
        DDLogInfo(@"CM-sabd: Addressbook revert start");
        ABAddressBookRevert(addressBook);
        DDLogInfo(@"CM-sabd: Addressbook revert done");
    }
    
    // create addressbook dictionary
    //
    if (!self.addressBookDictionary){
        NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
        self.addressBookDictionary = newDictionary;
        [newDictionary release];
    }
    
    DDLogVerbose(@"CM-sabd: initialing from addressbook DB all persons");
    NSArray *personRecords = (NSArray *) ABAddressBookCopyArrayOfAllPeople(self.addressBook);
    
    // search for set if faster
    //
    NSMutableSet *linkedPersonsToSkip = [[NSMutableSet alloc] init];
    
    // populate person dictionaries
    DDLogInfo(@"CM-sabd: Init person dictionary");
    
    // loop through all contacts and store master list of recordIDs
    //
    self.numberOfPhonesInAddressBook = 0;
    
    for (int i=0; i<[personRecords count]; i++){
        
        ABRecordRef personRecordRef = [personRecords objectAtIndex:i];
        
        // skip if contact is already merged
        //
        if ([linkedPersonsToSkip member:personRecordRef]) {
            continue;
        }
        
        // get this person's information
        NSMutableDictionary *personDictionary = [self personDictionaryForPersonRef:personRecordRef];
        NSNumber *recordID = [personDictionary valueForKey:kABRecordIDKey];
        
        // check if there are linked contacts
        // - merge their contact information
        // - then skip them later on
        // ~ Note: overhead for checking linked for 288 contact was 0.02 sec (negligible)
        //
        NSArray *linked = (NSArray *) ABPersonCopyArrayOfAllLinkedPeople(personRecordRef);
        if ([linked count] > 1) {
            [linkedPersonsToSkip addObjectsFromArray:linked];
            
            // merge linked contact info
            for (int m = 0; m < [linked count]; m++) {
                ABRecordRef iLinked = [linked objectAtIndex:m];
                // don't merge the same contact
                if (iLinked == personRecordRef) {
                    continue;
                }
                NSMutableDictionary *iDict  = [self personDictionaryForPersonRef:iLinked];
                [self mergePersonDictionary:iDict intoPersonDictionary:personDictionary];
            }
        }
        [linked release];
        
        // don't save to AB if no phone or email info
        //
        if (recordID && [personDictionary count] > 0) {
            [self.addressBookDictionary setObject:personDictionary forKey:recordID];
        }
        else {
            DDLogError(@"CM-syncAB: AB contact has no info recordID:%@", recordID);
        }

    }
    [linkedPersonsToSkip release];
    
    DDLogInfo(@"CM-sabd: Extract person info - Fin");

    [personRecords release];
    
    
    // sort array of recordID keys
    //
    /*NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:[self.addressBookDictionary count]];
    for (NSString *iKey in [self.addressBookDictionary allKeys]) {
        [keys addObject:[NSNumber numberWithInt:[iKey intValue]]];
    }*/
    NSArray *keys = [self.addressBookDictionary allKeys];
    
    NSArray *sortedKeys = [keys sortedArrayUsingComparator:^(NSNumber *a, NSNumber *b){
        return [a compare:b];
    }];
    self.sortedRecordIDKeys = sortedKeys;
    
    NSInteger sortedRecordIDCount = [self.sortedRecordIDKeys count];
    DDLogInfo(@"CM-sabd: gen sorted records count %d", sortedRecordIDCount);
    
    // if device is w/o multitask
    // - then save addressbook for faster loading next session
    //
    /*if (![Utility isMultitaskSupported] && [self.addressBookDictionary count] > 0) {
        DDLogInfo(@"CM-sabd: cache save - start");
        // save cache of dictionary to load next time
        NSString *cacheFilePath = [Utility documentFilePath:kContactManagerABDictionaryCacheFilename];
        BOOL writeSuccess = [self.addressBookDictionary writeToFile:cacheFilePath atomically:YES];
        DDLogInfo(@"CM-sabd: cache save - fin - %@ : %@", writeSuccess?@"OK":@"Failed", cacheFilePath);
    }*/
    
    // check if we should start phone sync
    if (self.shouldCheckForAddressBookChangeManually) {
        self.shouldCheckForAddressBookChangeManually = NO;
        
        NSInteger lastCount = [[[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingLastPhoneBookContactCount] intValue];
        
        // if count is different, we should try syncing again
        if ([self numberOfPhoneBookNumbers] != lastCount) {
            DDLogInfo(@"CM-sabd: manually detect AB change - start phone sync");

            dispatch_async(dispatch_get_main_queue(), ^{
                [MPContactManager tryStartingPhoneBookSyncForceStart:YES delayed:NO];
            });
        }
    }
    
    // update value
    [[MPSettingCenter sharedMPSettingCenter] setValueForID:kMPSettingLastPhoneBookContactCount settingValue:[NSNumber numberWithInt:[self numberOfPhoneBookNumbers]]];
    
    DDLogVerbose(@"CM-sabd: after person dictionary init");
}


/*!
 @abstract Find a matching phone number string for a given addressbook record
 
 @param phoneToMatch    The phone number to match with - registered M+ phonenumber 
                        (may sometimes include country code - not consistent as of 12/04/17)
 @param recordID        Record ID of addressbook person
 
 @return                Phone string to display in friend info view
 
 */
- (NSString *) getMatchingPhoneString:(NSString *)phoneToMatch abRecordID:(NSNumber *)recordID {
    
    NSDictionary *personD = [self personDictionaryForRecordID:recordID];
    NSArray *phoneNumbers = [personD valueForKey:kABPhoneKey];
    NSArray *phoneStrings = [personD valueForKey:kABPhoneStringKey];

    NSString *stripPhoneToMatch = [AppUtility stripZeroPrefixForString:phoneToMatch];

    for (int i=0; i < [phoneNumbers count]; i++) {
        
        // need to strip out zero prefix before we search
        NSString *iNumber = [AppUtility stripZeroPrefixForString:[phoneNumbers objectAtIndex:i]];
        
        // try to match both ways since we don't know which is longer
        if ([stripPhoneToMatch hasSuffix:iNumber] ||
            [iNumber hasSuffix:stripPhoneToMatch]) {
            
            // return formatted phone string if available
            if (i < [phoneStrings count]) {
                return [phoneStrings objectAtIndex:i];
            }
            // otherwise return unformated number
            else {
                return [phoneNumbers objectAtIndex:i];
            }
        }
    }
    return nil;
}



/*!
 @abstract gets an array with all phone book numbers
 
 by combining the phone numbers of each person found.
 
 
 */
- (NSSet *) getPhoneNumbersFromContacts:(NSArray *)contactsArray {
    
    
    NSMutableSet *phoneSet = [[[NSMutableSet alloc] init] autorelease];
    
    for (NSDictionary *iValue in contactsArray){
        NSString *recordID = [iValue objectForKey:kABRecordIDKey];
        NSArray *phones = [iValue objectForKey:kABPhoneKey];
    
        // append recordID behind each phone number
        for (NSString *iPhone in phones){
            [phoneSet addObject:[NSString stringWithFormat:@"%@,%@", iPhone, recordID]];
        }
        //[phoneSet addObjectsFromArray:phones];
    }
        
    return phoneSet;
}

/*!
 @abstract gets array of email contacts properties
 
 */
- (NSSet *) getABEmailProperties {
    
    // create addressbook dictionary, if not available yet
    //
    if (!self.addressBookDictionary){
        [self syncABData];
    }
    
    NSMutableSet *properties = [[[NSMutableSet alloc] init] autorelease];
    
    int i = 1;
    
    for (NSNumber *iRecord in self.sortedRecordIDKeys){
        
        NSDictionary *contactD = [self personDictionaryForRecordID:iRecord];
        
        NSString *name = [contactD valueForKey:kABNameKey];
        NSArray *emails = [contactD valueForKey:kABEmailKey];
        
        for (NSString *iEmail in emails){
            ContactProperty *cp = [[ContactProperty alloc] initWithName:name 
                                                                  value:iEmail 
                                                                     id:[NSNumber numberWithInt:i] 
                                                             abRecordID:iRecord 
                                                            valueString:nil];
            [properties addObject:cp];
            [cp release];
            i++;
        }
    }
    return properties;
}




/*!
 @abstract gets array of phone contacts properties
 
 See ContactProperty Object
 
 */
- (NSSet *) getABPhonePropertiesTWMobileOnly:(BOOL)twMobileOnly {
    
    // create addressbook dictionary, if not available yet
    //
    if (!self.addressBookDictionary){
        [self syncABData];
    }
    
    NSMutableSet *properties = [[[NSMutableSet alloc] init] autorelease];
    
    BOOL shouldAdd = YES;

    int i = 1;
    NSString *valueString = nil;
    for (NSNumber *iRecord in self.sortedRecordIDKeys){
        
        NSDictionary *contactD = [self personDictionaryForRecordID:iRecord];
        
        NSString *name = [contactD valueForKey:kABNameKey];
        NSArray *values = [contactD valueForKey:kABPhoneKey];
        NSArray *valueStrings = [contactD valueForKey:kABPhoneStringKey];
        
        int j = 0;
        for (NSString *iValue in values){
            
            shouldAdd = YES;

            if (j < [valueStrings count]) {
                valueString = [valueStrings objectAtIndex:j];
            }
            else {
                valueString = nil;
            }
            
            // don't add non mobile phone if requested
            //
            if (twMobileOnly) {
                if ([Utility isTWFixedLinePhoneNumber:iValue]) {
                    shouldAdd = NO;
                }
            }
            
            if (shouldAdd) {
                ContactProperty *cp = [[ContactProperty alloc] initWithName:name 
                                                                      value:iValue 
                                                                         id:[NSNumber numberWithInt:i] 
                                                                 abRecordID:iRecord
                                                                valueString:valueString];
                [properties addObject:cp];
                [cp release];
            }

            i++;
            j++;
        }
    }
    return properties;
}

/*!
 @abstract gets the number of contacts available in phonebook
 
 Use:
 - to check contacts count changed and if we need to run phone sync
 
 */
- (NSInteger)numberOfPhoneBookContacts {
    
    if (!self.addressBookDictionary) {
        [self syncABData];
    }
    
    return [self.addressBookDictionary count];
}

/*!
 @abstract gets number of phone numbers
 
 Use:
 - to check if phone count changed and if we need to run phone sync
 
 */
- (NSInteger)numberOfPhoneBookNumbers {
    
    if (!self.addressBookDictionary) {
        [self syncABData];
    }
    
    return self.numberOfPhonesInAddressBook;
}


/*!
 @abstract Gets image for the addressbook person
 */
- (UIImage *) personImageWithRecordID:(NSNumber *)recordIDNumber {
	
    ABRecordRef personRef = ABAddressBookGetPersonWithRecordID(self.addressBook, [recordIDNumber intValue]);
    NSData *imageData = (NSData *)ABPersonCopyImageDataWithFormat(personRef, kABPersonImageFormatThumbnail);
	
    if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
        [imageData release];
        return image;
    }
    
    return nil;
}


#pragma mark - App Status Methods

/*!
 @abstract Clears the badge count for "Friends" Tab
 
 @discussion When ever a new unread messages arrives or when a message is read, we should update this count.  Also used at launch to get current count.  This checks the number of chats with unread message > 0.
 
 */
+ (void) clearFriendBadgeCount {
    [AppUtility setBadgeCount:0 controllerIndex:kMPTabIndexFriend];
}

/*!
 @abstract Updates the badge count for "Chats" Tab
 
 @discussion When ever a new unread messages arrives or when a message is read, we should update this count.  Also used at launch to get current count.  This checks the number of chats with unread message > 0.
 Use:
 - after phone sync
 - after manually add friend
 - after app launch
 
 */
+ (void) updateFriendBadgeCount {
    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    if (dispatch_get_current_queue() != back_queue) {
        
        dispatch_async(back_queue, ^{
            NSInteger newCount = [[AppUtility getBackgroundContactManager] getNewFriendCount];
            
            // update in main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [AppUtility setBadgeCount:newCount controllerIndex:kMPTabIndexFriend];
            });
            
        });
    }
    else {
        NSInteger newCount = [[AppUtility getBackgroundContactManager] getNewFriendCount];
        
        // update in main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [AppUtility setBadgeCount:newCount controllerIndex:kMPTabIndexFriend];
        });
    }
}


#pragma mark - Background CM attribute management


/*!
 @abstract Updates Contacts Cache from DB
 
 */
- (void) refreshContacts {
    NSAssert(dispatch_get_current_queue() == [AppUtility getBackgroundMOCQueue], @"Must be dispatched on backQueue");
    self.contacts = [CDContact allContacts];
}

/*!
 @abstract Use contact cache to gets a contact given it's userID
 */
- (CDContact *) cachedContactWithUserID:(NSString *)userID {
    
    if (self.contacts == nil) {
        [self refreshContacts];
    }
    
    for (CDContact *iContact in self.contacts) {
        if ([iContact.userID isEqualToString:userID]) {
            return iContact;
        }
    }
    DDLogError(@"CM-ccwu: Can't find user with ID %@", userID);
    return nil;
}


#pragma mark - Contact List Management


/*!
 @abstract gets the count of friends that are consider new
 
 Note: this should be faster than DB query if contacts are already present
 */
- (NSInteger) getNewFriendCount {
    
    return [CDContact newFriendContactsCount];
    
    /*NSDate *lastResignDate = [[MPSettingCenter sharedMPSettingCenter] valueForID:kMPSettingAppResignActiveAfterViewingFriendDate];
    
    NSInteger newCount = 0;
    
    // only check if app was resigned before
    if (lastResignDate) {
        for (CDContact *iContact in self.contacts){
            if ([iContact.addFriendDate compare:lastResignDate] == NSOrderedDescending && ![iContact isBlockedByMe]) {
                newCount++;
            }
        }
    }
    return newCount;*/
}

/*!
 @abstract Changes this contact state to a friend
 
 @param updateBadgeCount - Should we update the badge count after adding this friend?
 
 Use:
 - when adding a single friend we should also update the badge count
 */
+ (void) makeFriend:(CDContact *)contact updateBadgeCount:(BOOL)updateCount {
    
    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    if (dispatch_get_current_queue() != back_queue) {
        
        dispatch_async(back_queue, ^{
            [contact makeFriend];
            [AppUtility cdSaveWithIDString:@"CM-mf: adding new friend" quitOnFail:NO];
        });
    }
    else {
        [contact makeFriend];
        [AppUtility cdSaveWithIDString:@"CM-mf: adding new friend" quitOnFail:NO];
    }

    if (updateCount) {
        [MPContactManager updateFriendBadgeCount];
    }
}


/*!
 @abstract Unfriend this contact
 
 @param updateBadgeCount - Should we update the badge count after unfriending?
 
 Use:
 - After deleting a person as a friend
 
 */
+ (void) unFriend:(NSString *)contactUserID updateBadgeCount:(BOOL)updateCount {
    
    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    if (dispatch_get_current_queue() != back_queue) {
        
        dispatch_async(back_queue, ^{
            CDContact *contact = [[AppUtility getBackgroundContactManager] cachedContactWithUserID:contactUserID];
            [contact unFriend];
            [AppUtility cdSaveWithIDString:@"CM-mf: unfriend contact" quitOnFail:NO];
        });
    }
    else {
        CDContact *contact = [[AppUtility getBackgroundContactManager] cachedContactWithUserID:contactUserID];
        [contact unFriend];
        [AppUtility cdSaveWithIDString:@"CM-mf: unfriend contact" quitOnFail:NO];
    }
    
    if (updateCount) {
        [MPContactManager updateFriendBadgeCount];
    }
}


/*!
 @abstract Process query response notification and add contact as friend if successful
 
 @return YES if contact was added
 
 If successful, then add this person as a friend in the DB, update new friend badge
 
 // notification object
 //
 NSMutableDictionary *newD = [[NSMutableDictionary alloc] initWithDictionary:responseDictionary];
 [newD setValue:presenceArray forKey:@"array"];
 
 */
+ (BOOL) processAddFriendNotification:(NSNotification *)notification contactToAdd:(CDContact *)addContact {
    
    NSDictionary *responseD = [notification object];
    NSArray *presenceArray = [responseD valueForKey:@"array"];
    NSString *queryTypeTag = [responseD valueForKey:kTTXMLTypeTag];
    NSString *queryIDTag = [responseD valueForKey:kTTXMLIDTag];
    
    DDLogInfo(@"CM-pafn: add candidate type: %@ id: %@", queryTypeTag, queryIDTag);
    
    // if this is my response - check userID
    if ([queryIDTag isEqualToString:addContact.userID]) {
        
        // got a matching reply, so stop activity indicator
        [AppUtility stopActivityIndicator];
        
        if ([presenceArray count] == 1) {
            MPPresence *addPresence = [presenceArray objectAtIndex:0];
            
            if ([addContact.userID isEqualToString:addPresence.aUserID]) {
                
                // account deleted, so we can't add
                if ([addPresence isContactDeleted]) {
                    
                    NSString *failedTitle = NSLocalizedString(@"Add Friend Failed", @"AddFriend - alert title:");
                    NSString *failedText = NSLocalizedString(@"This user's account has been deleted.", @"AddFriend - alert: can't add since account is deleted.");
                    [Utility showAlertViewWithTitle:failedTitle message:failedText];
                    
                }
                // ok
                else {
                    // add as a friend
                    [addContact makeFriend];
                    [MPContactManager updateFriendBadgeCount];
                    [AppUtility cdSaveWithIDString:@"add friend suggestion" quitOnFail:NO];
                    
                    return YES;
                }
            }
            else {
                
                NSString *failedTitle = NSLocalizedString(@"Add Friend Failed", @"AddFriend - alert title:");
                NSString *failedText = NSLocalizedString(@"Add friend failed. Try again later.", @"FindID - alert: Inform of failure");
                [Utility showAlertViewWithTitle:failedTitle message:failedText];
            }
        }
        // must have failed
        else {
            
            NSString *failedTitle = NSLocalizedString(@"Add Friend Failed", @"AddFriend - alert title:");
            NSString *failedText = [responseD valueForKey:@"text"];
            [Utility showAlertViewWithTitle:failedTitle message:failedText];
        }
    }
    // ignore if other's 
    
    return NO;
}



#pragma mark - Presence Methods

/*!
 @abstract Resets Phone Sync Process
 
 Use:
 - call if sync request failed
 - allows another sync to be performed at a later point
 
 */
- (void) resetPhoneSyncProcess {
    
    self.isSyncRunning = NO;
    self.isSyncPending = NO;
    
    // notify others that we are done!
    //
    dispatch_queue_t main_queue = dispatch_get_main_queue();
    dispatch_async(main_queue, ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_CONTACTMANAGER_PHONESYNC_COMPLETE_NOTIFICATION object:nil];
        DDLogInfo(@"CM-reset: Phonebook sync reset - complete or failed");
    });
}

/*!
 @abstract Checks if sync was in progress - from last session
 
 running means during this session
 in-progress means that it was running in a previous session and did not finish!
 
 */
+ (BOOL)isSyncInProgress {
    
    NSNumber *lastRecordID = [[MPSettingCenter sharedMPSettingCenter] getPhoneSyncLastRecordID];

    // invalid value or was never set
    //
    if ([lastRecordID intValue] < 0 || lastRecordID == nil) {
        return NO;
    }
    return YES;
}


/*!
 @abstract Checks if any DB-PB friends were deleted from the phonebook, unfriend these contacts
 
 Unfriend DB Friends that were deleted from PB 
  * Query DB friends who are PB contacts
  * Query all AB contacts
  * Does DB friend's recordID still exists?
   - If friend not in PB, then unfriend this contact, remove Request
   ~ delete contacts deleted from PB and was a PB contact
   ~ check AB records

Cost:
  * Expensive due to PB query and Removal request
   ~ Best if run when syncing
 
 
 */
- (void) unfriendContactsDeletedFromAddressBook {
    
    // create addressbook dictionary, if not available yet
    //
    if (!self.addressBookDictionary){
        [self syncABData];
    }
    
    if (self.contacts == nil) {
        [self refreshContacts]; 
    }
    
    NSMutableArray *deleteCandidates = [[NSMutableArray alloc] init];
    
    // check if PB Friends is in addressbook
    //
    for (CDContact *iContact in self.contacts) {
        
        // only PB Friends, ignore ID friends
        // - record not nil and is valid
        if ([iContact isSyncedFromPhoneBook]) {
            NSDictionary *abContactD = [self personDictionaryForRecordID:iContact.abRecordID];
            if (abContactD == nil) {
                [deleteCandidates addObject:iContact];
            }
            // check if the registered number is still present
            // - if not also delete this contact
            // - can't match the whole phone number since PB numbers may not include country code
            //
            else {
                BOOL foundPhone = NO;
                NSString *registeredPhoneToMatch = [AppUtility stripZeroPrefixForString:iContact.registeredPhone];
                
                NSArray *phoneStrings = [abContactD valueForKey:kABPhoneKey];
                for (NSString *iPhoneString in phoneStrings) {
                    NSString *testPhone = [AppUtility stripZeroPrefixForString:iPhoneString];
                    
                    // in case reg is longer or if testphone is longer
                    // - not sure which one since presence info is currently not consistent 12/4/26
                    if ([registeredPhoneToMatch hasSuffix:testPhone] ||
                        [testPhone hasSuffix:registeredPhoneToMatch]
                        ) {
                        foundPhone = YES;
                        break;
                    }
                }
                
                if (foundPhone == NO) {
                    [deleteCandidates addObject:iContact];
                }
            }
        }
    }
                     
    // Revert contact to ID contact and unfriend
    // - note: unfriend does not require deletion of CDContact - keep this person in our DB so we can accept their info.
    //
    for (CDContact *deleteContact in deleteCandidates){
        deleteContact.abRecordID = nil;
        deleteContact.abName = nil; //@DESIGN - Are you sure you want to delete the name?  This is easier to recognize
        [deleteContact unFriend];
        
        DDLogInfo(@"CM-dfda: PB unfriend a contact deleted from Phonebook %@-%@", deleteContact.userID, deleteContact.nickname);
        
        // send remove request to server
        [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:[NSArray arrayWithObject:deleteContact.userID] action:kMPHCQueryTagRemove idTag:deleteContact.userID itemType:kMPHCItemTypeUserID];
        
    }
    
    if ([deleteCandidates count] > 0) {
        
        [AppUtility cdSaveWithIDString:@"CM-df: deleting friends" quitOnFail:NO];
        
        NSString *notificationName = MP_CONTACTMANAGER_INDEX_NOTIFICATION;
    
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
        });
    }
    [deleteCandidates release];
}
 


/*!
 @abstract Start sync process: friends synced to phonebook entries
 @discussion 
 
 @param isInitialStart is this an intial start, otherwise a continuation
 
 */
- (void) syncFriendToPhoneBookInitialStart:(BOOL)isInitialStart {
    
    // don't start a new sync, if sync already in progress
    // - however continuation can sync remaining contacts
    //
    if (self.isSyncRunning && isInitialStart) {
        return;
    }
    
    DDLogInfo(@"CM-sftopb: prepare phone sync request");
    
    // mark as running, don't start another until we are done.
    self.isSyncRunning = YES;
    
    
    // create addressbook dictionary, if not available yet
    //
    if (!self.addressBookDictionary){
        [self syncABData];
    }

    
    // if last recordID is invalid - get X contacts from the start - anyways invalid == -1 so nothing special to do
    // if last recordID exists - get X contacts with recordId greater than last 
    NSNumber *lastRecordID = [[MPSettingCenter sharedMPSettingCenter] getPhoneSyncLastRecordID];
    
    NSMutableArray *syncContacts = [[NSMutableArray alloc] init];
    
    int i = 0;
    for (NSNumber *iRecordID in self.sortedRecordIDKeys) {
        // if record > last record
        if ([iRecordID compare:lastRecordID] == NSOrderedDescending) {
            [syncContacts addObject:[self personDictionaryForRecordID:iRecordID]];
            i++;
            // if full, then stop
            if (i > kCMParamMaxSyncCount){
                break;
            }
        }
    }
    
    // save this array to compare with results
    //
    self.lastSyncContacts = syncContacts;
    [syncContacts release];
    
    
    // get their phone numbers
    //
    NSSet *phones = [self getPhoneNumbersFromContacts:self.lastSyncContacts];

    // start another method to checks if any DB-PB friends were deleted from the phonebook
    // - only if this sync just started
    //
    if (![MPContactManager isSyncInProgress]){ 
        [self unfriendContactsDeletedFromAddressBook];
    }
    
    // if initial start and no phone numbers
    // - then cancel this sync process since there are no numbers
    //
    if (isInitialStart && [phones count] == 0) {
        [self resetPhoneSyncProcess];
        return;
    }
    
    // send request to M+ servers
    // new http requests - always request on main queue
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:[phones allObjects] action:kMPHCQueryTagAddPhoneSync idTag:nil itemType:kMPHCItemTypePhone];
    });
}

/*!
 @abstract Updates current friend datamodel status using info from M+ servers
 @discussion 
 
 @param forceStart  Run no matter what
 
 */
- (void) queryFriendInfoForceStart:(BOOL)forceStart {
    
    // runs in background thread
    //
    
    // run only once per session
    //
    BOOL didRun = [[MPSettingCenter sharedMPSettingCenter] didSessionRunActionYet:kMPSettingSessionActionTagFriendInfoQuery runIt:YES];
    if (didRun && !forceStart) {
        return;
    }
    // @THINK - Probabaly best to mark as already ran after results returned, but Query results may be from other types of queries
    // - so it is hard to know for sure if this request was successful, so just set it as "ran" for now
    
    
    // create addressbook dictionary, if not available yet
    //
    if (!self.addressBookDictionary){
        [self syncABData];
    }
    
    if (self.contacts == nil) {
        [self refreshContacts];
    }
    
    // run both queries now
    // - no arguments to recover friends or add new phone contacts that just registered for a M+ account
    // - also query presence info for non friends
    
    // recover and find new friends
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:nil action:kMPHCQueryTagQueryNoArguments idTag:nil itemType:kMPHCItemTypeUserID];
    });
    
    // query info for non friends: so we can remove deleted contacts
    //
    NSMutableArray *friendIDs = [[[NSMutableArray alloc] init] autorelease];
    for (CDContact *iContact in self.contacts){
        // don't ask about deleted accounts or friends
        if ([iContact isUserAccountedCanceled] || [iContact isFriend]) {
            continue;
        }
        [friendIDs addObject:iContact.userID];
    }
    
    // send request to M+ servers
    // new http requests - always request on main queue
    //
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:friendIDs action:kMPHCQueryTagQuery idTag:nil itemType:kMPHCItemTypeUserID];
    });
    
    
    /*
    // first run is used to recover friends
    //
    if ([[MPSettingCenter sharedMPSettingCenter] didNotRunFirstStartTag:kMPSettingFirstStartTagRecoverFriends]) {
        // friendIDS = nil will get all my old friends back
        //
        
        // get all my old friends back
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:nil action:kMPHCQueryTagQueryNoArguments idTag:nil itemType:kMPHCItemTypeUserID];
        });
        
    }
    // future requests: only ask for people we know about
    // - not all of these are friends so we can keep up-to-date about their status in case they delete their account
    else {
        // query info for all known contacts
        // - this helps remove contacts who are deleted
        //
        NSMutableArray *friendIDs = [[[NSMutableArray alloc] init] autorelease];
        for (CDContact *iContact in self.contacts){
            
            // if contact already deleted, no need to ask again
            if ([iContact isUserAccountedCanceled]) {
                continue;
            }
            
            [friendIDs addObject:iContact.userID];
        }
        
        // send request to M+ servers
        // new http requests - always request on main queue
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:friendIDs action:kMPHCQueryTagQuery idTag:nil itemType:kMPHCItemTypeUserID];
        });
    }
     */
}



#pragma mark - External Requests

/*!
 @abstract start presence udpate query
 
 Use:
 - used to get presence info update to refresh friend list data model
 */
+ (void) startFriendInfoQueryInBackGroundForceStart:(BOOL)forceStart {
    
    // should only start if registered
    //
    BOOL isRegistered = [[MPHTTPCenter sharedMPHTTPCenter] isUserRegistered];
    if (!isRegistered) {
        return;
    }
    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    
    dispatch_async(back_queue, ^{
        
        [[AppUtility getBackgroundContactManager] queryFriendInfoForceStart:forceStart];
        
    });
}

/*!
 @abstract Get friend suggestions
 
 Use:
 - used to get presence info update to refresh friend list data model
 */
+ (void) startFriendSuggestionQuery {
    
    dispatch_queue_t mainQ = dispatch_get_main_queue();
    
    // send request to M+ servers
    // new http requests - always request on main queue
    //
    if (mainQ == dispatch_get_current_queue()) {
        [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:nil action:kMPHCQueryTagSuggestion idTag:nil itemType:kMPHCItemTypeUserID];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MPHTTPCenter sharedMPHTTPCenter] getUserInformation:nil action:kMPHCQueryTagSuggestion idTag:nil itemType:kMPHCItemTypeUserID];
        });
    }
}


/*!
 @abstract starts phone sync in background
 */
+ (void) startPhoneBookSyncInBackground {
    
    // notify others that we are starting
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:MP_CONTACTMANAGER_PHONESYNC_START_NOTIFICATION object:nil];
    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    
    dispatch_async(back_queue, ^{
        [[AppUtility getBackgroundContactManager] syncFriendToPhoneBookInitialStart:YES];
    });
}

/*!
 @abstract class method to sync phonebook friends
 
 @param ForceStart start even though it sync is still fresh, but if actually running now, it will not start
 @param shouldDelay should we add a timer delay before starting sync: used at launch only
 
 Use:
 - always use this to call the background CM, so state is AB query state is available once response comes back
 */
+ (void) tryStartingPhoneBookSyncForceStart:(BOOL)shouldForceStart delayed:(BOOL)shouldDelay {
    
    DDLogInfo(@"CM-tsps: try phone sync start");

    BOOL isRegistered = [[MPHTTPCenter sharedMPHTTPCenter] isUserRegistered];

    // can't run if user is not registered
    if (!isRegistered) {
        return;
    }
    
    BOOL shouldStart = NO;
    
    if (shouldForceStart) {
        shouldStart = YES;
    }
    // this means that we were still syncing in a previous session, so start it up again
    // - however if it is running during this session, don't start
    //
    else if ([MPContactManager isSyncInProgress]){
        shouldStart = YES;
    }
    // if auto start should kick in?
    //
    else if (![[MPSettingCenter sharedMPSettingCenter] isPhoneSyncFresh:kCMParamPhoneSyncAutoRefreshSecs]){
        shouldStart = YES;
    }
    /*else if ([[AppUtility getBackgroundContactManager] didAddressBookChangeAndReset]) {
        DDLogInfo(@"CM: detect AB change");
        shouldStart = YES;
    }*/
    // @DISABLE - don't use count difference since Addressbook change call back should be even better
    // check if Addressbook has different count than before
    else {
        
        if (dispatch_get_current_queue() != [AppUtility getBackgroundMOCQueue]) {
            dispatch_async([AppUtility getBackgroundMOCQueue], ^{
                [[AppUtility getBackgroundContactManager] setShouldCheckForAddressBookChangeManually:YES];
            });
        }
        else {
            [[AppUtility getBackgroundContactManager] setShouldCheckForAddressBookChangeManually:YES];
        }
    
    }
    
    // don't schedule another phone sync if one is already running
    if ([[AppUtility getBackgroundContactManager] isSyncPending]) {
        return;
    }
    
    
    // start in background thread
    //
    if (shouldStart) {
        DDLogInfo(@"CM-tsps: schedule phone sync");

        [[AppUtility getBackgroundContactManager] setIsSyncPending:YES];
        
        if (shouldDelay) {
            [NSTimer scheduledTimerWithTimeInterval:kCMParamStartPhoneSyncDelay target:self selector:@selector(startPhoneBookSyncInBackground) userInfo:nil repeats:NO];
        }
        else {
            [self startPhoneBookSyncInBackground];
        }
        
        // also start friend suggestion query!
        if (shouldDelay) {
            [NSTimer scheduledTimerWithTimeInterval:kCMParamStartPhoneSyncDelay+2.0 target:self selector:@selector(startFriendSuggestionQuery) userInfo:nil repeats:NO];
        }
        else {
            [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(startFriendSuggestionQuery) userInfo:nil repeats:NO];
        }
    }
}






#pragma mark - Message Handling and Creation

/*!
 @abstract searches for a contact with given userID
 
 @return CDContact for match, nil if no match
 */
- (CDContact *)contactWithUserID:(NSString *)userID {
    
    for (CDContact *iContact in self.contacts){
        if ([userID isEqualToString:iContact.userID]) {
            return iContact;
        }
    }
    return nil;
}


/*!
 @abstract Gets the recordID of a matching contact from last sync contacts
 
 @param phoneString MSISDN string from presence data - this will be longer 
 Use:
 - to get recordID for contacts that turned from ID to PB friend.
 
 TODO: This may be inefficient - may need dictionary to quickly find the phonebook contact
 
 */
- (NSNumber *)recordIDOfLastSyncContactWithPhoneNumber:(NSString *)phoneString {

    for (NSDictionary *iContactD in self.lastSyncContacts){
        
        NSArray *numbers = [iContactD objectForKey:kABPhoneKey];
        for (NSString *iPhoneNumber in numbers){
            
            // strip off single '+' prefix
            if ([iPhoneNumber hasPrefix:@"+"] && [iPhoneNumber length] > 1) {
                iPhoneNumber = [iPhoneNumber substringFromIndex:0];
            }
            // strip off zeros
            iPhoneNumber = [AppUtility stripZeroPrefixForString:iPhoneNumber];
            
            // does phone number match?
            if ([phoneString hasSuffix:iPhoneNumber]) {
                return [iContactD objectForKey:kABRecordIDKey];
            }
        }
        
    }
    return nil;
}

/*!
 @abstract Process Presence Information
 
 Use:
 - normally for single presence updates from the DS servers
 
 Presence Format:
 (msisdn,USERID,presence,domain-address,from-address, nickname ,headshot, logintime,status)
 
 */
- (void) processPresenceText:(NSString *)presenceText {
            
    NSArray *presences = [MPPresence getArrayFromPresence:presenceText];
    
    // update the presence data of each person
    // - don't create contacts incase garbage fed to us by DS
    //
    NSMutableSet *contactIDs = [[NSMutableSet alloc] init];
    for (MPPresence *iPresence in presences){
        CDContact *foundContact = [CDContact contactForPresence:iPresence create:NO addAsFriend:NO onlyAddIfCreated:NO updateBadgeCount:NO updatePhoneNumber:YES save:YES];
        if (foundContact.userID) {
            [contactIDs addObject:foundContact.userID];
        }
    }
    
    NSSet *notifUserIDs = [NSSet setWithSet:contactIDs];
    
    // send notification to reload contacts
    // - to main queue
    //
    dispatch_queue_t main_queue = dispatch_get_main_queue();
    dispatch_async(main_queue, ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MP_CONTACTMANAGER_RELOAD_DATA_NOTIFICATION object:notifUserIDs];
    });
    [contactIDs release];
}

/*!
 @abstract Process Results from GetUserInfo
 
 Presence Format:
 (msisdn,USERID,presence,domain-address,from-address, nickname ,headshot, logintime, status, recordID)
 
 Phone Sync: Add
  - if userID is nil,  then not found in M+, ignore it
  - if userID == -1,  then delete this contact
  - if valid userID,  update or create
    ~ use recordID to match phonebook records
 
 */
- (void) processGetUserInformation:(NSArray *)presenceArray responseDictionary:(NSDictionary *)responseDictionary {
    
    // runs in background queue
    //
    
    
    DDLogVerbose(@"CM-pgui: ab size = %d", [self.lastSyncContacts count]);
    
    MPCauseType cause = [MPHTTPCenter getCauseForResponseDictionary:responseDictionary];
    NSString *queryTag = [responseDictionary valueForKey:kTTXMLTypeTag];
    NSString *queryID = [responseDictionary valueForKey:kTTXMLIDTag];
    
    // used to determine if we should update UI
    BOOL hasChangedContacts = NO;
    BOOL hasAddedContacts = NO;

    BOOL isFirstRun = NO;
    
    // Mark first run tags to recover friends
    // - not recover blocked
    //
    if ([queryTag isEqualToString:kMPHCQueryTagQueryNoArguments] && 
        ![queryID isEqualToString:kMPHCQueryIDTagBlockedRecovery] &&
        cause == kMPCauseTypeSuccess) {
        
        // always add now
        isFirstRun = YES;
        
        // first run we should recover friends
        //
        /*if ([[MPSettingCenter sharedMPSettingCenter] didNotRunFirstStartTag:kMPSettingFirstStartTagRecoverFriends]) {
            isFirstRun = YES;
            [[MPSettingCenter sharedMPSettingCenter] markFirstStartTagComplete:kMPSettingFirstStartTagRecoverFriends];
        }*/
    }
        
    for (MPPresence *iPresence in presenceArray){
                
        NSString *iUserID = iPresence.aUserID;
        
        // only need to process if a userID is valid ~ only these values represents M+ users
        // 
        if ([AppUtility isUserIDValid:iUserID]) {
            
            
            // ******* Phone Sync Requests**: update and add new contacts! *******
            //
            if ([queryTag isEqualToString:kMPHCQueryTagAddPhoneSync]) {
                // is there an existing contact?
                //
                CDContact *foundContact = [self contactWithUserID:iUserID];
                
                // contact found using presence userID
                // - then update the information
                //
                if (foundContact) {
                    
                    // updates contact info from presence data
                    CDContact *freshContact = [CDContact contactForPresence:iPresence create:YES addAsFriend:YES onlyAddIfCreated:NO updateBadgeCount:NO updatePhoneNumber:YES save:NO];
                    
                    // if recordID exists also update name as well
                    NSNumber *iRecord = iPresence.aRecordID;
                    if (iRecord) {
                        NSDictionary *contactD = [self personDictionaryForRecordID:iRecord];
                        if (contactD) {
                            NSString *nameString = [contactD objectForKey:kABNameKey];
                            //DDLogVerbose(@"**N**%@-%@", nameString, freshContact.nickname);
                            if (nameString) {
                                freshContact.abName = nameString;
                            }
                        }
                    }
                    
                    hasChangedContacts = YES;
                    
                    // was a ID friend, should turn contact into PB friend
                    /*if (foundContact.abRecordID == nil) {
                        
                        // try using what we got back
                        NSNumber *newRecordID = nil;
                        if (iRecordInt > -1) {
                            newRecordID = [NSNumber numberWithInt:iRecordInt];
                        }
                        // else find it ourselves
                        else {
                            // find the recordID
                            NSString *presencePhone = iPresence.aMSISDN;
                            newRecordID = [self recordIDOfLastSyncContactWithPhoneNumber:presencePhone];
                        }
                        if (newRecordID){
                            foundContact.abRecordID = newRecordID;
                            hasChangedContacts = YES;
                        }
                    }*/
                }
                // no contact found, create it
                else {
                    CDContact *newContact = [CDContact contactForPresence:iPresence create:YES addAsFriend:YES onlyAddIfCreated:NO updateBadgeCount:NO updatePhoneNumber:YES save:NO];
                    
                    // if recordID exists also update name as well
                    NSNumber *iRecord = iPresence.aRecordID;
                    if (iRecord) {
                        NSDictionary *contactD = [self personDictionaryForRecordID:iRecord];
                        if (contactD) {
                            NSString *nameString = [contactD objectForKey:kABNameKey];
                            //DDLogVerbose(@"**N**%@-%@", nameString, freshContact.nickname);
                            if (nameString) {
                                newContact.abName = nameString;
                            }
                        }
                        
                    }
                    
                    hasChangedContacts = YES;
                    hasAddedContacts = YES;
                }
            }
            // **************** Suggestions *********************
            // create contacts, but don't add as friends
            // 
            else if([queryTag isEqualToString:kMPHCQueryTagSuggestion]) {
                
                // recID from regular queries are NOT valid!
                // - don't update them - clearing it so we don't use them
                //
                iPresence.aRecordID = nil;
                
                // - this handles unfriend canceled accounts
                [CDContact contactForPresence:iPresence create:YES addAsFriend:NO onlyAddIfCreated:NO updateBadgeCount:NO updatePhoneNumber:NO save:NO];
                hasChangedContacts = YES;
                
            }
            // **************** Blocked Recovery *********************
            // create contacts and mark ask blocked
            // 
            else if([queryTag isEqualToString:kMPHCQueryTagQuery] && [queryID isEqualToString:kMPHCQueryIDTagBlockedRecovery]) {
                
                // recID from regular queries are NOT valid!
                // - don't update them - clearing it so we don't use them
                //
                iPresence.aRecordID = nil;
                // - this handles unfriend canceled accounts
                CDContact *blockContact = [CDContact contactForPresence:iPresence
                                                                 create:YES
                                                            addAsFriend:NO onlyAddIfCreated:NO 
                                                       updateBadgeCount:NO
                                                      updatePhoneNumber:NO save:NO];
                [blockContact blockUser];
                hasChangedContacts = YES;
            }
            
            // **************** Regular Query *********************
            // for regular queries 
            // - just update existing contacts
            // - or first run query to recover friends
            //
            else {
                
                BOOL createAndAdd = NO;
                
                if (isFirstRun) {
                    createAndAdd = YES;
                    hasAddedContacts = YES;
                }
                
                // recID from regular queries are NOT valid!
                // - don't update them - clearing it so we don't use them
                //
                iPresence.aRecordID = nil;
                // - this handles unfriend canceled accounts
                // - for first time after registration - create and add as friends!!!
                CDContact *refreshedContact = [CDContact contactForPresence:iPresence 
                                                                     create:createAndAdd 
                                                                addAsFriend:createAndAdd onlyAddIfCreated:YES
                                                           updateBadgeCount:NO 
                                                          updatePhoneNumber:NO 
                                                                       save:NO];
                
                // if recordID exists also update name as well
                if ([refreshedContact.abRecordID intValue] != kABRecordInvalidID) {
                    NSDictionary *contactD = [self personDictionaryForRecordID:refreshedContact.abRecordID];
                    if (contactD) {
                        NSString *nameString = [contactD objectForKey:kABNameKey];
                        //DDLogVerbose(@"**N**%@-%@", nameString, freshContact.nickname);
                        if (nameString) {
                            refreshedContact.abName = nameString;
                        }
                    }
                }
                
                hasChangedContacts = YES;
            }
        }
    }
    
    
    BOOL startAgain = NO;
    if ([queryTag isEqualToString:kMPHCQueryTagAddPhoneSync]) {
        // mark lastID so sync can start where we took off
        //
        NSNumber *lastRecordID = [[self.lastSyncContacts lastObject] objectForKey:kABRecordIDKey];
        
        // this may been flushed, only run if available
        NSInteger sortedRecordIDCount = [self.sortedRecordIDKeys count];
        DDLogInfo(@"CM-pgui: sorted records count %d", sortedRecordIDCount);
        
        if ([self.sortedRecordIDKeys count] > 0) {
            // check if we have reached the last recordID - we are done?
            if ([lastRecordID isEqualToNumber:[self.sortedRecordIDKeys lastObject]]) {
                
                // we are done!
                [self resetPhoneSyncProcess];
                [[MPSettingCenter sharedMPSettingCenter] setPhoneSyncCompleteDateToNow];
                DDLogInfo(@"CM-pgui: Sync complete at last record:%@", lastRecordID);
                
            }
            // still in the middle of the list - keep going
            else {
                [[MPSettingCenter sharedMPSettingCenter] setPhoneSyncLastRecordID:lastRecordID];
                startAgain = YES;
                DDLogInfo(@"CM-pgui: Start sync again starting at recordID:%@", lastRecordID);
            }
        }
        // sorted keys are invalid, then stop the process
        else {
            
            [self resetPhoneSyncProcess];
            [[MPSettingCenter sharedMPSettingCenter] setPhoneSyncCompleteDateToNow];
            DDLogInfo(@"CM-pgui: Sync stopped due to missing sorted keys");
        }
        // reset working list for next iteration
        self.lastSyncContacts = nil;
    }
    
    
    // send notification to reload contacts
    // - to main queue
    //
    if (hasChangedContacts || hasAddedContacts) {
        [AppUtility cdSaveWithIDString:@"CM-pgui: save updates to contacts" quitOnFail:NO];

        // we should update our contacts since contacts may have been added
        //
        [self refreshContacts];
        

        // inform mainthread to reload UI
        NSString *notificationName = MP_CONTACTMANAGER_INDEX_NOTIFICATION;

        /*if (hasAddedContacts) {
            notificationName = MP_CONTACTMANAGER_INDEX_NOTIFICATION;
        }*/
        
        dispatch_queue_t main_queue = dispatch_get_main_queue();
        dispatch_async(main_queue, ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
        });
    }
    
    // if blocked user covered got response
    // - inform name registration so it can continue
    if([queryTag isEqualToString:kMPHCQueryTagQuery] && [queryID isEqualToString:kMPHCQueryIDTagBlockedRecovery]) {
        
        dispatch_queue_t main_queue = dispatch_get_main_queue();
        dispatch_async(main_queue, ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_CONTACTMANAGER_BLOCKED_RECOVERED_NOTIFICATION object:nil];
        });
    }
    
    
    // if new contacts, update friend count
    if (hasAddedContacts || hasChangedContacts){
        [MPContactManager updateFriendBadgeCount];
    }
    
    if (startAgain) {
        // not done, start query again!
        [self syncFriendToPhoneBookInitialStart:NO];
    }
}


/*!
 @abstract handles message related to this object
 */
- (void) handleMessage:(MPMessage *)newMessage {
    
 
    /*
     Got presence information:
     - extract individual presence string
     - 
     
     Example
     @presence?id=2011082328260333000001 &text=(886911223344,10012345,1,61.66.229.112,192.168.1.23,John,6, 201108231435,上班)+
     (886988776655,10002556,0,61.66.229.109, 61.66.229.109,Mary,0, 201108211030,sleep)+ ....................................................... + (193563804,20998124,0,61.66.229.131, 61.66.229.131,Hawk,1, 201107050916,出差)
     
     */
    if ([newMessage.mType isEqualToString:kMPMessageTypePresence]) {
        
        [self processPresenceText:newMessage.text];
        
    }
}


#pragma mark - Contact Collation Data Model


/*!
 @abstract populates objects lists that need to referenced by collation
 
 */
- (void) refreshUserIDToContactD {
    
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Must be dispatched on mainQueue");
    
    // most likely DB changed so update it
    //
    // no need to reset DB - changes are now merged in deletegate -- [AppUtility cdReset];
    
    NSArray *allContacts = [CDContact allContacts];
    
    NSMutableDictionary *objectDictionary = [[NSMutableDictionary alloc] initWithCapacity:[self.contacts count]];
    for (CDContact *iContact in allContacts){
        [objectDictionary setObject:iContact forKey:iContact.userID];
    }
    
    self.userIDToContactsD = objectDictionary;
    [objectDictionary release];
    
}

/*!
 @abstract refresh contacts from the database
 
 Use:
 - used to refresh contacts and their data to show in view
 ~ presence info updates
 
 */
- (void) reloadContacts {
    
    [self refreshUserIDToContactD];
    [self.collation assignObjectRepository:self.userIDToContactsD];
}



/*!
 @abstract setup the group member IDs from a list of members
 */
+ (BOOL) isFriendAHelper:(CDContact *)friend
{
    // if ID equal or higher helper limit
    //
    if ([friend.userID compare:kMPParamHelperMinID] != NSOrderedAscending) {
        return YES;
    }
    return NO;
}

/*!
 @abstract setup the group member IDs from a list of members
 
 */
- (void) setGroupMembers:(NSSet *)members sectionTitle:(NSString *)sectionTitle indexTitle:(NSString *)indexTitle {
    
    NSMutableArray *memberIDs = [[NSMutableArray alloc] initWithCapacity:[members count]];
    
    for (CDContact *iContact in members){
        [memberIDs addObject:iContact.userID];
    }
    
    self.currentGroupMemberIDs = memberIDs;
    self.currentGroupMemberSectionTitle = sectionTitle;
    self.currentGroupMemberIndexTitle = indexTitle;
    
    [memberIDs release];
}


/*!
 @abstract get all collation contacts - those that should be showing in the table
 
 Use:
 - listing to check who was selected in SelectContactsController
 
 */
- (NSArray *) getCollationContacts {
    
    return [self.collation getAllObjects];
}

/*!
 Update data model and tell tableview to reload
 */
/*- (void) updateDataModel {
	
	// update data and then save to archive for later use
	//
	[self.collation syncLoadedData];
	[self.collation saveToArchive:kIndexCacheContactManagerFileName];
	
	// stop inidcator and udpate data
    
	[self.memberController stopActivityIndicator];
	[self.memberController reloadController];
	
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MP_CONTACTMANAGER_RELOAD_NOTIFICATION object:nil];
}*/





/*
 @abstract Indexes contacts using collation object to properly order contacts for display
 
 @param excludeHelper - Don't include helper contacts in this list - select friends
 
 
 Creates a new collation
 - indexes the collation with fresh data from background DB
 - updates data model in main DB
 - replace the old collation ~ to display fresh data
 
 If currentGroupMemberID exists
 - prepend new section to the top with these members
 - filter these members from the main list
 
 */
- (void) startCollationIndexingExcludeHelper:(BOOL)excludeHelper {
	
    DDLogInfo(@"CM-si: Collation Index - start1");
    
    dispatch_queue_t back_queue = [AppUtility getBackgroundMOCQueue];
    
    dispatch_async(back_queue, ^{
    
        
        // Load the cached collation and data model from file
        // 
        //if ([self.collation loadFromArchive:kIndexCacheContactManagerFileName]) {
		// do nothing
        //}
        
        SEL userIDSelector = @selector(userID);
        SEL userIDToObjectSelector = @selector(objectForKey:);
        TTCollationWrapper *newCollation = [[TTCollationWrapper alloc] initWithIDSelector:userIDSelector idToObjectSelector:userIDToObjectSelector];
        
        //self.collation = newCollation;
        //[newCollation release];
        [newCollation addSearchIcon:YES];

        // empty list to add items we want to collate
        NSMutableArray *workingList = [[NSMutableArray alloc] init];
        
        // empty list to add group members
        NSMutableArray *currentMembers = [[NSMutableArray alloc] initWithCapacity:[self.currentGroupMemberIDs count]];
        
        // *** Generate an ordered array of person objects *** //
        // start with unsorted list - FRESH from DB!
        //NSArray *allFriends = [CDContact allValidFriends];  // only show friends that are not blocked
        NSArray *allContacts = [CDContact allContacts];  // show contacts that are not blocked
        
        
        // don't include member in main list
        if ([self.currentGroupMemberIDs count] > 0) {
            // filter out members
            for (CDContact *iContact in allContacts) {
                // if is member
                if ([self.currentGroupMemberIDs indexOfObject:iContact.userID] != NSNotFound) {
                    [currentMembers addObject:iContact];
                }
                // non members
                else if ([iContact isFriend] && ![iContact isBlockedByMe]) {
                    // don't include helper
                    if (excludeHelper) {
                        if (![MPContactManager isFriendAHelper:iContact]) {
                            [workingList addObject:iContact];
                            //NSString *test = iFriend.userID;
                        }
                        /*else {
                            DDLogVerbose(@"CM: excludingHelper: %@", iFriend.userID);
                        }*/
                    }
                    else {
                        [workingList addObject:iContact];
                    }
                }
            }
        }
        // no members, then show all friends
        else {
            // exclude helper contacts
            if (excludeHelper) {
                for (CDContact *iContact in allContacts) {
                    if ([iContact isFriend] && 
                        ![MPContactManager isFriendAHelper:iContact] &&
                        ![iContact isBlockedByMe]) {
                        [workingList addObject:iContact];
                    }
                }
            }
            else {
                for (CDContact *iContact in allContacts) {
                    if ([iContact isFriend] && ![iContact isBlockedByMe]) {
                        [workingList addObject:iContact];
                    }
                }
            }
        }
        
        
        DDLogInfo(@"CM-si: bk - total contacts %d", [workingList count]);
		
		
        DDLogVerbose(@"CM-si: bk - index start");
        // if we have people to index or memberList to prepend
        // 
        if ([workingList count] > 0 || [self.currentGroupMemberIDs count] > 0) {
            /******************************************************
             Setup sectionsArray according to localized index collation
             - new method
             *****************************************************/
            
            
            // define section segregation selector
            //
            SEL sectionSelector = @selector(displayName);
            
            // should each section be split up into sub sections?
            // - so section "new york" & "new jersey" will be separate sections under on index section "n"
            //
            BOOL splitSection = NO;
            
            // how should each section be sorted
            // * try to use "name" selector if possible
            SEL sectionSortSelector = @selector(displayName);
            
            // index objects
            //
            [newCollation setupSectionsArrayWithObjects:workingList 
                                          sectionSelector:sectionSelector 
                                             sortSelector:sectionSortSelector 
                                             splitSection:splitSection];
                        
            DDLogInfo(@"CM-si: bk - index done");
        }
        [workingList release];
        
        // sort and prepend current members to top of the list
        //
        if ([self.currentGroupMemberIDs count] > 0) {
            NSArray *sortedMemberArray = [newCollation sortedArrayFromArray:currentMembers collationStringSelector:@selector(displayName)];
            [newCollation prependSectionTitle:self.currentGroupMemberSectionTitle
                            sectionIndexTitle:self.currentGroupMemberIndexTitle
                                  objectArray:sortedMemberArray];
        }
        [currentMembers release];
        
        [newCollation syncLoadedData];

                
        // update data model in main thread
        // - wait in order to handover objects for thread safety
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            
            DDLogInfo(@"CM-si: updating data model");

            // load in new objects & assign to collation for use
            [self refreshUserIDToContactD];  // need main
            [newCollation assignObjectRepository:self.userIDToContactsD];
            
            // replace old collation with new one!
            self.collation = newCollation;
            [newCollation release];
            
            // update data and then save to archive for later use
            //
            //[self.collation syncLoadedData];
            //[self.collation saveToArchive:kIndexCacheContactManagerFileName];
            
            // tell tableview to reload
            [[NSNotificationCenter defaultCenter] postNotificationName:MP_CONTACTMANAGER_RELOAD_TABLE_NOTIFICATION object:nil];
        
        });
    });
}

/*!
 @abstract Include all friends
 */
- (void) startCollationIndexing {
    [self startCollationIndexingExcludeHelper:NO];
}



#pragma mark - TableView related methods

/**
 Check if indexPath points to the last count section
 
 */
- (BOOL)isIndexAtCountSection:(NSIndexPath *)indexPath {
	NSUInteger section = [indexPath section];
	if (section == [self.collation sectionCount]) {
		return YES;
	}
	return NO;
}


- (NSInteger)numberOfTotalContactsForMode:(NSString *)modeString {
	
	if ([modeString isEqualToString:@"search"]){
		return [self.filteredContacts count];
	}
	// mode == "list" or other
	else {
		return [self.collation numberOfTotalObjects];
	}
}


- (NSInteger)numberOfSections {
	// it is possible that search will eliminate all sections
	// but always return 1 section that will hold empty data
	NSUInteger count = [self.collation sectionCount];
    return (count > 0) ? count : 1;
}


// Customize the number of rows in the table view.
- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    
	// how many sections are there?
	NSUInteger count = [self.collation sectionCount];
	// if no sections exists - show empty list
	if (count == 0){
		return 0;
	}
	// if last "#" section requested, return 1 row for member count
	else if (section == count) {
		return 1;
	}
	else {
		return [self.collation numberOfRowsInSection:section];
	}    
}

// Given indexPath, return the what should be shown in the table cell
//  * if indexing: use cache index
//  * if indexed: used new index data
//
- (CDContact *) personAtIndexPath:(NSIndexPath *)indexPath {
	
	return [self.collation objectAtIndexPath:indexPath];
}


/**
 Given the person get index path that the person is at
 
 Used:
 - find index of person, so app can auto scroll to that location
 
 Return:
 - nil if not found
 
 */
- (NSIndexPath *) indexPathForPerson:(CDContact *)person {
	return [self.collation indexPathForObject:person];
}


// show headers
- (NSString *)titleForHeaderInSection:(NSInteger)section {
    
    return [self.collation titleForHeaderInSection:section];

}

// returns an array of index items
- (NSArray *)sectionIndexTitlesForTableView {
	return [self.collation sectionIndexTitles];
}

/**
 Given index title index and title
 
 Return:
 - the action section index for the associated index
 */
- (NSInteger) tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.collation sectionForSectionIndexTitleAtIndex:index];
}


#pragma mark -
#pragma mark Search Methods

/**
 Removes all filtered person results
 */
- (void) removeAllfilteredContacts {
	[self.filteredContacts removeAllObjects];
}

// Customize the number of rows in the table view.
- (NSInteger)searchNumberOfRowsInSection:(NSInteger)section {	
	return [self.filteredContacts count];
}

// Given indexPath, return the what should be shown in the table cell
- (CDContact *) searchContactAtIndexPath:(NSIndexPath *)indexPath {
	NSUInteger row = [indexPath row];
	return [self.filteredContacts objectAtIndex:row];
}

/*!
 @abstract Given search contact find the current index path
 
 Used:
 - find index of person, so app can auto scroll to that location, refresh, etc.
 
 Return:
 - nil if not found
 
 */
- (NSIndexPath *) searchIndexPathForPerson:(CDContact *)contact {
    NSInteger rowLocation = [self.filteredContacts indexOfObject:contact];
    if (rowLocation != NSNotFound) {
        return [NSIndexPath indexPathForRow:rowLocation inSection:0];
    }
	return nil;
}

/**
 filter data according to search string
 */
- (void)filterContentForSearchText:(NSString*)searchText {
    /*
     Update the filtered array based on the search text and scope.
     */
    
    [self.filteredContacts removeAllObjects]; // First clear the filtered array.
    
	NSArray *allContacts = [self.collation getAllObjects];
	
	if ([allContacts count] > 0){
		
		// for small lists, query built-in DB
		
		for (CDContact *iContact in allContacts){
            
			NSString *searchString = [iContact displayName];
			
			if (searchString) {
				if ([searchString rangeOfString:searchText
										options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)].location != NSNotFound)
				{
					[self.filteredContacts addObject:iContact];
				}
			}
		}
	}
}




@end
