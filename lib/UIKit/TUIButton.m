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

#import "TUIButton.h"
#import "TUICGAdditions.h"
#import "NSBezierPath+TUIExtensions.h"
#import "NSShadow+TUIExtensions.h"
#import "NSImage+TUIExtensions.h"
#import "TUIImageView.h"
#import "TUILabel.h"
#import "TUINSView.h"
#import "TUIStretchableImage.h"
#import "TUITextRenderer.h"

@interface TUIButtonContent : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSColor *titleColor;
@property (nonatomic, strong) NSColor *shadowColor;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSImage *backgroundImage;

@end

@interface TUIButton () {
    struct {
        unsigned int buttonType:8;
		unsigned int wasHighlighted:1;
		
		unsigned int dimsInBackground:1;
		unsigned int adjustsImageWhenHighlighted:1;
		unsigned int adjustsImageWhenDisabled:1;
		unsigned int reversesTitleShadowWhenHighlighted:1;
    } _buttonFlags;
}

@property (nonatomic, strong) NSTimer *menuHoldTimer;
@property (nonatomic, strong) NSMutableDictionary *contentLookup;
@property (nonatomic, strong, readwrite) TUILabel *titleLabel;

@end

@implementation TUIButton

+ (NSPopUpButtonCell *)sharedGraphicsRenderer {
	static NSPopUpButtonCell *_backingCell = nil;
	if(!_backingCell)
		_backingCell = [NSPopUpButtonCell new];
	return _backingCell;
}

#pragma mark - Initialization

+ (instancetype)buttonWithType:(TUIButtonType)buttonType {
	TUIButton *b = [[self alloc] initWithFrame:CGRectZero];
	b->_buttonFlags.buttonType = buttonType;
	
	return b;
}

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		_buttonFlags.buttonType = TUIButtonTypeStandard;
		self.imagePosition = TUIControlImagePositionOverlap;
		self.menuHoldDelay = 1.0f;
		self.synchronizeMenuTitle = YES;
		
		self.contentLookup = [NSMutableDictionary dictionary];
		self.backgroundColor = [NSColor clearColor];
		self.opaque = NO;
		
		self.needsDisplayWhenWindowsKeyednessChanges = YES;
		_buttonFlags.adjustsImageWhenDisabled = YES;
		_buttonFlags.adjustsImageWhenHighlighted = YES;
		_buttonFlags.dimsInBackground = YES;
	}
	return self;
}

#pragma mark - Setup

- (BOOL)acceptsFirstResponder {
	return NO;
}

- (TUIButtonType)buttonType {
	return _buttonFlags.buttonType;
}

#pragma mark - Properties

- (TUILabel *)titleLabel {
	if(!_titleLabel) {
		_titleLabel = [[TUILabel alloc] initWithFrame:CGRectZero];
		_titleLabel.userInteractionEnabled = NO;
		_titleLabel.backgroundColor = [NSColor clearColor];
		_titleLabel.lineBreakMode = TUILineBreakModeTailTruncation;
		
		// We'll draw the title ourselves.
		_titleLabel.hidden = YES;
		[self addSubview:_titleLabel];
	}
	return _titleLabel;
}

- (BOOL)dimsInBackground {
	return _buttonFlags.dimsInBackground;
}

- (void)setDimsInBackground:(BOOL)flag {
	_buttonFlags.dimsInBackground = flag;
}

- (BOOL)adjustsImageWhenHighlighted {
	return _buttonFlags.adjustsImageWhenHighlighted;
}

- (void)setAdjustsImageWhenHighlighted:(BOOL)flag {
	_buttonFlags.adjustsImageWhenHighlighted = flag;
}

- (BOOL)adjustsImageWhenDisabled {
	return _buttonFlags.adjustsImageWhenDisabled;
}

- (void)setAdjustsImageWhenDisabled:(BOOL)flag {
	_buttonFlags.adjustsImageWhenDisabled = flag;
}

- (BOOL)reversesTitleShadowWhenHighlighted {
	return _buttonFlags.reversesTitleShadowWhenHighlighted;
}

