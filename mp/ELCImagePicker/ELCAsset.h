//
//  Asset.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

extern CGFloat const kASPhotoSize;

@class ELCAsset;

@protocol ELCAssetDelegate <NSObject>
@optional

/*!
 @abstract Call when asset is tapped
 
 @param YES if ok to select this item
 
 Use:
 - Asks for permission to select if there is a max limit
 
 */
- (BOOL)ELCAsset:(ELCAsset *)newAsset isAllowedToSelect:(BOOL)selected;

/*!
 @abstract Call when asset is tapped
 
 Use:
 - helps de-select old view if only single selection is allowed
 */
- (void)ELCAsset:(ELCAsset *)newAsset toggleSelection:(BOOL)selected;


@end 


@interface ELCAsset : UIView {
    id <ELCAssetDelegate> delegate;
	ALAsset *asset;
	UIImageView *overlayView;
	BOOL selected;
	id parent;
}
@property (nonatomic, assign) id <ELCAssetDelegate> delegate;
@property (nonatomic, retain) ALAsset *asset;
@property (nonatomic, assign) id parent;

-(id)initWithAsset:(ALAsset*)_asset;
-(BOOL)selected;
-(void)setSelected:(BOOL)_selected;


@end