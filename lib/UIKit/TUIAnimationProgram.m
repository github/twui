#import "TUIAnimationProgram.h"

@interface TUIAnimationStep ()

- (NSArray *)animationStepArray;
- (TUIAnimationStepBlock)animationStep:(BOOL)animated;

@end

@interface TUIAnimationProgram ()

@property (nonatomic, strong, readwrite) NSArray* steps;

@end

@implementation TUIAnimationProgram

+ (id)programWithSteps:(TUIAnimationStep *)first, ... {
	TUIAnimationProgram *instance = [[self alloc] init];
	
	if(instance) {
		NSMutableArray* tempSteps = [[NSMutableArray alloc] initWithCapacity:10];
		va_list args;
		va_start(args, first);
		[tempSteps insertObject:first atIndex:0];
		
		TUIAnimationStep *aStep;
		while((aStep = va_arg(args, TUIAnimationStep*)))
			[tempSteps insertObject:aStep atIndex:0];
		instance.steps = [NSArray arrayWithArray:tempSteps];
		va_end(args);
	}
	
	return instance;
}

- (void)setDelay:(NSTimeInterval)delay {
    NSAssert(NO, @"You cannot set a delay on a TUIAnimationProgram.");
}

- (void)setDuration:(NSTimeInterval)duration {
    NSAssert(NO, @"You cannot set a duration on a TUIAnimationProgram.");
}

- (NSTimeInterval)longestDuration {
	TUIAnimationStep *longestStep = nil;
	for(TUIAnimationStep *current in self.steps) {
		NSTimeInterval currentDuration = current.delay + current.duration;
		
		if(currentDuration > longestStep.delay + longestStep.duration)
			longestStep = current;
	}
	
	NSAssert(longestStep, @"This program seems to contain no steps.");
	return self.delay + longestStep.delay + longestStep.duration;
}

- (NSArray *)animationStepArray {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:3];
	
	// There are in reverse order.
	[array addObject:[TUIAnimationStep after:[self longestDuration] animate:^{}]];
    [array addObject:self];
	[array addObject:[TUIAnimationStep after:self.delay animate:^{}]];
	
	return array;
}

- (TUIAnimationStepBlock)animationStep:(BOOL)animated {
	TUIAnimationStepBlock programStep = ^{
		for(TUIAnimationStep *current in self.steps)
			[current runAnimated:animated];
	};
	
	return [programStep copy];
}

- (NSString *)description {
	NSMutableString *programBody = [[NSMutableString alloc] initWithCapacity:100 * [self.steps count]];
	for(TUIAnimationStep *step in self.steps)
		[programBody appendString:[step description]];
	
	[programBody replaceOccurrencesOfString:@"\n"
								 withString:@"\n\t"
									options:NSCaseInsensitiveSearch
									  range:NSMakeRange(0, programBody.length)];
	
	return [NSString stringWithFormat:@"\n<%@: %p> [program:%@\n]", NSStringFromClass(self.class), self, programBody];
}

@end
