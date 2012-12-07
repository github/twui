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

#import "ExampleTabBar.h"

@interface ExampleTab : TUIControl

@property (nonatomic, assign) CGFloat originalPosition;
@property (nonatomic, strong) NSTimer *flashTimer;

@end

@implementation ExampleTab

// Convinience to call delegate methods, since by default, our
// superview SHOULD be a tab bar, and nothing else. This will
// horribly crash if you add an ExampleTab to anything but a tab bar.
- (ExampleTabBar *)tabBar {
	return (ExampleTabBar *)self.superview;
}

// If a tracking event occurs within a tab, we want to move the
// tab around, so return YES.
- (BOOL)beginTrackingWithEvent:(NSEvent *)event {
	[self setNeedsDisplay];
	
	// So the tab doesn't move over just on mouse pressed.
	self.originalPosition = [self convertPoint:[event locationInWindow] fromView:nil].x;
	
	return YES;
}

// Find the tab that was being dragged- although this isn't the
// most efficient way, this will suffice for now.
- (BOOL)continueTrackingWithEvent:(NSEvent *)event {
	
	// Offset the tab's x origin by whatever we dragged by.
	CGFloat currentPosition = [self convertPoint:event.locationInWindow fromView:nil].x;
	
	CGRect draggedRect = self.frame;
	draggedRect.origin.x += roundf(currentPosition - self.originalPosition);
	self.frame = draggedRect;
	
	return YES;
}

// Restore tabs to their original condition.
- (void)endTrackingWithEvent:(NSEvent *)event {
	
	// By nature, the event *must* be inside the tab's bounds, otherwise the
	// tracking process will not be invoked. If we were dragged, we were NOT
	// pressed, so don't call the delegate.
	CGFloat currentPosition = [self convertPoint:event.locationInWindow fromView:nil].x;
	if(self.originalPosition == currentPosition)
		[self.tabBar.delegate tabBar:self.tabBar didSelectTab:self.tag];
	
	// Since tracking is done, move the tab back. This whole ordeal lets us
	// "stretch" our tabs around.
	CGFloat originalPoint = self.tag * (self.tabBar.bounds.size.width / self.tabBar.tabViews.count);
	[TUIView animateWithDuration:0.25f animations:^{
		CGRect draggedRect = self.frame;
		draggedRect.origin.x = roundf(originalPoint);
		self.frame = draggedRect;
	}];
	
	// Rather than a simple -setNeedsDisplay, let's fade it back out.
	[TUIView animateWithDuration:0.25f animations:^{
		
		// -redraw forces a .contents update immediately based on drawRect,
		// and it happens inside an animation block, so CoreAnimation gives
		// us a cross-fade for free.
		[self redraw];
	}];
}

// End control tracking when cancelled for any reason.
- (void)cancelTrackingWithEvent:(NSEvent *)event {
	[self endTrackingWithEvent:event];
}

// When the tab is tapped with two fingers, let it pulse, otherwise
// do nothing. To let it pulse, use the selected property and toggle it.
- (void)touchesBeganWithEvent:(NSEvent *)event {
	if([self touchesMatchingPhase:NSTouchPhaseTouching forEvent:event].count != 2)
		return;
	
	// Using -redraw within an animation block lets us crossfade
	// the tab selection. When we finish this animation, queue
	// the pulsing with a timer set repeat the -flash method.
	[TUIView animateWithDuration:0.25f animations:^{
		self.selected = YES;
		[self redraw];
	} completion:^(BOOL finished) {
		if(finished) {
			self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:0.25f
															   target:self selector:@selector(flash)
															 userInfo:nil repeats:YES];
		}
	}];
}

// If the touches have ended, invalidate the timer and animate
// back to the standard state, setting .selected as NO.
- (void)touchesEndedWithEvent:(NSEvent *)event {
	[self.flashTimer invalidate];
	self.flashTimer = nil;
	
	[TUIView animateWithDuration:0.25f animations:^{
		self.selected = NO;
		[self redraw];
	}];
}

// End touch tracking when cancelled for any reason.
- (void)touchesCancelledWithEvent:(NSEvent *)event {
	[self touchesEndedWithEvent:event];
}

// This method, called from a timer, should pulse the tab by
// flipping the .selected property value, and animating the change.
- (void)flash {
	[TUIView animateWithDuration:0.25f animations:^{
		self.selected = !self.selected;
		[self redraw];
	}];
}

@end

@interface ExampleTabBar ()

@property (nonatomic, assign) ExampleTab *draggingTab;

@end

@implementation ExampleTabBar

- (id)initWithNumberOfTabs:(NSUInteger)count {
	if((self = [super initWithFrame:CGRectZero])) {
		NSMutableArray *tabs = [NSMutableArray arrayWithCapacity:count];
		
		for(int i = 0; i < count; ++i) {
			ExampleTab *tab = [[ExampleTab alloc] initWithFrame:CGRectZero];
			tab.acceptsTouchEvents = YES;
			tab.wantsRestingTouches = YES;
			tab.tag = i;
			
			// The layout of an individual tab is a function of the superview bounds,
			// the number of tabs, and the current tab index.
			// Reference the passed-in 'view' rather than 'tab' to avoid a retain cycle.
			tab.layout = ^(TUIView *view) {
				CGRect rect = view.superview.bounds;
				CGFloat width = (rect.size.width / count);
				return CGRectMake(roundf(i * width), 0, roundf(width), CGRectGetHeight(rect));
			};
			
			[self addSubview:tab];
			[tabs addObject:tab];
		}
		
		_tabViews = [[NSArray alloc] initWithArray:tabs];
	}
	return self;
}


- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	
	// Drawing the bar gradient using CGContextRef functions.
	CGFloat colorA[] = { 0.85f, 0.85f, 0.85f, 1.0f };
	CGFloat colorB[] = { 0.71f, 0.71f, 0.71f, 1.0f };
	CGContextDrawLinearGradientBetweenPoints(ctx, CGPointMake(0, CGRectGetHeight(self.bounds)),
											 colorA, CGPointMake(0, 0), colorB);
	
	// Drawing the separator etch using Cocoa Graphics objects.
	[[NSColor colorWithCalibratedWhite:1.0f alpha:0.5f] set];
	[[NSBezierPath bezierPathWithRect:CGRectMake(0, CGRectGetHeight(self.bounds) - 2, CGRectGetWidth(self.bounds), 1)] fill];
	[[NSColor colorWithCalibratedWhite:0.0f alpha:0.25f] set];
	[[NSBezierPath bezierPathWithRect:CGRectMake(0, CGRectGetHeight(self.bounds) - 1, CGRectGetWidth(self.bounds), 1)] fill];
}

- (BOOL)isHighlightingTab:(TUIView *)tab {
	if(![self.tabViews containsObject:tab])
		return NO;
	
	if([(ExampleTab *)tab state] & (TUIControlStateHighlighted | TUIControlStateSelected))
		return YES;
	else return NO;
}

@end
