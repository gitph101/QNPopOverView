//
//  QNPopOverView.m
//  Pods
//
//  Created by 研究院01 on 17/3/28.
//
//

#import "QNPopOverView.h"
#import "QNContainerCellView.h"

CGFloat QNPopOverViewAnimationDuration = 0.3;

CGFloat QNPopOverViewMaxVisibleItems = 30;

@interface QNPopOverView ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) NSMutableDictionary *mutableItemViews;

@property (nonatomic, strong) NSMutableSet *reusingItemViews;

@property (nonatomic, assign) NSUInteger numberOfItemViews;

@property (nonatomic, assign) NSUInteger numberOfVisibleItemViews;

@property (nonatomic, assign) CGSize itemViewSize;  // Default is content-size inseted -7;

@end


@implementation QNPopOverView

- (instancetype)init{
    if (self = [super init]) {
        [self _qn_initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self _qn_initialize];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self _qn_layoutItemViews];
}

- (void)_qn_layoutItemViews {
    
    self.itemViewSize = CGRectInset([self bounds], 7, 7).size;
    self.contentView.frame = [self bounds];
    
    // load unload item views
    [self _qn_loadUnloadItemViews];
}

#pragma mark - private

- (void)_qn_initialize{
    
    self.maxTranslation = CGSizeEqualToSize(CGSizeZero, [self bounds].size) ? CGSizeMake(100, 100) : [self bounds].size;
    self.mutableItemViews = [NSMutableDictionary dictionary];
    self.reusingItemViews = [NSMutableSet set];
    self.itemViewRotateAngle = 10 /180. * M_PI;
    self.numberOfVisibleItemViews = 3;
    self.allowBackToFront = YES;
    self.allowDirections = QNPopOverViewAnimationDirectionTop | QNPopOverViewAnimationDirectionBottom | QNPopOverViewAnimationDirectionLeft | QNPopOverViewAnimationDirectionRight;
    
    self.contentView = [UIView new];
    self.contentView.layer.masksToBounds = NO;
    
    [self addSubview:[self contentView]];
    [[self contentView] addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanGestureRecognizerChanged:)]];
}

- (void)_qn_updateLayoutForItemViews:(NSArray *)itemViews{
    // update frame for loaded container views
    [itemViews enumerateObjectsUsingBlock:^(UIView *itemView, NSUInteger nIndex, BOOL * _Nonnull stop) {
        CGSize itemViewSize = [self itemViewSizeAtIndex:nIndex];
        [self _qn_updatelayoutItemView:itemView size:itemViewSize];
        [self _qn_rotateTransformItemView:itemView atIndex:nIndex progress:0];
    }];
}

- (void)_qn_loadUnloadItemViews{
    // update number of visible items  更新可用的cellview
    [self _qn_updateNumberOfVisibleItemViews];
    
    //visible view indices
    NSMutableSet *visibleIndices = [NSMutableSet setWithCapacity:[self numberOfVisibleItemViews]];
    NSInteger translation = [self currentItemIndex];
    for (NSInteger nIndex = 0; nIndex < [self numberOfVisibleItemViews]; nIndex++) {
        [visibleIndices addObject:@([self clampedIndex:nIndex + translation])];
    }
    
    //remove offscreen views
    for (NSNumber *number in [[self mutableItemViews] allKeys]) {
        if (![visibleIndices containsObject:number]) {
            UIView *view = [self mutableItemViews][number];
            if ([number integerValue] > 0 && [number integerValue] < [self numberOfItemViews]) {
                [self queueReusingItemView:view];
            }
            [[view superview] removeFromSuperview];
            [[self mutableItemViews] removeObjectForKey:number];
        }
    }
    
    //add onscreen views
    NSMutableArray *itemViews = [NSMutableArray array];
    for (NSNumber *number in visibleIndices) {
        UIView *itemView = [self mutableItemViews][number];
        if (itemView == nil) {
            itemView = [self _qn_loadItemViewAtIndex:[number integerValue]];
        }
        [itemViews addObject:itemView];
    }
    
    // update frame for loaded container views
    [self _qn_updateLayoutForItemViews:itemViews];
}

