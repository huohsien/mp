//
//  TTWebViewController.h
//  ContactBook
//
//  Created by M Tsai on 11-3-14.
//  Copyright 2011 TernTek. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TTWebViewController : UIViewController <UIWebViewDelegate> {

	UIWebView *webView;
	NSString *urlText;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSString *urlText;

- (void)setURLText:(NSString *)uText;

@end