- (void)setReversesTitleShadowWhenHighlighted:(BOOL)flag {
	_buttonFlags.reversesTitleShadowWhenHighlighted = flag;
}

#pragma mark - Overrides

- (CGRect)backgroundRectForBounds:(CGRect)bounds {
	if(self.buttonType == TUIButtonTypeStandard) {
		bounds.origin.y -= 2.0f;
		bounds.size.width += 10.0f;
		bounds.origin.x -= 5.0f;
	}
	
	return CGRectIntegral(bounds);
}

- (CGRect)contentRectForBounds:(CGRect)bounds {
	if(self.buttonType == TUIButtonTypeStandard) {
		bounds.origin.y -= 2.0f;
		bounds.size.width += 10.0f;
		bounds.origin.x -= 5.0f;
	} else {
		bounds = CGRectInset(bounds, 2.0f, 0.0f);
	}
	
	if(self.menuType == TUIButtonMenuTypePopUp || self.menuType == TUIButtonMenuTypePullDown)
		bounds.size.width -= 15.0f;
	
	return CGRectIntegral(bounds);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
	return contentRect;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
	return contentRect;
}

- (CGSize)sizeThatFits:(CGSize)size {
	return self.currentImage.size;
}

#pragma mark - Drawing

- (void)drawBackground:(CGRect)rect {
	CGRect drawingRect = [self backgroundRectForBounds:self.bounds];
	NSPopUpButtonCell *renderer = [TUIButton sharedGraphicsRenderer];
	
	// Secondary State holds either highlighted or selected states.
	// Background State holds window background and disabled states.
	BOOL secondaryState = (self.state & TUIControlStateHighlighted) || (self.state & TUIControlStateSelected);
	BOOL backgroundState = (![self.nsView isWindowKey] && _buttonFlags.dimsInBackground) || !self.enabled;
	
	// Determine the correct graphics renderer style, and use
	// NSNotFound for Inline and Custom drawing styles.
	NSBezelStyle graphicsStyle = NSNotFound;
	if(self.buttonType == TUIButtonTypeStandard)
		graphicsStyle = NSRoundedBezelStyle;
	else if(self.buttonType == TUIButtonTypeMinimal)
		graphicsStyle = NSRoundRectBezelStyle;
	else if(self.buttonType == TUIButtonTypeTextured)
		graphicsStyle = NSTexturedRoundedBezelStyle;
	else if(self.buttonType == TUIButtonTypeRectangular)
		graphicsStyle = NSSmallSquareBezelStyle;
	else if(self.buttonType == TUIButtonTypeCircular)
		graphicsStyle = NSCircularBezelStyle;
	
	// Set the graphics renderer states so CoreUI draws the button for us properly.
	[renderer setHighlighted:secondaryState];
	[renderer setEnabled:!backgroundState];
	
	// Configure the menu arrow which is also automatically drawn for us.
	[renderer setArrowPosition:(self.menuType != TUIButtonMenuTypeNone && self.menuType != TUIButtonMenuTypeHold)];
	[renderer setPullsDown:(self.menuType != TUIButtonMenuTypePopUp)];
	
	// If we found the proper graphics style, allow the graphics renderer to draw it.
	// If not, draw it ourselves (Inline or Custom styles only, currently).
	if(graphicsStyle != NSNotFound) {
		[renderer setBezelStyle:graphicsStyle];
		[renderer drawBezelWithFrame:drawingRect inView:self.nsView];
		
	} else if(self.buttonType == TUIButtonTypeInline) {
		CGFloat radius = self.bounds.size.height / 2;
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:drawingRect xRadius:radius yRadius:radius];
		
		if(secondaryState) {
			[[NSColor colorWithCalibratedWhite:0.15 alpha:0.85] set];
			[path fill];
			
			if(self.state & TUIControlStateSelected) {
				[path tui_fillWithInnerShadow:[NSShadow tui_shadowWithRadius:3.0 offset:NSZeroSize
																	   color:[NSColor shadowColor]]];
			}
		} else if(self.state & TUIControlStateHover) {
			[[NSColor colorWithCalibratedWhite:0.15 alpha:0.5] set];
			[path fill];
		}
	} else if(self.buttonType == TUIButtonTypeCustom) {
		NSImage *backgroundImage = self.currentBackgroundImage;
		if(backgroundImage) {
			[backgroundImage tui_drawInRect:rect];
		} else {
			[self.backgroundColor setFill];
			CGContextFillRect(TUIGraphicsGetCurrentContext(), self.bounds);
		}
	}
}

