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

#import "TUIScroller.h"
#import "TUIScrollView+Private.h"

#import "TUICGAdditions.h"
#import "NSColor+TUIExtensions.h"
#import "CAAnimation+TUIExtensions.h"

static CGFloat const TUIScrollerMinimumKnobSize = 25.0f;
static CGFloat const TUIScrollerKnobInset = 1.0f;

static CGFloat const TUIScrollerDefaultWidth = 11.0f;
static CGFloat const TUIScrollerExpandedWidth = 15.0f;
static CGFloat const TUIScrollerDefaultCornerRadius = 3.5f;
static CGFloat const TUIScrollerExpandedCornerRadius = 5.5f;

static CGFloat const TUIScrollerTrackVisibleAlpha = 1.0f;
static CGFloat const TUIScrollerHiddenAlpha = 0.0f;
static CGFloat const TUIScrollerHoverAlpha = 0.5f;

static NSTimeInterval const TUIScrollerStateChangeSpeed = 0.20f;
static NSTimeInterval const TUIScrollerRefreshSpeed = 0.08f;
static NSTimeInterval const TUIScrollerFlashSpeed = 0.60f;

static NSTimeInterval const TUIScrollerDisplayDuration = 0.75f;

@interface TUIScroller () {
	struct {
		unsigned hover:1;
		unsigned active:1;
		unsigned trackingInsideKnob:1;
		unsigned scrollIndicatorStyle:2;
		unsigned flashing:1;
		unsigned forcedDisableExpand:1;
	} _scrollerFlags;
}

@property (nonatomic, assign, getter = isKnobHidden) BOOL knobHidden;
@property (nonatomic, strong) NSTimer *hideKnobTimer;

@property (nonatomic, assign) CGPoint mouseDown;
@property (nonatomic, assign) CGRect knobStartFrame;

@property (nonatomic, assign, getter = isTrackShown) BOOL trackShown;
@property (nonatomic, readonly, getter = isVertical) BOOL vertical;

- (void)_hideKnob;
- (void)_refreshKnobTimer;
- (void)_updateKnobAlphaWithSpeed:(CGFloat)speed;

@end

@implementation TUIScroller

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		_knob = [[TUIView alloc] initWithFrame:CGRectZero];
		self.knob.userInteractionEnabled = NO;
		self.knob.clipsToBounds = NO;
		
		self.knob.layer.shadowColor = [NSColor whiteColor].tui_CGColor;
		self.knob.layer.shadowOffset = CGSizeMake(0, 0);
		self.knob.layer.shadowOpacity = 1.0;
		self.knob.layer.shadowRadius = 1.0;
		
		self.scrollIndicatorStyle = TUIScrollViewIndicatorStyleDefault;
		[self addSubview:self.knob];
		[self _updateKnobAlphaWithSpeed:0.0];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(preferredScrollerStyleChanged:)
													 name:NSPreferredScrollerStyleDidChangeNotification
												   object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setHideKnobTimer:(NSTimer *)hideKnobTimer {
	if (!hideKnobTimer && _hideKnobTimer) {
		[_hideKnobTimer invalidate];
		_hideKnobTimer = nil;
	} else {
		_hideKnobTimer = hideKnobTimer;
	}
}

- (void)preferredScrollerStyleChanged:(NSNotification *)notification {
	self.hideKnobTimer = nil;
	
	if ([NSScroller preferredScrollerStyle] == NSScrollerStyleOverlay) {
		[self _hideKnob];
	} else {
		self.knobHidden = NO;
		[self _updateKnobAlphaWithSpeed:TUIScrollerStateChangeSpeed];
	}
}

- (void)_refreshKnobTimer {
	if ([NSScroller preferredScrollerStyle] != NSScrollerStyleOverlay)
		return;
	
	TUIScrollViewIndicatorVisibility visibility;
	if (self.vertical)
		visibility = self.scrollView.verticalScrollIndicatorVisibility;
	else
		visibility = self.scrollView.horizontalScrollIndicatorVisibility;
	
	if (visibility != TUIScrollViewIndicatorVisibleNever) {
		self.hideKnobTimer = nil;
		self.hideKnobTimer = [NSTimer scheduledTimerWithTimeInterval:TUIScrollerDisplayDuration
															  target:self
															selector:@selector(_hideKnob)
															userInfo:nil
															 repeats:NO];
		
		self.knobHidden = NO;
		[self _updateKnobAlphaWithSpeed:TUIScrollerRefreshSpeed];
	} else {
		self.knobHidden = YES;
		[self _updateKnobAlphaWithSpeed:TUIScrollerRefreshSpeed];
	}
}