/**
 *  load a item view into container view
 *
 *  @param nIndex index of item view
 *
 *  @return container view
 */
- (UIView *)_qn_loadItemViewAtIndex:(NSUInteger)nIndex {
    return [self _qn_loadItemViewAtIndex:nIndex withContainerView:nil];
}

/**
 *  load a item view into container view
 *
 *  @param nIndex index of item view
 *
 *  @param containerView container of item view at this index, it will create a new container view if this is nil.
 *
 *  @return container view
 */
- (UIView *)_qn_loadItemViewAtIndex:(NSUInteger)nIndex withContainerView:(UIView *)containerView{
    NSParameterAssert(nIndex >= 0 && nIndex < [self numberOfItemViews]);
    
    UIView *itemView = [[self dataSource] popupOverView:self viewForItemAtIndex:nIndex reusingView:[self dequeueReusingItemView]];
    if (!itemView){
        itemView = [[UIView alloc] init];
    }
    
    if ([[self delegate] respondsToSelector:@selector(popupOverView:willDisplayItemView:atIndex:)]) {
        [[self delegate] popupOverView:self willDisplayItemView:itemView atIndex:nIndex];
    }
    
    CGSize itemViewSize = [self itemViewSizeAtIndex:nIndex];
    if (containerView) {
        //get old item view
        UIView *oldItemView = [[containerView subviews] lastObject];
        [self queueReusingItemView:oldItemView];
        //switch views
        [oldItemView removeFromSuperview];
        [containerView addSubview:itemView];
    } else {
        containerView = [self containerView:itemView];
        [self _qn_insertSubviewWithContainerView:containerView atIndex:nIndex];
    }
    [self setItemView:itemView forIndex:nIndex];
    //set container frame
    [self _qn_updatelayoutItemView:itemView size:itemViewSize];
    
    if ([[self delegate] respondsToSelector:@selector(popupOverView:willDisplayItemView:atIndex:)]) {
        [[self delegate] popupOverView:self willDisplayItemView:itemView atIndex:nIndex];
    }
    
    return itemView;
}

- (void)_qn_insertSubviewWithContainerView:(UIView *)containerView atIndex:(NSUInteger)nIndex{
    NSArray *indexesForVisibleItemViews = [self indexesForVisibleItemViews];
    [indexesForVisibleItemViews enumerateObjectsUsingBlock:^(NSNumber *visibleIndex, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger nVisibleIndex = [visibleIndex integerValue];
        NSParameterAssert(nVisibleIndex != nIndex);
        if (nVisibleIndex > nIndex) {
            UIView *belowContainerView = [[self itemViewAtIndex:nVisibleIndex] superview];
            [[self contentView] insertSubview:containerView aboveSubview:belowContainerView];
            *stop = YES;
        }
    }];
    
    if (![containerView superview]) {
        UIView *mostBelowContainerView = [[self itemViewAtIndex:[[indexesForVisibleItemViews lastObject] integerValue]] superview];
        if (mostBelowContainerView) {
            [[self contentView] insertSubview:containerView belowSubview:mostBelowContainerView];
        } else {
            [[self contentView] addSubview:containerView];
        }
    }
}

- (void)_qn_deleteAtIndex:(NSInteger)nIndex{
    UIView *itemView = [self mutableItemViews][@(nIndex)];
    if (itemView) {
        [self queueReusingItemView:itemView];
        [[self mutableItemViews] removeObjectForKey:@(nIndex)];
        [[itemView superview] removeFromSuperview];
    }
}

- (void)_qn_removeItemViewAtIndex:(NSUInteger)nIndex {
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[[self mutableItemViews] count] - 1];
    for (NSNumber *number in [self indexesForVisibleItemViews]) {
        NSUInteger i = [number integerValue];
        if (i < nIndex) {
            newItemViews[number] = [self mutableItemViews][number];
        } else if (i > nIndex) {
            newItemViews[@(i - 1)] = [self mutableItemViews][number];
        }
    }
    self.mutableItemViews = newItemViews;
}

