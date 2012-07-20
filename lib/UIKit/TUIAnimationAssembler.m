#import "TUIAnimationAssembler.h"
#import "TUIView.h"

// Find a CGPoint that will cause the viewFrame to be
// placed at the edge or corner of the enclosingViewFrame 
// in the specified direction.
static inline CGPoint TUIAnimationOutOfViewCenterPoint(CGRect enclosingViewFrame, CGRect viewFrame, CGPoint viewCenter, TUIAnimationDirection direction) {
	switch (direction) {
		case TUIAnimationDirectionBottom: {
			CGFloat extraOffset = viewFrame.size.height / 2;
			return CGPointMake(viewCenter.x, enclosingViewFrame.size.height + extraOffset);
			break;
		}
		case TUIAnimationDirectionTop: {
			CGFloat extraOffset = viewFrame.size.height / 2;
			return CGPointMake(viewCenter.x, enclosingViewFrame.origin.y - extraOffset);
			break;
		}
		case TUIAnimationDirectionLeft: {
			CGFloat extraOffset = viewFrame.size.width / 2;
			return CGPointMake(enclosingViewFrame.origin.x - extraOffset, viewCenter.y);
			break;
		}
		case TUIAnimationDirectionRight: {
			CGFloat extraOffset = viewFrame.size.width / 2;
			return CGPointMake(enclosingViewFrame.size.width + extraOffset, viewCenter.y);
			break;
		}
		case TUIAnimationDirectionBottomLeft: {
			CGFloat extraOffsetHeight = viewFrame.size.height / 2;
			CGFloat extraOffsetWidth = viewFrame.size.width / 2;
			return CGPointMake(enclosingViewFrame.origin.x - extraOffsetWidth, enclosingViewFrame.size.height + extraOffsetHeight);
			break;
		}
		case TUIAnimationDirectionTopLeft: {
			CGFloat extraOffsetHeight = viewFrame.size.height / 2;
			CGFloat extraOffsetWidth = viewFrame.size.width / 2;
			return CGPointMake(enclosingViewFrame.origin.x - extraOffsetWidth, enclosingViewFrame.origin.y - extraOffsetHeight);
			break;
		}
		case TUIAnimationDirectionBottomRight: {
			CGFloat extraOffsetHeight = viewFrame.size.height / 2;
			CGFloat extraOffsetWidth = viewFrame.size.width / 2;
			return CGPointMake(enclosingViewFrame.size.width + extraOffsetWidth, enclosingViewFrame.size.height + extraOffsetHeight);
			break;
		}
		case TUIAnimationDirectionTopRight: {
			CGFloat extraOffsetHeight = viewFrame.size.height / 2;
			CGFloat extraOffsetWidth = viewFrame.size.width / 2;
			return CGPointMake(enclosingViewFrame.size.width + extraOffsetWidth, enclosingViewFrame.origin.y - extraOffsetHeight);
			break;
		}
	}
	return CGPointZero;
}

// Find a CGPoint that will cause the *viewFrame* to be 
// completely offscreen in a specified *direction*.
static inline CGPoint TUIAnimationOffscreenCenterPoint(CGRect viewFrame, CGPoint viewCenter, TUIAnimationDirection direction) {
    CGRect screenRect = [[NSScreen mainScreen] frame];
    
    switch (direction) {
        case TUIAnimationDirectionBottom: {
            CGFloat extraOffset = viewFrame.size.height / 2;
            return CGPointMake(viewCenter.x, screenRect.size.height + extraOffset);
            break;
        }
        case TUIAnimationDirectionTop: {
            CGFloat extraOffset = viewFrame.size.height / 2;
            return CGPointMake(viewCenter.x, screenRect.origin.y - extraOffset);
            break;
        }
        case TUIAnimationDirectionLeft: {
            CGFloat extraOffset = viewFrame.size.width / 2;
            return CGPointMake(screenRect.origin.x - extraOffset, viewCenter.y);
            break;
        }
        case TUIAnimationDirectionRight: {
            CGFloat extraOffset = viewFrame.size.width / 2;
            return CGPointMake(screenRect.size.width + extraOffset, viewCenter.y);
            break;
        }
        default:
            break;
    }
	return TUIAnimationOutOfViewCenterPoint([[NSScreen mainScreen] frame], viewFrame, viewCenter, direction);
}