- (void)_hideKnob {
	if (_scrollerFlags.hover || _scrollerFlags.active || self.scrollView.dragging || self.scrollView.decelerating) {
		[self _refreshKnobTimer];
		return;
	}
	
	self.hideKnobTimer = nil;
	self.knobHidden = YES;
	self.trackShown = NO;
	
	[self _updateKnobAlphaWithSpeed:TUIScrollerStateChangeSpeed];
}

- (BOOL)isVertical {
	return self.bounds.size.height > self.bounds.size.width;
}

- (BOOL)isExpanded {
	if (![TUIScrollView requiresExpandingScrollers] || _scrollerFlags.forcedDisableExpand) {
		return NO;
	} else if ([(NSWindow *)self.nsWindow isKeyWindow]) {
		return (_scrollerFlags.hover || (_scrollerFlags.active && self.knobHidden) || self.trackShown);
	} else return NO;
}

- (BOOL)isFlashing {
	return _scrollerFlags.flashing;
}

- (CGFloat)updatedScrollerWidth {
	return (self.expanded ? TUIScrollerExpandedWidth : TUIScrollerDefaultWidth) + TUIScrollerKnobInset;
}

- (CGFloat)updatedScrollerCornerRadius {
	return (self.expanded ? TUIScrollerExpandedCornerRadius : TUIScrollerDefaultCornerRadius);
}

- (void)forceDisableExpandedScroller:(BOOL)disable {
	_scrollerFlags.forcedDisableExpand = disable;
}

- (void)anchorScroller {
	
	// Adjust the anchor points so if the scroll knob expands, it
	// expands outwards left/up. Set our anchor point to match this.
	self.layer.anchorPoint = self.vertical ? CGPointMake(1.0, 0.5) : CGPointMake(0.5, 0.0);
	self.knob.layer.anchorPoint = self.vertical ? CGPointMake(1.0, 0.5) : CGPointMake(0.5, 0.0);
}

- (void)layoutSubviews {
	CGFloat oldKnobWidth;
	CGFloat knobLength = MIN(2000, [self adjustedKnobWidth]);
	CGFloat knobOffset = [self adjustedKnobOffsetForWidth:knobLength];
	
	// Calculate the proper overscroll and squish the knob by that much.
	CGFloat bounce;
	if (self.vertical)
		bounce = (self.scrollView.bounceOffset.y + self.scrollView.pullOffset.y);
	else
		bounce = (self.scrollView.bounceOffset.x + self.scrollView.pullOffset.x);
	
	// Allow the scroll indicator to "rubber band" squish if we overscroll.
	CGFloat modifier = self.vertical ? self.bounds.size.height : self.bounds.size.width;
	CGFloat pullFactor = 1.25f * (1.0f - ((modifier - knobLength) / modifier));
	
	// If we're at the base of the scroller track, don't offset the knob.
	bounce *= pullFactor;
	knobLength -= fabs(bounce);
	knobOffset += fabs(bounce) * (knobOffset == 0 ? 0 : 1);
	
	// Get the new scroller frame and set the scroller position, so
	// if we are expanding the scroller, it doesn't jump, but expands.
	CGRect frame = CGRectZero;
	if (self.vertical) {
		oldKnobWidth = self.knob.frame.size.width;
		frame = CGRectMake(TUIScrollerKnobInset, knobOffset, self.updatedScrollerWidth - TUIScrollerKnobInset, knobLength);
		frame = CGRectInset(frame, 2, 3);
		
		self.knob.layer.position = CGPointMake(CGRectGetMaxX(frame), CGRectGetMidY(frame));
	} else {
		oldKnobWidth = self.knob.frame.size.height;
		frame = CGRectMake(knobOffset, TUIScrollerKnobInset, knobLength, self.updatedScrollerWidth - TUIScrollerKnobInset);
		frame = CGRectInset(frame, 2, 2);
		
		self.knob.layer.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMinY(frame));
	}
	
	[self _refreshKnobTimer];
	
	// If the knob width has changed, don't animate it-- it may be a resize.
	// If we just un-expanded, don't animate the knob shrinking.
	CGFloat newKnobWidth = (self.vertical ? frame.size.width : frame.size.height);
	BOOL knobShrinked = !_scrollerFlags.forcedDisableExpand;
	if (self.vertical)
		knobShrinked &= self.knob.frame.size.width > frame.size.width;
	else knobShrinked &= self.knob.frame.size.height > frame.size.height;
	
	BOOL animateKnobChanges = (oldKnobWidth != newKnobWidth && !knobShrinked);
	[TUIView animateWithDuration:animateKnobChanges ? TUIScrollerFadeSpeed : 0.0f animations:^{
		self.knob.frame = frame;
		self.knob.layer.cornerRadius = self.updatedScrollerCornerRadius;
	}];
}

