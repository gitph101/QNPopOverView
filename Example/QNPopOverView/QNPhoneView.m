//
//  QNPhoneView.m
//  QNPopOverView
//
//  Created by 研究院01 on 17/3/30.
//  Copyright © 2017年 gitph101. All rights reserved.
//

#import "QNPhoneView.h"
#import "Masonry.h"
#import <UIKit/UIKit.h>

@interface QNPhoneView ()

@end

@implementation QNPhoneView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    self.backgroundColor = [UIColor whiteColor];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1].CGColor;
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    [self addSubview:self.phoneImageView];
    self.phoneImageView.frame = CGRectMake(0, 0, rect.size.width, rect.size.height - 100);
    self.phoneImageView.layer.masksToBounds = YES;
//    [self.phoneImageView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.equalTo(self.superview).with.insets(UIEdgeInsetsMake(0, 0, 100, 0));
//    }];
}

#pragma mark - getter and setter
//
-(UIImageView *)phoneImageView{
    
    if (_phoneImageView == nil) {
        _phoneImageView = [[UIImageView alloc]init];
        _phoneImageView.contentMode = UIViewContentModeScaleAspectFill;
        _phoneImageView.image = [UIImage imageNamed:@"5.png"];
    }
    return _phoneImageView;
}

@end