/**
 Call a delegate method if the selector exists.
 */
#define TUI_CALL_DELEGATE(_delegate, _selector) \
do { \
id _theDelegate = _delegate; \
if(_theDelegate != nil && [_theDelegate respondsToSelector:_selector]) { \
[_theDelegate performSelector:_selector]; \
} \
} while(0);

/**
 Call a delegate method that accepts one argument if the selector exists.
 */
#define TUI_CALL_DELEGATE_WITH_ARG(_delegate, _selector, _argument) \
do { \
id _theDelegate = _delegate; \
if(_theDelegate != nil && [_theDelegate respondsToSelector:_selector]) { \
[_theDelegate performSelector:_selector withObject:_argument]; \
} \
} while(0);

/**
 Call a delegate method that accepts two arguments if the selector exists.
 */
#define TUI_CALL_DELEGATE_WITH_ARGS(_delegate, _selector, _arg1, _arg2) \
do { \
id _theDelegate = _delegate; \
if(_theDelegate != nil && [_theDelegate respondsToSelector:_selector]) { \
[_theDelegate performSelector:_selector withObject:_arg1 withObject:_arg2]; \
} \
} while(0);

// Internal NSObject selector actions methods.
@interface NSObject (TUIAnimationAdditions)

- (void)performSelector:(SEL)selector andReturnTo:(void *)returnData withArguments:(void **)arguments;
- (void)performSelector:(SEL)selector withArguments:(void **)arguments;
- (void)performSelectorIfExists:(SEL)selector andReturnTo:(void *)returnData withArguments:(void **)arguments;
- (void)performSelectorIfExists:(SEL)selector withArguments:(void **)arguments;

@end

NSString *const TUIAnimationName = @"TUIAnimationName";
NSString *const TUIAnimationType = @"TUIAnimationType";
NSString *const TUIAnimationTypeIn = @"TUIAnimationTypeIn";
NSString *const TUIAnimationTypeOut = @"TUIAnimationTypeOut";

NSString *const TUIAnimationSlideOut = @"TUIAnimationNameSlideOut";
NSString *const TUIAnimationSlideIn = @"TUIAnimationNameSlideIn";
NSString *const TUIAnimationBackOut = @"TUIAnimationNameBackOut";
NSString *const TUIAnimationBackIn = @"TUIAnimationNameBackIn";
NSString *const TUIAnimationFadeOut = @"TUIAnimationFadeOut";
NSString *const TUIAnimationFadeIn = @"TUIAnimationFadeIn";
NSString *const TUIAnimationFadeBackgroundOut = @"TUIAnimationFadeBackgroundOut";
NSString *const TUIAnimationFadeBackgroundIn = @"TUIAnimationFadeBackgroundIn";
NSString *const TUIAnimationPopIn = @"TUIAnimationPopIn";
NSString *const TUIAnimationPopOut = @"TUIAnimationPopOut";
NSString *const TUIAnimationFallIn = @"TUIAnimationFallIn";
NSString *const TUIAnimationFallOut = @"TUIAnimationFallOut";
NSString *const TUIAnimationFlyOut = @"TUIAnimationFlyOut";

NSString *const TUIAnimationCallerDelegateKey = @"TUIAnimationCallerDelegateKey";
NSString *const TUIAnimationCallerStartSelectorKey = @"TUIAnimationCallerStartSelectorKey";
NSString *const TUIAnimationCallerStopSelectorKey = @"TUIAnimationCallerStopSelectorKey";
NSString *const TUIAnimationTargetViewKey = @"TUIAnimationTargetViewKey";
NSString *const TUIAnimationIsChainedKey = @"TUIAnimationIsChainedKey";
NSString *const TUIAnimationNextAnimationKey = @"TUIAnimationNextAnimationKey";
NSString *const TUIAnimationPrevAnimationKey = @"TUIAnimationPrevAnimationKey";
NSString *const TUIAnimationWasInteractionEnabledKey = @"TUIAnimationWasInteractionEnabledKey";

@interface TUIAnimationAssembler ()

