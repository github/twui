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

#import "TUIActivityIndicatorView.h"
#import "TUILayoutConstraint.h"
#import "TUICGAdditions.h"

static TUIActivityIndicatorViewStyle const TUIActivityIndicatorDefaultStyle = TUIActivityIndicatorViewStyleGray;
static CGRect const TUIActivityIndicatorDefaultFrame = {
	.size.width = 32,
	.size.height = 32
};

static CGFloat const TUIActivityIndicatorDefaultToothCount = 12.0f;
static CGFloat const TUIActivityIndicatorDefaultToothWidth = 2.0f;

@interface TUIActivityIndicatorView ()

@property (nonatomic, readonly) TUIView *proxyIndicator;

@property (nonatomic, readwrite, getter = isAnimating) BOOL animating;

@end

@implementation TUIActivityIndicatorView

- (id)initWithFrame:(CGRect)frame activityIndicatorStyle:(TUIActivityIndicatorViewStyle)style {
	if((self = [super initWithFrame:frame])) {
		_proxyIndicator = [[TUIView alloc] initWithFrame:self.bounds];
		self.proxyIndicator.autoresizingMask = TUIViewAutoresizingFlexibleSize;
		self.proxyIndicator.backgroundColor = [NSColor clearColor];
		self.proxyIndicator.userInteractionEnabled = NO;
		self.proxyIndicator.hidden = YES;
		[self addSubview:self.proxyIndicator];
		
		self.activityIndicatorStyle = style;
		self.hidesWhenStopped = YES;
		
		__unsafe_unretained TUIActivityIndicatorView *weakSelf = self;
		self.proxyIndicator.drawRect = ^(TUIView *indicator, CGRect rect) {
			CGFloat radius = rect.size.width / 2.0f;
			NSColor *toothColor = [NSColor whiteColor];
			
			if(weakSelf.activityIndicatorStyle == TUIActivityIndicatorViewStyleGray)
				toothColor = [NSColor grayColor];
			else if(weakSelf.activityIndicatorStyle == TUIActivityIndicatorViewStyleBlack)
				toothColor = [NSColor blackColor];
			
			CGContextRef ctx = TUIGraphicsGetCurrentContext();
			CGContextSaveGState(ctx);
			CGContextTranslateCTM(ctx, radius, radius);
			CGContextScaleCTM(ctx, 1, -1);
			
			for(int toothNumber = 0; toothNumber < TUIActivityIndicatorDefaultToothCount; toothNumber++) {
				CGFloat alpha = 0.3 + ((toothNumber / TUIActivityIndicatorDefaultToothCount) * 0.7);
				[[toothColor colorWithAlphaComponent:alpha] setFill];
				
				CGContextRotateCTM(ctx, 1 / TUIActivityIndicatorDefaultToothCount * (M_PI * 2.0f));
				CGRect toothRect = CGRectMake(-TUIActivityIndicatorDefaultToothWidth / 2.0f, -radius,
											  TUIActivityIndicatorDefaultToothWidth, ceilf(radius * 0.54f));
				CGContextFillRoundRect(ctx, toothRect, TUIActivityIndicatorDefaultToothWidth / 2.0f);
			}
			
			CGContextRestoreGState(ctx);
		};
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	return [self initWithFrame:frame activityIndicatorStyle:TUIActivityIndicatorDefaultStyle];
}

- (id)initWithActivityIndicatorStyle:(TUIActivityIndicatorViewStyle)style {
	return [self initWithFrame:TUIActivityIndicatorDefaultFrame activityIndicatorStyle:style];
}

- (void)setHidesWhenStopped:(BOOL)hide {
	_hidesWhenStopped = hide;
	if(!self.animating && !hide)
		self.proxyIndicator.hidden = NO;
	else
		self.proxyIndicator.hidden = YES;
}

- (void)setActivityIndicatorStyle:(TUIActivityIndicatorViewStyle)style {
	_activityIndicatorStyle = style;
	[self refreshAnimations];
}

- (void)startAnimating {
	if(!self.animating) {
		self.proxyIndicator.hidden = NO;
		self.animating = YES;
		
		[self refreshAnimations];
	}
}

- (void)refreshAnimations {
	if(self.animating) {
		[self.proxyIndicator.layer removeAllAnimations];
		
		NSMutableArray *values = [NSMutableArray array];
		NSMutableArray *times = [NSMutableArray array];
		
		for(int i = 0; i < TUIActivityIndicatorDefaultToothCount + 1; i++)
			[values addObject:@(2.0 * (-i / TUIActivityIndicatorDefaultToothCount) * M_PI)];
		
		for(int i = 0; i < TUIActivityIndicatorDefaultToothCount + 1; i++)
			[times addObject:@(1.0 * (i / TUIActivityIndicatorDefaultToothCount))];
		
		CAKeyframeAnimation *rotate = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
		rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
		rotate.calculationMode = kCAAnimationDiscrete;
		rotate.repeatCount = HUGE_VALF;
		rotate.duration = 1.0f;
		rotate.values = values;
		rotate.keyTimes = times;
		rotate.cumulative = YES;
		
		[self.proxyIndicator.layer addAnimation:rotate forKey:nil];
	}
}

- (void)stopAnimating {
	if(self.animating) {
		if(self.hidesWhenStopped)
			self.proxyIndicator.hidden = YES;
		
		[self.proxyIndicator.layer removeAllAnimations];
		self.animating = NO;
	}
}

// Animation glitch fixes-- don't let the view lose its animations
// because we take charge of that. When the view is moved on or
// off a window or superview, refresh the animation, so it doesn't freeze.
- (void)removeAllAnimations {
	// Don't remove any animations.
}

- (void)willMoveToSuperview:(TUIView *)newSuperview {
	[self refreshAnimations];
}

- (void)willMoveToWindow:(TUINSWindow *)newWindow {
	[self refreshAnimations];
}

@end
