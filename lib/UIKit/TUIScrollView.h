/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TUIView.h"
#import "TUIGeometry.h"

typedef enum TUIScrollViewIndicatorStyle : NSUInteger {
  /** Dark scroll indicator style suitable for light background */
  TUIScrollViewIndicatorStyleDark,
  /** Light scroll indicator style suitable for dark backgrounds */
  TUIScrollViewIndicatorStyleLight,
  /** Dark scroll indicator with a light border style suitable for all backgrounds */
  TUIScrollViewIndicatorStyleDefault
} TUIScrollViewIndicatorStyle;

typedef enum TUIScrollViewIndicatorVisibility : NSUInteger {
  /** Never show scrollers */
  TUIScrollViewIndicatorVisibleNever,
  /** Show scrollers only during an animated scroll (not particularly useful yet) */
  TUIScrollViewIndicatorVisibleWhenScrolling,
  /** Show scrollers only when the mouse is inside the scroll view */
  TUIScrollViewIndicatorVisibleWhenMouseInside,
  /** Always show scrollers */
  TUIScrollViewIndicatorVisibleAlways,
  /** Default scroller visibility (always) */
  TUIScrollViewIndicatorVisibleDefault = TUIScrollViewIndicatorVisibleAlways
} TUIScrollViewIndicatorVisibility;

typedef enum TUIScrollViewIndicator : NSUInteger {
  TUIScrollViewIndicatorVertical,
  TUIScrollViewIndicatorHorizontal,
} TUIScrollViewIndicator;

@protocol TUIScrollViewDelegate;

@class TUIScroller;

/**
 
 Bouncing is enabled on 10.7+ or if ForceEnableScrollBouncing defaults = YES
 (Only tested with vertical bouncing)
 
 The physics are different than AppKit on 10.7.  Namely:
 
 1. During a rubber band (finger down, pulling outside the allowed bounds)
 the rubber-band-force (force keeping it from pulling too far) isn't a
 fixed multiplier of the offset (iOS and 10.7 use 0.5x).  Rather
 it's exponential, so the harder you pull the stronger it tugs.
 2. Again, during a rubber band (fingers down): if you push back the other way
 the rubber band doesn't fight you.  On iOS the this behavior makes 
 sense because you want your finger to be tracking the same spot
 if you ever return to an in-bounds case.  But there isn't a 1:1 mental
 mapping between your two fingers on the trackpad and the reflected
 scroll offset on screen in the case of the Mac.  This way feels a little
 less like the scroll view is *fighting* you if you ever change your mind
 and want to scroll the opposite way if you're currently in a "pull" state.
 
 */

@interface TUIScrollView : TUIView
{
  CGPoint         _unroundedContentOffset;
  CGSize          _contentSize;
  CGSize          resizeKnobSize;
  TUIEdgeInsets   _contentInset;
	
	__unsafe_unretained id _delegate;
	
	CVDisplayLinkRef displayLink;
	CGPoint destinationOffset;
	CGPoint unfixedContentOffset;
	
	float decelerationRate;
	
	struct {
		float dx;
		float dy;
		CFAbsoluteTime t;
	} _lastScroll;
	
	struct {
		float vx;
		float vy;
		CFAbsoluteTime t;
		BOOL throwing;
	} _throw;
	
	struct {
		float x;
		float y;
		float vx;
		float vy;
		CFAbsoluteTime t;
		BOOL bouncing;
	} _bounce;
	
  struct {
    float x;
    float y;
    BOOL  xPulling;
    BOOL  yPulling;
  } _pull;
	
	CGPoint  _dragScrollLocation;
	
	BOOL x;
	
