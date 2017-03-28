//
//  QNPopOverView.h
//  Pods
//
//  Created by 研究院01 on 17/3/28.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, QNPopOverViewAnimationDirection) {
    QNPopOverViewAnimationDirectionNone   = 0,
    QNPopOverViewAnimationDirectionTop     = 1 << 0,
    QNPopOverViewAnimationDirectionBottom   = 1 << 1,
    QNPopOverViewAnimationDirectionLeft   = 1 << 2,
    QNPopOverViewAnimationDirectionRight  = 1 << 3,
    QNPopOverViewAnimationDirectionRandom = 1 << 4,
};


@class QNPopOverView;
@protocol QNPopOverViewDelegate <NSObject>
@optional
- (CGSize)popupOverView:(QNPopOverView *)popupOverView sizeForItemAtIndex:(NSUInteger)nIndex;

// Display customization
- (void)popupOverView:(QNPopOverView *)popupOverView willDisplayItemView:(UIView *)itemView atIndex:(NSUInteger)nIndex;
- (void)popupOverView:(QNPopOverView *)popupOverView didEndDisplayingItemView:(UIView *)itemView atIndex:(NSUInteger)nIndex;

- (void)popupOverView:(QNPopOverView *)popupOverView willMoveItemAtIndex:(NSUInteger)nIndex;

- (void)popupOverView:(QNPopOverView *)popupOverView movingItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex;
// If this method hasn't been implemented, it caculate with content width. eg: translation.x / content-width
- (CGFloat)popupOverView:(QNPopOverView *)popupOverView progressMovingItemViewWithTranslation:(CGPoint)translation sizeForItemAtIndex:(NSUInteger)nIndex;

- (CATransform3D)popupOverView:(QNPopOverView *)popupOverView itemViewTransformForTranslation:(CGPoint)translation defaultTransform:(CATransform3D)transform;
- (CATransform3D)popupOverView:(QNPopOverView *)popupOverView itemViewTransformOnDirection:(QNPopOverViewAnimationDirection)direction defaultTransform:(CATransform3D)transform;

- (void)popupOverView:(QNPopOverView *)popupOverView didMoveItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex;

- (BOOL)popupOverView:(QNPopOverView *)popupOverView shouldPopupOverItemView:(UIView *)itemView direction:(QNPopOverViewAnimationDirection)direction atIndex:(NSUInteger)nIndex;
- (void)popupOverView:(QNPopOverView *)popupOverView didPopupOverItemViewOnDirection:(QNPopOverViewAnimationDirection)direction atIndex:(NSUInteger)nIndex;

@end

@protocol QNPopOverViewDataSource <NSObject>

@required
- (UIView *)popupOverView:(QNPopOverView *)popupOverView viewForItemAtIndex:(NSUInteger)nIndex reusingView:(UIView *)view;

- (NSInteger)numberOfItemsInPopupOverViewView:(QNPopOverView *)popupOverView;

- (NSInteger)numberOfVisibleItemsInPopupOverViewView:(QNPopOverView *)popupOverView;

@optional
- (BOOL)popupOverView:(QNPopOverView *)popupOverView canMoveItemViewAtIndex:(NSUInteger)nIndex;

@end


@interface QNPopOverView : UIView

@property (nonatomic, assign) id<QNPopOverViewDelegate> delegate;
@property (nonatomic, assign) id<QNPopOverViewDataSource> dataSource;
@property (nonatomic, assign) QNPopOverViewAnimationDirection allowDirections;
@property (nonatomic, assign) QNPopOverViewAnimationDirection allowBackToFront;
@property (nonatomic, strong, readonly) NSArray *visibleItemViews;
@property (nonatomic, assign) CGSize maxTranslation;        // Default is half of size;
@property (nonatomic, assign) CGFloat itemViewRotateAngle;         // Default is 10/180.f * M_PI
@property (nonatomic, assign, readonly) NSUInteger numberOfVisibleItemViews; // Default is 3.
@property (nonatomic, assign, readonly) NSUInteger numberOfItemViews;
@property (nonatomic, assign, readonly) NSUInteger currentItemIndex;

- (void)reloadData;
- (QNPopOverViewAnimationDirection)directionAtTranslation:(CGPoint)translation;
- (void)removeItemAtIndex:(NSUInteger)nIndex onDirection:(QNPopOverViewAnimationDirection)direction animated:(BOOL)animated;
- (void)insertItemAtIndex:(NSUInteger)nIndex animated:(BOOL)animated;
- (BOOL)popOverTopItemViewOnDirection:(QNPopOverViewAnimationDirection)direction animated:(BOOL)animated;

@end
