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
	// Animating it makes it fun if the drag goes pretty far.
	CGFloat currentPosition = [self convertPoint:[event locationInWindow] fromView:nil].x;
	[TUIView animateWithDuration:0.1 animations:^{
		
		// Setting an ease-in-out animation curve slows down
		// the animation at the start and finish, but speeds it up
		// during the middle. Just for that "don't slide me!" fun.
		[TUIView setAnimationCurve:TUIViewAnimationCurveEaseInOut];
		
		CGRect draggedRect = self.frame;
		draggedRect.origin.x += roundf(currentPosition - self.originalPosition);
		self.frame = draggedRect;
	}];
	
	return YES;
}

// Restore tabs to their original condition.
- (void)endTrackingWithEvent:(NSEvent *)event {
	
	// By nature, the event *must* be inside the tab's bounds, otherwise the
	// tracking process will not be invoked. If we were dragged, we were NOT
	// pressed, so don't call the delegate.
	CGFloat currentPosition = [self convertPoint:[event locationInWindow] fromView:nil].x;
	if(self.originalPosition == currentPosition)
		[[self tabBar].delegate tabBar:[self tabBar] didSelectTab:self.tag];
	
	// Since tracking is done, move the tab back. This whole ordeal lets us
	// "stretch" our tabs around.
	float originalPoint = self.tag * (self.tabBar.bounds.size.width / self.tabBar.tabViews.count);
	[TUIView animateWithDuration:0.2 animations:^{
		CGRect draggedRect = self.frame;
		draggedRect.origin.x = roundf(originalPoint);
		self.frame = draggedRect;
	}];
	
	// Rather than a simple -setNeedsDisplay, let's fade it back out.
	[TUIView animateWithDuration:0.3 animations:^{
		
		// -redraw forces a .contents update immediately based on drawRect,
		// and it happens inside an animation block, so CoreAnimation gives
		// us a cross-fade for free.
		[self redraw];
	}];
}

@end

@interface ExampleTabBar ()

@property (nonatomic, assign) ExampleTab *draggingTab;

@end

@implementation ExampleTabBar

@synthesize delegate;
@synthesize tabViews;

- (id)initWithNumberOfTabs:(NSInteger)nTabs
{
	if((self = [super initWithFrame:CGRectZero])) {
		NSMutableArray *_tabViews = [NSMutableArray arrayWithCapacity:nTabs];
		for(int i = 0; i < nTabs; ++i) {
			ExampleTab *t = [[ExampleTab alloc] initWithFrame:CGRectZero];
			t.tag = i;
			t.layout = ^(TUIView *v) { // the layout of an individual tab is a function of the superview bounds, the number of tabs, and the current tab index
				CGRect b = v.superview.bounds; // reference the passed-in 'v' rather than 't' to avoid a retain cycle
				float width = (b.size.width / nTabs);
				float x = i * width;
				return CGRectMake(roundf(x), 0, roundf(width), b.size.height);
			};
			[self addSubview:t];
			[_tabViews addObject:t];
		}
		
		tabViews = [[NSArray alloc] initWithArray:_tabViews];
	}
	return self;
}


- (void)drawRect:(CGRect)rect
{
	// draw tab bar background
	
	CGRect b = self.bounds;
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	
	// gray gradient
	CGFloat colorA[] = { 0.90, 0.90, 0.90, 1.00 };
	CGFloat colorB[] = { 0.80, 0.80, 0.80, 1.00 };
	CGContextDrawLinearGradientBetweenPoints(ctx, CGPointMake(0, b.size.height), colorA, CGPointMake(0, 0), colorB);
	
	// top emboss
	CGContextSetRGBFillColor(ctx, 1, 1, 1, 0.5);
	CGContextFillRect(ctx, CGRectMake(0, b.size.height-2, b.size.width, 1));
	CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.3);
	CGContextFillRect(ctx, CGRectMake(0, b.size.height-1, b.size.width, 1));
}

@end