- (CGPoint)overshootPointFor:(CGPoint)point withDirection:(TUIAnimationDirection)direction threshold:(CGFloat)threshold;

@end

@implementation TUIAnimationAssembler

@synthesize overshootThreshold = overshootThreshold_;

- (CAAnimationGroup *)delayStartOfAnimation:(CAAnimation *)animation withDelay:(CFTimeInterval)delayTime {
  animation.fillMode = kCAFillModeBoth;
  animation.beginTime = delayTime;
  TUIView *targetView = [animation valueForKey:TUIAnimationTargetViewKey];
  NSString *name = [animation valueForKey:TUIAnimationName];
  NSString *type = [animation valueForKey:TUIAnimationType];
  id delegate = [animation valueForKey:TUIAnimationCallerDelegateKey];
  NSString *startSelectorString = [animation valueForKey:TUIAnimationCallerStartSelectorKey];
  NSString *stopSelectorString = [animation valueForKey:TUIAnimationCallerStopSelectorKey];
  SEL startSelector = nil;
  SEL stopSelector = nil;
  if(startSelectorString != nil) {
    startSelector = NSSelectorFromString(startSelectorString);
  }
  if(stopSelectorString != nil) {
    stopSelector = NSSelectorFromString(stopSelectorString);
  }
  CAAnimationGroup *group = [[TUIAnimationAssembler animationAssembler] 
                             animationGroupFor:[NSArray arrayWithObject:animation] 
                             withView:targetView duration:animation.duration + delayTime 
                             delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                             name:name type:type];
  return group;
}

- (CAAnimationGroup *)pauseAtEndOfAnimation:(CAAnimation *)animation withDelay:(CFTimeInterval)delayTime {
  animation.fillMode = kCAFillModeForwards;
  TUIView *targetView = [animation valueForKey:TUIAnimationTargetViewKey];
  NSString *name = [animation valueForKey:TUIAnimationName];
  NSString *type = [animation valueForKey:TUIAnimationType];
  id delegate = [animation valueForKey:TUIAnimationCallerDelegateKey];
  NSString *startSelectorString = [animation valueForKey:TUIAnimationCallerStartSelectorKey];
  NSString *stopSelectorString = [animation valueForKey:TUIAnimationCallerStopSelectorKey];
  SEL startSelector = nil;
  SEL stopSelector = nil;
  if(startSelectorString != nil) {
    startSelector = NSSelectorFromString(startSelectorString);
  }
  if(stopSelectorString != nil) {
    stopSelector = NSSelectorFromString(stopSelectorString);
  }
  CAAnimationGroup *group = [[TUIAnimationAssembler animationAssembler] 
                             animationGroupFor:[NSArray arrayWithObject:animation] 
                             withView:targetView duration:animation.duration + delayTime 
                             delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                             name:name type:type];
  return group;
}

- (CAAnimation *)chainAnimations:(NSArray *)animations run:(BOOL)run {
  CAAnimation *head = nil;
  CAAnimation *prev = nil;
  
  for(CAAnimation *anim in animations) {
    if(!head) {
      head = anim;
    } else {
      [prev setValue:anim forKey:TUIAnimationNextAnimationKey];
    }
    [anim setValue:prev forKey:TUIAnimationPrevAnimationKey];
    [anim setValue:[NSNumber numberWithBool:YES] forKey:TUIAnimationIsChainedKey];
    prev = anim;
  }
  if(run) {
    TUIView *target = [head valueForKey:TUIAnimationTargetViewKey];
    [target.layer addAnimation:head forKey:[head valueForKey:TUIAnimationName]];
  }
  return head;
}

