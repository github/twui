typedef void (^TUIAnimationStepBlock)(void);

// A TUIAnimationStep defines a single animation object
// with a delay, duration, execution block and animation options.
// This is a Composite design pattern class. It allows for
// subclassing and complex animation patterns. For examples,
// look at TUIAnimationProgram and TUIAnimationSequence.
@interface TUIAnimationStep : NSObject

+ (id)after:(NSTimeInterval)delay
	animate:(TUIAnimationStepBlock)step;

+ (id)for:(NSTimeInterval)duration
  animate:(TUIAnimationStepBlock)step;

+ (id)after:(NSTimeInterval)delay
		for:(NSTimeInterval)duration
	animate:(TUIAnimationStepBlock)step;

@property (nonatomic) NSTimeInterval delay;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic, copy) TUIAnimationStepBlock step;

// Execute the  step with or without animation.
- (void)runAnimated:(BOOL)animated;

// Shortcut method for -runAnimated:YES.
- (void)run;

@end
