#import "TUIAnimationStep.h"

// A TUIAnimationSequence defines a sequence of steps,
// which can be run with or without animation.
// The delay property will be interpreted from end
// point of the previous step.
// All steps inserted into a squence are run in
// series. You can also nest programs and other
// sequences within a sequence.
@interface TUIAnimationSequence : TUIAnimationStep

+ (id)sequenceWithSteps:(TUIAnimationStep *)first, ... NS_REQUIRES_NIL_TERMINATION;

// The array of TUIAnimationSteps the program contains.
// It may or may not represent sequence information,
// such as series vs. parallel, or order.
@property (nonatomic, strong, readonly) NSArray *steps;

@end