- (void)drawImage:(CGRect)rect {
	
	// Secondary State holds either highlighted or selected states.
	// Background State holds window background and disabled states.
	BOOL secondaryState = (self.state & TUIControlStateHighlighted) || (self.state & TUIControlStateSelected);
	secondaryState &= self.adjustsImageWhenHighlighted;
	BOOL backgroundState = (![self.nsView isWindowKey] && _buttonFlags.dimsInBackground);
	backgroundState |= !self.enabled;
	
	// Using the shared graphics renderer, we get free template image drawing,
	// along with disabled and highlighted state drawing.
	[[TUIButton sharedGraphicsRenderer] setEnabled:!backgroundState];
	[[TUIButton sharedGraphicsRenderer] setHighlighted:secondaryState];
	[[TUIButton sharedGraphicsRenderer] drawImage:self.currentImage
										withFrame:TUIEdgeInsetsInsetRect(rect, self.imageEdgeInsets)
										   inView:self.nsView];
}

- (void)drawTitle:(CGRect)rect {
	NSString *title = self.currentTitle;
	if(title != nil)
		self.titleLabel.text = title;
	
	NSColor *color = self.currentTitleColor;
	if(color != nil)
		self.titleLabel.textColor = color;
	
	// The renderer's shadow color may have been manually set,
	// in which case we don't want to reset it to nothing.
	NSColor *shadowColor = self.currentTitleShadowColor;
	if(shadowColor != nil)
		self.titleLabel.renderer.shadowColor = shadowColor;
	
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	CGContextSaveGState(ctx); {
		CGFloat alpha = ((self.nsView.isWindowKey && _buttonFlags.dimsInBackground) ? 1.0f : 0.5);
		CGContextSetAlpha(ctx, alpha);
		
		CGContextTranslateCTM(ctx, rect.origin.x + _titleEdgeInsets.left, rect.origin.y + _titleEdgeInsets.bottom);
		rect.size.width -= (_titleEdgeInsets.left + _titleEdgeInsets.right);
		rect.size.height -= (_titleEdgeInsets.top + _titleEdgeInsets.bottom);
		
		self.titleLabel.frame = (CGRect) { .size = rect.size };
		[self.titleLabel drawRect:self.titleLabel.bounds];
	} CGContextRestoreGState(ctx);
}

- (void)drawRect:(CGRect)rect {
	[self drawBackground:[self backgroundRectForBounds:self.bounds]];
	rect = [self contentRectForBounds:rect];
	
	CGRect imageRect = rect;
	NSImage *image = self.currentImage;
	if(image != nil && self.imagePosition != TUIControlImagePositionNone) {
		if(![image isKindOfClass:[TUIStretchableImage class]]) {
			CGRect b = rect;
			if(self.imagePosition == TUIControlImagePositionBelow || self.imagePosition == TUIControlImagePositionAbove) {
				b.size.height /= 2;
				if(self.imagePosition == TUIControlImagePositionAbove)
					b.origin.y += b.size.height;
			} else if(self.imagePosition == TUIControlImagePositionLeft || self.imagePosition == TUIControlImagePositionRight) {
				b.size.width = image.size.width;
				if(self.imagePosition == TUIControlImagePositionRight)
					b.origin.x = rect.size.width - image.size.width;
			}
			
			imageRect = ABRectCenteredInRect((CGRect) { .size = image.size }, b);
		}
		
		[self drawImage:[self imageRectForContentRect:imageRect]];
	}
	
	NSString *title = self.currentTitle;
	if(title != nil && self.imagePosition != TUIControlImagePositionOnly) {
		CGRect b = rect;
		if(self.imagePosition == TUIControlImagePositionBelow || self.imagePosition == TUIControlImagePositionAbove) {
			b.size.height /= 2;
			if(self.imagePosition == TUIControlImagePositionBelow)
				b.origin.y += b.size.height;
		} else if(self.imagePosition == TUIControlImagePositionLeft || self.imagePosition == TUIControlImagePositionRight) {
			b.size.width = rect.size.width - imageRect.size.width;
			if(self.imagePosition == TUIControlImagePositionLeft)
				b.origin.x = imageRect.size.width;
		}
		
		b.origin.x += 5.0f;
		b.size.width -= 5.0f;
		[self drawTitle:[self titleRectForContentRect:b]];
	}
}

