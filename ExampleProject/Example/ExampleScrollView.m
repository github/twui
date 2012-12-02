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

#import "ExampleScrollView.h"
#import "ExampleTableViewController.h"

@implementation ExampleScrollView

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
		self.backgroundColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
		
		self.tabInformation = [[TUIPopover alloc] init];
		self.tabInformation.contentViewController = [[TUIViewController alloc] init];
		self.tabInformation.contentSize = CGSizeMake(240, 240);
		self.tabInformation.behavior = TUIPopoverBehaviorTransient;
		
        self.tabTest = [[NSPopover alloc] init];
		self.tabTest.contentViewController = [[NSViewController alloc] init];
		self.tabTest.contentSize = CGSizeMake(240, 240);
		self.tabTest.behavior = NSPopoverBehaviorTransient;
		
		NSView *example1 = [[NSView alloc] initWithFrame:(CGRect) {
			.size = self.tabTest.contentSize
		}];
		self.tabTest.contentViewController.view = example1;
		
		TUIView *example2 = [[TUIView alloc] initWithFrame:(CGRect) {
			.size = self.tabInformation.contentSize
		}];
		self.tabInformation.contentViewController.view = example2;
		
		TUILabel *label = [[TUILabel alloc] initWithFrame:self.bounds];
		label.userInteractionEnabled = NO;
		label.backgroundColor = [NSColor clearColor];
		label.textColor = [NSColor darkGrayColor];
		label.font = [NSFont boldSystemFontOfSize:24.0f];
		label.text = @"Click here to show popover test.";
		label.alignment = TUITextAlignmentCenter;
		label.renderer.shadowBlur = 1.0f;
		label.renderer.shadowColor = [NSColor highlightColor];
		label.renderer.shadowOffset = CGSizeMake(0, 1);
		self.infoLabel = label;
		
		/*_scrollView = [[TUIScrollView alloc] initWithFrame:self.bounds];
		_scrollView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
		_scrollView.scrollIndicatorStyle = TUIScrollViewIndicatorStyleDefault;
		[self addSubview:_scrollView];
		
		TUIImageView *imageView = [[TUIImageView alloc] initWithImage:[NSImage imageNamed:@"large-image.jpeg"]];
		[_scrollView addSubview:imageView];
		[_scrollView setContentSize:imageView.frame.size];
		*/
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	self.infoLabel.frame = self.bounds;
	[self.infoLabel drawRect:rect];
}

- (void)mouseUp:(NSEvent *)theEvent {
	[self.tabInformation showRelativeToRect:self.bounds ofView:self preferredEdge:CGRectMinXEdge];
	[self.tabTest showRelativeToRect:self.bounds ofView:self.nsView preferredEdge:CGRectMaxXEdge];
}

@end
