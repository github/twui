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
#import "TUICAAction.h"

@class TUIViewAnimation;

static NSMutableArray *TUIViewAnimationStack;
static TUIViewAnimation *TUIViewCurrentAnimation;
static BOOL TUIViewAnimationsEnabled = YES;
static BOOL TUIViewAnimateContents = NO;

static CGFloat TUIViewAnimationSlowMotionMultiplier (void) {
	if (([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSShiftKeyMask) {
		return 5.0;
	} else {
		return 1.0;
	}
}

@interface TUIViewAnimation : NSObject <CAAction>

@property (nonatomic, assign) void *context;
@property (nonatomic, copy) NSString *animationID;

@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, assign) SEL animationWillStartSelector;
@property (nonatomic, assign) SEL animationDidStopSelector;
@property (nonatomic, copy) void (^animationCompletionBlock)(BOOL finished);

@property (nonatomic, strong, readonly) CABasicAnimation *basicAnimation;

@end

@implementation TUIViewAnimation

+ (void)initialize {
	if (self != [TUIViewAnimation class]) return;

	TUIViewAnimationStack = [NSMutableArray array];
}

- (id)init {
	self = [super init];
	if (self == nil) return nil;

	_basicAnimation = [CABasicAnimation animation];
	return self;
}

- (void)dealloc {
	if (self.animationCompletionBlock == nil) return;

	self.animationCompletionBlock(NO);
	if (self.animationCompletionBlock != nil) NSLog(@"Error: animationCompletionBlock didn't complete!");
}

- (void)runActionForKey:(NSString *)event object:(id)anObject arguments:(NSDictionary *)dict {
	CAAnimation *animation = [self.basicAnimation copy];
	animation.delegate = self;
	[animation runActionForKey:event object:anObject arguments:dict];
}

- (void)animationDidStart:(CAAnimation *)anim {
	if (self.delegate == nil || self.animationWillStartSelector == NULL) return;

	void (*animationWillStartIMP)(id, SEL, NSString *, void *) = (__typeof__(animationWillStartIMP))[(id)self.delegate methodForSelector:self.animationWillStartSelector];
	animationWillStartIMP(self.delegate, self.animationWillStartSelector, self.animationID, self.context);

	// only fire this once
	self.animationWillStartSelector = NULL;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	if (self.delegate != nil && self.animationDidStopSelector != NULL) {
		void (*animationDidStopIMP)(id, SEL, NSString *, NSNumber *, void *) = (__typeof__(animationDidStopIMP))[(id)self.delegate methodForSelector:self.animationDidStopSelector];
		animationDidStopIMP(self.delegate, self.animationDidStopSelector, self.animationID, @(flag), self.context);

		// only fire this once
		self.animationDidStopSelector = NULL;
	} else if (self.animationCompletionBlock) {
		self.animationCompletionBlock(flag);

		// only fire this once
		self.animationCompletionBlock = nil;
	}
}

@end

@implementation TUIView (TUIViewAnimation)

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations {
	[self animateWithDuration:duration animations:animations completion:NULL];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
	[self beginAnimations:nil context:NULL];
	self.animationDuration = duration;

	TUIViewCurrentAnimation.animationCompletionBlock = completion;
	animations();

	[self commitAnimations];
}

+ (void)beginAnimations:(NSString *)animationID context:(void *)context {
	[NSAnimationContext beginGrouping];

	TUIViewCurrentAnimation = [[TUIViewAnimation alloc] init];
	TUIViewCurrentAnimation.context = context;
	TUIViewCurrentAnimation.animationID = animationID;
	[TUIViewAnimationStack addObject:TUIViewCurrentAnimation];
	
	// setup defaults
	self.animationDuration = 0.25;
	self.animationCurve = TUIViewAnimationCurveEaseInOut;
}

+ (void)commitAnimations {
	[TUIViewAnimationStack removeLastObject];
	TUIViewCurrentAnimation = TUIViewAnimationStack.lastObject;

	[NSAnimationContext endGrouping];
}

+ (BOOL)isInAnimationContext {
	return TUIViewCurrentAnimation != nil;
}

+ (void)setAnimationDelegate:(id)delegate {
	TUIViewCurrentAnimation.delegate = delegate;
}

+ (void)setAnimationWillStartSelector:(SEL)selector {
	TUIViewCurrentAnimation.animationWillStartSelector = selector;
}

+ (void)setAnimationDidStopSelector:(SEL)selector {
	TUIViewCurrentAnimation.animationDidStopSelector = selector;
}

+ (void)setAnimationDuration:(NSTimeInterval)duration {
	duration *= TUIViewAnimationSlowMotionMultiplier();
	TUIViewCurrentAnimation.basicAnimation.duration = duration;
	[NSAnimationContext currentContext].duration = duration;
}

+ (void)setAnimationDelay:(NSTimeInterval)delay {
	TUIViewCurrentAnimation.basicAnimation.beginTime = CACurrentMediaTime() + delay * TUIViewAnimationSlowMotionMultiplier();
	TUIViewCurrentAnimation.basicAnimation.fillMode = kCAFillModeBoth;
}

+ (void)setAnimationCurve:(TUIViewAnimationCurve)curve {
	NSString *functionName = kCAMediaTimingFunctionEaseInEaseOut;

	switch (curve) {
		case TUIViewAnimationCurveLinear:
			functionName = kCAMediaTimingFunctionLinear;
			break;
		case TUIViewAnimationCurveEaseIn:
			functionName = kCAMediaTimingFunctionEaseIn;
			break;
		case TUIViewAnimationCurveEaseOut:
			functionName = kCAMediaTimingFunctionEaseOut;
			break;
		case TUIViewAnimationCurveEaseInOut:
			functionName = kCAMediaTimingFunctionEaseInEaseOut;
			break;
		default:
			NSAssert(NO, @"Unrecognized animation curve: %i", (int)curve);
	}

	TUIViewCurrentAnimation.basicAnimation.timingFunction = [CAMediaTimingFunction functionWithName:functionName];
}

+ (void)setAnimationRepeatCount:(float)repeatCount {
	TUIViewCurrentAnimation.basicAnimation.repeatCount = repeatCount;
}

+ (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses {
	TUIViewCurrentAnimation.basicAnimation.autoreverses = repeatAutoreverses;
}

+ (void)setAnimationIsAdditive:(BOOL)additive {
	TUIViewCurrentAnimation.basicAnimation.additive = additive;
}

+ (void)setAnimationsEnabled:(BOOL)enabled block:(void(^)(void))block {
	BOOL save = TUIViewAnimationsEnabled;
	TUIViewAnimationsEnabled = enabled;

	block();

	TUIViewAnimationsEnabled = save;
}

+ (void)setAnimationsEnabled:(BOOL)enabled {
	TUIViewAnimationsEnabled = enabled;
}

+ (BOOL)areAnimationsEnabled {
	return TUIViewAnimationsEnabled;
}

+ (void)setAnimateContents:(BOOL)enabled {
	TUIViewAnimateContents = enabled;
}

+ (BOOL)willAnimateContents {
	return TUIViewAnimateContents;
}

- (void)removeAllAnimations {
	[self.layer removeAllAnimations];
	[self.subviews makeObjectsPerformSelector:@selector(removeAllAnimations)];
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
	id defaultAction = [NSNull null];

	if (!TUIViewAnimationsEnabled) return defaultAction;
	if (!TUIViewAnimateContents && [event isEqualToString:@"contents"]) return defaultAction;

	TUIViewAnimation *animation = TUIViewCurrentAnimation;
	if (animation == nil) return defaultAction;

	if ([TUICAAction interceptsActionForKey:event]) {
		return [TUICAAction actionWithAction:animation];
	} else {
		return animation;
	}
}

@end