#pragma mark - Menu and Selected State

// FIXME: Happens even for large clickCount.
- (void)mouseDown:(NSEvent *)event {
	[super mouseDown:event];
	
	if(self.menu && self.menuType != TUIButtonMenuTypeNone) {
		self.selected = YES;
		self.menuHoldTimer = [NSTimer timerWithTimeInterval:fabs(self.menuHoldDelay)
													 target:self
												   selector:@selector(displayMenu:)
												   userInfo:event
													repeats:NO];
		
		if(self.menuType == TUIButtonMenuTypeHold)
			[[NSRunLoop currentRunLoop] addTimer:self.menuHoldTimer forMode:NSRunLoopCommonModes];
		else
			[self.menuHoldTimer fire];
	}
}

- (void)displayMenu:(NSTimer *)timer {
	NSEvent *event = timer.userInfo;
	
	// Allow NSPopUpButtonCell to handle menu semantics for us: smarter!
	[[TUIButton sharedGraphicsRenderer] setMenu:self.menu];
	[[TUIButton sharedGraphicsRenderer] setPreferredEdge:self.preferredMenuEdge];
	[[TUIButton sharedGraphicsRenderer] performClickWithFrame:self.frameInNSView inView:self.nsView];
	
	// After this happens, we never get a mouseUp: in the TUINSView.
	// This screws up _trackingView. For now, fake it with a fake mouseUp:.
	[self.nsView performSelector:@selector(mouseUp:) withObject:event afterDelay:0.0];
	[TUIView animateWithDuration:0.25f animations:^{
		[self redraw];
	}];
}

- (void)mouseUp:(NSEvent *)event {
	[super mouseUp:event];
	
	[self.menuHoldTimer invalidate];
	self.menuHoldTimer = nil;
	
	if(![self eventInside:event])
		return;
	
	if((self.selectable || self.buttonType == TUIButtonTypeInline || self.menu) && self.enabled)
		self.selected = !self.selected;
}

#pragma mark - Highlight Reversing

- (void)stateWillChange {
	_buttonFlags.wasHighlighted = (self.state & (TUIControlStateHighlighted | TUIControlStateSelected));
}

- (void)stateDidChange {
	BOOL reverseShadow = (self.state & (TUIControlStateHighlighted | TUIControlStateSelected)) != _buttonFlags.wasHighlighted;
	
	if(reverseShadow && self.reversesTitleShadowWhenHighlighted) {
		CGSize shadow = _titleLabel.renderer.shadowOffset;
		_titleLabel.renderer.shadowOffset = (CGSize) {
			.height = shadow.height * -1,
			.width = shadow.width * -1
		};
	}
}

#pragma mark -

@end

@implementation TUIButtonContent
@end

@implementation TUIButton (Content)

#pragma mark - Button Content Lookup

- (TUIButtonContent *)_contentForState:(TUIControlState)state {
	id key = @(state);
	TUIButtonContent *c = [_contentLookup objectForKey:key];
	
	// Try matching without the NotKey state.
	if(c == nil && (state & TUIControlStateNotKey))
		c = [_contentLookup objectForKey:@(state & ~TUIControlStateNotKey)];
	
	if(c == nil) {
		c = [[TUIButtonContent alloc] init];
		[_contentLookup setObject:c forKey:key];
	}
	
	return c;
}

