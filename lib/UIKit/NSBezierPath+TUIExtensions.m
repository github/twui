#import "NSBezierPath+TUIExtensions.h"
#import "TUICGAdditions.h"

// Sourced from Apple Documentation.
static void CGPathCallback(void *info, const CGPathElement *element) {
	NSBezierPath *path = (__bridge NSBezierPath *)(info);
	CGPoint *points = element->points;
	
	switch (element->type) {
		case kCGPathElementMoveToPoint: {
			[path moveToPoint:NSMakePoint(points[0].x, points[0].y)];
			break;
		} case kCGPathElementAddLineToPoint: {
			[path lineToPoint:NSMakePoint(points[0].x, points[0].y)];
			break;
		} case kCGPathElementAddQuadCurveToPoint: {
			NSPoint currentPoint = [path currentPoint];
			NSPoint interpolatedPoint = NSMakePoint((currentPoint.x + 2*points[0].x) / 3,
                                                    (currentPoint.y + 2*points[0].y) / 3);
			[path curveToPoint:NSMakePoint(points[1].x, points[1].y)
                 controlPoint1:interpolatedPoint
                 controlPoint2:interpolatedPoint];
			break;
		} case kCGPathElementAddCurveToPoint: {
			[path curveToPoint:NSMakePoint(points[2].x, points[2].y)
                 controlPoint1:NSMakePoint(points[0].x, points[0].y)
                 controlPoint2:NSMakePoint(points[1].x, points[1].y)];
			break;
		} case kCGPathElementCloseSubpath: {
			[path closePath];
			break;
		}
	}
}

@implementation NSBezierPath (TUIExtensions)

// Sourced from Apple Documentation.
+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)pathRef {
	NSBezierPath *path = [NSBezierPath bezierPath];
	CGPathApply(pathRef, (__bridge void *)(path), CGPathCallback);
	
	return path;
}

- (CGPathRef)CGPath {
    CGPathRef immutablePath = NULL;
    int numElements = (int)[self elementCount];
    
    if(numElements > 0) {
        CGMutablePathRef path = CGPathCreateMutable();
        NSPoint points[3];
        BOOL didClosePath = YES;
        
        for(int i = 0; i < numElements; i++) {
            switch ([self elementAtIndex:i associatedPoints:points]) {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        
        if(!didClosePath)
            CGPathCloseSubpath(path);
		
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
	
    return immutablePath;
}

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect radius:(CGFloat)radius {
	return [self bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
}

// Sourced from Google Source Toolbox for Mac.
+ (NSBezierPath *)bezierPathWithRoundedRect:(CGRect)rect
                           byRoundingCorners:(TUIRectCorner)corners
                                 cornerRadii:(CGSize)cornerRadii {
    CGMutablePathRef path = CGPathCreateMutable();
    
    const CGPoint topLeft = rect.origin;
    const CGPoint topRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    const CGPoint bottomRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    const CGPoint bottomLeft = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    
    if (corners & TUIRectCornerTopLeft)
        CGPathMoveToPoint(path, NULL, topLeft.x+cornerRadii.width, topLeft.y);
    else CGPathMoveToPoint(path, NULL, topLeft.x, topLeft.y);
    
    if (corners & TUIRectCornerTopRight) {
        CGPathAddLineToPoint(path, NULL, topRight.x-cornerRadii.width, topRight.y);
        CGPathAddCurveToPoint(path, NULL, topRight.x, topRight.y, topRight.x, topRight.y+cornerRadii.height, topRight.x, topRight.y+cornerRadii.height);
    } else CGPathAddLineToPoint(path, NULL, topRight.x, topRight.y);
    
    if (corners & TUIRectCornerBottomRight) {
        CGPathAddLineToPoint(path, NULL, bottomRight.x, bottomRight.y-cornerRadii.height);
        CGPathAddCurveToPoint(path, NULL, bottomRight.x, bottomRight.y, bottomRight.x-cornerRadii.width, bottomRight.y, bottomRight.x-cornerRadii.width, bottomRight.y);
    } else CGPathAddLineToPoint(path, NULL, bottomRight.x, bottomRight.y);
    
    if (corners & TUIRectCornerBottomLeft) {
        CGPathAddLineToPoint(path, NULL, bottomLeft.x+cornerRadii.width, bottomLeft.y);
        CGPathAddCurveToPoint(path, NULL, bottomLeft.x, bottomLeft.y, bottomLeft.x, bottomLeft.y-cornerRadii.height, bottomLeft.x, bottomLeft.y-cornerRadii.height);
    } else CGPathAddLineToPoint(path, NULL, bottomLeft.x, bottomLeft.y);
    
    if (corners & TUIRectCornerTopLeft) {
        CGPathAddLineToPoint(path, NULL, topLeft.x, topLeft.y+cornerRadii.height);
        CGPathAddCurveToPoint(path, NULL, topLeft.x, topLeft.y, topLeft.x+cornerRadii.width, topLeft.y, topLeft.x+cornerRadii.width, topLeft.y);
    } else CGPathAddLineToPoint(path, NULL, topLeft.x, topLeft.y);
    
    CGPathCloseSubpath(path);
    NSBezierPath *bezier = [NSBezierPath bezierPathWithCGPath:path];
	CGPathRelease(path);
	
	return bezier;
}

// Sourced from Matt Gemmell's NSBezierPath+StrokeExtensions
- (void)strokeInside {
    [self strokeInsideWithinRect:NSZeroRect];
}

- (void)strokeInsideWithinRect:(NSRect)clipRect {
	CGFloat lineWidth = self.lineWidth;
	
    [[NSGraphicsContext currentContext] saveGraphicsState]; {
		self.lineWidth *= 2.0f;
		[self setClip];
		
		if(clipRect.size.width > 0.0 && clipRect.size.height > 0.0)
			[NSBezierPath clipRect:clipRect];
		
		[self stroke];
	} [[NSGraphicsContext currentContext] restoreGraphicsState];
	
	self.lineWidth = lineWidth;
}

@end