- (void)drawRect:(CGRect)rect {
	self.trackShown = self.expanded;
	if (!self.expanded)
		return;
	
	// TUIScrollViewIndicatorStyleLight draws a dark track underneath,
	// but the other indicator styles draw a light track.
	BOOL lightScroller = self.scrollIndicatorStyle == TUIScrollViewIndicatorStyleLight;
	NSArray *lightTrack = @[[NSColor colorWithCalibratedWhite:0.90 alpha:0.85],
							[NSColor colorWithCalibratedWhite:0.95 alpha:0.85]];
	NSArray *darkTrack = @[[NSColor colorWithCalibratedWhite:0.15 alpha:0.85],
						   [NSColor colorWithCalibratedWhite:0.20 alpha:0.85]];
	
	[[[NSGradient alloc] initWithColors:lightScroller ? darkTrack : lightTrack] drawInRect:rect angle:0];
	[[NSColor colorWithCalibratedWhite:lightScroller ? 0.25 : 0.75 alpha:0.75] set];
	NSRectFill(CGRectMake(0, 0, 1, rect.size.height));
}

- (void)flash {
	_scrollerFlags.flashing = 1;
	
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
	animation.duration = TUIScrollerFlashSpeed;
	animation.values = @[@0.5f, @0.2f, @0.0f];
	animation.tui_completionBlock = ^{
		_scrollerFlags.flashing = 0;
		[self.scrollView setNeedsLayout];
	};
	[self.knob.layer addAnimation:animation forKey:@"opacity"];
}

- (void)_updateKnobAlphaWithSpeed:(CGFloat)duration {
	[TUIView animateWithDuration:duration animations:^{
		if (self.knobHidden) {
			self.knob.alpha = TUIScrollerHiddenAlpha;
			self.alpha = TUIScrollerHiddenAlpha;
		} else {
			self.knob.alpha = TUIScrollerHoverAlpha;
			self.alpha = TUIScrollerTrackVisibleAlpha;
		}
	}];
}

- (TUIScrollViewIndicatorStyle)scrollIndicatorStyle {
	return _scrollerFlags.scrollIndicatorStyle;
}

- (void)setScrollIndicatorStyle:(TUIScrollViewIndicatorStyle)style {
	_scrollerFlags.scrollIndicatorStyle = style;
	
	switch(style) {
		case TUIScrollViewIndicatorStyleLight:
			self.knob.backgroundColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
			self.knob.layer.shadowColor = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0].tui_CGColor;
			break;
		case TUIScrollViewIndicatorStyleDark:
			self.knob.backgroundColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
			self.knob.layer.shadowColor = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0].tui_CGColor;
			break;
		default:
			self.knob.backgroundColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
			self.knob.layer.shadowColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0].tui_CGColor;
			break;
	}
	
	[TUIView animateWithDuration:TUIScrollerDisplayDuration animations:^{
		[self redraw];
	}];
}

- (void)mouseEntered:(NSEvent *)event {
	_scrollerFlags.hover = 1;
	[self _updateKnobAlphaWithSpeed:TUIScrollerRefreshSpeed];
	[self.scrollView _updateScrollersAnimated:NO];
	
	// Propogate mouse events.
	[super mouseEntered:event];
}

- (void)mouseExited:(NSEvent *)event {
	_scrollerFlags.hover = 0;
	[self _updateKnobAlphaWithSpeed:TUIScrollerStateChangeSpeed];
	[self.scrollView _updateScrollersAnimated:NO];
	
	// Propogate mouse events.
	[super mouseExited:event];
}

- (void)mouseDown:(NSEvent *)event {
	_mouseDown = [self localPointForEvent:event];
	_knobStartFrame = self.knob.frame;
	_scrollerFlags.active = 1;
	[self _updateKnobAlphaWithSpeed:TUIScrollerRefreshSpeed];
	
	// Normal knob dragging scroll.
	// We can't use hitTest because userInteractionEnabled = NO.
	if ([self.knob pointInside:[self convertPoint:_mouseDown toView:self.knob] withEvent:event]) {
		_scrollerFlags.trackingInsideKnob = 1;
	} else {
		
		// Paged scroll.
		_scrollerFlags.trackingInsideKnob = 0;
		
		CGRect visible = self.scrollView.visibleRect;
		CGPoint contentOffset = self.scrollView.contentOffset;
		
		if (self.vertical) {
			if (_mouseDown.y < _knobStartFrame.origin.y)
				contentOffset.y += visible.size.height;
			else
				contentOffset.y -= visible.size.height;
		} else {
			if (_mouseDown.x < _knobStartFrame.origin.x)
				contentOffset.x += visible.size.width;
			else
				contentOffset.x -= visible.size.width;
		}
		
		[self.scrollView setContentOffset:contentOffset animated:YES];
	}
	
	// Propogate mouse events.
	[super mouseDown:event];
}

