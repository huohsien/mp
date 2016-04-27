//
//  UIDevice(Identifier).h
//  UIDeviceAddition
//
//  Created by Georg Kitz on 20.08.11.
//  Copyright 2011 Aurora Apps. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIDevice (IdentifierAddition)

/*
 * @method uniqueDeviceIdentifier
 * @description use this method when you need a unique identifier in one app.
 * It generates a hash from the MAC-address in combination with the bundle identifier
 * of your app.
 */

- (NSString *) uniqueDeviceIdentifier;

/*
 * @method uniqueGlobalDeviceIdentifier
 * @description use this method when you need a unique global identifier to track a device
 * with multiple apps. as example a advertising network will use this method to track the device
 * from different apps.
 * It generates a hash from the MAC-address only.
 */

- (NSString *) uniqueGlobalDeviceIdentifier;

/*!
 @abstract gets IP address for this device
 
 */
- (NSString *)getIPAddress:(NSString *)targetInterfaceName;
- (NSString *)getIPAddress3G;

/*!
 @abstract gets the mac address for device
 */
- (NSString *) getMACAddress;

/*!
 @abstract get screen size in pixels
 */
- (CGSize)getScreenSizePixels;

/*!
 @abstract Detailed hardware device model
 */
- (NSString *) modelDetailedName;

@end
