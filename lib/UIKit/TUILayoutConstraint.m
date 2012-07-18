#import "TUILayoutConstraint.h"

@interface TUIView (TUILayoutConstraint)
@property (nonatomic, copy) NSString *constraintIdentifier;
@end

static TUIView* subviewWithConstraintIdentifierInView(TUIView *view, NSString *identifier) {
    for (TUIView *subview in view.subviews)
        if ([subview.constraintIdentifier isEqualToString:identifier])
            return subview;
    return nil;
}

@interface TUILayoutConstraint ()

@property (nonatomic, readwrite, copy) NSString *firstItem;
@property (nonatomic, readwrite, copy) NSString *secondItem;
@property (nonatomic, readwrite, assign) TUILayoutAttribute firstAttribute;
@property (nonatomic, readwrite, assign) TUILayoutAttribute secondAttribute;
@property (nonatomic, readwrite, assign) CGFloat multiplier;
@property (nonatomic, readwrite, assign) CGFloat constant;

- (id)initWithItem:(NSString *)firstItem
         attribute:(TUILayoutAttribute)firstAttribute
            toItem:(NSString *)secondItem
         attribute:(TUILayoutAttribute)secondAttribute
        multiplier:(CGFloat)multiplier
          constant:(CGFloat)constant;

@end

@implementation TUILayoutConstraint

@synthesize firstItem = _firstItem;
@synthesize secondItem = _secondItem;
@synthesize firstAttribute = _firstAttribute;
@synthesize secondAttribute = _secondAttribute;
@synthesize multiplier = _multiplier;
@synthesize constant = _constant;

+ (id)constraintWithItem:(NSString *)firstItem
               attribute:(TUILayoutAttribute)firstAttribute
                  toItem:(NSString *)secondItem
               attribute:(TUILayoutAttribute)secondAttribute
              multiplier:(CGFloat)multiplier
                constant:(CGFloat)constant {
    return [[TUILayoutConstraint alloc] initWithItem:firstItem
                                            attribute:firstAttribute
                                               toItem:secondItem
                                            attribute:secondAttribute
                                           multiplier:multiplier
                                             constant:constant];
}

- (id)initWithItem:(NSString *)firstItem
         attribute:(TUILayoutAttribute)firstAttribute 
            toItem:(NSString *)secondItem 
         attribute:(TUILayoutAttribute)secondAttribute 
        multiplier:(CGFloat)multiplier 
          constant:(CGFloat)constant {
    if((self = [super init])) {
        self.firstItem = firstItem;
        self.firstAttribute = firstAttribute;
        self.secondItem = secondItem;
        self.secondAttribute = secondAttribute;
        self.multiplier = multiplier;
        self.constant = constant;
    } return self;
}


- (CGFloat)relativeValueInView:(TUIView *)superview {
    CGRect frame = CGRectZero;
    if(self.secondItem)
        frame = subviewWithConstraintIdentifierInView(superview, self.secondItem).frame;
    else frame = superview.frame;
    
    CGFloat rVal = 0.0f;
    switch(self.secondAttribute) {
        case TUILayoutAttributeLeft:
            rVal = CGRectGetMinX(frame);
            break;
        case TUILayoutAttributeCenterX:
            rVal = CGRectGetMidX(frame);
            break;
        case TUILayoutAttributeRight:
            rVal = CGRectGetMaxX(frame);
            break;
        case TUILayoutAttributeWidth:
            rVal = CGRectGetWidth(frame);
            break;
        case TUILayoutAttributeBottom:
            rVal = CGRectGetMinY(frame);
            break;
        case TUILayoutAttributeCenterY:
            rVal = CGRectGetMidY(frame);
            break;
        case TUILayoutAttributeTop:
            rVal = CGRectGetMaxY(frame);
            break;
        case TUILayoutAttributeHeight:
            rVal = CGRectGetHeight(frame);
            break;
    }
    
    return (rVal * self.multiplier) + self.constant;
}

- (NSString *)attributeToString:(TUILayoutAttribute)aAttribute {
    switch(aAttribute) {
        case TUILayoutAttributeLeft:
            return @"Left";
        case TUILayoutAttributeCenterX:
            return @"CenterX";
        case TUILayoutAttributeRight:
            return @"Right";
        case TUILayoutAttributeWidth:
            return @"Width";
        case TUILayoutAttributeBottom:
            return @"Bottom";
        case TUILayoutAttributeCenterY:
            return @"CenterY";
        case TUILayoutAttributeTop:
            return @"Top";
        case TUILayoutAttributeHeight:
            return @"Height";
    } return @"";
}

- (NSString *)description; {
    return [NSString stringWithFormat:@"Layout %p: %p's %@ attribute depends on %p's %@ attribute.",
            self,
            self.firstItem,
            [self attributeToString:self.firstAttribute],
            self.secondItem,
            [self attributeToString:self.secondAttribute]];
}

@end