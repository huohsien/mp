//
//  TextEditController.h
//  mp
//
//  Created by Min Tsai on 2/16/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TextEditController;

/*!
 Delegate that handles input from this view's controls
 */
@protocol TextEditControllerDelegate <NSObject>

/*!
 @abstract User pressed saved with new text string
 
 Use:
 - when composer is done editing text
 */
- (void)TextEditController:(TextEditController *)controller didEditText:(NSString *)newText;

@end


@interface TextEditController : UIViewController <UITextViewDelegate> {
    
    id <TextEditControllerDelegate> delegate; 
    NSString *doneButtonTitle;
    NSString *originalText;

}

/*! delegate to that gets new text */
@property (nonatomic, assign) id <TextEditControllerDelegate> delegate;

/*! title for done button */
@property (nonatomic, retain) NSString *doneButtonTitle;

/*! original text to edit */
@property (nonatomic, retain) NSString *originalText;

@end
