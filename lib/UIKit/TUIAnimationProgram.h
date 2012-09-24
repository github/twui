#import "TUIAnimationStep.h"

// A TUIAnimationProgram defines a program of steps,
// which can be run with or without animation.
// The delay property will be interpreted from start
// point of the program.
// All steps inserted into a program are run in
// parallel. You can also nest sequences and other
// programs within a program.
@interface TUIAnimationProgram : TUIAnimationStep

+ (id)programWithSteps:(TUIAnimationStep *)first, ... NS_REQUIRES_NIL_TERMINATION;

// The array of TUIAnimationSteps the program contains.
// It may or may not represent sequence information,
// such as series vs. parallel, or order.
@property (nonatomic, strong, readonly) NSArray* steps;

@end
