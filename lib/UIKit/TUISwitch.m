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

#import "TUISwitch.h"
#import "TUIStringDrawing.h"
#import "TUICGAdditions.h"

@implementation TUISwitch {
	TUIView *proxy;
	TUIView *toggle;
	TUIView *outline;
	TUIView *knob;
}

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		proxy = [[TUIView alloc] initWithFrame:self.bounds];
		self.backgroundColor = [NSColor clearColor];
		
		toggle = [[TUIView alloc] initWithFrame:self.bounds];
		toggle.drawRect = ^(TUIView *view, CGRect rect) {
			CGRect half = view.bounds;
			half.size.width /= 2.0f;
			
			[[NSColor colorWithCalibratedRed:0.0 green:0.46 blue:0.91 alpha:1.0] set];
			NSRectFill(half);
			half.origin.x = half.size.width;
			[[NSColor colorWithCalibratedWhite:0.96 alpha:1.0] set];
			NSRectFill(half);
		};
		
		outline = [[TUIView alloc] initWithFrame:self.bounds];
		outline.drawRect = ^(TUIView *view, CGRect rect) {
			CGContextRef ctx = TUIGraphicsGetCurrentContext();
			
			CGContextSaveGState(ctx);
			CGRect glossRect = CGPathGetBoundingBox(self.switchMask);
			glossRect.size.height /= 2.0f;
			
			CGContextClipToRoundRect(ctx, glossRect, self.bounds.size.height * 0.3f);
			NSGradient *gradient = [[NSGradient alloc] initWithColors:@[[NSColor colorWithCalibratedWhite:1.0 alpha:0.15],
																		[NSColor colorWithCalibratedWhite:1.0 alpha:0.50]]];
			[gradient drawInRect:glossRect angle:270.0f];
			CGContextRestoreGState(ctx);
			
			CGContextSaveGState(ctx);
			CGContextAddPath(ctx, self.switchMask);
			CGContextSetShadowWithColor(ctx, CGSizeMake(0, -1), 3.0f,
										[NSColor colorWithCalibratedWhite:0.15 alpha:0.7].CGColor);
			
			CGContextSetGrayStrokeColor(ctx, 0.6f, 1.0f);
			CGContextSetLineWidth(ctx, 1.0f);
			CGContextStrokePath(ctx);
			CGContextRestoreGState(ctx);
		};
		
		knob = [[TUIView alloc] initWithFrame:self.bounds];
		knob.drawRect = ^(TUIView *view, CGRect rect) {
			NSArray *knobColors = @[[NSColor colorWithCalibratedWhite:self.knobGripped ? 0.89 : 0.99 alpha:1.0],
			[NSColor colorWithCalibratedWhite:0.82 alpha:1.0]];
			NSArray *highlightColors = @[[NSColor whiteColor], [NSColor colorWithCalibratedWhite:1.0 alpha:0.5]];
			
			NSBezierPath *knobPath = [NSBezierPath bezierPathWithOvalInRect:CGRectInset(rect, 0.5, 0.5)];
			NSGradient *knobGradient = [[NSGradient alloc] initWithColors:knobColors];
			
			[knobGradient drawInBezierPath:knobPath angle:90.0f];
			[[NSColor colorWithCalibratedWhite:0.5 alpha:1.0f] set];
			[knobPath stroke];
			
			CGContextRef ctx = TUIGraphicsGetCurrentContext();
			CGContextSaveGState(ctx);
			
			CGContextAddEllipseInRect(ctx, CGRectInset(rect, 1.0, 1.0));
			CGContextAddEllipseInRect(ctx, CGRectInset(rect, 2.0, 2.0));
			CGContextEOClip(ctx);
			
			[[[NSGradient alloc] initWithColors:highlightColors] drawInRect:rect angle:270.0f];
			CGContextRestoreGState(ctx);
		};
		
		proxy.userInteractionEnabled = NO;
		proxy.backgroundColor = [NSColor clearColor];
		toggle.userInteractionEnabled = NO;
		toggle.backgroundColor = [NSColor clearColor];
		outline.userInteractionEnabled = NO;
		outline.backgroundColor = [NSColor clearColor];
		knob.userInteractionEnabled = NO;
		knob.backgroundColor = [NSColor clearColor];
		
		[proxy addSubview:toggle];
		[proxy addSubview:outline];
		[proxy addSubview:knob];
		[self addSubview:proxy];
	}
	return self;
}