- (void)mouseUp:(NSEvent *)event {
	_scrollerFlags.active = 0;
	[self _updateKnobAlphaWithSpeed:TUIScrollerRefreshSpeed];
	
	// Propogate mouse events.
	[super mouseUp:event];
}

- (void)mouseDragged:(NSEvent *)event {
	// Normal knob dragging.
	if (_scrollerFlags.trackingInsideKnob) {
		CGPoint p = [self localPointForEvent:event];
		CGSize diff = CGSizeMake(p.x - _mouseDown.x, p.y - _mouseDown.y);
		CGFloat proportion = [self adjustedKnobProportionForDifference:diff];
		CGFloat maxContentOffset = [self adjustedMaximumContentOffet];
		
		CGPoint scrollOffset = self.scrollView.contentOffset;
		if (self.vertical)
			scrollOffset.y = roundf(-proportion * maxContentOffset);
		else
			scrollOffset.x = roundf(-proportion * maxContentOffset);
		self.scrollView.contentOffset = scrollOffset;
	}
	// Otherwise, dragged in the knob tracking area. Ignore this.
	
	// Propogate mouse events.
	[super mouseDragged:event];
}

- (CGFloat)adjustedKnobOffsetForWidth:(CGFloat)knobLength {
	CGRect trackBounds = self.bounds;
	CGRect visible = self.scrollView.visibleRect;
	CGSize contentSize = self.scrollView.contentSize;
	
	CGFloat rangeOfMotion, maxOffset, currentOffset;
	if (self.vertical) {
		rangeOfMotion = trackBounds.size.height - knobLength;
		maxOffset = contentSize.height - visible.size.height;
		currentOffset = visible.origin.y;
	} else {
		rangeOfMotion = trackBounds.size.width - knobLength;
		maxOffset = contentSize.width - visible.size.width;
		currentOffset = visible.origin.x;
	}
	
	CGFloat offsetProportion = 1.0 - (maxOffset - currentOffset) / maxOffset;
	CGFloat knobOffset = offsetProportion * rangeOfMotion;
	
	if (isnan(knobOffset)) {
		knobOffset = 0.0f;
	} else if (self.vertical) {
		if (knobOffset + knobLength > trackBounds.size.height)
			knobOffset = trackBounds.size.height - knobLength;
		else if (knobOffset < trackBounds.origin.y)
			knobOffset = trackBounds.origin.y;
	} else {
		if (knobOffset + knobLength > trackBounds.size.width)
			knobOffset = trackBounds.size.width - knobLength;
		else if (knobOffset < trackBounds.origin.x)
			knobOffset = trackBounds.origin.x;
	}
	
	return knobOffset;
}

- (CGFloat)adjustedKnobWidth {
	CGRect trackBounds = self.bounds;
	CGRect visible = self.scrollView.visibleRect;
	CGSize contentSize = self.scrollView.contentSize;
	
	CGFloat knobLength = TUIScrollerMinimumKnobSize;
	if (self.vertical)
		knobLength = trackBounds.size.height * (visible.size.height / contentSize.height);
	else
		knobLength = trackBounds.size.width * (visible.size.width / contentSize.width);
	
	if (knobLength < TUIScrollerMinimumKnobSize)
		knobLength = TUIScrollerMinimumKnobSize;
	if (isnan(knobLength))
		knobLength = 0.0;
	
	return knobLength;
}

- (CGFloat)adjustedKnobProportionForDifference:(CGSize)diff {
	CGRect trackBounds = self.bounds;
	
	CGRect knobFrame = _knobStartFrame;
	CGFloat maxKnobOffset, knobOffset = 0.0;
	if (self.vertical) {
		knobFrame.origin.y += diff.height;
		knobOffset = knobFrame.origin.y;
		maxKnobOffset = trackBounds.size.height - knobFrame.size.height;
	} else {
		knobFrame.origin.x += diff.width;
		knobOffset = knobFrame.origin.x;
		maxKnobOffset = trackBounds.size.width - knobFrame.size.width;
	}
	
	return ((knobOffset - 1.0) / maxKnobOffset);
}

- (CGFloat)adjustedMaximumContentOffet {
	CGRect visible = self.scrollView.visibleRect;
	CGSize contentSize = self.scrollView.contentSize;
	
	if (self.vertical)
		return (contentSize.height - visible.size.height);
	else
		return (contentSize.width - visible.size.width);
}

@end
