#import "TUIView+AnimationAssembly.h"

#define __duration duration * SlomoTime()
static CGFloat SlomoTime() {
	if((NSUInteger)([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == (NSUInteger)(NSShiftKeyMask))
		return 2.0;
	return 1.0;
}

@implementation TUIView (AnimationAdditions)

- (void)slideInFrom:(TUIAnimationDirection)direction duration:(NSTimeInterval)duration delegate:(id)delegate
      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *slideInAnim = [[TUIAnimationAssembler animationAssembler] slideInAnimationFor:self direction:direction
                                                                                      duration:__duration delegate:delegate
                                                                                 startSelector:startSelector stopSelector:stopSelector];
    [slideInAnim setRemovedOnCompletion:YES];
    slideInAnim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:slideInAnim forKey:TUIAnimationSlideIn];
}

- (void)slideInFrom:(TUIAnimationDirection)direction duration:(NSTimeInterval)duration delegate:(id)delegate {
    [self slideInFrom:direction duration:__duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)slideOutTo:(TUIAnimationDirection)direction duration:(NSTimeInterval)duration
          delegate:(id)delegate startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *slideOutAnim = [[TUIAnimationAssembler animationAssembler] slideOutAnimationFor:self direction:direction
                                                                                        duration:__duration delegate:delegate
                                                                                   startSelector:startSelector stopSelector:stopSelector];
    [slideOutAnim setRemovedOnCompletion:YES];
    slideOutAnim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:slideOutAnim forKey:TUIAnimationSlideOut];
}

- (void)slideOutTo:(TUIAnimationDirection)direction duration:(NSTimeInterval)duration delegate:(id)delegate {
    [self slideOutTo:direction duration:__duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)slideInFrom:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView duration:(NSTimeInterval)duration delegate:(id)delegate
      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
	CAAnimation *slideInAnim = [[TUIAnimationAssembler animationAssembler] slideInAnimationFor:self direction:direction
                                                                                        inView:(TUIView *)enclosingView
                                                                                      duration:__duration
                                                                                      delegate:delegate
                                                                                 startSelector:startSelector stopSelector:stopSelector];
    [slideInAnim setRemovedOnCompletion:YES];
    slideInAnim.fillMode = kCAFillModeForwards;
	[self.layer addAnimation:slideInAnim forKey:TUIAnimationSlideIn];
}

- (void)slideOutTo:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView duration:(NSTimeInterval)duration
          delegate:(id)delegate startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
	CAAnimation *slideOutAnim = [[TUIAnimationAssembler animationAssembler] slideOutAnimationFor:self direction:direction
                                                                                          inView:(TUIView *)enclosingView
                                                                                        duration:__duration delegate:delegate
                                                                                   startSelector:startSelector stopSelector:stopSelector];
    [slideOutAnim setRemovedOnCompletion:YES];
    slideOutAnim.fillMode = kCAFillModeForwards;
	[self.layer addAnimation:slideOutAnim forKey:TUIAnimationSlideOut];
}

- (void)backOutTo:(TUIAnimationDirection)direction withFade:(BOOL)fade duration:(NSTimeInterval)duration delegate:(id)delegate
    startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *backOutAnim = [[TUIAnimationAssembler animationAssembler] backOutAnimationFor:self withFade:fade direction:direction
                                                                                      duration:__duration delegate:delegate
                                                                                 startSelector:startSelector stopSelector:stopSelector];
    [backOutAnim setRemovedOnCompletion:YES];
    backOutAnim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:backOutAnim forKey:TUIAnimationBackOut];
}

- (void)backOutTo:(TUIAnimationDirection)direction withFade:(BOOL)fade duration:(NSTimeInterval)duration delegate:(id)delegate {
    [self backOutTo:direction withFade:fade duration:__duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)backInFrom:(TUIAnimationDirection)direction withFade:(BOOL)fade duration:(NSTimeInterval)duration delegate:(id)delegate
     startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *backInAnim = [[TUIAnimationAssembler animationAssembler] backInAnimationFor:self withFade:fade direction:direction
                                                                                    duration:__duration delegate:delegate
                                                                               startSelector:startSelector stopSelector:stopSelector];
    [backInAnim setRemovedOnCompletion:YES];
    backInAnim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:backInAnim forKey:TUIAnimationBackIn];
}

- (void)backInFrom:(TUIAnimationDirection)direction withFade:(BOOL)fade duration:(NSTimeInterval)duration delegate:(id)delegate {
    [self backInFrom:direction withFade:fade duration:__duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)backOutTo:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView withFade:(BOOL)fade duration:(NSTimeInterval)duration delegate:(id)delegate
    startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
	CAAnimation *backOutAnim = [[TUIAnimationAssembler animationAssembler] backOutAnimationFor:self withFade:fade direction:direction
                                                                                        inView:enclosingView
																			  duration:__duration delegate:delegate
																		 startSelector:startSelector stopSelector:stopSelector];
    [backOutAnim setRemovedOnCompletion:YES];
    backOutAnim.fillMode = kCAFillModeForwards;
	[self.layer addAnimation:backOutAnim forKey:TUIAnimationBackOut];
}

