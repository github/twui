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
        unsigned buttonType:8;
		unsigned wasHighlighted:1;
		
		unsigned dimsInBackground:1;
		unsigned adjustsImageWhenHighlighted:1;
		unsigned adjustsImageWhenDisabled:1;
		unsigned reversesTitleShadowWhenHighlighted:1;
    } _buttonFlags;
}

@property (nonatomic, strong) NSMutableDictionary *contentLookup;

@property (nonatomic, strong, readwrite) TUILabel *titleLabel;
@property (nonatomic, strong, readwrite) TUIImageView *imageView;

@end

@implementation TUIButton

#pragma mark - Initialization

+ (instancetype)buttonWithType:(TUIButtonType)buttonType {
	TUIButton *b = [[self alloc] initWithFrame:CGRectZero];
	b->_buttonFlags.buttonType = buttonType;
	
	return b;
}

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		self.contentLookup = [NSMutableDictionary dictionary];
		_buttonFlags.buttonType = TUIButtonTypeStandard;
		
		self.tintColor = [NSColor colorWithCalibratedWhite:0.95f alpha:1.0f];
		self.backgroundColor = [NSColor clearColor];
		self.tintFactor = 0.10f;
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

#pragma mark - Content

- (TUILabel *)titleLabel {
	if(!_titleLabel) {
		_titleLabel = [[TUILabel alloc] initWithFrame:CGRectZero];
		_titleLabel.userInteractionEnabled = NO;
		_titleLabel.backgroundColor = [NSColor clearColor];
		
		// We'll draw the title ourselves.
		_titleLabel.hidden = YES;
		[self addSubview:_titleLabel];
	}
	return _titleLabel;
}

- (TUIImageView *)imageView {
	if(!_imageView) {
		_imageView = [[TUIImageView alloc] initWithFrame:TUIEdgeInsetsInsetRect(self.bounds, self.imageEdgeInsets)];
		_imageView.backgroundColor = [NSColor clearColor];
		
		[self addSubview:_imageView];
	}
	return _imageView;
}

#pragma mark - Properties

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
	return bounds;
}

- (CGRect)contentRectForBounds:(CGRect)bounds {
	return bounds;
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
	BOOL secondaryState = (self.state & TUIControlStateHighlighted) || (self.state & TUIControlStateSelected);
	
	if(self.buttonType == TUIButtonTypeCustom) {
		NSImage *backgroundImage = self.currentBackgroundImage;
		if(backgroundImage) {
			[backgroundImage drawInRect:[self backgroundRectForBounds:self.bounds]
							   fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		} else {
			[self.backgroundColor setFill];
			CGContextFillRect(TUIGraphicsGetCurrentContext(), self.bounds);
		}
	} else if(self.buttonType == TUIButtonTypeStandard) {
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 1.0f, 1.0f)
															 xRadius:3.5f yRadius:3.5f];
		NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[self.tintColor shadowWithLevel:self.tintFactor]
															 endingColor:[self.tintColor highlightWithLevel:self.tintFactor]];
		
		[NSGraphicsContext saveGraphicsState]; {
			[[NSShadow tui_shadowWithRadius:1.0f offset:CGSizeMake(0, -1)
									  color:[NSColor colorWithCalibratedWhite:0.86f alpha:0.75f]] set];
			[path fill];
		} [NSGraphicsContext restoreGraphicsState];
		
		[gradient drawInBezierPath:path angle:(secondaryState ? 270.0f : 90.0f)];
		[[NSColor colorWithCalibratedWhite:0.25f alpha:1.0f] setStroke];
		[path tui_strokeInside];
		
		if(secondaryState) {
			[path tui_fillWithInnerShadow:[NSShadow tui_shadowWithRadius:5.0f offset:CGSizeZero
																   color:[NSColor shadowColor]]];
		}
	} else if(self.buttonType == TUIButtonTypeFlat) {
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 2.0, 2.0)
															 xRadius:3.5f yRadius:3.5f];
		
		[NSGraphicsContext saveGraphicsState]; {
			[[NSShadow tui_shadowWithRadius:2.0f offset:CGSizeMake(0, -1)
									  color:[NSColor colorWithCalibratedWhite:0.0f alpha:0.5f]] set];
			[self.tintColor set];
			[path fill];
		} [NSGraphicsContext restoreGraphicsState];
		
		if(secondaryState) {
			[[NSColor colorWithCalibratedWhite:0.0f alpha:0.1f] set];
			[path fill];
		}
		
		[path tui_fillWithInnerShadow:[NSShadow tui_shadowWithRadius:2.0f offset:CGSizeMake(0, -1)
															   color:[NSColor colorWithCalibratedWhite:1.0f alpha:0.5f]]];
		
	} else if(self.buttonType == TUIButtonTypeMinimal) {
		CGFloat radius = self.bounds.size.height / 2;
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.5f, 0.5f)
															 xRadius:radius yRadius:radius];
		NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[self.tintColor highlightWithLevel:self.tintFactor]
															 endingColor:[self.tintColor shadowWithLevel:self.tintFactor]];
		
		[gradient drawInBezierPath:path angle:(secondaryState ? 90.0f : 270.0f)];
		[[NSColor grayColor] setStroke];
		[path stroke];
		
	} else if(self.buttonType == TUIButtonTypeClear) {
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.5f, 0.5f)
															 xRadius:3.5f yRadius:3.5f];
		NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.1f]
															 endingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.9f]];
		
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.1f] set];
		if(!secondaryState) {
			[gradient drawInBezierPath:path angle:90.0f];
		} else {
			[path fill];
		}
		
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5f] set];
		[path tui_strokeInside];
		
		if(secondaryState) {
			[path tui_fillWithInnerShadow:[NSShadow tui_shadowWithRadius:3.5f offset:CGSizeMake(0, -1)
																   color:[NSColor colorWithCalibratedWhite:0.0f alpha:0.5f]]];
		}
		
		[[NSColor colorWithCalibratedWhite:0.0f alpha:0.5f] set];
		[path stroke];
	} else if(self.buttonType == TUIButtonTypeInline) {
		CGFloat radius = self.bounds.size.height / 2;
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:radius yRadius:radius];
		
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
	}
}

