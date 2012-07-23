//
//	NSTextView+TUIExtensions.m
//
//	Created by Justin Spahr-Summers on 10.03.12.
//	Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSTextView+TUIExtensions.h"
#import <objc/runtime.h>

static void (*originalDrawRectIMP)(id, SEL, NSRect);

static void fixedDrawRect (NSTextView *self, SEL _cmd, NSRect rect) {
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;

	CGContextSetAllowsAntialiasing(context, YES);
	CGContextSetAllowsFontSmoothing(context, YES);
	CGContextSetAllowsFontSubpixelPositioning(context, YES);
	CGContextSetAllowsFontSubpixelQuantization(context, YES);

	CGContextSetShouldAntialias(context, YES);

	// TODO: SPAA seems to stop working when text fields and text views lose
	// focus, so it's disabled for now.
	CGContextSetShouldSmoothFonts(context, NO);
	CGContextSetShouldSubpixelPositionFonts(context, NO);
	CGContextSetShouldSubpixelQuantizeFonts(context, NO);

	if (self.superview) {
		// NSTextView likes to fall on non-integral points sometimes -- fix that
		self.frame = [self.superview backingAlignedRect:self.frame options:NSAlignAllEdgesNearest];
	}

	originalDrawRectIMP(self, _cmd, rect);
}

@implementation NSTextView (TUIExtensions)

+ (void)load {
	Method drawRect = class_getInstanceMethod(self, @selector(drawRect:));
	originalDrawRectIMP = (void (*)(id, SEL, NSRect))method_getImplementation(drawRect);

	class_replaceMethod(self, method_getName(drawRect), (IMP)&fixedDrawRect, method_getTypeEncoding(drawRect));
}

@end