	struct {
		unsigned didChangeContentInset:1;
		unsigned bounceEnabled:1;
		unsigned alwaysBounceVertical:1;
		unsigned alwaysBounceHorizontal:1;
		unsigned mouseInside:1;
		unsigned mouseDownInScroller:1;
		unsigned ignoreNextScrollPhaseNormal_10_7:1;
		unsigned gestureBegan:1;
		unsigned touchesBegan:1;
		unsigned animationMode:2;
		unsigned scrollDisabled:1;
		unsigned scrollIndicatorStyle:2;
		unsigned verticalScrollIndicatorVisibility:2;
		unsigned horizontalScrollIndicatorVisibility:2;
		unsigned verticalScrollIndicatorShowing:1;
		unsigned horizontalScrollIndicatorShowing:1;
		unsigned verticalScrollIndicatorExpanded:1;
		unsigned horizontalScrollIndicatorExpanded:1;
		unsigned delegateScrollViewDidScroll:1;
		unsigned delegateScrollViewWillBeginDragging:1;
		unsigned delegateScrollViewDidEndDragging:1;
		unsigned delegateScrollViewDidEndDecelerating:1;
		unsigned delegateScrollViewWillShowScrollIndicator:1;
		unsigned delegateScrollViewDidShowScrollIndicator:1;
		unsigned delegateScrollViewWillHideScrollIndicator:1;
		unsigned delegateScrollViewDidHideScrollIndicator:1;
	} _scrollViewFlags;
}

@property (nonatomic) CGPoint contentOffset;
@property (nonatomic) CGSize contentSize;
@property (nonatomic) BOOL bounces;
@property (nonatomic) BOOL alwaysBounceVertical;
@property (nonatomic) BOOL alwaysBounceHorizontal;
@property (nonatomic) CGSize resizeKnobSize;
@property (nonatomic) TUIEdgeInsets contentInset;
@property (nonatomic, unsafe_unretained) id<TUIScrollViewDelegate> delegate;
@property (nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;
@property (nonatomic) TUIScrollViewIndicatorVisibility horizontalScrollIndicatorVisibility;
@property (nonatomic) TUIScrollViewIndicatorVisibility verticalScrollIndicatorVisibility;
@property (readonly, nonatomic) BOOL verticalScrollIndicatorShowing;
@property (readonly, nonatomic) BOOL horizontalScrollIndicatorShowing;
@property (nonatomic) TUIScrollViewIndicatorStyle scrollIndicatorStyle;
@property (nonatomic) float decelerationRate;

@property (nonatomic, readonly) CGRect visibleRect;
@property (nonatomic, readonly) TUIEdgeInsets scrollIndicatorInsets;

@property (nonatomic, strong, readonly) TUIScroller *verticalScroller;
@property (nonatomic, strong, readonly) TUIScroller *horizontalScroller;

@property (nonatomic, readonly) CGPoint pullOffset;
@property (nonatomic, readonly) CGPoint bounceOffset;

@property (nonatomic, readonly, getter=isTracking) BOOL tracking;
@property (nonatomic, readonly, getter=isDragging) BOOL dragging;
@property (nonatomic, readonly, getter=isBouncing) BOOL bouncing;
@property (nonatomic, readonly, getter=isDecelerating) BOOL decelerating;
@property (nonatomic, readonly, getter=isScrollingToTop) BOOL scrollingToTop;

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;
- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated;
- (void)scrollToTopAnimated:(BOOL)animated;
- (void)scrollToBottomAnimated:(BOOL)animated;

- (void)beginContinuousScrollForDragAtPoint:(CGPoint)dragLocation animated:(BOOL)animated;
- (void)endContinuousScrollAnimated:(BOOL)animated;

- (void)flashScrollIndicators;
- (void)stopThrowing;

@end

@protocol TUIScrollViewDelegate <NSObject>

@optional

- (void)scrollViewDidScroll:(TUIScrollView *)scrollView;
- (void)scrollViewWillBeginDragging:(TUIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(TUIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(TUIScrollView *)scrollView;

- (void)scrollView:(TUIScrollView *)scrollView willShowScrollIndicator:(TUIScrollViewIndicator)indicator;
- (void)scrollView:(TUIScrollView *)scrollView didShowScrollIndicator:(TUIScrollViewIndicator)indicator;
- (void)scrollView:(TUIScrollView *)scrollView willHideScrollIndicator:(TUIScrollViewIndicator)indicator;
- (void)scrollView:(TUIScrollView *)scrollView didHideScrollIndicator:(TUIScrollViewIndicator)indicator;

@end
