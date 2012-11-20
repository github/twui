/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "NSBezierPath+TUIExtensions.h"
#import "TUICGAdditions.h"

// Sourced from Apple Documentation.
static void tui_CGPathCallback(void *info, const CGPathElement *element) {
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
+ (NSBezierPath *)tui_bezierPathWithCGPath:(CGPathRef)pathRef {
	NSBezierPath *path = [NSBezierPath bezierPath];
	CGPathApply(pathRef, (__bridge void *)(path), tui_CGPathCallback);
	
	return path;
}

- (CGPathRef)tui_CGPath {
	CGPathRef immutablePath = NULL;
	NSInteger numElements = [self elementCount];
	
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

- (void)tui_fillWithInnerShadow:(NSShadow *)shadow {
	NSSize offset = shadow.shadowOffset;
	NSSize originalOffset = offset;
	CGFloat radius = shadow.shadowBlurRadius;
	NSRect bounds = NSInsetRect(self.bounds, -(fabs(offset.width) + radius), -(fabs(offset.height) + radius));
	offset.height += bounds.size.height;
	shadow.shadowOffset = offset;
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	if ([[NSGraphicsContext currentContext] isFlipped])
		[transform translateXBy:0 yBy:bounds.size.height];
	else
		[transform translateXBy:0 yBy:-bounds.size.height];
	
	NSBezierPath *drawingPath = [NSBezierPath bezierPathWithRect:bounds];
	[drawingPath setWindingRule:NSEvenOddWindingRule];
	[drawingPath appendBezierPath:self];
	[drawingPath transformUsingAffineTransform:transform];
	
	[NSGraphicsContext saveGraphicsState];
	[self addClip];
	[shadow set];
	
	[[NSColor blackColor] set];
	[drawingPath fill];
	[NSGraphicsContext restoreGraphicsState];
	
	shadow.shadowOffset = originalOffset;
}

- (void)tui_drawBlurWithColor:(NSColor *)color radius:(CGFloat)radius {
	NSRect bounds = NSInsetRect(self.bounds, -radius, -radius);
	NSShadow *shadow = [NSShadow tui_shadowWithRadius:radius offset:NSMakeSize(0, bounds.size.height) color:color];
	
	NSBezierPath *path = [self copy];
	NSAffineTransform *transform = [NSAffineTransform transform];
	if([[NSGraphicsContext currentContext] isFlipped])
		[transform translateXBy:0 yBy:bounds.size.height];
	else
		[transform translateXBy:0 yBy:-bounds.size.height];
	[path transformUsingAffineTransform:transform];
	
	[NSGraphicsContext saveGraphicsState];
	[shadow set];
	[[NSColor blackColor] set];
	
	NSRectClip(bounds);
	[path fill];
	[NSGraphicsContext restoreGraphicsState];
}

// Sourced from Google Source Toolbox for Mac.
+ (NSBezierPath *)tui_bezierPathWithRoundedRect:(CGRect)rect
							  byRoundingCorners:(TUIRectCorner)corners
									cornerRadii:(CGSize)cornerRadii {
	CGMutablePathRef path = CGPathCreateMutable();
	
	CGPoint topLeft = rect.origin;
	CGPoint topRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
	CGPoint bottomRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
	CGPoint bottomLeft = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
	
	if (corners & TUIRectCornerTopLeft)
		CGPathMoveToPoint(path, NULL, topLeft.x + cornerRadii.width, topLeft.y);
	else
		CGPathMoveToPoint(path, NULL, topLeft.x, topLeft.y);
	
	if (corners & TUIRectCornerTopRight) {
		CGPathAddLineToPoint(path, NULL, topRight.x - cornerRadii.width, topRight.y);
		CGPathAddCurveToPoint(path, NULL, topRight.x, topRight.y, topRight.x,
							  topRight.y + cornerRadii.height, topRight.x, topRight.y+cornerRadii.height);
	} else {
		CGPathAddLineToPoint(path, NULL, topRight.x, topRight.y);
	}
	
	if (corners & TUIRectCornerBottomRight) {
		CGPathAddLineToPoint(path, NULL, bottomRight.x, bottomRight.y - cornerRadii.height);
		CGPathAddCurveToPoint(path, NULL, bottomRight.x, bottomRight.y, bottomRight.x - cornerRadii.width,
							  bottomRight.y, bottomRight.x - cornerRadii.width, bottomRight.y);
	} else {
		CGPathAddLineToPoint(path, NULL, bottomRight.x, bottomRight.y);
	}
	
	if (corners & TUIRectCornerBottomLeft) {
		CGPathAddLineToPoint(path, NULL, bottomLeft.x + cornerRadii.width, bottomLeft.y);
		CGPathAddCurveToPoint(path, NULL, bottomLeft.x, bottomLeft.y, bottomLeft.x,
							  bottomLeft.y - cornerRadii.height, bottomLeft.x, bottomLeft.y - cornerRadii.height);
	} else {
		CGPathAddLineToPoint(path, NULL, bottomLeft.x, bottomLeft.y);
	}
	
	if (corners & TUIRectCornerTopLeft) {
		CGPathAddLineToPoint(path, NULL, topLeft.x, topLeft.y + cornerRadii.height);
		CGPathAddCurveToPoint(path, NULL, topLeft.x, topLeft.y, topLeft.x + cornerRadii.width,
							  topLeft.y, topLeft.x + cornerRadii.width, topLeft.y);
	} else {
		CGPathAddLineToPoint(path, NULL, topLeft.x, topLeft.y);
	}
	
	CGPathCloseSubpath(path);
	NSBezierPath *bezier = [NSBezierPath tui_bezierPathWithCGPath:path];
	CGPathRelease(path);
	
	return bezier;
}

// Sourced from Matt Gemmell's NSBezierPath+StrokeExtensions
- (void)tui_strokeInside {
	[self tui_strokeInsideWithinRect:NSZeroRect];
}

- (void)tui_strokeInsideWithinRect:(NSRect)clipRect {
	CGFloat lineWidth = self.lineWidth;
	
	[NSGraphicsContext saveGraphicsState];
	self.lineWidth *= 2.0f;
	[self setClip];
	
	if (clipRect.size.width > 0.0 && clipRect.size.height > 0.0)
		[NSBezierPath clipRect:clipRect];
	
	[self stroke];
	[NSGraphicsContext restoreGraphicsState];
	
	self.lineWidth = lineWidth;
}

@end
