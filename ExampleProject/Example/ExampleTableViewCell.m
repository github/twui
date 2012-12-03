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
		
		// Set the separator style to etched, to draw a fancy light emboss border.
		self.separatorStyle = TUITableViewCellSeparatorStyleEtched;
		
		// Set up the alternating cell color scheme.
		self.backgroundColor = [NSColor colorWithCalibratedWhite:0.97 alpha:1.0f];
		self.highlightColor = [NSColor colorWithCalibratedWhite:0.87 alpha:1.0f];
		self.selectionColor = [NSColor colorWithCalibratedWhite:0.77 alpha:1.0f];
		self.alternateBackgroundColor = [NSColor colorWithCalibratedWhite:0.92 alpha:1.0f];
		self.alternateHighlightColor = [NSColor colorWithCalibratedWhite:0.82 alpha:1.0f];
		self.alternateSelectionColor = [NSColor colorWithCalibratedWhite:0.72 alpha:1.0f];
		
		// Create an actionButton that can be selected and deselected to
		// trigger cell selection, to show off the overridden cell drawing.
		_actionButton = [TUIButton buttonWithType:TUIButtonTypeClear];
		self.actionButton.frame = CGRectMake(5.0f, 0.0f, 75.0f, 22.0f);
		self.actionButton.titleLabel.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
		self.actionButton.selectable = YES;
		self.actionButton.reversesTitleShadowWhenHighlighted = YES;
		
		// Configure the label's internal text renderer to draw the text
		// centered and in the middle of the label with an embossed shadow.
		self.actionButton.titleLabel.alignment = TUITextAlignmentCenter;
		self.actionButton.titleLabel.renderer.verticalAlignment = TUITextVerticalAlignmentMiddle;
		self.actionButton.titleLabel.renderer.shadowBlur = 1.0f;
		self.actionButton.titleLabel.renderer.shadowColor = [NSColor highlightColor];
		self.actionButton.titleLabel.renderer.shadowOffset = CGSizeMake(0, -1);
		
		// Configure the titles and title colors for the button states.
		// If we don't configure anything for a state, it tries to default
		// to the normal state's configured values, i.e. title color.
		[self.actionButton setTitle:@"Select" forState:TUIControlStateNormal];
		[self.actionButton setTitle:@"Deselect" forState:TUIControlStateSelected];
		[self.actionButton setTitleColor:[NSColor blackColor] forState:TUIControlStateNormal];
		
		// If the button is selected, and we're not selected, animate ourselves
		// into the selected state, and scroll until we're visible on screen.
		// If we're already selected, deselect ourselves. This state should be
		// mirrored by the actionButton's state in -prepareForDisplay.
		[self.actionButton addActionForControlEvents:TUIControlEventMouseUpInside block:^{
			if(!self.selected) {
				[self.tableView selectRowAtIndexPath:self.indexPath animated:YES
									  scrollPosition:TUITableViewScrollPositionToVisible];
			} else {
				[self.tableView deselectRowAtIndexPath:self.indexPath animated:YES];
			}
		}];
		[self addSubview:self.actionButton];
		
		// Instead of using a TUILabel or TUITextField, let's take a little
		// course in the art of using a TUITextRenderer. It acts as a simple
		// text -> layer rendering mechanism class with tie-ins to TUIView,
		// but can achieve far more if used right (like TUITextView).
		_textRenderer = [[TUITextRenderer alloc] init];
		self.textRenderer.verticalAlignment = TUITextVerticalAlignmentMiddle;
		self.textRenderer.shouldRefuseFirstResponder = YES;
		self.textRenderer.shadowBlur = 1.0f;
		self.textRenderer.shadowColor = [NSColor whiteColor];
		self.textRenderer.shadowOffset = CGSizeMake(0, 1);
		
		// Add the text renderer to the view so events get routed to it
		// properly. Text selection, dictionary popup, etc should just work.
		// You can add more than one.
		// The text renderer encapsulates an attributed string and a frame.
		// The attributed string in this case is set by setAttributedString:
		// which is configured by the table view delegate.  The frame needs to
		// be set before it can be drawn, we do that in drawRect: below.
		self.textRenderers = @[self.textRenderer];
		
		// Add in a standard Cocoa text field. We have to enclose this within
		// a TUIViewNSViewContainer, and we MUST adjust only the frame of that
		// container, and not the text field's itself.
		NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 180, 91, 22)];
		self.textFieldContainer = [[TUIViewNSViewContainer alloc] initWithNSView:textField];
		[textField.cell setUsesSingleLineMode:YES];
		[textField.cell setScrollable:YES];
		
		[self addSubview:self.textFieldContainer];
	}
	
	return self;
}

// Create a simple attributed string setter/getter to the text renderer.
- (NSAttributedString *)attributedString {
	return self.textRenderer.attributedString;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
	self.textRenderer.attributedString = attributedString;
	[self setNeedsDisplay];
}

// When we subclass any view and override the layout or drawing methods,
// it's a must to insert a super call before doing your own thing.
- (void)layoutSubviews {
	[super layoutSubviews];
	CGFloat padding = 10.0f;
	
	// Set the text field container's frame (NOT THE TEXT FIELD).
	CGSize textFieldSize = self.textFieldContainer.bounds.size;
	CGFloat textFieldLeft = CGRectGetWidth(self.bounds) - textFieldSize.width - padding;
	self.textFieldContainer.frame = CGRectMake(textFieldLeft, 14, textFieldSize.width, textFieldSize.height);
	
	// Set the action button's frame.
	CGRect buttonRect = self.actionButton.frame;
	buttonRect.origin.y = floor((self.bounds.size.height / 2) - (buttonRect.size.height / 2));
	self.actionButton.frame = buttonRect;
	
	// Set the text renderer's frame.
	CGRect textRect = self.bounds;
	textRect.origin.x += padding + buttonRect.size.width;
	textRect.size.width -= self.textFieldContainer.frame.size.width + buttonRect.size.width + (padding * 3);
	self.textRenderer.frame = textRect;
}

// Note that we only override the drawRect: to add in a call to
// let the text renderer draw as well. For TUITableView, customization
// is preferrably left to the overridable drawing methods - not this.
- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	[self.textRenderer draw];
}

// Override the highlighted and selected drawing methods to draw a
// nifty gradient, and also take into account that we might be an
// alternately colored cell.
- (void)drawHighlightedBackground:(CGRect)rect {
	NSColor *alternateColor = self.alternateHighlightColor ?: self.alternateBackgroundColor;
	BOOL alternated = (alternateColor && (self.indexPath.row % 2));
	
	[[[NSGradient alloc] initWithStartingColor:alternated ? alternateColor : self.highlightColor
								   endingColor:self.backgroundColor] drawInRect:rect angle:270.0f];
}

- (void)drawSelectedBackground:(CGRect)rect {
	[self drawHighlightedBackground:rect];
}

// When we are removed from the cell queue to be displayed, this method
// is called to allow us to make cell changes before display. We'll use
// this to set the selected state of the action button based on our state.
- (void)prepareForDisplay {
	self.actionButton.selected = self.selected;
}

@end
