//
//  AssetCell.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "TKLog.h"


@implementation ELCAssetCell

@synthesize rowAssets;

-(id)initWithAssets:(NSArray*)_assets reuseIdentifier:(NSString*)_identifier {
    
	if(self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_identifier]) {
        
        self.rowAssets = _assets;
        
	}
	return self;
}

-(void)setAssets:(NSArray*)_assets {
	
    
    // remove old views
    //
	for(UIView *view in self.rowAssets) 
    {		
		[view removeFromSuperview];
	}
    
	self.rowAssets = _assets;
    
}

-(void)layoutSubviews {
    
    CGRect frame = CGRectMake(4.0, 3.0, kASPhotoSize, kASPhotoSize);
    
	for(ELCAsset *elcAsset in self.rowAssets) {
        
		[elcAsset setFrame:frame];
		[self addSubview:elcAsset];
        
		frame.origin.x = frame.origin.x + frame.size.width + 4.0;
	}
}

-(void)dealloc 
{
	[rowAssets release];
    
	[super dealloc];
}

@end
