//
//  AssetTablePicker.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCAsset.h"

@interface ELCAssetTablePicker : UITableViewController <ELCAssetDelegate>
{
	ALAssetsGroup *assetsGroup;
    NSString *assetsGroupID;
    ALAssetsLibrary *assetsLibrary;
    
	NSUInteger numberOfAssets;
    
	NSMutableArray *elcAssets;
    NSThread *backgroundThread;
    NSMutableArray *createdCells;
	id parent;
    
    BOOL onlySingleSelection;
    ELCAsset *lastSelectedAsset;
    NSMutableArray *selectedAssets;
	
}

@property (nonatomic, assign) id parent;

@property (nonatomic, retain) ALAssetsGroup *assetsGroup;
@property (nonatomic, retain) NSString *assetsGroupID;
@property (nonatomic, retain) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, assign) NSUInteger numberOfAssets;

@property (nonatomic, retain) NSMutableArray *elcAssets;
@property (nonatomic, retain) IBOutlet UILabel *selectedAssetsLabel;

@property (nonatomic, assign) BOOL onlySingleSelection;
@property (nonatomic, retain) ELCAsset *lastSelectedAsset;

@property (nonatomic, retain) NSMutableArray *selectedAssets;

-(int) totalSelectedAssets;
-(void) doneAction:(id)sender;
- (void) setAssetsGroup:(ALAssetsGroup *)aAssetGroup assetsLibrary:(ALAssetsLibrary *)aAssetLibrary;

@end