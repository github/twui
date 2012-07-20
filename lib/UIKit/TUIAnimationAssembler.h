#import <QuartzCore/QuartzCore.h>
@class TUIView;

// Types of possible animation directions
// when using animation managers to
// automate animation batches.
typedef enum {
    TUIAnimationDirectionTop,
    TUIAnimationDirectionRight,
    TUIAnimationDirectionBottom,
    TUIAnimationDirectionLeft,
    TUIAnimationDirectionTopLeft,
    TUIAnimationDirectionTopRight,
    TUIAnimationDirectionBottomLeft,
    TUIAnimationDirectionBottomRight
} TUIAnimationDirection;

// TUIAnimation modifier keys.
extern NSString *const TUIAnimationName;
extern NSString *const TUIAnimationType;
extern NSString *const TUIAnimationTypeIn;
extern NSString *const TUIAnimationTypeOut;
extern NSString *const TUIAnimationTargetViewKey;

// TUIAnimation indentifier keys.
extern NSString *const TUIAnimationSlideIn;
extern NSString *const TUIAnimationSlideOut;
extern NSString *const TUIAnimationBackOut;
extern NSString *const TUIAnimationBackIn;
extern NSString *const TUIAnimationFadeOut;
extern NSString *const TUIAnimationFadeIn;
extern NSString *const TUIAnimationFadeBackgroundOut;
extern NSString *const TUIAnimationFadeBackgroundIn;
extern NSString *const TUIAnimationPopIn;
extern NSString *const TUIAnimationPopOut;
extern NSString *const TUIAnimationFallIn;
extern NSString *const TUIAnimationFallOut;
extern NSString *const TUIAnimationFlyOut;

// The TUIAnimationAssembler class is meant to be used as a singleton. 
// Developers should avoid creating mulitple instances and should 
// get a reference to an instance via the animationAssembler class method.
// This should be used sparingly, and the TUIView animation category
// which wraps this animation manager should be used instead.
@interface TUIAnimationAssembler : NSObject

// The maximum value (in points) that the bouncing animations will
//travel past their end value before coming to rest. The default is 10.0.
@property(assign) CGFloat overshootThreshold;

// Get a reference to the TUIAnimationAssembler singleton.
+ (TUIAnimationAssembler *)animationAssembler;

// Wraps a CAAnimation in a CAAnimationGroup which will delay 
// the start of  the animation once it is added to a CALayer.
- (CAAnimationGroup *)delayStartOfAnimation:(CAAnimation *)animation withDelay:(CFTimeInterval)delayTime;

// Wraps a CAAnimation in a CAAnimationGroup which will delay  
// the firing of the animationDidStop:finished: delegate method 
// once the animation has stopped.
- (CAAnimationGroup *)pauseAtEndOfAnimation:(CAAnimation *)animation withDelay:(CFTimeInterval)delayTime;

// Chains a sequence of animation objects to be run sequentially.
// The animation chaining only works with animations created 
// with one of the TUIAnimationAssembler animations. If you want 
// to sequence your own CAAnimation objects, you must wrap 
// each of them with the method
// animationGroupFor:withView:duration:delegate:startSelector:stopSelector:name:type:
- (CAAnimation *)chainAnimations:(NSArray *)animations run:(BOOL)run;

// Groups a list of CAAnimations and associates them with a view.
// All animations created by TUIAnimationAssembler are created by this method.
- (CAAnimationGroup *)animationGroupFor:(NSArray *)animations withView:(TUIView *)view 
                               duration:(NSTimeInterval)duration delegate:(id)delegate 
                          startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector 
                                   name:(NSString *)name type:(NSString *)type;

// Slides a view in from offscreen.
- (CAAnimation *)slideInAnimationFor:(TUIView *)view direction:(TUIAnimationDirection)direction 
                            duration:(NSTimeInterval)duration delegate:(id)delegate 
                       startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Slides a view offscreen.
- (CAAnimation *)slideOutAnimationFor:(TUIView *)view direction:(TUIAnimationDirection)direction 
                             duration:(NSTimeInterval)duration delegate:(id)delegate 
                        startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Slides a view in from offscreen.