- (CAAnimationGroup *)animationGroupFor:(NSArray *)animations withView:(TUIView *)view 
                               duration:(NSTimeInterval)duration delegate:(id)delegate 
                          startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector
                                   name:(NSString *)name type:(NSString *)type {
  CAAnimationGroup *group = [CAAnimationGroup animation];
  group.animations = [NSArray arrayWithArray:animations];
  group.delegate = self;
  group.duration = duration;
  group.removedOnCompletion = NO;
  if([type isEqualToString:TUIAnimationTypeOut]) {
    group.fillMode = kCAFillModeBoth;
  }
  group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  [group setValue:view forKey:TUIAnimationTargetViewKey];
  [group setValue:delegate forKey:TUIAnimationCallerDelegateKey];
  if(!startSelector) {
    startSelector = @selector(animationDidStart:);
  }
  [group setValue:NSStringFromSelector(startSelector) forKey:TUIAnimationCallerStartSelectorKey];
  if(!stopSelector) {
    stopSelector = @selector(animationDidStop:finished:);
  }
  [group setValue:NSStringFromSelector(stopSelector) forKey:TUIAnimationCallerStopSelectorKey];
  [group setValue:name forKey:TUIAnimationName];
  [group setValue:type forKey:TUIAnimationType];
  return group;
}

- (CAAnimation *)slideInAnimationFor:(TUIView *)view direction:(TUIAnimationDirection)direction 
                            duration:(NSTimeInterval)duration delegate:(id)delegate 
                       startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
  animation.fromValue = [NSValue valueWithPoint:TUIAnimationOffscreenCenterPoint(view.frame, view.center, direction)];
  animation.toValue = [NSValue valueWithPoint:view.center];
  return [self animationGroupFor:[NSArray arrayWithObject:animation] withView:view duration:duration 
                        delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                            name:TUIAnimationSlideIn type:TUIAnimationTypeIn];
}

- (CAAnimation *)slideOutAnimationFor:(TUIView *)view direction:(TUIAnimationDirection)direction 
                             duration:(NSTimeInterval)duration delegate:(id)delegate 
                        startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector{
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
  animation.fromValue = [NSValue valueWithPoint:view.center];
  animation.toValue = [NSValue valueWithPoint:TUIAnimationOffscreenCenterPoint(view.frame, view.center, direction)];
  return [self animationGroupFor:[NSArray arrayWithObject:animation] withView:view duration:duration 
                        delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                            name:TUIAnimationSlideOut type:TUIAnimationTypeOut];
}

- (CAAnimation *)slideInAnimationFor:(TUIView *)view direction:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView
                            duration:(NSTimeInterval)duration delegate:(id)delegate 
                       startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
	animation.fromValue = [NSValue valueWithPoint:TUIAnimationOutOfViewCenterPoint(enclosingView.bounds, view.frame, view.center, direction)];
	animation.toValue = [NSValue valueWithPoint:view.center];
	return [self animationGroupFor:[NSArray arrayWithObject:animation] withView:view duration:duration 
						  delegate:delegate startSelector:startSelector stopSelector:stopSelector 
							  name:TUIAnimationSlideIn type:TUIAnimationTypeIn];
}

- (CAAnimation *)slideOutAnimationFor:(TUIView *)view direction:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView
                             duration:(NSTimeInterval)duration delegate:(id)delegate 
                        startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector{
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
	animation.fromValue = [NSValue valueWithPoint:view.center];
	animation.toValue = [NSValue valueWithPoint:TUIAnimationOutOfViewCenterPoint(view.superview.bounds, view.frame, view.center, direction)];
	return [self animationGroupFor:[NSArray arrayWithObject:animation] withView:view duration:duration 
						  delegate:delegate startSelector:startSelector stopSelector:stopSelector 
							  name:TUIAnimationSlideOut type:TUIAnimationTypeOut];
}

- (CGPoint)overshootPointFor:(CGPoint)point withDirection:(TUIAnimationDirection)direction threshold:(CGFloat)threshold {
  CGPoint overshootPoint;
  if(direction == TUIAnimationDirectionTop || direction == TUIAnimationDirectionBottom) {
    overshootPoint = CGPointMake(point.x, point.y + ((direction == TUIAnimationDirectionBottom ? -1 : 1) * threshold));
  } else if (direction == TUIAnimationDirectionLeft || direction == TUIAnimationDirectionRight){
    overshootPoint = CGPointMake(point.x + ((direction == TUIAnimationDirectionRight ? -1 : 1) * threshold), point.y);
  } else if (direction == TUIAnimationDirectionTopLeft){
	  overshootPoint = CGPointMake(point.x + threshold, point.y + threshold);
  } else if (direction == TUIAnimationDirectionTopRight){
	  overshootPoint = CGPointMake(point.x - threshold, point.y + threshold);
  } else if (direction == TUIAnimationDirectionBottomLeft){
	  overshootPoint = CGPointMake(point.x + threshold, point.y - threshold);
  } else if (direction == TUIAnimationDirectionBottomRight){
	  overshootPoint = CGPointMake(point.x - threshold, point.y - threshold);
  }

  return overshootPoint;
}

