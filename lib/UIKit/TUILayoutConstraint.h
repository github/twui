@class TUIView;

typedef enum : NSUInteger {
	TUILayoutConstraintAttributeMinY    = 1,
	TUILayoutConstraintAttributeMaxY    = 2,
	TUILayoutConstraintAttributeMinX    = 3,
	TUILayoutConstraintAttributeMaxX    = 4,
	TUILayoutConstraintAttributeWidth   = 5,
	TUILayoutConstraintAttributeHeight  = 6,
	TUILayoutConstraintAttributeMidY    = 7,
	TUILayoutConstraintAttributeMidX    = 8,
	
	TUILayoutConstraintAttributeMinXMinY = 101,
	TUILayoutConstraintAttributeMinXMidY = 102,
	TUILayoutConstraintAttributeMinXMaxY = 103,
	
	TUILayoutConstraintAttributeMidXMinY = 104,
	TUILayoutConstraintAttributeMidXMidY = 105,
	TUILayoutConstraintAttributeMidXMaxY = 106,
	
	TUILayoutConstraintAttributeMaxXMinY = 107,
	TUILayoutConstraintAttributeMaxXMidY = 108,
	TUILayoutConstraintAttributeMaxXMaxY = 109,
	
	TUILayoutConstraintAttributeBoundsCenter = 110,
	
	TUILayoutConstraintAttributeFrame   = 1000,
	TUILayoutConstraintAttributeBounds  = 1001
} TUILayoutConstraintAttribute;

typedef CGFloat (^TUILayoutTransformer)(CGFloat);

@interface TUILayoutConstraint : NSObject

@property (readonly) TUILayoutConstraintAttribute attribute;
@property (readonly) TUILayoutConstraintAttribute sourceAttribute;
@property (readonly) NSString *sourceName;

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)source
                    attribute:(TUILayoutConstraintAttribute)srcAttr;
+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)source
                    attribute:(TUILayoutConstraintAttribute)srcAttr
                       offset:(CGFloat)offset;
+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)source
                    attribute:(TUILayoutConstraintAttribute)srcAttr
                        scale:(CGFloat)scale
                       offset:(CGFloat)offset;

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)source
                    attribute:(TUILayoutConstraintAttribute)srcAttr
             blockTransformer:(TUILayoutTransformer)transformer;
+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)source
                    attribute:(TUILayoutConstraintAttribute)srcAttr
             valueTransformer:(NSValueTransformer *)transformer;

@end
