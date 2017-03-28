//
//  QNContentView.m
//  QNPopOverView
//
//  Created by 研究院01 on 17/3/28.
//  Copyright © 2017年 gitph101. All rights reserved.
//

#import "QNContentView.h"
#import "QNPopOverView.h"

@interface QNContentView ()<QNPopOverViewDelegate,QNPopOverViewDataSource>

@property (nonatomic, strong) QNPopOverView *popOverView;

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *likeButton;

@property (nonatomic, strong) UIButton *insertButton;
@property (nonatomic, strong) UIButton *deleteButton;

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
    
    self.closeButton.frame = CGRectMake(24, 174, 48, 48);
    self.likeButton.frame = CGRectMake(CGRectGetWidth([self bounds]) - 24 - 48, 174, 48, 48);
    self.insertButton.frame = CGRectMake(24, 400, 98, 48);
    self.deleteButton.frame = CGRectMake(CGRectGetWidth([self bounds]) - 24 - 98, 400, 98, 48);
    self.popOverView.frame = CGRectMake(CGRectGetWidth([self bounds]) / 2. - 167/2., 124, 167, 167);
}

#pragma mark - private

- (void)_createSubviews{
    
    self.popOverView = [QNPopOverView new];
    self.closeButton = [UIButton new];
    self.likeButton = [UIButton new];
    self.insertButton = [UIButton new];
    self.deleteButton = [UIButton new];
    
    [self addSubview:[self closeButton]];
    [self addSubview:[self likeButton]];
    [self addSubview:[self insertButton]];
    [self addSubview:[self deleteButton]];
    [self addSubview:[self popOverView]];
}

- (void)_configurateSubviewsDefault{
    
    self.dataSource = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", @"", @"", @"", nil];
    
    self.popOverView.delegate = self;
    self.popOverView.dataSource = self;
    self.popOverView.maxTranslation = CGSizeMake(160, 160);
    self.popOverView.itemViewRotateAngle = 5/180.f * M_PI;
    
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:24];
    self.closeButton.layer.cornerRadius = 48/2.;
    self.closeButton.layer.borderWidth = 1.f;
    self.closeButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    [[self closeButton] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[self closeButton] setTitleColor:[UIColor greenColor] forState:UIControlStateHighlighted];
    [[self closeButton] setTitle:@"L" forState:UIControlStateNormal];
    [[self closeButton] addTarget:self action:@selector(didClickClose:) forControlEvents:UIControlEventTouchUpInside];
    
    self.insertButton.titleLabel.font = [UIFont systemFontOfSize:24];
    self.insertButton.layer.cornerRadius = 48/2.;
    self.insertButton.layer.borderWidth = 1.f;
    self.insertButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    [[self insertButton] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[self insertButton] setTitle:@"insert" forState:UIControlStateNormal];
    [[self insertButton] addTarget:self action:@selector(didClickInsert:) forControlEvents:UIControlEventTouchUpInside];
    
    self.likeButton.titleLabel.font = [UIFont systemFontOfSize:24];
    self.likeButton.layer.cornerRadius = 48/2.;
    self.likeButton.layer.borderWidth = 1.f;
    self.likeButton.layer.borderColor = [[UIColor redColor] CGColor];
    [[self likeButton] setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [[self likeButton] setTitleColor:[UIColor greenColor] forState:UIControlStateHighlighted];
    [[self likeButton] setTitle:@"R" forState:UIControlStateNormal];
    [[self likeButton] addTarget:self action:@selector(didClickLike:) forControlEvents:UIControlEventTouchUpInside];
    
    self.deleteButton.titleLabel.font = [UIFont systemFontOfSize:24];
    self.deleteButton.layer.cornerRadius = 48/2.;
    self.deleteButton.layer.borderWidth = 1.f;
    self.deleteButton.layer.borderColor = [[UIColor redColor] CGColor];
    [[self deleteButton] setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [[self deleteButton] setTitle:@"delete" forState:UIControlStateNormal];
    [[self deleteButton] addTarget:self action:@selector(didClickDelete:) forControlEvents:UIControlEventTouchUpInside];
    
    [[self popOverView] reloadData];
}

#pragma mark - POPopupOverViewDelegate, POPopupOverViewDataSource

- (NSInteger)numberOfItemsInPopupOverViewView:(QNPopOverView *)popupOverView;{
    return [[self dataSource] count];
}

- (NSInteger)numberOfVisibleItemsInPopupOverViewView:(QNPopOverView *)popupOverView;{
    return 3;
}

- (CGSize)popupOverView:(QNPopOverView *)popupOverView sizeForItemAtIndex:(NSUInteger)nIndex;{
    return CGSizeMake(200, 200);
}

- (UIView *)popupOverView:(QNPopOverView *)popupOverView viewForItemAtIndex:(NSUInteger)nIndex reusingView:(UIView *)view;{
    
    
    if (!view) {
        view = [UIView new];
    }
    view.layer.cornerRadius = 4;
    view.layer.borderWidth = 2;
    view.layer.masksToBounds = YES;
    view.layer.borderColor = [[UIColor whiteColor] CGColor];
//    view.backgroundColor = [UIColor colorWithRed:(arc4random()%255)/255.f green:(arc4random()%255)/255.f blue:(arc4random()%255)/255.f alpha:1];
    view.backgroundColor = [UIColor clearColor];
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:view.bounds];
    imageView.image = [UIImage imageNamed:@"1.png"];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [view addSubview:imageView];
    
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