- (void)_qn_insertItemView:(UIView *)view atIndex:(NSUInteger)nIndex {
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[[self mutableItemViews] count] + 1];
    for (NSNumber *number in [self indexesForVisibleItemViews]) {
        NSUInteger i = [number integerValue];
        if (i < nIndex) {
            newItemViews[number] = [self mutableItemViews][number];
        } else {
            newItemViews[@(i + 1)] = [self mutableItemViews][number];
        }
    }
    if (view) {
        newItemViews[@(nIndex)] = view;
    }
    self.mutableItemViews = newItemViews;
}

- (void)_qn_restoreTransformExcludeIndex:(NSUInteger)excludeIndex animated:(BOOL)animated{
    [self _qn_restoreTransformExcludeIndex:excludeIndex animated:animated completion:nil];
}

- (void)_qn_restoreTransformExcludeIndex:(NSUInteger)excludeIndex animated:(BOOL)animated completion:(void (^)())completion{
    [self _qn_rotateTransformExcludeIndex:excludeIndex indexOffset:0 progress:0 animated:animated completion:completion];
}

- (void)_qn_rotateTransformExcludeIndex:(NSUInteger)excludeIndex progress:(CGFloat)progress animated:(BOOL)animated{
    [self _qn_rotateTransformExcludeIndex:excludeIndex progress:progress animated:animated completion:nil];
}

- (void)_qn_rotateTransformExcludeIndex:(NSUInteger)excludeIndex progress:(CGFloat)progress animated:(BOOL)animated completion:(void (^)())completion{
    [self _qn_rotateTransformExcludeIndex:excludeIndex indexOffset:0 progress:progress animated:animated completion:completion];
}

- (void)_qn_rotateTransformExcludeIndex:(NSUInteger)excludeIndex indexOffset:(NSInteger)indexOffset progress:(CGFloat)progress animated:(BOOL)animated{
    [self _qn_rotateTransformExcludeIndex:excludeIndex indexOffset:indexOffset progress:progress
                              animated:animated completion:nil];
}

