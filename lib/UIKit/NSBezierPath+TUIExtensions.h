#import "TUIGeometry.h"

@interface NSBezierPath (TUIExtensions)

+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)pathRef;
- (CGPathRef)CGPath CF_RETURNS_RETAINED;

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect radius:(CGFloat)radius;
+ (NSBezierPath *)bezierPathWithRoundedRect:(CGRect)rect
                          byRoundingCorners:(TUIRectCorner)corners
                                cornerRadii:(CGSize)cornerRadii;

- (void)strokeInside;
- (void)strokeInsideWithinRect:(NSRect)clipRect;

@end