#import "TUILayoutConstraint.h"
#import "TUILayoutManager.h"

@interface TUIView (Layout_Private)

- (NSRect)valueForLayoutAttribute:(TUILayoutConstraintAttribute)attribute;
- (void)setValue:(NSRect)newValue forLayoutAttribute:(TUILayoutConstraintAttribute)attribute;

@end


@interface TUILayoutConstraint ()

@property (nonatomic, copy) NSValueTransformer *valueTransformer;

- (CGFloat)transformValue:(CGFloat)original;
- (void)applyToTargetView:(TUIView *)target;
- (void)applyToTargetView:(TUIView *)target sourceView:(TUIView *)source;

@end

@interface TUILayoutBlockValueTransformer : NSValueTransformer

@property (nonatomic, copy) TUILayoutTransformer transformer;

+ (id)transformerWithBlock:(TUILayoutTransformer)block;
- (id)initWithBlock:(TUILayoutTransformer)block;

@end

@implementation TUILayoutConstraint

@synthesize attribute = _attribute;
@synthesize sourceAttribute = _sourceAttribute;
@synthesize sourceName = _sourceName;
@synthesize valueTransformer = _valueTransformer;

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)srcLayer
                    attribute:(TUILayoutConstraintAttribute)srcAttr {
	return [self constraintWithAttribute:attr relativeTo:srcLayer attribute:srcAttr scale:1.0 offset:0.0];
}

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)srcLayer
                    attribute:(TUILayoutConstraintAttribute)srcAttr
                       offset:(CGFloat)offset {
	return [self constraintWithAttribute:attr relativeTo:srcLayer attribute:srcAttr scale:1.0 offset:offset];
}

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)source
                    attribute:(TUILayoutConstraintAttribute)srcAttr
                        scale:(CGFloat)scale
                       offset:(CGFloat)offset {
    return [[self alloc] initWithAttribute:attr relativeTo:source attribute:srcAttr scale:scale offset:offset];
}

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                    relativeTo:(NSString *)srcLayer
                    attribute:(TUILayoutConstraintAttribute)srcAttr
             blockTransformer:(TUILayoutTransformer)transformer {
	TUILayoutBlockValueTransformer *t = [TUILayoutBlockValueTransformer transformerWithBlock:transformer];
	return [self constraintWithAttribute:attr relativeTo:srcLayer attribute:srcAttr valueTransformer:t];
}

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)srcLayer
                    attribute:(TUILayoutConstraintAttribute)srcAttr
             valueTransformer:(NSValueTransformer *)transformer {
	return [[self alloc] initWithAttribute:attr relativeTo:srcLayer attribute:srcAttr valueTransformer:transformer];
}

- (id)initWithAttribute:(TUILayoutConstraintAttribute)attr
             relativeTo:(NSString *)srcLayer
              attribute:(TUILayoutConstraintAttribute)srcAttr
       valueTransformer:(NSValueTransformer *)transformer {
    
	double attributeRange = floor(log10(attr));
	double sourceAttributeRange = floor(log10(srcAttr));
	
    NSAssert(fabs(attributeRange - sourceAttributeRange) < 0.001, @"Invalid source and target attributes: %f, %f", sourceAttributeRange, attributeRange);
	
	if((self = [super init])) {
		_attribute = attr;
		_sourceAttribute = srcAttr;
				
		_sourceName = [srcLayer copy];
		_valueTransformer = transformer;
	}
    return self;
}

- (CGFloat)transformValue:(CGFloat)original {
	id transformed = [self.valueTransformer transformedValue:[NSNumber numberWithFloat:original]];
	return [transformed floatValue];
}

- (void)applyToTargetView:(TUIView *)target {
	TUIView *source = [target relativeViewForName:[self sourceName]];
	[self applyToTargetView:target sourceView:source];
}

- (void)applyToTargetView:(TUIView *)target sourceView:(TUIView *)source {
	if(source == target) return;
	if(source == nil) return;
	if([self sourceAttribute] == 0) return;
	
	NSRect sourceValue = [source valueForLayoutAttribute:[self sourceAttribute]];
	NSRect targetValue = sourceValue;
    
	if(self.attribute >= TUILayoutConstraintAttributeMinY && self.attribute <= TUILayoutConstraintAttributeMidX)
		targetValue.origin.x = [self transformValue:sourceValue.origin.x];
	
	[target setValue:targetValue forLayoutAttribute:[self attribute]];
}

@end

@implementation TUILayoutBlockValueTransformer

@synthesize transformer = _transformer;

+ (id)transformerWithBlock:(TUILayoutTransformer)block {
	return [[self alloc] initWithBlock:block];
}

- (id)initWithBlock:(TUILayoutTransformer)block {
	if((self = [super init])) {
		_transformer = [block copy];
	}
    return self;
}

- (id)transformedValue:(id)value {
    if(!self.transformer) return nil;
	CGFloat source = [value floatValue];
	CGFloat transformed = self.transformer(source);
	return [NSNumber numberWithFloat:transformed];
}

@end