- (CAAnimation *)slideInAnimationFor:(TUIView *)view direction:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView
                            duration:(NSTimeInterval)duration delegate:(id)delegate 
                       startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Slides a view offscreen.
- (CAAnimation *)slideOutAnimationFor:(TUIView *)view direction:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView
                             duration:(NSTimeInterval)duration delegate:(id)delegate 
                        startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Backs a view offscreen.
- (CAAnimation *)backOutAnimationFor:(TUIView *)view withFade:(BOOL)fade direction:(TUIAnimationDirection)direction 
                            duration:(NSTimeInterval)duration delegate:(id)delegate 
                       startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Backs a view in from offscreen.
- (CAAnimation *)backInAnimationFor:(TUIView *)view withFade:(BOOL)fade direction:(TUIAnimationDirection)direction 
                           duration:(NSTimeInterval)duration delegate:(id)delegate 
                      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;
// Backs a view offscreen.
- (CAAnimation *)backOutAnimationFor:(TUIView *)view withFade:(BOOL)fade direction:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView
                            duration:(NSTimeInterval)duration delegate:(id)delegate 
                       startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Backs a view in from offscreen.
- (CAAnimation *)backInAnimationFor:(TUIView *)view withFade:(BOOL)fade direction:(TUIAnimationDirection)direction inView:(TUIView *)enclosingView
                           duration:(NSTimeInterval)duration delegate:(id)delegate 
                      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Aniamtes the alpha of the view.
- (CAAnimation *)fadeAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration 
                         delegate:(id)delegate startSelector:(SEL)startSelector 
                     stopSelector:(SEL)stopSelector fadeOut:(BOOL)fadeOut;

// Animates the backgroundColor of the view.
- (CAAnimation *)fadeBackgroundColorAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration 
                                        delegate:(id)delegate startSelector:(SEL)startSelector 
                                    stopSelector:(SEL)stopSelector fadeOut:(BOOL)fadeOut;

// Pops a view in from offscreen.
- (CAAnimation *)popInAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration delegate:(id)delegate 
                     startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Pops a view offscreen.
- (CAAnimation *)popOutAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration delegate:(id)delegate 
                      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Shrinks and fades out view.
- (CAAnimation *)fallInAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration delegate:(id)delegate 
                      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Shrinks and fades in view which starts scaled to double of its original size.
- (CAAnimation *)fallOutAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration delegate:(id)delegate 
                       startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Scales up and fades out a view.
- (CAAnimation *)flyOutAnimationFor:(TUIView *)view duration:(NSTimeInterval)duration delegate:(id)delegate 
                      startSelector:(SEL)startSelector stopSelector:(SEL)stopSelector;

// Creates an animation for a specified frame shake. You can specify the frame to
// animate, the number of shakes, the duration PER SHAKE, and the frame deviance
// index, which is how much to shake by. Think: the Mac OS X Login Window shake.
- (CAKeyframeAnimation *)shakeAnimationFor:(CGRect)frame 
                            numberOfShakes:(NSUInteger)shakes 
                                  duration:(NSTimeInterval)duration 
                         withDevianceIndex:(CGFloat)deviance;

@end

// This category on CAAnimation allows for using individual 
// selectors on arbitrary objects to respond the CAAnimationDelegate
// calls. You must not set the CAAnimation delegate property
// when using a start or stop selector. If you call 
// setStartSelector:withTarget:setStopSelector:withTarget: 
// the CAAnimation's delegate will be overwritten.
@interface CAAnimation (TUIAnimationAdditions)

// Called right before the animation starts. This has the same effect as 
// implementing the animationDidStart: delegate method.
// The selector should accept a single argument of type CAAnimation.
- (void)setStartSelector:(SEL)selector withTarget:(id)target;

// Called right before the animation stops. This has the same effect as 
// implementing the animationDidStop:finished: delegate method.
// The selector should accept a two arguments. The first argument is the
// CAAnimation object sending the message and the second is a BOOL 
// indicating whether the animation ran to completion.
- (void)setStopSelector:(SEL)selector withTarget:(id)target;

@end