- (CAAnimation *)backOutAnimationFor:(TUIView *)view withFade:(BOOL)fade direction:(TUIAnimationDirection)direction 
                            duration:(NSTimeInterval)duration delegate:(id)delegate 
                       startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
  CGPoint path[3] = {
    view.center,
    [self overshootPointFor:view.center withDirection:direction threshold:overshootThreshold_],
    TUIAnimationOffscreenCenterPoint(view.frame, view.center, direction)
  };
  
  CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
  CGMutablePathRef thePath = CGPathCreateMutable();
  CGPathAddLines(thePath, NULL, path, 3);
  animation.path = thePath;
  CGPathRelease(thePath);
  NSArray *animations;
  if(fade) {
    CAAnimation *fade = [self fadeAnimationFor:view duration:duration * .5f delegate:nil startSelector:nil stopSelector:nil fadeOut:YES];
    fade.beginTime = duration * .5f;
    fade.fillMode = kCAFillModeForwards;
    animations = [NSArray arrayWithObjects:animation, fade, nil];
  } else {
    animations = [NSArray arrayWithObject:animation];
  }
  return [self animationGroupFor:animations withView:view duration:duration 
                        delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                            name:TUIAnimationBackOut type:TUIAnimationTypeOut];
}

- (CAAnimation *)backInAnimationFor:(TUIView *)view withFade:(BOOL)fade direction:(TUIAnimationDirection)direction 
                           duration:(NSTimeInterval)duration delegate:(id)delegate 
                      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
  CGPoint path[3] = {
    TUIAnimationOffscreenCenterPoint(view.frame, view.center, direction),
    [self overshootPointFor:view.center withDirection:direction threshold:(overshootThreshold_ * 1.15)],
    view.center
  };
  
  CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
  CGMutablePathRef thePath = CGPathCreateMutable();
  CGPathAddLines(thePath, NULL, path, 3);
  animation.path = thePath;
  CGPathRelease(thePath);
  NSArray *animations;
  if(fade) {
    CAAnimation *fade = [self fadeAnimationFor:view duration:duration * .5f delegate:nil startSelector:nil stopSelector:nil fadeOut:NO];
    fade.fillMode = kCAFillModeForwards;
    
    animations = [NSArray arrayWithObjects:animation, fade, nil];
  } else {
    animations = [NSArray arrayWithObject:animation];
  }
  return [self animationGroupFor:animations withView:view duration:duration 
                        delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                            name:TUIAnimationBackIn type:TUIAnimationTypeIn];
}

- (CAAnimation *)backOutAnimationFor:(TUIView *)view withFade:(BOOL)fade direction:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView
                            duration:(NSTimeInterval)duration delegate:(id)delegate 
                       startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
	CGPoint path[3] = {
		view.center,
		[self overshootPointFor:view.center withDirection:direction threshold:overshootThreshold_],
		TUIAnimationOutOfViewCenterPoint(enclosingView.bounds, view.frame, view.center, direction)
	};
	
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
	CGMutablePathRef thePath = CGPathCreateMutable();
	CGPathAddLines(thePath, NULL, path, 3);
	animation.path = thePath;
	CGPathRelease(thePath);
	NSArray *animations;
	if(fade) {
		CAAnimation *fade = [self fadeAnimationFor:view duration:duration * .5f delegate:nil startSelector:nil stopSelector:nil fadeOut:YES];
		fade.beginTime = duration * .5f;
		fade.fillMode = kCAFillModeForwards;
		animations = [NSArray arrayWithObjects:animation, fade, nil];
	} else {
		animations = [NSArray arrayWithObject:animation];
	}
	return [self animationGroupFor:animations withView:view duration:duration 
						  delegate:delegate startSelector:startSelector stopSelector:stopSelector 
							  name:TUIAnimationBackOut type:TUIAnimationTypeOut];
}


