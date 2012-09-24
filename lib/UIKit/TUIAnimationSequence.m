#import "TUIAnimationSequence.h"

@interface TUIAnimationStep ()

- (NSArray *)animationStepArray;

@end

@interface TUIAnimationSequence ()

@property (nonatomic, strong, readwrite) NSArray *steps;

@end

@implementation TUIAnimationSequence

+ (id)sequenceWithSteps:(TUIAnimationStep *)first, ... {
	TUIAnimationSequence *instance = [[self alloc] init];
	
	if(instance) {
		NSMutableArray *tempSteps = [[NSMutableArray alloc] initWithCapacity:10];
		va_list args;
		va_start(args, first);
		[tempSteps insertObject:first atIndex:0];
		
		TUIAnimationStep *aStep;
		while((aStep = va_arg(args, TUIAnimationStep *)))
			[tempSteps insertObject:aStep atIndex:0];
		instance.steps = [NSArray arrayWithArray:tempSteps];
		va_end(args);
	}
	
	return instance;
}


- (void)setDelay:(NSTimeInterval)delay {
    NSAssert(NO, @"You cannot set a delay on a TUIAnimationSequence.");
}

- (void)setDuration:(NSTimeInterval)duration {
    NSAssert(NO, @"You cannot set a duration on a TUIAnimationSequence.");
}

- (NSTimeInterval)duration {
	NSTimeInterval fullDuration = 0;
	
	for(TUIAnimationStep *current in self.animationStepArray) {
		fullDuration += current.delay;
		fullDuration += current.duration;
	}
	
	return fullDuration + self.delay;
}

- (NSArray *)animationStepArray {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.steps count]];
	for(TUIAnimationStep *current in self.steps)
		[array addObjectsFromArray:[current animationStepArray]];
	return array;
}

- (NSString *)description {
	NSMutableString *sequenceBody = [[NSMutableString alloc] initWithCapacity:100 * [self.steps count]];
	for(TUIAnimationStep *step in self.steps)
		[sequenceBody appendString:[step description]];
	
	[sequenceBody replaceOccurrencesOfString:@"\n"
								 withString:@"\n\t"
									options:NSCaseInsensitiveSearch
									  range:NSMakeRange(0, [sequenceBody length])];
	return [NSString stringWithFormat:@"\n<%@: %p> [sequence:%@\n]", NSStringFromClass(self.class), self, sequenceBody];
}

@end
