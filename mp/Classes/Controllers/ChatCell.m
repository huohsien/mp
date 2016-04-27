//
//  ChatCell.m
//  mp
//
//  Created by Min Tsai on 4/4/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "ChatCell.h"
#import "CDChat.h"
#import "MPFoundation.h"


#define HEADSHOT_IMG_TAG    12001
#define ARROW_IMG_TAG       12002
#define ALERT_IMG_TAG       12003

#define NAME_LABEL_TAG      14000
#define DATE_LABEL_TAG      14001
#define MESSAGE_LABEL_TAG     14003
#define BADGE_IMAGE_TAG     14006
#define GROUP_BADGE_TAG     14008



@implementation ChatCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Add subviews
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


#define kEditShift 10.0


-(void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing: editing animated: animated];
    
    CGRect headRect = CGRectMake(0.0, 0.0, 54.0, 54.0);
    CGRect headRectEdit = CGRectMake(kEditShift, 0.0, 54.0, 54.0);
    
    CGRect arrowRect = CGRectMake(60.0, 34.0, 15.0, 10.0);
    CGRect arrowRectEdit = CGRectMake(60.0+kEditShift, 34.0, 15.0, 10.0);
    
    CGRect alertRect = CGRectMake(60.0, 34.0, 15.0, 15.0);
    CGRect alertRectEdit = CGRectMake(60.0+kEditShift, 34.0, 15.0, 15.0);
    
    // get components
    UIImageView *headShotView = (UIImageView *)[self.contentView viewWithTag:HEADSHOT_IMG_TAG];
    UIImageView *arrowView = (UIImageView *)[self.contentView viewWithTag:ARROW_IMG_TAG];
    UIImageView *alertView = (UIImageView *)[self.contentView viewWithTag:ALERT_IMG_TAG];

    UILabel *nameLabel = (UILabel *)[self.contentView viewWithTag:NAME_LABEL_TAG];
    UILabel *dateLabel = (UILabel *)[self.contentView viewWithTag:DATE_LABEL_TAG];
    UIView *messageLabel = [self.contentView viewWithTag:MESSAGE_LABEL_TAG];
    UIButton *badgeButton = (UIButton *)[self.contentView viewWithTag:BADGE_IMAGE_TAG];
    UIButton *groupBadgeButton = (UIButton *)[self.contentView viewWithTag:GROUP_BADGE_TAG];
    
    CGFloat messageIndent = 0.0;
    if (arrowView.hidden == NO || alertView.hidden == NO) {
        messageIndent = 16.0;
    }
    
    [UIView animateWithDuration:kMPParamAnimationStdDuration 
                     animations:^{
                         if (editing) {
                             
                             headShotView.frame = headRectEdit;
                             arrowView.frame = arrowRectEdit;
                             alertView.frame = alertRectEdit;
                             dateLabel.alpha = 0.0;
                             badgeButton.alpha = 0.0;
                             
                             nameLabel.frame = CGRectMake(60.0+kEditShift, 7.0, 170.0, 22.0);
                             messageLabel.frame = CGRectMake(60.0+kEditShift+messageIndent, 30.0, 170.0, 20.0);
                             
                         }
                         else {
                             
                             headShotView.frame = headRect;
                             arrowView.frame = arrowRect;
                             alertView.frame = alertRect;
                             dateLabel.alpha = 1.0;
                             badgeButton.alpha = 1.0;
                             
                             nameLabel.frame = CGRectMake(60.0, 7.0, 170.0, 22.0);
                             messageLabel.frame = CGRectMake(60.0+messageIndent, 30.0, 170.0, 20.0);
                             
                         }
                         
                         CGSize nameSize = [nameLabel sizeThatFits:nameLabel.frame.size];
                         CGRect newFrame = groupBadgeButton.frame;
                         newFrame.origin.x = nameLabel.frame.origin.x + MIN(nameSize.width + 10.0, 170.0);
                         newFrame.origin.y = nameLabel.frame.origin.y + (nameLabel.frame.size.height-newFrame.size.height)/2.0;
                         groupBadgeButton.frame = newFrame;
                         
                     }];
    
}


@end