- (CAAnimation *)backInAnimationFor:(TUIView *)view withFade:(BOOL)fade direction:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView
                           duration:(NSTimeInterval)duration delegate:(id)delegate 
                      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
	CGPoint path[3] = {
		TUIAnimationOutOfViewCenterPoint(enclosingView.bounds, view.frame, view.center, direction),
		[self overshootPointFor:view.center withDirection:direction threshold:(overshootThreshold_ * 1.15)],
		view.center
	};
	
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
	CGMutablePathRef thePath = CGPathCreateMutable();
	CGPathAddLines(thePath, NULL, path, 3);
	animation.path = thePath;
	CGPathRelease(thePath);
	NSArray *animations;
	if(fade) {
		CAAnimation *fade = [self fadeAnimationFor:view duration:duration * .5f delegate:nil startSelector:nil stopSelector:nil fadeOut:NO];
		fade.fillMode = kCAFillModeForwards;
		
		animations = [NSArray arrayWithObjects:animation, fade, nil];
	} else {
		animations = [NSArray arrayWithObject:animation];
	}
	return [self animationGroupFor:animations withView:view duration:duration 
						  delegate:delegate startSelector:startSelector stopSelector:stopSelector 
							  name:TUIAnimationBackIn type:TUIAnimationTypeIn];
}

- (CAAnimation *)fadeAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration 
                         delegate:(id)delegate startSelector:(SEL)startSelector 
                     stopSelector:(SEL)stopSelector fadeOut:(BOOL)fadeOut {
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
  
  NSString *name, *type;
  if(fadeOut) {
    animation.fromValue = [NSNumber numberWithFloat:1.f];
    animation.toValue = [NSNumber numberWithFloat:0.f];
    name = TUIAnimationFadeOut;
    type = TUIAnimationTypeOut;
  } else {
    animation.fromValue = [NSNumber numberWithFloat:0.f];
    animation.toValue = [NSNumber numberWithFloat:1.f];
    name = TUIAnimationFadeIn;
    type = TUIAnimationTypeIn;
  }
  CAAnimationGroup *group = [self animationGroupFor:[NSArray arrayWithObject:animation] withView:view duration:duration 
                                           delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                                               name:name type:type];
  group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  return group;
  
}


- (CAAnimation *)fadeBackgroundColorAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration 
                                        delegate:(id)delegate startSelector:(SEL)startSelector 
                                    stopSelector:(SEL)stopSelector fadeOut:(BOOL)fadeOut {
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
  
  NSString *name, *type;
  if(fadeOut) {
    animation.fromValue = (id)view.layer.backgroundColor;
    animation.toValue = (id)[[TUIColor clearColor] CGColor];
    name = TUIAnimationFadeBackgroundOut;
    type = TUIAnimationTypeOut;
  } else {
    animation.fromValue = (id)[[TUIColor clearColor] CGColor];
    animation.toValue = (id)view.layer.backgroundColor;
    name = TUIAnimationFadeBackgroundIn;
    type = TUIAnimationTypeIn;
  }
  CAAnimationGroup *group = [self animationGroupFor:[NSArray arrayWithObject:animation] withView:view duration:duration 
                                           delegate:delegate startSelector:startSelector stopSelector:stopSelector
                                               name:name type:type];
  group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  return group;
}

- (CAAnimation *)popInAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration delegate:(id)delegate 
                     startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
  CAKeyframeAnimation *scale = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
  scale.duration = duration;
  scale.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:.5f],
                  [NSNumber numberWithFloat:1.2f],
                  [NSNumber numberWithFloat:.85f],
                  [NSNumber numberWithFloat:1.f],
                  nil];
  
  CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
  fadeIn.duration = duration * .4f;
  fadeIn.fromValue = [NSNumber numberWithFloat:0.f];
  fadeIn.toValue = [NSNumber numberWithFloat:1.f];
  fadeIn.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
  fadeIn.fillMode = kCAFillModeForwards;
  
  CAAnimationGroup *group = [self animationGroupFor:[NSArray arrayWithObjects:scale, fadeIn, nil] withView:view duration:duration 
                                           delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                                               name:TUIAnimationPopIn type:TUIAnimationTypeIn];
  group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  return group;
}

