#import "TUIScrollView.h"
#import "TUIScroller.h"

// Required by both TUIScroller and TUIScrollView.
static NSTimeInterval const TUIScrollerFadeSpeed = 0.25f;

@interface TUIScrollView ()

+ (BOOL)requiresLegacyScrollers;
+ (BOOL)requiresSlimScrollers;
+ (BOOL)requiresExpandingScrollers;

+ (BOOL)requiresElasticSrolling;

- (void)_updateScrollers;
- (void)_updateScrollersAnimated:(BOOL)animated;

@end

@interface TUIScroller ()

- (CGFloat)updatedScrollerWidth;
- (CGFloat)updatedScrollerCornerRadius;

- (void)anchorScroller;
- (void)forceDisableExpandedScroller:(BOOL)expand;

@end