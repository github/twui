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

#import "ExampleTableViewCell.h"

@implementation ExampleTableViewCell

- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		
		// Set up the alternating row "look". Very slick, clean look. Just by
		// setting up a few colors (and optionally a few styles, and if we
		// need more, overridable methods) we can achieve whatever look we want.
		self.backgroundColor = [NSColor colorWithCalibratedWhite:0.97 alpha:1.0f];
		self.highlightColor = [NSColor colorWithCalibratedWhite:0.87 alpha:1.0f];
		self.selectionColor = [NSColor colorWithCalibratedWhite:0.77 alpha:1.0f];
		self.alternateBackgroundColor = [NSColor colorWithCalibratedWhite:0.92 alpha:1.0f];
		self.alternateHighlightColor = [NSColor colorWithCalibratedWhite:0.82 alpha:1.0f];
		self.alternateSelectionColor = [NSColor colorWithCalibratedWhite:0.72 alpha:1.0f];
		
		// Instead of using a TUILabel or TUITextField, let's take a little
		// course in the art of using a TUITextRenderer. It acts as a simple
		// text -> layer rendering mechanism class with tie-ins to TUIView,
		// but can achieve far more if used right (like TUITextView).
		_textRenderer = [[TUITextRenderer alloc] init];
		_textRenderer.verticalAlignment = TUITextVerticalAlignmentMiddle;
		_textRenderer.shouldRefuseFirstResponder = YES;
		_textRenderer.shadowBlur = 1.0f;
		_textRenderer.shadowColor = [NSColor whiteColor];
		_textRenderer.shadowOffset = CGSizeMake(0, 1);
		
		self.slider = [[TUISlider alloc] initWithFrame:CGRectMake(0, 0, 150, self.bounds.size.height)];
		[self addSubview:self.slider];
		
		// Add the text renderer to the view so events get routed to it
		// properly. Text selection, dictionary popup, etc should just work.
		// You can add more than one.
		// The text renderer encapsulates an attributed string and a frame.
		// The attributed string in this case is set by setAttributedString:
		// which is configured by the table view delegate.  The frame needs to
		// be set before it can be drawn, we do that in drawRect: below.
		self.textRenderers = @[_textRenderer];
		
		// Add in a standard Cocoa text field. We have to enclose this within
		// a TUIViewNSViewContainer, and we MUST adjust only the frame of that
		// container, and not the text field's itself.
		NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 180, 91, 22)];
		[textField.cell setUsesSingleLineMode:YES];
		[textField.cell setScrollable:YES];
		
		self.textFieldContainer = [[TUIViewNSViewContainer alloc] initWithNSView:textField];
		self.textFieldContainer.backgroundColor = [NSColor blueColor];
		[self addSubview:self.textFieldContainer];
	}
	
	return self;
}

// Create a simple attributed string setter/getter to the text renderer.
- (NSAttributedString *)attributedString {
	return _textRenderer.attributedString;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
	_textRenderer.attributedString = attributedString;
	[self setNeedsDisplay];
}

// When we subclass any view and override the layout or drawing methods,
// it's a must to insert a super call before doing your own thing.
- (void)layoutSubviews {
	[super layoutSubviews];
	
	// Set the text field container's frame (NOT THE TEXT FIELD).
	CGSize textFieldSize = self.textFieldContainer.bounds.size;
	CGFloat textFieldLeft = CGRectGetWidth(self.bounds) - textFieldSize.width - 16;
	self.textFieldContainer.frame = CGRectMake(textFieldLeft, 14, textFieldSize.width, textFieldSize.height);
	
	self.slider.frame = CGRectMake(0, 0, self.slider.bounds.size.width, self.bounds.size.height);
	
	// Set the text renderer's frame. Take indentation into account.
	CGFloat indentation = 10.0f;
	CGRect textRect = self.bounds;
	textRect.origin.x += indentation + self.slider.bounds.size.width;
	textRect.size.width -= (self.textFieldContainer.frame.size.width + 16) + (indentation * 2) + self.slider.bounds.size.width;
	_textRenderer.frame = textRect;
}

// Note that we only override the drawRect: to add in a call to
// let the text renderer draw as well. For TUITableView, customization
// is preferrably left to the overridable drawing methods - not this.
- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	[_textRenderer draw];
}

@end
