//
//  PreviewAnnotation.h
//  mp
//
//  Created by Min Tsai on 2/14/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface PreviewAnnotation: NSObject <MKAnnotation> {
    
    CLLocationCoordinate2D coordinate;
    NSString *name;
    NSString *address;
    
}

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

/*! name of place or business */
@property (nonatomic, retain) NSString *name;

/*! area or street address of place */
@property (nonatomic, retain) NSString *address;

@end