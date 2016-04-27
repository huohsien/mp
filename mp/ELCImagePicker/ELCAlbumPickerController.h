//
//  AlbumPickerController.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>



@interface ELCAlbumPickerController : UITableViewController <UIAlertViewDelegate> {
	
	NSMutableArray *assetGroups;
	id parent;
    BOOL hasError;
    BOOL onlySingleSelection;
    
    ALAssetsLibrary *library;
    BOOL isLoadingGroups;
    BOOL shouldReloadGroups;
    NSInteger pendingSelectIndex;

}

@property (nonatomic, assign) id parent;
@property (nonatomic, retain) NSMutableArray *assetGroups;
@property (nonatomic, assign) BOOL onlySingleSelection;

/*! YES is currently loading asset groups */
@property (nonatomic, assign) BOOL isLoadingGroups;

/*! YES if we should stop current load process and start a new load process */
@property (nonatomic, assign) BOOL shouldReloadGroups;

/*! Row index that was pressed whilte groups were loading */
@property (nonatomic, assign) NSInteger pendingSelectIndex;



-(void)selectedAssets:(NSArray*)_assets;

@end

