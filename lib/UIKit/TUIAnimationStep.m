#import "TUIAnimationStep.h"
#import "TUIView.h"

@interface TUIAnimationStep ()

// A temporary reverse queue of animation steps.
// It is created when the step is run,  is modified
// during the animation, is destroyed when finished.
@property (nonatomic, strong) NSMutableArray *consumableSteps;

@end

@implementation TUIAnimationStep

+ (id)after:(NSTimeInterval)delay animate:(TUIAnimationStepBlock)step {
	return [self after:delay for:0.0 animate:step];
}

+ (id)for:(NSTimeInterval)duration animate:(TUIAnimationStepBlock)step {
   return [self after:0.0 for:duration animate:step];
}

+ (id)after:(NSTimeInterval)delay for:(NSTimeInterval)duration animate:(TUIAnimationStepBlock)step {
	TUIAnimationStep *instance = [[self alloc] init];
	if(instance) {
		instance.delay = delay;
		instance.duration = duration;
		instance.step = [step copy];
	}
	
	return instance;
}

+ (void)runBlock:(TUIAnimationStepBlock)block afterDelay:(NSTimeInterval)delay {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*delay), dispatch_get_current_queue(), block);
}

- (NSArray *)animationStepArray {
	
	// Subclasses must override this.
	return [NSArray arrayWithObject:self];
}

- (TUIAnimationStepBlock)animationStep:(BOOL)animated {
	
	// Subclasses may want to override this.
	return self.step;
}

- (void)runAnimated:(BOOL)animated {
	if(!self.consumableSteps)
		self.consumableSteps = [[NSMutableArray alloc] initWithArray:[self animationStepArray]];
	
	// Recursion Anchor.
	if(![self.consumableSteps count]) {
		self.consumableSteps = nil;
		return;
	}
	
	// Recursive Initiatior.
	TUIAnimationStepBlock completionStep = ^{
		[self.consumableSteps removeLastObject];
		[self runAnimated:animated];
	};
	
	TUIAnimationStep *currentStep = [self.consumableSteps lastObject];
	
	// Note: do not animate steps too short in duration.
	if (animated && currentStep.duration >= 0.02) {
		[TUIView animateWithDuration:currentStep.duration
							   delay:currentStep.delay
						  animations:[currentStep animationStep:animated]
						  completion:^(BOOL finished) {
							  if(finished) {
								  completionStep();
							  }
						  }];
	} else {
		void(^execution)(void) = ^{
			[currentStep animationStep:animated]();
			completionStep();
		};
		
		if(animated && currentStep.delay) {
			[TUIAnimationStep runBlock:execution afterDelay:currentStep.delay];
		} else {
			execution();
		}
	}
}

- (void)run {
	[self runAnimated:YES];
}

- (NSString *)description {
	NSMutableString *result = [[NSMutableString alloc] initWithCapacity:100];
	
	[result appendString:@"\n["];
	if(self.delay > 0.0)
		[result appendFormat:@"after:%.1f ", self.delay];
	if(self.duration > 0.0)
		[result appendFormat:@"for:%.1f ", self.duration];
	
	[result appendFormat:@"animate:%@", self.step];
	[result appendString:@"]"];
	
	return result;
}

@end
