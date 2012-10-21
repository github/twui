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

@implementation ExampleScrollView

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		self.backgroundColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
		
		TUIImageView *imageView = [[TUIImageView alloc] initWithImage:[NSImage imageNamed:@"large-image.jpeg"]];
		imageView.userInteractionEnabled = YES;
		imageView.editable = YES;
		imageView.editingSizesToFit = YES;
		imageView.savable = YES;
		imageView.savedFilename = @"TUIImageView Example";
		
		imageView.imageEditedHandler = ^{
			self.scrollView.contentSize = imageView.frame.size;
		};
		
		self.scrollView = [[TUIScrollView alloc] initWithFrame:self.bounds];
		self.scrollView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
		
		[self addSubview:_scrollView];
		[self.scrollView addSubview:imageView];
		
		self.scrollView.contentSize = imageView.frame.size;
		
	}
	return self;
}


@end