- (void)setTitle:(NSString *)title forState:(TUIControlState)state {
	[self applyStateChangeAnimated:self.animateStateChange block:^{
		[[self _contentForState:state] setTitle:title];
	}];
}

- (void)setTitleColor:(NSColor *)color forState:(TUIControlState)state {
	[self applyStateChangeAnimated:self.animateStateChange block:^{
		[[self _contentForState:state] setTitleColor:color];
	}];
}

- (void)setTitleShadowColor:(NSColor *)color forState:(TUIControlState)state {
	[self applyStateChangeAnimated:self.animateStateChange block:^{
		[[self _contentForState:state] setShadowColor:color];
	}];
}

- (void)setImage:(NSImage *)i forState:(TUIControlState)state {
	[self applyStateChangeAnimated:self.animateStateChange block:^{
		[[self _contentForState:state] setImage:i];
	}];
}

- (void)setBackgroundImage:(NSImage *)i forState:(TUIControlState)state {
	[self applyStateChangeAnimated:self.animateStateChange block:^{
		[[self _contentForState:state] setBackgroundImage:i];
	}];
}

- (NSString *)titleForState:(TUIControlState)state {
	return [[self _contentForState:state] title];
}

- (NSColor *)titleColorForState:(TUIControlState)state {
	return [[self _contentForState:state] titleColor];
}

- (NSColor *)titleShadowColorForState:(TUIControlState)state {
	return [[self _contentForState:state] shadowColor];
}

- (NSImage *)imageForState:(TUIControlState)state {
	return [[self _contentForState:state] image];
}

- (NSImage *)backgroundImageForState:(TUIControlState)state {
	return [[self _contentForState:state] backgroundImage];
}

- (NSString *)currentTitle {
	if(self.menu && self.synchronizeMenuTitle) {
		if(self.menuType == TUIButtonMenuTypePopUp) {
			NSMenuItem *titleItem = self.menu.highlightedItem;
			if(!titleItem)
				titleItem = [self.menu itemAtIndex:0];
			
			return titleItem.title;
		} else if(self.menuType == TUIButtonMenuTypePullDown) {
			return [[self.menu itemAtIndex:0] title];
		}
	}
	
	NSString *title = [self titleForState:self.state];
	if(title == nil) {
		if(self.state & TUIControlStateSelected)
			title = [self titleForState:TUIControlStateHighlighted];
		if(title == nil)
			title = [self titleForState:TUIControlStateNormal];
	}
	
	return title;
}

- (NSColor *)currentTitleColor {
	NSColor *color = [self titleColorForState:self.state];
	if(color == nil) {
		if(self.state & TUIControlStateSelected)
			color = [self titleColorForState:TUIControlStateHighlighted];
		if(color == nil)
			color = [self titleColorForState:TUIControlStateNormal];
	}
	
	return color;
}

- (NSColor *)currentTitleShadowColor {
	NSColor *color = [self titleShadowColorForState:self.state];
	if(color == nil) {
		if(self.state & TUIControlStateSelected)
			color = [self titleShadowColorForState:TUIControlStateHighlighted];
		if(color == nil)
			color = [self titleShadowColorForState:TUIControlStateNormal];
	}
	
	return color;
}

- (NSImage *)currentImage {
	NSImage *image = [self imageForState:self.state];
	if(image == nil) {
		if(self.state & TUIControlStateSelected)
			image = [self imageForState:TUIControlStateHighlighted];
		if(image == nil)
			image = [self imageForState:TUIControlStateNormal];
	}
	
	return image;
}

- (NSImage *)currentBackgroundImage {
	NSImage *image = [self backgroundImageForState:self.state];
	if(image == nil) {
		if(self.state & TUIControlStateSelected)
			image = [self backgroundImageForState:TUIControlStateHighlighted];
		if(image == nil)
			image = [self backgroundImageForState:TUIControlStateNormal];
	}
	
	return image;
}

#pragma mark -

@end