- (CAAnimation *)popOutAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration delegate:(id)delegate 
                      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
  CAKeyframeAnimation *scale = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
  scale.duration = duration;
  scale.removedOnCompletion = NO;
  scale.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1.f],
                  [NSNumber numberWithFloat:1.2f],
                  [NSNumber numberWithFloat:.75f],
                  nil];
  
  CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
  fadeOut.duration = duration * .4f;
  fadeOut.fromValue = [NSNumber numberWithFloat:1.f];
  fadeOut.toValue = [NSNumber numberWithFloat:0.f];
  fadeOut.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
  fadeOut.beginTime = duration * .6f;
  fadeOut.fillMode = kCAFillModeBoth;
  
  return [self animationGroupFor:[NSArray arrayWithObjects:scale, fadeOut, nil] withView:view duration:duration 
                        delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                            name:TUIAnimationPopOut type:TUIAnimationTypeOut];
}

- (CAAnimation *)fallInAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration delegate:(id)delegate 
                      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
  
  CABasicAnimation *fall = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
  fall.fromValue = [NSNumber numberWithFloat:2.f];
  fall.toValue = [NSNumber numberWithFloat:1.f];
  fall.duration = duration;
  
  CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
  fade.fromValue = [NSNumber numberWithFloat:0.f];
  fade.toValue = [NSNumber numberWithFloat:1.f];
  fade.duration = duration;
  
  CAAnimationGroup *group = [self animationGroupFor:[NSArray arrayWithObjects:fall, fade, nil] withView:view duration:duration 
                                           delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                                               name:TUIAnimationFallIn type:TUIAnimationTypeIn];
  return group;
}

- (CAAnimation *)fallOutAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration delegate:(id)delegate 
                       startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
  
  CABasicAnimation *fall = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
  fall.fromValue = [NSNumber numberWithFloat:1.f];
  fall.toValue = [NSNumber numberWithFloat:.15f];
  fall.duration = duration;
  
  CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
  fade.fromValue = [NSNumber numberWithFloat:1.f];
  fade.toValue = [NSNumber numberWithFloat:0.f];
  fade.duration = duration;
  
  CAAnimationGroup *group = [self animationGroupFor:[NSArray arrayWithObjects:fall, fade, nil] withView:view duration:duration 
                                           delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                                               name:TUIAnimationFallOut type:TUIAnimationTypeOut];
  return group;
}


- (CAAnimation *)flyOutAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration delegate:(id)delegate 
                      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
  
  CABasicAnimation *fly = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
  fly.toValue = [NSNumber numberWithFloat:2.f];
  fly.duration = duration;
  
  CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
  fade.toValue = [NSNumber numberWithFloat:0.f];
  fade.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
  
  CAAnimationGroup *group = [self animationGroupFor:[NSArray arrayWithObjects:fly, fade, nil] withView:view duration:duration 
                                           delegate:delegate startSelector:startSelector stopSelector:stopSelector 
                                               name:TUIAnimationFlyOut type:TUIAnimationTypeOut];
  return group;
}

- (CAKeyframeAnimation *)shakeAnimationFor:(CGRect)frame 
                            numberOfShakes:(NSUInteger)shakes 
                                  duration:(NSTimeInterval)duration 
                         withDevianceIndex:(CGFloat)deviance {
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
	
    CGMutablePathRef shakePath = CGPathCreateMutable();
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
    
	for(int index = 0; index < shakes; ++index) {
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * deviance, NSMinY(frame));
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * deviance, NSMinY(frame));
	}
    
    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = duration;
    CGPathRelease(shakePath);
    
    return shakeAnimation;
}

