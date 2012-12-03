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

#import "ExampleSectionHeaderView.h"

@implementation ExampleSectionHeaderView

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		_labelRenderer = [[TUITextRenderer alloc] init];
		self.textRenderers = @[self.labelRenderer];
		self.backgroundColor = [NSColor clearColor];
		
		// Add an activity indicator to the header view with a 24x24 size.
		// Since we know the height of the header won't change we can pre-
		// pad it to 4. However, since the table view's width can change,
		// we'll create a layout constraint to keep the activity indicator
		// anchored 16px left of the right side of the header view.
		TUIActivityIndicatorView *indicator = [[TUIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 4, 24, 24)
																	   activityIndicatorStyle:TUIActivityIndicatorViewStyleBlack];
		[indicator addLayoutConstraint:[TUILayoutConstraint constraintWithAttribute:TUILayoutConstraintAttributeMaxX
																		 relativeTo:@"superview"
																		  attribute:TUILayoutConstraintAttributeMaxX
																			 offset:-16.0f]];
		
		// Add a simple embossing shadow to the white activity indicator.
		// This way, we can see it better on a bright background. Using
		// the standard layer property keeps the shadow stable through
		// animations.
		indicator.layer.shadowColor = [NSColor highlightColor].tui_CGColor;
		indicator.layer.shadowOffset = CGSizeMake(0, 1);
		indicator.layer.shadowOpacity = 1.0f;
		indicator.layer.shadowRadius = 1.0f;
		
		// We then add it as a subview and tell it to start animating.
		[self addSubview:indicator];
		[indicator startAnimating];
	}
	
	return self;
}

// Change opaqueness based on the header being pinned or not.
- (void)headerWillBecomePinned {
	self.opaque = YES;
	[super headerWillBecomePinned];
}

- (void)headerWillBecomeUnpinned {
	self.opaque = YES;
	[super headerWillBecomeUnpinned];
}

// Draw a custom gradient background for the section header.
- (void)drawRect:(CGRect)rect {
	
	// If we're pinned, don't draw transparent.
	if(!self.pinnedToViewport) {
		[[NSColor whiteColor] set];
		NSRectFill(self.bounds);
    }
    
    NSColor *start = [NSColor colorWithCalibratedWhite:0.90f alpha:0.75f];
    NSColor *end = [NSColor colorWithCalibratedWhite:0.95f alpha:0.75f];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
	
    [gradient drawInRect:self.bounds angle:90.0f];
    [[end highlightWithLevel:0.25f] set];
    NSRectFill(NSMakeRect(0, self.bounds.size.height - 1, self.bounds.size.width, 1));
    [[start shadowWithLevel:0.25f] set];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
    
    CGFloat labelHeight = 18.0f;
    self.labelRenderer.frame = CGRectMake(15, roundf((self.bounds.size.height - labelHeight) / 2.0),
										  self.bounds.size.width - 30, labelHeight);
    [self.labelRenderer draw];
}

@end
