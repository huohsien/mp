//
//  ToneController.h
//  mp
//
//  Created by Min Tsai on 2/22/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenAL/al.h>

@class SettingButton;
@class ToneController;

@protocol ToneControllerDelegate <NSObject>

/*!
 @abstract Used to notify parent view which tone was selected
 */
- (void)ToneController:(ToneController *)controller selectedToneFilename:(id)filename;

@end


@interface ToneController : UIViewController {
    
    id <ToneControllerDelegate> delegate;
    BOOL isGroup;
    NSString *selectedTone;
    
    NSArray *toneFiles;
    NSMutableArray *toneButtons;
    SettingButton *selectedButton;
    
}

/*! Delegate to inform */
@property (nonatomic, assign) id <ToneControllerDelegate> delegate;


/*! Is group notification - if not then P2P notification settings */
@property (nonatomic, assign) BOOL isGroup;

/*! Current ringtone filename */
@property (nonatomic, retain) NSString *selectedTone;


/*! Available tone filenames */
@property (nonatomic, retain) NSArray *toneFiles;

/*! Rows respresenting tones */
@property (nonatomic, retain) NSMutableArray *toneButtons;

/*! Track last selected button - so we can deselect it */
@property (nonatomic, retain) SettingButton *selectedButton;


+ (NSString *) nameForToneFilename:(NSString *)toneFilename;
- (id)initIsGroupNotification:(BOOL)isGroupNotification;

@end