- (void)animationDidStart:(CAAnimation *)theAnimation {
  TUIView *targetView = [theAnimation valueForKey:TUIAnimationTargetViewKey];
  [theAnimation setValue:[NSNumber numberWithBool:targetView.userInteractionEnabled] forKey:TUIAnimationWasInteractionEnabledKey];
  [targetView setUserInteractionEnabled:NO];
  
  if([[theAnimation valueForKey:TUIAnimationType] isEqualToString:TUIAnimationTypeIn]) {
    [targetView setHidden:NO];
  }
  
  //Check for chaining and forward the delegate call if necessary
  NSObject *callerDelegate = [theAnimation valueForKey:TUIAnimationCallerDelegateKey];
  SEL startSelector = NSSelectorFromString([theAnimation valueForKey:TUIAnimationCallerStartSelectorKey]);
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  TUI_CALL_DELEGATE_WITH_ARG(callerDelegate, startSelector, theAnimation)
#pragma clang diagnostic pop
}
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)finished {
  TUIView *targetView = [theAnimation valueForKey:TUIAnimationTargetViewKey];
  BOOL wasInteractionEnabled = [[theAnimation valueForKey:TUIAnimationWasInteractionEnabledKey] boolValue];
  [targetView setUserInteractionEnabled:wasInteractionEnabled];
  
  if([[theAnimation valueForKey:TUIAnimationType] isEqualToString:TUIAnimationTypeOut]) {
    [targetView setHidden:YES];
  }
  [targetView.layer removeAnimationForKey:[theAnimation valueForKey:TUIAnimationName]];
  
  //Forward the delegate call
  id callerDelegate = [theAnimation valueForKey:TUIAnimationCallerDelegateKey];
  SEL stopSelector = NSSelectorFromString([theAnimation valueForKey:TUIAnimationCallerStopSelectorKey]);
  
  if([theAnimation valueForKey:TUIAnimationIsChainedKey]) {
    CAAnimation *next = [theAnimation valueForKey:TUIAnimationNextAnimationKey];
    if(next) {
      //Add the next animation to its layer
      TUIView *nextTarget = [next valueForKey:TUIAnimationTargetViewKey];
      [nextTarget.layer addAnimation:next forKey:[next valueForKey:TUIAnimationName]];
    }
  }
  
  void *arguments[] = { &theAnimation, &finished };
  [callerDelegate performSelectorIfExists:stopSelector withArguments:arguments];
}

static TUIAnimationAssembler *sharedAnimationManager = nil;

+ (TUIAnimationAssembler *)animationAssembler {
  @synchronized(self) {
    if (sharedAnimationManager == nil) {
      sharedAnimationManager = [[self alloc] init];
    }
  }
  return sharedAnimationManager;
}

- (id)init {
  self = [super init];
  if (self != nil) {
    overshootThreshold_ = 10.f;
  }
  return self;
}

@end

@implementation CAAnimation (TUIAnimationAdditions)

- (void)setStartSelector:(SEL)selector withTarget:(id)target {
  [self setValue:target forKey:TUIAnimationCallerDelegateKey];
  [self setValue:NSStringFromSelector(selector) forKey:TUIAnimationCallerStartSelectorKey];
}

- (void)setStopSelector:(SEL)selector withTarget:(id)target {
  [self setValue:target forKey:TUIAnimationCallerDelegateKey];
  [self setValue:NSStringFromSelector(selector) forKey:TUIAnimationCallerStopSelectorKey];
}

@end

@implementation NSObject (TUIAnimationAdditions)

- (void)performSelector:(SEL)selector andReturnTo:(void *)returnData withArguments:(void **)arguments {
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setSelector:selector];
    
    NSUInteger argCount = [methodSignature numberOfArguments];
    
    for (int i=2; i < argCount; i++) {
        void *arg = arguments[i-2];
        [invocation setArgument:arg atIndex:i];
    }
    
    [invocation invokeWithTarget:self];
    if(returnData != NULL) {
        [invocation getReturnValue:returnData];
    }
}

- (void)performSelector:(SEL)selector withArguments:(void **)arguments {
    [self performSelector:selector andReturnTo:NULL withArguments:arguments];
}

- (void)performSelectorIfExists:(SEL)selector andReturnTo:(void *)returnData withArguments:(void **)arguments {
    if([self respondsToSelector:selector]) {
        [self performSelector:selector andReturnTo:returnData withArguments:arguments];
    }
}

- (void)performSelectorIfExists:(SEL)selector withArguments:(void **)arguments {
    [self performSelectorIfExists:selector andReturnTo:NULL withArguments:arguments];
}

@end