- (void)backInFrom:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView withFade:(BOOL)fade duration:(NSTimeInterval)duration delegate:(id)delegate
     startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
	CAAnimation *backInAnim = [[TUIAnimationAssembler animationAssembler] backInAnimationFor:self withFade:fade direction:direction
                                                                                      inView:enclosingView
                                                                                    duration:__duration delegate:delegate
                                                                               startSelector:startSelector stopSelector:stopSelector];
	[backInAnim setRemovedOnCompletion:YES];
    backInAnim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:backInAnim forKey:TUIAnimationBackIn];
}

- (void)fadeIn:(NSTimeInterval)duration delegate:(id)delegate startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *anim = [[TUIAnimationAssembler animationAssembler] fadeAnimationFor:self duration:__duration delegate:delegate
                                                                       startSelector:startSelector stopSelector:stopSelector fadeOut:NO];
    [anim setRemovedOnCompletion:YES];
    anim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:anim forKey:TUIAnimationFadeIn];
}

- (void)fadeIn:(NSTimeInterval)duration delegate:(id)delegate {
    [self fadeIn:duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)fadeOut:(NSTimeInterval)duration delegate:(id)delegate startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *anim = [[TUIAnimationAssembler animationAssembler] fadeAnimationFor:self duration:__duration delegate:delegate
                                                                       startSelector:startSelector stopSelector:stopSelector fadeOut:YES];
    [anim setRemovedOnCompletion:YES];
    anim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:anim forKey:TUIAnimationFadeOut];
}

- (void)fadeOut:(NSTimeInterval)duration delegate:(id)delegate {
    [self fadeOut:duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)fadeBackgroundColorIn:(NSTimeInterval)duration delegate:(id)delegate
                startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *anim = [[TUIAnimationAssembler animationAssembler] fadeBackgroundColorAnimationFor:self duration:__duration
                                                                                           delegate:delegate startSelector:startSelector
                                                                                       stopSelector:stopSelector fadeOut:NO];
    [anim setRemovedOnCompletion:YES];
    anim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:anim forKey:TUIAnimationFadeBackgroundIn];
}

- (void)fadeBackgroundColorIn:(NSTimeInterval)duration delegate:(id)delegate {
    [self fadeBackgroundColorIn:duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)fadeBackgroundColorOut:(NSTimeInterval)duration delegate:(id)delegate
                 startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *anim = [[TUIAnimationAssembler animationAssembler] fadeBackgroundColorAnimationFor:self duration:__duration
                                                                                           delegate:delegate startSelector:startSelector
                                                                                       stopSelector:stopSelector fadeOut:YES];
    [anim setRemovedOnCompletion:YES];
    anim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:anim forKey:TUIAnimationFadeBackgroundOut];
}

- (void)fadeBackgroundColorOut:(NSTimeInterval)duration delegate:(id)delegate {
    [self fadeBackgroundColorOut:duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)popIn:(NSTimeInterval)duration delegate:(id)delegate startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *anim = [[TUIAnimationAssembler animationAssembler] popInAnimationFor:self duration:__duration delegate:delegate
                                                                        startSelector:startSelector stopSelector:stopSelector];
    [anim setRemovedOnCompletion:YES];
    anim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:anim forKey:TUIAnimationPopIn];
}

- (void)popIn:(NSTimeInterval)duration delegate:(id)delegate {
    [self popIn:duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)popOut:(NSTimeInterval)duration delegate:(id)delegate startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *anim = [[TUIAnimationAssembler animationAssembler] popOutAnimationFor:self duration:__duration delegate:delegate
                                                                         startSelector:startSelector stopSelector:stopSelector];
    [anim setRemovedOnCompletion:YES];
    anim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:anim forKey:TUIAnimationPopOut];
}

- (void)popOut:(NSTimeInterval)duration delegate:(id)delegate {
    [self popOut:duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)fallIn:(NSTimeInterval)duration delegate:(id)delegate {
    [self fallIn:duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)fallIn:(NSTimeInterval)duration delegate:(id)delegate startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *anim = [[TUIAnimationAssembler animationAssembler] fallInAnimationFor:self duration:__duration delegate:delegate
                                                                         startSelector:startSelector stopSelector:stopSelector];
    [anim setRemovedOnCompletion:YES];
    anim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:anim forKey:TUIAnimationFallIn];
}

- (void)fallOut:(NSTimeInterval)duration delegate:(id)delegate {
    [self fallOut:duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)fallOut:(NSTimeInterval)duration delegate:(id)delegate startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *anim = [[TUIAnimationAssembler animationAssembler] fallOutAnimationFor:self duration:__duration delegate:delegate
                                                                          startSelector:startSelector stopSelector:stopSelector];
    [anim setRemovedOnCompletion:YES];
    anim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:anim forKey:TUIAnimationFallOut];
}

- (void)flyOut:(NSTimeInterval)duration delegate:(id)delegate {
    [self flyOut:duration delegate:delegate startSelector:nil stopSelector:nil];
}

- (void)flyOut:(NSTimeInterval)duration delegate:(id)delegate startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector {
    CAAnimation *anim = [[TUIAnimationAssembler animationAssembler] flyOutAnimationFor:self duration:__duration delegate:delegate
                                                                         startSelector:startSelector stopSelector:stopSelector];
    [anim setRemovedOnCompletion:YES];
    anim.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:anim forKey:TUIAnimationFlyOut];
}

@end