- (void)layoutSubviews {
	CGFloat padding = 2.0f;
	CGRect backRect = self.bounds;
	CGRect knobRect = CGRectMake(self.bounds.size.width - self.bounds.size.height, 0,
								 self.bounds.size.height, self.bounds.size.height);
	backRect.size.width *= 2.0f;
	backRect.size.width -= knobRect.size.width;
	
	knob.frame = CGRectInset(knobRect, padding, padding);
	outline.frame = self.bounds;
	toggle.frame = backRect;
	
	CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.path = self.switchMask;
    maskLayer.fillColor = CGColorGetConstantColor(kCGColorBlack);
    
    proxy.layer.mask = maskLayer;
}

- (CGPathRef)switchMask {
	CGFloat padding = 2.0f;
	CGRect rect = CGRectInset(self.bounds, padding, padding);
	CGFloat radius = rect.size.height / 2.0;
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddArc(path, NULL, radius + padding, radius + padding,
				 radius, M_PI / 2 , 3 * M_PI / 2, NO);
	CGPathAddArc(path, NULL, rect.size.width - radius + padding, radius + padding,
				 radius, 3 * M_PI / 2, M_PI / 2, NO);
	CGPathCloseSubpath(path);
	
	return path;
}

- (BOOL)beginTrackingWithEvent:(NSEvent *)event {
	self.knobGripped = YES;
	[knob setNeedsDisplay];
	[outline setNeedsDisplay];
	[toggle setNeedsDisplay];
	
	return YES;
}

- (BOOL)continueTrackingWithEvent:(NSEvent *)event {
	CGRect knobRect = CGRectIntegral(knob.frame);
	CGRect toggleRect = CGRectIntegral(toggle.frame);
	
	toggleRect.origin.x += event.deltaX;
	knobRect.origin.x += event.deltaX;
	
	CGRect switchFrame = CGPathGetBoundingBox(self.switchMask);
	if(knobRect.origin.x < switchFrame.origin.x ||
	   (knobRect.origin.x + knobRect.size.width) > (switchFrame.origin.x + switchFrame.size.width))
		return YES;
	
	[TUIView animateWithDuration:0.1 animations:^{
		[TUIView setAnimationCurve:TUIViewAnimationCurveLinear];
		knob.frame = knobRect;
		toggle.frame = toggleRect;
	}];
	
	return YES;
}

- (void)endTrackingWithEvent:(NSEvent *)event {
	CGRect knobRect = CGRectIntegral(knob.frame);
	CGRect toggleRect = CGRectIntegral(toggle.frame);
	
	self.knobGripped = NO;
	[knob setNeedsDisplay];
	[outline setNeedsDisplay];
	[toggle setNeedsDisplay];
	
	CGRect switchFrame = CGPathGetBoundingBox(self.switchMask);
	if(CGRectGetMidX(knobRect) < CGRectGetMidX(switchFrame))
		knobRect.origin.x = CGRectGetMinX(switchFrame);
	else
		knobRect.origin.x = CGRectGetMaxX(switchFrame) - knobRect.size.width;
	toggleRect.origin.x = CGRectGetMidX(knobRect) - CGRectGetWidth(toggleRect) / 2;
	
	[TUIView animateWithDuration:0.2 animations:^{
		[TUIView setAnimationCurve:TUIViewAnimationCurveEaseInOut];
		knob.frame = knobRect;
		toggle.frame = toggleRect;
	}];
}

@end
