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

@interface TUISwitch ()

@property (nonatomic, strong) TUIView *proxy;
@property (nonatomic, strong) TUIView *toggle;
@property (nonatomic, strong) TUIView *outline;
@property (nonatomic, strong) TUIView *knob;

@property (nonatomic, readwrite, getter = knobIsGrippsed) BOOL knobGripped;

@end

@implementation TUISwitch

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		self.proxy = [[TUIView alloc] initWithFrame:self.bounds];
		self.backgroundColor = [NSColor clearColor];
		
		self.toggle = [[TUIView alloc] initWithFrame:self.bounds];
		self.toggle.drawRect = ^(TUIView *view, CGRect rect) {
			CGRect half = view.bounds;
			half.size.width /= 2.0f;
			
			[[NSColor colorWithCalibratedRed:0.0 green:0.46 blue:0.91 alpha:1.0] set];
			NSRectFill(half);
			half.origin.x = half.size.width;
			[[NSColor colorWithCalibratedWhite:0.96 alpha:1.0] set];
			NSRectFill(half);
		};
		
		self.outline = [[TUIView alloc] initWithFrame:self.bounds];
		self.outline.drawRect = ^(TUIView *view, CGRect rect) {
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
		
		self.knob = [[TUIView alloc] initWithFrame:self.bounds];
		self.knob.drawRect = ^(TUIView *view, CGRect rect) {
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
		
		self.proxy.userInteractionEnabled = NO;
		self.proxy.backgroundColor = [NSColor clearColor];
		self.toggle.userInteractionEnabled = NO;
		self.toggle.backgroundColor = [NSColor clearColor];
		self.outline.userInteractionEnabled = NO;
		self.outline.backgroundColor = [NSColor clearColor];
		self.knob.userInteractionEnabled = NO;
		self.knob.backgroundColor = [NSColor clearColor];
		
		[self.proxy addSubview:self.toggle];
		[self.proxy addSubview:self.outline];
		[self.proxy addSubview:self.knob];
		[self addSubview:self.proxy];
		
		_on = NO;
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
	
	self.knob.frame = CGRectInset(knobRect, padding, padding);
	self.outline.frame = self.bounds;
	self.toggle.frame = backRect;
	
	CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.path = self.switchMask;
    maskLayer.fillColor = CGColorGetConstantColor(kCGColorBlack);
    self.proxy.layer.mask = maskLayer;
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
	CGRect knobRect = CGRectIntegral(self.knob.frame);
	CGRect toggleRect = CGRectIntegral(self.toggle.frame);
	
	CGRect switchFrame = CGPathGetBoundingBox(self.switchMask);
	CGPoint eventPoint = [self convertPoint:event.locationInWindow fromView:nil];
	
	// If the user clicked the knob, tell it that it's gripped.
	if([self.knob pointInside:[self.knob convertPoint:eventPoint fromView:self] withEvent:event]) {
		self.knobGripped = YES;
		
		[self.knob setNeedsDisplay];
		[self.outline setNeedsDisplay];
		[self.toggle setNeedsDisplay];
	}
	
	// Attempt to calculate the point to slide the knob to,
	// which would be right where the user clicked the track.
	knobRect.origin.x += floor(eventPoint.x - CGRectGetMidX(knobRect));
	toggleRect.origin.x += floor(eventPoint.x - CGRectGetMidX(toggleRect));
	
	// If the user pressed the knob close the the edges, and the
	// knob might poke out of the track, adjust it so it stays in.
	if(CGRectGetMinX(knobRect) < CGRectGetMinX(switchFrame))
		knobRect.origin.x = CGRectGetMinX(switchFrame);
	else if(CGRectGetMaxX(knobRect) > CGRectGetMaxX(switchFrame))
		knobRect.origin.x = CGRectGetMaxX(switchFrame) - CGRectGetWidth(knobRect);
	toggleRect.origin.x = CGRectGetMidX(knobRect) - CGRectGetWidth(toggleRect) / 2;
	
	// Animate its new position by sliding it.
	[TUIView animateWithDuration:0.1 animations:^{
		[TUIView setAnimationCurve:TUIViewAnimationCurveLinear];
		self.knob.frame = knobRect;
		self.toggle.frame = toggleRect;
	}];
	
	return YES;
}

- (BOOL)continueTrackingWithEvent:(NSEvent *)event {
	CGRect knobRect = CGRectIntegral(self.knob.frame);
	CGRect toggleRect = CGRectIntegral(self.toggle.frame);
	CGRect switchFrame = CGPathGetBoundingBox(self.switchMask);
	
	// If the user drags the knob, move the knob and its track.
	toggleRect.origin.x += event.deltaX;
	knobRect.origin.x += event.deltaX;
	
	// If they dragged it out of the track's bounds, don't move it.
	if(CGRectGetMinX(knobRect) < CGRectGetMinX(switchFrame) ||
	   CGRectGetMaxX(knobRect) > CGRectGetMaxX(switchFrame))
		return YES;
	
	// If the knob is still within bounds, interpolate it by
	// using a linear animation curve, so any "jumps" aren't seen.
	[TUIView animateWithDuration:0.1 animations:^{
		[TUIView setAnimationCurve:TUIViewAnimationCurveLinear];
		self.knob.frame = knobRect;
		self.toggle.frame = toggleRect;
	}];
	
	return YES;
}

- (void)endTrackingWithEvent:(NSEvent *)event {
	CGRect knobRect = CGRectIntegral(self.knob.frame);
	CGRect switchFrame = CGPathGetBoundingBox(self.switchMask);
	
	// If the knob ended on the right half of the track, it's on.
	// Tell ourselves to animate and cache the state of the switch.
	[self setOn:(CGRectGetMidX(knobRect) > CGRectGetMidX(switchFrame)) animated:YES];
}

- (void)setOn:(BOOL)on {
	[self setOn:on animated:NO];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
	_on = on;
	
	CGRect knobRect = CGRectIntegral(self.knob.frame);
	CGRect toggleRect = CGRectIntegral(self.toggle.frame);
	CGRect switchFrame = CGPathGetBoundingBox(self.switchMask);
	
	// Adjust the knob to slide to the left or right track edge
	// depending on whether it's on or off.
	knobRect.origin.x = on ? CGRectGetMaxX(switchFrame) - CGRectGetWidth(knobRect) : CGRectGetMinX(switchFrame);
	toggleRect.origin.x = CGRectGetMidX(knobRect) - CGRectGetWidth(toggleRect) / 2;
	
	// The knob can't be gripped anymore, so un-grip it, and animate
	// the knob slide. Ease the knob over so it seems natural.
	self.knobGripped = NO;
	if(animated) {
		[TUIView animateWithDuration:0.2 animations:^{
			[TUIView setAnimationCurve:TUIViewAnimationCurveEaseInOut];
			self.knob.frame = knobRect;
			self.toggle.frame = toggleRect;
			
			[self.knob redraw];
			[self.outline redraw];
			[self.toggle redraw];
		}];
	} else {
		self.knob.frame = knobRect;
		self.toggle.frame = toggleRect;
		
		[self.knob setNeedsDisplay];
		[self.outline setNeedsDisplay];
		[self.toggle setNeedsDisplay];
	}
	
	// Alert listeners that the value of the switch changed.
	[self sendActionsForControlEvents:TUIControlEventValueChanged];
}

@end
