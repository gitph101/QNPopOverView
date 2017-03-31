//
//  QNContentView.m
//  QNPopOverView
//
//  Created by 研究院01 on 17/3/28.
//  Copyright © 2017年 gitph101. All rights reserved.
//

#import "QNContentView.h"
#import "QNPopOverView.h"
#import "Masonry.h"
#import "QNPhoneView.h"

@interface QNContentView ()<QNPopOverViewDelegate,QNPopOverViewDataSource>

@property (nonatomic, strong) QNPopOverView *popOverView;

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *likeButton;


@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation QNContentView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        [self _createSubviews];
        [self _configurateSubviewsDefault];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    [self.popOverView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self).with.insets(UIEdgeInsetsMake(0, 10, 120, 0));
    }];
    
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(80, 40));
        make.left.equalTo(self.mas_left).with.offset(40);
        make.top.equalTo(self.popOverView.mas_bottom).with.offset(40);
    }];

    [self.likeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(80, 40));
        make.top.equalTo(self.popOverView.mas_bottom).with.offset(40);
        make.right.equalTo(self.mas_right).with.offset(-40);
    }];

    
}

#pragma mark - private

- (void)_createSubviews{
    
    self.popOverView = [QNPopOverView new];
    self.closeButton = [UIButton new];
    self.likeButton = [UIButton new];
    
    [self addSubview:[self closeButton]];
    [self addSubview:[self likeButton]];
    [self addSubview:[self popOverView]];
}

- (void)_configurateSubviewsDefault{
    
    self.dataSource = [NSMutableArray arrayWithObjects:@"", @"", @"", @"",@"",@"",@"",@"", nil];
    self.popOverView.delegate = self;
    self.popOverView.dataSource = self;
    self.popOverView.maxTranslation = CGSizeMake(160, 160);
    self.popOverView.itemViewRotateAngle = 5/180.f * M_PI;
    
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:20];
    self.closeButton.layer.cornerRadius = 6.;
    self.closeButton.layer.borderWidth = 0.5f;
    self.closeButton.layer.borderColor = [[UIColor colorWithRed:0.87 green:0.87 blue:0.87 alpha:1] CGColor];
    [[self closeButton] setTitleColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1] forState:UIControlStateNormal];
    [[self closeButton] setTitleColor:[UIColor greenColor] forState:UIControlStateHighlighted];
    [[self closeButton] setTitle:@"X" forState:UIControlStateNormal];

    self.likeButton.titleLabel.font = [UIFont systemFontOfSize:20];
    self.likeButton.layer.cornerRadius = 6.;
    self.likeButton.layer.borderWidth = 0.5f;
    self.likeButton.layer.borderColor = [[UIColor colorWithRed:0.87 green:0.87 blue:0.87 alpha:1] CGColor];
    [[self likeButton] setTitleColor:[UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:1] forState:UIControlStateNormal];
    [[self likeButton] setTitleColor:[UIColor greenColor] forState:UIControlStateHighlighted];
    [[self likeButton] setTitle:@"OK" forState:UIControlStateNormal];
    [[self likeButton] addTarget:self action:@selector(didClickLike:) forControlEvents:UIControlEventTouchUpInside];
    
    [[self popOverView] reloadData];
}

#pragma mark - POPopupOverViewDelegate, POPopupOverViewDataSource

- (NSInteger)numberOfItemsInPopupOverViewView:(QNPopOverView *)popupOverView;{
    return [[self dataSource] count];
}

- (NSInteger)numberOfVisibleItemsInPopupOverViewView:(QNPopOverView *)popupOverView;{
    return 4;
}

- (CGSize)popupOverView:(QNPopOverView *)popupOverView sizeForItemAtIndex:(NSUInteger)nIndex;{
    return CGSizeMake(self.frame.size.width -20, self.frame.size.height - 120);
}

- (UIView *)popupOverView:(QNPopOverView *)popupOverView viewForItemAtIndex:(NSUInteger)nIndex reusingView:(UIView *)view;{
    if (!view) {
        view = [[QNPhoneView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width-20, self.frame.size.height-120)];
    }
    view.backgroundColor = [UIColor whiteColor];
    return view;
}

- (BOOL)popupOverView:(QNPopOverView *)popupOverView shouldPopupOverItemView:(UIView *)itemView direction:(QNPopOverViewAnimationDirection)direction atIndex:(NSUInteger)nIndex;{
    return YES;
}

- (void)popupOverView:(QNPopOverView *)popupOverView movingItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex;{
    QNPopOverViewAnimationDirection direction = [popupOverView directionAtTranslation:translation];
    self.closeButton.highlighted = direction & QNPopOverViewAnimationDirectionLeft;
    self.likeButton.highlighted = direction & QNPopOverViewAnimationDirectionRight;
}

- (void)popupOverView:(QNPopOverView *)popupOverView didMoveItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex;{
    self.closeButton.highlighted = NO;
    self.likeButton.highlighted = NO;
}

- (void)popupOverView:(QNPopOverView *)popupOverView didPopupOverItemViewOnDirection:(QNPopOverViewAnimationDirection)direction atIndex:(NSUInteger)nIndex;{
}

#pragma mark - actions

- (IBAction)didClickInsert:(id)sender{
    [[self dataSource] insertObject:@"" atIndex:1];
    [[self popOverView] insertItemAtIndex:1 animated:YES];
}

- (IBAction)didClickDelete:(id)sender{
    
    [[self dataSource] removeObjectAtIndex:1];
    [[self popOverView] removeItemAtIndex:1 onDirection:QNPopOverViewAnimationDirectionBottom animated:YES];
}

- (IBAction)didClickClose:(id)sender{
    
    [[self popOverView] popOverTopItemViewOnDirection:QNPopOverViewAnimationDirectionLeft animated:YES];
}

- (IBAction)didClickLike:(id)sender{
    
    [[self popOverView] popOverTopItemViewOnDirection:QNPopOverViewAnimationDirectionRight animated:YES];
}

@end