- (void)drawRect:(CGRect)rect {
	[self drawBackground:rect];
	
	// Handle the image if it exists.
	NSImage *image = self.currentImage;
	if(image) {
		CGRect imageRect = self.bounds;
		if(![image isKindOfClass:[TUIStretchableImage class]]) {
			
			// Not a stretchable image, so center it.
			imageRect.origin = CGPointZero;
			imageRect.size = image.size;
			
			CGRect b = self.bounds;
			b.origin.x += _imageEdgeInsets.left;
			b.origin.y += _imageEdgeInsets.bottom;
			b.size.width -= _imageEdgeInsets.left + _imageEdgeInsets.right;
			b.size.height -= _imageEdgeInsets.bottom + _imageEdgeInsets.top;
			imageRect = ABRectRoundOrigin(ABRectCenteredInRect(imageRect, b));
		}
		
		// Shadow or highlight the image if either option is enabled.
		if(_buttonFlags.adjustsImageWhenDisabled || _buttonFlags.adjustsImageWhenHighlighted) {
			[image lockFocus]; {
				if(_buttonFlags.adjustsImageWhenDisabled)
					[[NSColor colorWithCalibratedWhite:0.0 alpha:(1.0f / 3.0f)] set];
				else if(_buttonFlags.adjustsImageWhenHighlighted)
					[[NSColor colorWithCalibratedWhite:1.0 alpha:(1.0f / 3.0f)] set];
				NSRectFillUsingOperation((NSRect) {.size = image.size}, NSCompositeSourceAtop);
			} [image unlockFocus];
		}
		
		CGFloat alpha = ((self.nsView.isWindowKey && _buttonFlags.dimsInBackground) ? 1.0f : 0.5);
		[image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:alpha];
	}
	
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
		CGContextTranslateCTM(ctx, _titleEdgeInsets.left, _titleEdgeInsets.bottom);
		CGContextSetAlpha(ctx, alpha);
		
		CGRect titleFrame = self.bounds;
		titleFrame.size.width -= (_titleEdgeInsets.left + _titleEdgeInsets.right);
		titleFrame.size.height -= (_titleEdgeInsets.top + _titleEdgeInsets.bottom);
		
		self.titleLabel.frame = titleFrame;
		[self.titleLabel drawRect:self.titleLabel.bounds];
	} CGContextRestoreGState(ctx);
}

#pragma mark - Menu and Selected State

// FIXME: Happens even for large clickCount.
- (void)mouseDown:(NSEvent *)event {
	[super mouseDown:event];
	
	if(self.menu) {
		self.selected = YES;
		[self.menu popUpMenuPositioningItem:nil atLocation:(CGPoint) {
			.x = self.frameInNSView.origin.x + 6,
			.y = self.frameInNSView.origin.y - 2
		} inView:self.nsView];
		
		// After this happens, we never get a mouseUp: in the TUINSView.
		// This screws up _trackingView. For now, fake it with a fake mouseUp:.
		[self.nsView performSelector:@selector(mouseUp:) withObject:event afterDelay:0.0];
		[TUIView animateWithDuration:0.25f animations:^{
			[self redraw];
		}];
	}
}

- (void)mouseUp:(NSEvent *)event {
	[super mouseUp:event];
	if(![self eventInside:event])
		return;
	
	if(self.selectable || self.buttonType == TUIButtonTypeInline || self.menu)
		self.selected = !self.selected;
}

#pragma mark - Highlight Reversing

- (void)stateWillChange {
	_buttonFlags.wasHighlighted = (self.state & TUIControlStateHighlighted);
}

- (void)stateDidChange {
	BOOL reverseShadow = (self.state & TUIControlStateHighlighted) != _buttonFlags.wasHighlighted;
	
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
	NSString *title = [self titleForState:self.state];
	if(title == nil)
		title = [self titleForState:TUIControlStateNormal];
	
	return title;
}

- (NSColor *)currentTitleColor {
	NSColor *color = [self titleColorForState:self.state];
	if(color == nil)
		color = [self titleColorForState:TUIControlStateNormal];
	
	return color;
}

- (NSColor *)currentTitleShadowColor {
	NSColor *color = [self titleShadowColorForState:self.state];
	if(color == nil)
		color = [self titleShadowColorForState:TUIControlStateNormal];
	
	return color;
}

- (NSImage *)currentImage {
	NSImage *image = [self imageForState:self.state];
	if(image == nil)
		image = [self imageForState:TUIControlStateNormal];
	
	return image;
}

- (NSImage *)currentBackgroundImage {
	NSImage *image = [self backgroundImageForState:self.state];
	if(image == nil)
		image = [self backgroundImageForState:TUIControlStateNormal];
	
	return image;
}

#pragma mark -

@end