- (void)_qn_rotateTransformExcludeIndex:(NSUInteger)excludeIndex indexOffset:(NSInteger)indexOffset progress:(CGFloat)progress animated:(BOOL)animated completion:(void (^)())completion{
    void (^transform)() = ^(){
        NSArray *indexesForVisibleItemViews = [self indexesForVisibleItemViews];
        NSUInteger numberOfItemViews = [self numberOfItemViews];
        NSUInteger currentIndex = [[indexesForVisibleItemViews firstObject] integerValue];
        for (NSNumber *index in indexesForVisibleItemViews) {
            if (excludeIndex != [index integerValue]) {
                UIView *itemView = [self itemViewAtIndex:[index integerValue]];
                
                NSInteger nextIndex = [index integerValue] + indexOffset;
                nextIndex = MAX(0, nextIndex);
                nextIndex = MIN(nextIndex, numberOfItemViews - 1);
                
                CGFloat angleAtIndex = [self angleAtIndex:[index integerValue] - currentIndex progress:0];
                CGFloat angleAtIndexOffset = [self angleAtIndex:nextIndex - currentIndex progress:0];
                CGFloat angle = angleAtIndex + (angleAtIndexOffset - angleAtIndex) * progress;
                
                itemView.superview.layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
            }
        }
    };
    if (animated) {
        [UIView animateWithDuration:QNPopOverViewAnimationDuration animations:transform completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    } else {
        transform();
        if (completion) {
            completion();
        }
    }
}

- (void)_qn_rotateTransformItemView:(UIView *)itemView atIndex:(NSInteger)nIndex progress:(CGFloat)progress{
    //center view
    itemView.superview.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
    
    //enable/disable interaction
    itemView.superview.userInteractionEnabled = (nIndex == self.currentItemIndex);
    
    //account for retina
    itemView.superview.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    //return back
    itemView.superview.layer.autoreverses = NO;
    //calculate transform
    CATransform3D transform = [self transformAtIndex:nIndex progress:progress];
    
    //transform view
    itemView.superview.layer.transform = transform;
}

- (void)_qn_restoreLayoutItemView:(UIView *)itemView animated:(BOOL)animated{
    if (animated) {
        [UIView animateWithDuration:QNPopOverViewAnimationDuration animations:^{
            itemView.superview.layer.transform = CATransform3DIdentity;
        }];
    } else {
        itemView.superview.layer.transform = CATransform3DIdentity;
    }
}

- (void)_qn_updateNumberOfVisibleItemViews{
    self.numberOfVisibleItemViews = MIN(QNPopOverViewMaxVisibleItems, [self numberOfVisibleItemViews]);
    //协议方法再赋值
    if ([[self dataSource] respondsToSelector:@selector(numberOfVisibleItemsInPopupOverViewView:)]) {
        self.numberOfVisibleItemViews = [[self dataSource] numberOfVisibleItemsInPopupOverViewView:self];
    }
    self.numberOfVisibleItemViews = MAX(0, MIN([self numberOfVisibleItemViews], [self numberOfItemViews] - [self currentItemIndex]));
}

- (void)_qn_updatelayoutItemView:(UIView *)itemView size:(CGSize)size{
    //set container frame
    CGRect bounds = [self bounds];
    itemView.superview.layer.transform = CATransform3DIdentity;
    itemView.superview.frame = CGRectMake((CGRectGetWidth(bounds) - size.width) / 2., (CGRectGetHeight(bounds) - size.height) / 2., size.width, size.height);
    itemView.frame = CGRectMake(0, 0, size.width, size.height);
}

- (void)_qn_willMoveCurrentItemViewAtIndex:(NSUInteger)nIndex{
    if ([[self delegate] respondsToSelector:@selector(popupOverView:willMoveItemAtIndex:)]) {
        [[self delegate] popupOverView:self willMoveItemAtIndex:nIndex];
    }
}

- (void)_qn_movingCurrentItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex{
    if ([[self delegate] respondsToSelector:@selector(popupOverView:movingItemViewWithTranslation:atIndex:)]) {
        [[self delegate] popupOverView:self movingItemViewWithTranslation:translation atIndex:nIndex];
    }
}

- (void)_qn_didMoveCurrentItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex{
    if ([[self delegate] respondsToSelector:@selector(popupOverView:didMoveItemViewWithTranslation:atIndex:)]) {
        [[self delegate] popupOverView:self didMoveItemViewWithTranslation:translation atIndex:nIndex];
    }
}

- (BOOL)_qn_canMoveCurrentItemViewAtIndex:(NSUInteger)nIndex{
    if ([[self dataSource] respondsToSelector:@selector(popupOverView:canMoveItemViewAtIndex:)]) {
        return [[self dataSource] popupOverView:self canMoveItemViewAtIndex:nIndex];
    }
    return YES;
}

#pragma mark - accessor

- (CATransform3D)_qn_transformForMoveOutItemView:(UIView *)itemView onDirection:(QNPopOverViewAnimationDirection)direction{
    
    return [self _qn_transformForMoveOutItemView:itemView translation:CGPointZero direction:direction];
}

- (CATransform3D)_qn_transformForMoveOutItemView:(UIView *)itemView translation:(CGPoint)translation direction:(QNPopOverViewAnimationDirection)direction{
    
    CATransform3D transform = CATransform3DIdentity;
    
    if ([[self delegate] respondsToSelector:@selector(popupOverView:itemViewTransformOnDirection:defaultTransform:)]) {
        transform = [[self delegate] popupOverView:self itemViewTransformOnDirection:direction defaultTransform:transform];
    }
    
    translation = [self defaultTransformAtTranslation:translation direction:direction];
    
    transform = CATransform3DTranslate(transform, translation.x, translation.y, 0);
    
    return transform;
}

- (CATransform3D)_qn_transformForMovingItemView:(UIView *)itemView atTranslation:(CGPoint)translation{
    CATransform3D transform = CATransform3DTranslate(CATransform3DIdentity, translation.x, translation.y, 0);
    
    if ([[self delegate] respondsToSelector:@selector(popupOverView:itemViewTransformForTranslation:defaultTransform:)]) {
        return [[self delegate] popupOverView:self itemViewTransformForTranslation:translation defaultTransform:transform];
    }
    return transform;
}

- (CGFloat)_qn_progressForMovingCurrentItemViewWithTranslation:(CGPoint)translation location:(CGPoint)location atIndex:(NSUInteger)nIndex;{
    if ([[self delegate] respondsToSelector:@selector(popupOverView:progressMovingItemViewWithTranslation:sizeForItemAtIndex:)]) {
        return [[self delegate] popupOverView:self progressMovingItemViewWithTranslation:translation sizeForItemAtIndex:nIndex];
    }
    return [self _qn_defaultProgressWithTranslation:translation];
}

/**
  计算移动距离
 */
- (CGFloat)_qn_defaultProgressWithTranslation:(CGPoint)translation{
    
    CGFloat distance = sqrt(powf(translation.x, 2) + powf(translation.y, 2)); //平方根
    CGFloat maxDistance = sqrt(powf([self maxTranslation].width / 2., 2) + powf([self maxTranslation].width / 2., 2));
    if (maxDistance <= 0) {
        return 1.f;
    }
    return MIN(distance / maxDistance, 1);
}

- (CGPoint)defaultTransformAtTranslation:(CGPoint)translation direction:(QNPopOverViewAnimationDirection)direction{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    
    CGPoint toTranslation = CGPointZero;
    CGSize  windowSize = [window bounds].size;
    CGPoint centerInWindow = [[self contentView] convertPoint:[[self contentView] center] toView:window];
    
    CGFloat scale = translation.y == 0 ? ((windowSize.width - centerInWindow.x) / (windowSize.height - centerInWindow.y)) : fabs(translation.x / translation.y);
    
    if (direction & QNPopOverViewAnimationDirectionLeft && [self allowDirections] & QNPopOverViewAnimationDirectionLeft) {
        toTranslation.x = -(windowSize.width - centerInWindow.x);
    }
    if (direction & QNPopOverViewAnimationDirectionRight && [self allowDirections] & QNPopOverViewAnimationDirectionRight) {
        toTranslation.x = (windowSize.width - centerInWindow.x);
    }
    
    if (direction & QNPopOverViewAnimationDirectionTop && [self allowDirections] & QNPopOverViewAnimationDirectionTop) {
        toTranslation.y = -fabs(MAX(1, fabs(toTranslation.x)) / scale);
    }
    if (direction & QNPopOverViewAnimationDirectionBottom && [self allowDirections] & QNPopOverViewAnimationDirectionBottom) {
        toTranslation.y = fabs(MAX(1, fabs(toTranslation.x)) / scale);
    }
    return toTranslation;
}

/**
  根据位置判断方向
 */
- (QNPopOverViewAnimationDirection)directionAtTranslation:(CGPoint)translation{
    QNPopOverViewAnimationDirection direction = QNPopOverViewAnimationDirectionNone;
    if (translation.x > 5) {
        direction |= QNPopOverViewAnimationDirectionRight;
    } else if (translation.x < -5) {
        direction |= QNPopOverViewAnimationDirectionLeft;
    }
    if (translation.y > 5) {
        direction |= QNPopOverViewAnimationDirectionBottom;
    } else if (translation.y < -5) {
        direction |= QNPopOverViewAnimationDirectionTop;
    }
    return direction;
}

- (UIView *)containerView:(UIView *)itemView{
    UIView *containerView = [QNContainerCellView new];
    [containerView addSubview:itemView];
    return containerView;
}

- (NSArray *)indexesForVisibleItemViews {
    return [[[self mutableItemViews] allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)visibleItemViews{
    return [[self mutableItemViews] objectsForKeys:[self indexesForVisibleItemViews] notFoundMarker:[NSNull null]];
}

- (UIView *)itemViewAtIndex:(NSUInteger)nIndex {
    return [self mutableItemViews][@(nIndex)];
}

- (NSUInteger)currentItemIndex{
    return [[[self indexesForVisibleItemViews] firstObject] integerValue];
}

- (UIView *)currentItemView {
    return [self itemViewAtIndex:self.currentItemIndex];
}

- (NSUInteger)indexOfItemView:(UIView *)itemView {
    NSUInteger nIndex = [[[self mutableItemViews] allValues] indexOfObject:itemView];
    if (nIndex != NSNotFound) {
        return [[[self mutableItemViews] allKeys][nIndex] integerValue];
    }
    return NSNotFound;
}

- (NSUInteger)indexOfItemViewOrSubview:(UIView *)view {
    NSUInteger nIndex = [self indexOfItemView:view];
    if (nIndex == NSNotFound && view != nil && view != self) {
        return [self indexOfItemViewOrSubview:view.superview];
    }
    return nIndex;
}

- (void)setItemView:(UIView *)itemView forIndex:(NSUInteger)nIndex {
    [self mutableItemViews][@(nIndex)] = itemView;
}

- (UIView *)dequeueReusingItemView {
    UIView *view = [[self reusingItemViews] anyObject];
    if (view) {
        [[self reusingItemViews] removeObject:view];
    }
    return view;
}

- (void)queueReusingItemView:(UIView *)reusingItemView {
    NSParameterAssert(reusingItemView);
    [[self reusingItemViews] addObject:reusingItemView];
}

- (NSUInteger)clampedIndex:(NSUInteger)index {
    if ([self numberOfItemViews] == 0) {
        return -1;
    } else {
        return MIN(MAX(0, index), MAX(0, [self numberOfItemViews] - 1));
    }
}

- (QNPopOverViewAnimationDirection)adjustDirection:(QNPopOverViewAnimationDirection)direction{
    if (direction == QNPopOverViewAnimationDirectionRandom) {
        return 1 << (arc4random() % 4) | 1 << (arc4random() % 4);
    }
    return direction;
}

/**
    adjust
 */
- (CGPoint)adjustTranslation:(CGPoint)translation;{
    if (![self allowDirections] & QNPopOverViewAnimationDirectionLeft) {
        translation.x = MAX(translation.x, 0);
    }
    if (!([self allowDirections] & QNPopOverViewAnimationDirectionRight)) {
        translation.x = MIN(translation.x, 0);
    }
    if (!([self allowDirections] & QNPopOverViewAnimationDirectionTop)) {
        translation.y = MAX(translation.y, 0);
    }
    if (!([self allowDirections] & QNPopOverViewAnimationDirectionBottom)) {
        translation.y = MIN(translation.y, 0);
    }
    return translation;
}

- (CGSize)itemViewSizeAtIndex:(NSUInteger)nIndex{
    CGSize itemViewSize = [self itemViewSize];
    if ([[self delegate] respondsToSelector:@selector(popupOverView:sizeForItemAtIndex:)]) {
        itemViewSize = [[self delegate] popupOverView:self sizeForItemAtIndex:nIndex];
    }
    return itemViewSize;
}

- (CATransform3D)transformAtIndex:(NSUInteger)nIndex progress:(CGFloat)progress{
    CGFloat angle = [self angleAtIndex:nIndex progress:progress];
    return CATransform3DMakeRotation(angle, 0, 0, 1);
}

- (CGFloat)angleAtIndex:(NSUInteger)nIndex progress:(CGFloat)progress{
    progress = MIN(progress, 1);
    progress = MAX(progress, 0);
    
    NSUInteger number = nIndex % [self numberOfVisibleItemViews];
    
    return pow(-1, number % 2 + 1) * ((number + 1) / 2) * [self itemViewRotateAngle] * (1 - progress);
}

#pragma mark - public

- (void)reloadData{
    //Remove old views
    for (UIView *view in [self visibleItemViews]){
        [[view superview] removeFromSuperview];
    }
    [[self mutableItemViews] removeAllObjects];
    [[self reusingItemViews] removeAllObjects];
    //Bail out if not set up yet
    if (![self dataSource]){
        return;
    }
    //Get number of items and placeholders
    self.numberOfItemViews = [[self dataSource] numberOfItemsInPopupOverViewView:self];
    
    //layout views
    [self setNeedsLayout];
}

- (BOOL)popOverTopItemViewOnDirection:(QNPopOverViewAnimationDirection)direction animated:(BOOL)animated;{
    
    return [self popOverTopItemViewAtTranslation:CGPointZero direction:direction animated:animated];
}

/**
  des
 */
- (BOOL)popOverTopItemViewAtTranslation:(CGPoint)translation direction:(QNPopOverViewAnimationDirection)direction  animated:(BOOL)animated;{
    NSInteger currentIndex = [self currentItemIndex];
    UIView *itemView = [self itemViewAtIndex:currentIndex];
    BOOL shouldPopupOver = YES;
    if ([[self delegate] respondsToSelector:@selector(popupOverView:shouldPopupOverItemView:direction:atIndex:)]) {
        shouldPopupOver = [[self delegate] popupOverView:self shouldPopupOverItemView:itemView direction:direction atIndex:currentIndex];
    }
    if (!shouldPopupOver) {
        [self _qn_restoreTransformExcludeIndex:NSNotFound animated:YES];
        return NO;
    }
    BOOL allowBackToFront = [self allowBackToFront];
    void (^completion)() = ^{
        [self _qn_deleteAtIndex:currentIndex];
        if ([self numberOfItemViews] - currentIndex - 1 > 0 || allowBackToFront) {
            [self _qn_loadUnloadItemViews];
            [self _qn_restoreTransformExcludeIndex:NSNotFound animated:NO];
        }
        if ([[self delegate] respondsToSelector:@selector(popupOverView:didPopupOverItemViewOnDirection:atIndex:)]) {
            [[self delegate] popupOverView:self didPopupOverItemViewOnDirection:direction atIndex:currentIndex];
        }
    };
    if (animated) {
        self.userInteractionEnabled = NO;
        //        itemView.superview.View.transform = CATransform3DMakeTranslation(translation.x, translation.y, 0);
        CATransform3D transform = [self _qn_transformForMoveOutItemView:itemView translation:translation direction:direction];
        [UIView animateWithDuration:QNPopOverViewAnimationDuration animations:^{
            itemView.superview.alpha = 0;
            itemView.superview.layer.transform = transform;
        } completion:^(BOOL finished) {
            completion();
            self.userInteractionEnabled = YES;
        }];
    } else {
        completion();
    }
    return YES;
}

- (void)removeItemAtIndex:(NSUInteger)nIndex onDirection:(QNPopOverViewAnimationDirection)direction animated:(BOOL)animated;{
    
    direction = [self adjustDirection:direction];
    nIndex = [self clampedIndex:nIndex];
    UIView *itemView = [self itemViewAtIndex:nIndex];
    
    if (animated) {
        self.userInteractionEnabled = NO;
        CATransform3D transform = [self _qn_transformForMoveOutItemView:itemView onDirection:direction];
        [UIView animateWithDuration:QNPopOverViewAnimationDuration animations:^{
            itemView.superview.layer.transform = transform;
        } completion:^(BOOL finished) {
            self.numberOfItemViews--;
            
            [self _qn_deleteAtIndex:nIndex];
            [self _qn_removeItemViewAtIndex:nIndex];
            [self _qn_loadUnloadItemViews];
            [self _qn_restoreTransformExcludeIndex:NSNotFound animated:YES];
            self.userInteractionEnabled = YES;
        }];
    } else {
        
        self.numberOfItemViews--;
        [self _qn_deleteAtIndex:nIndex];
        [self _qn_removeItemViewAtIndex:nIndex];
        [self _qn_loadUnloadItemViews];
        [self _qn_restoreTransformExcludeIndex:NSNotFound animated:NO];
    }
}

- (void)insertItemAtIndex:(NSUInteger)nIndex animated:(BOOL)animated {
    self.numberOfItemViews++;
    nIndex = [self clampedIndex:nIndex];
    [self _qn_insertItemView:nil atIndex:nIndex];
    [self _qn_loadItemViewAtIndex:nIndex];
    
    if (animated) {
        self.userInteractionEnabled = NO;
        [UIView animateWithDuration:QNPopOverViewAnimationDuration animations:^{
            [self _qn_restoreTransformExcludeIndex:NSNotFound animated:NO];
        } completion:^(BOOL finished) {
            [self _qn_loadUnloadItemViews];
            self.userInteractionEnabled = YES;
        }];
    } else {
        [self _qn_restoreTransformExcludeIndex:NSNotFound animated:NO];
        [self _qn_loadUnloadItemViews];
    }
}

- (void)reloadItemAtIndex:(NSUInteger)nIndex animated:(BOOL)animated {
    //get container view
    UIView *containerView = [[self itemViewAtIndex:nIndex] superview];
    if (containerView) {
        if (animated) {
            //fade transition
            CATransition *transition = [CATransition animation];
            transition.duration = QNPopOverViewAnimationDuration;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
            [containerView.layer addAnimation:transition forKey:nil];
        }
        //reload view
        [self _qn_loadItemViewAtIndex:nIndex withContainerView:containerView];
    } else {
        [self _qn_loadItemViewAtIndex:nIndex withContainerView:nil];
        [self _qn_restoreTransformExcludeIndex:NSNotFound animated:YES];
        [self _qn_loadUnloadItemViews];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;{
    return [self _qn_canMoveCurrentItemViewAtIndex:[self currentItemIndex]];
}

#pragma mark - actions

- (IBAction)didPanGestureRecognizerChanged:(UIPanGestureRecognizer *)panGestureRecognizer{
    NSUInteger currentIndex = [self currentItemIndex];
    UIView *itemView = [self itemViewAtIndex:currentIndex];
    if (!itemView) {
        return;
    }
    CGPoint location = [panGestureRecognizer locationInView:self];
    CGPoint translation = [panGestureRecognizer translationInView:self];
    CGPoint limitTranslation = [self adjustTranslation:translation];
    
    switch ([panGestureRecognizer state]) {
        case UIGestureRecognizerStateBegan:
            [self _qn_willMoveCurrentItemViewAtIndex:currentIndex];
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat progress = [self _qn_progressForMovingCurrentItemViewWithTranslation:limitTranslation location:location atIndex:currentIndex];
            
            [self _qn_rotateTransformExcludeIndex:currentIndex indexOffset:-1 progress:progress animated:NO];
            
            itemView.superview.layer.transform = [self _qn_transformForMovingItemView:itemView atTranslation:limitTranslation];
            
            [self _qn_movingCurrentItemViewWithTranslation:limitTranslation atIndex:currentIndex];
        }   break;
        case UIGestureRecognizerStateEnded:
        {
            if ([self _qn_defaultProgressWithTranslation:limitTranslation] > 0.5) {
                [self popOverTopItemViewAtTranslation:translation direction:[self directionAtTranslation:limitTranslation] animated:YES];
                
            } else {
                self.userInteractionEnabled = NO;
                [self _qn_restoreTransformExcludeIndex:NSNotFound animated:YES completion:^{
                    self.userInteractionEnabled = YES;
                }];
            }
            [self _qn_didMoveCurrentItemViewWithTranslation:limitTranslation atIndex:currentIndex];
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            self.userInteractionEnabled = NO;
            [self _qn_restoreTransformExcludeIndex:NSNotFound animated:YES completion:^{
                self.userInteractionEnabled = YES;
            }];
        }
            break;
        default:
            break;
    }
}


@end
