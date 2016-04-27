//
//  ToneController.m
//  mp
//
//  Created by Min Tsai on 2/22/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "ToneController.h"

#import "MPFoundation.h"
#import "SettingButton.h"

@implementation ToneController

@synthesize delegate;
@synthesize isGroup;

@synthesize selectedTone;
@synthesize selectedButton;

@synthesize toneFiles;
@synthesize toneButtons;

- (void)dealloc {
    
    [toneFiles release];
    [toneButtons release];
    
    [selectedTone release];
    [selectedButton release];
    
    [super dealloc];
}

- (id)initIsGroupNotification:(BOOL)isGroupNotification
{
	self = [super init];
	if (self != nil)
	{
        self.isGroup = isGroupNotification;
	}
	return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

#define kStartX             5.0
#define kStartY             10.0
#define kShiftY             55.0

#define ALERT_BTN_TAG       17001
#define TONE_BTN_TAG        17002
#define PREVIEW_BTN_TAG     17003

#define POPUP_BTN_TAG           17004
#define INAPP_VIBRATION_BTN_TAG 17005
#define INAPP_SOUND_BTN_TAG     17006


/*!
 @abstract Look up dictionary to get tone name
 */
+ (NSString *) nameForToneFilename:(NSString *)toneFilename {
    
    NSDictionary *nameD = [[NSDictionary alloc] initWithObjectsAndKeys:
                           NSLocalizedString(@"None", @"Tone name"), @"silence.caf", 
                           NSLocalizedString(@"Witty", @"Tone name"), @"t1_witty.caf", 
                           NSLocalizedString(@"Marimba", @"Tone name"), @"t2_marimba.caf", 
                           NSLocalizedString(@"Icicles", @"Tone name"), @"t3_icicles.caf",
                           NSLocalizedString(@"Teleport", @"Tone name"), @"t4_teleport.caf",
                           NSLocalizedString(@"Chime", @"Tone name"), @"t5_chime.caf", 
                           NSLocalizedString(@"Dream", @"Tone name"), @"t6_dream.caf", 
                           NSLocalizedString(@"Drum", @"Tone name"), @"t7_drum.caf", 
                           nil];
    
    
    NSString *toneName = [nameD valueForKey:toneFilename];
    [nameD release];
    
    return toneName;
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    // specify order
    NSArray *toneFilenames = [[NSArray alloc] initWithObjects:@"silence.caf", @"t1_witty.caf", 
                              @"t2_marimba.caf", @"t3_icicles.caf", 
                              @"t4_teleport.caf", @"t5_chime.caf", 
                              @"t6_dream.caf", @"t7_drum.caf", 
                              nil];
    
    self.toneFiles = toneFilenames;
    [toneFilenames release];
    
    NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:[self.toneFiles count]];
    self.toneButtons = buttons;
    [buttons release];
    
    
    NSString *currentFilename = [[MPSettingCenter sharedMPSettingCenter] valueForID:self.isGroup?kMPSettingPushGroupRingTone:kMPSettingPushP2PRingTone];
    NSInteger currentFileIndex = [self.toneFiles indexOfObject:currentFilename];

    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    
    // title
    //

    self.title = NSLocalizedString(@"Notification Tones", @"Tones - title: select ring tone for message alerts");
    [AppUtility setCustomTitle:self.title navigationItem:self.navigationItem];
    
    
    // add title buttons
    //
    
    UIBarButtonItem *saveButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Save", @"Tone - button: try to save user selection") 
                                                      buttonType:kAUButtonTypeBarHighlight 
                                                          target:self action:@selector(pressSave:)];
    saveButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveButton;
    
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *cancelButton = [AppUtility barButtonWithTitle:NSLocalizedString(@"Cancel", @"Tone - button: cancel tone selection") 
                                                        buttonType:kAUButtonTypeBarNormal 
                                                            target:self action:@selector(pressCancel:)];
    self.navigationItem.leftBarButtonItem = cancelButton;

    
    
    // background
    //
    UIScrollView *setupView = [[UIScrollView alloc] initWithFrame:appFrame];
    setupView.scrollEnabled = YES;
    setupView.contentSize=CGSizeMake(appFrame.size.width, 400.0);
    setupView.backgroundColor = [AppUtility colorForContext:kAUColorTypeBackground];
    self.view = setupView;
    [setupView release];
    
    // create rows
    CGFloat endY = 400.0;
    int i = 0;
    for (NSString *iToneFilename in toneFilenames) {
        
        SBButtonType bType = kSBButtonTypeCenter;
        
        if (i == 0) {
            bType = kSBButtonTypeTop;
        }
        else if (i == [self.toneFiles count]-1) {
            bType = kSBButtonTypeBottom;
        }
        
        SettingButton *toneButton = [[SettingButton alloc] initWithOrigin:CGPointMake(kStartX, kStartY+kSBButtonHeight*i) 
                                                                buttonType:bType 
                                                                    target:self 
                                                                  selector:@selector(pressTone:) 
                                                                     title:[ToneController nameForToneFilename:iToneFilename] 
                                                                 showArrow:NO];
        [self.view addSubview:toneButton];
        [self.toneButtons addObject:toneButton];
        
        if (i == currentFileIndex) {
            [toneButton setCheckOn:YES];
            self.selectedButton = toneButton;
        }
        
        CGFloat bottomY = toneButton.frame.origin.y + toneButton.frame.size.height + 20.0;
        if (bottomY > endY) {
            endY = bottomY;
        }
        [toneButton release];
        i++;
    }
    
    setupView.contentSize=CGSizeMake(appFrame.size.width, endY);

}


/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad
 {
 [super viewDidLoad];
 }
 */

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    DDLogInfo(@"TC-vwa");
    [super viewWillAppear:animated];
    
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button



/*!
 @abstract Pressed a Tone button 
 */
- (void) pressTone:(SettingButton *) newButton {
    //static ALuint soundID = 0;
    
    // deselect old button
    [self.selectedButton setCheckOn:NO];
    
    // select new one
    [newButton setCheckOn:YES];
    self.selectedButton = newButton;
    
    // set filename
    //
    NSInteger selectedIndex = [self.toneButtons indexOfObject:newButton];
    
    if (selectedIndex < [self.toneFiles count]) {
        self.selectedTone = [self.toneFiles objectAtIndex:selectedIndex];
    }
    
    
    // play audio
    [Utility asPlaySystemSoundFilename:self.selectedTone playbackMode:YES];
    
    /*if (soundID) {
        [Utility audioStop:soundID];
    }
    soundID = [Utility audioPlayEffect:self.selectedTone];
    */
    
    // enable save button
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

/*!
 @abstract save tone
 
 */
- (void)pressSave:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(ToneController:selectedToneFilename:)]) {
        [self.delegate ToneController:self selectedToneFilename:self.selectedTone];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}


/*!
 @abstract save status
 */
- (void)pressCancel:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
    
}


@end

