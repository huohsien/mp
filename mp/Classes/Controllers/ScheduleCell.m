//
//  ScheduleCell.m
//  mp
//
//  Created by Min Tsai on 4/20/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "ScheduleCell.h"
#import "CDChat.h"
#import "MPFoundation.h"
#import "TextEmoticonView.h"


#define HEADSHOT_IMG_TAG    12001
#define NAME_LABEL_TAG      14000
#define DATE_LABEL_TAG      14001
#define MESSAGE_LABEL_TAG   14003
#define GROUP_BADGE_TAG     14008


@implementation ScheduleCell


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
    
    
    // get components
    // get components
    UIImageView *headShotView = (UIImageView *)[self.contentView viewWithTag:HEADSHOT_IMG_TAG];
    UILabel *nameLabel = (UILabel *)[self.contentView viewWithTag:NAME_LABEL_TAG];
    TextEmoticonView *messageLabel = (TextEmoticonView *)[self.contentView viewWithTag:MESSAGE_LABEL_TAG];
    UILabel *dateLabel = (UILabel *)[self.contentView viewWithTag:DATE_LABEL_TAG];
    UIButton *groupBadgeButton = (UIButton *)[self.contentView viewWithTag:GROUP_BADGE_TAG];
    
    
    [UIView animateWithDuration:kMPParamAnimationStdDuration 
                     animations:^{
                         if (editing) {
                             
                             headShotView.frame = headRectEdit;
                             dateLabel.alpha = 0.0;
                             nameLabel.frame = CGRectMake(60.0+kEditShift, 7.0, 165.0, 22.0);
                             messageLabel.frame = CGRectMake(60.0+kEditShift, 30.0, 165.0, 20.0);
                                                         
                         }
                         else {
                             
                             headShotView.frame = headRect;
                             dateLabel.alpha = 1.0;
                             nameLabel.frame = CGRectMake(60.0, 7.0, 165.0, 22.0);
                             messageLabel.frame = CGRectMake(60.0, 30.0, 165.0, 20.0);
                             
                         }
                         
                         CGSize nameSize = [nameLabel sizeThatFits:nameLabel.frame.size];
                         CGRect newFrame = groupBadgeButton.frame;
                         newFrame.origin.x = nameLabel.frame.origin.x + MIN(nameSize.width + 10.0, 165.0);
                         newFrame.origin.y = nameLabel.frame.origin.y + (nameLabel.frame.size.height-newFrame.size.height)/2.0;
                         groupBadgeButton.frame = newFrame;
                         
                     }];
}

@end

