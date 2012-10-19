#import <Cocoa/Cocoa.h>

enum {
    NSRectCornerTopLeft     = 1 << 0,
    NSRectCornerTopRight    = 1 << 1,
    NSRectCornerBottomLeft  = 1 << 2,
    NSRectCornerBottomRight = 1 << 3,
    NSRectCornerAllCorners  = ~0
};
typedef NSUInteger NSRectCorner;

@interface NSBezierPath (TUIExtensions)

+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)pathRef;
- (CGPathRef)CGPath CF_RETURNS_RETAINED;

+ (NSBezierPath *)bezierPathWithRoundedRect:(CGRect)rect
                          byRoundingCorners:(NSRectCorner)corners
                                cornerRadii:(CGSize)cornerRadii;

- (void)strokeInside;
- (void)strokeInsideWithinRect:(NSRect)clipRect;

@end