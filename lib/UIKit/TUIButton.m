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

#import "TUIImage.h"
#import "TUIButton.h"
#import "TUILabel.h"
#import "TUINSView.h"
#import "TUIControl+Private.h"

@interface TUIButton ()

- (void)_update;

@end

@implementation TUIButton

@synthesize popUpMenu;
@synthesize interactionSpeed;
@synthesize imageView = _imageView;
@synthesize backgroundImageView = _backgroundImageView;
@synthesize titleEdgeInsets = _titleEdgeInsets;
@synthesize imageEdgeInsets = _imageEdgeInsets;

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
        
		_contentLookup = [[NSMutableDictionary alloc] init];
		self.opaque = NO;
		_buttonFlags.buttonType = TUIButtonTypeCustom;
		_buttonFlags.dimsInBackground = 1;
        _buttonFlags.dimsWhenHighlighted = 1;
		_buttonFlags.firstDraw = 1;
        
        self.interactionSpeed = 0.5;
		self.backgroundColor = [TUIColor clearColor];
        self.needsDisplayWhenWindowsKeyednessChanges = YES;
        self.reversesTitleShadowWhenHighlighted = NO;
        
        [self addSubview:self.backgroundImageView];
        [self addSubview:self.imageView];
        [self addSubview:self.titleLabel];
	}
	return self;
}


+ (id)button
{
	return [self buttonWithType:TUIButtonTypeCustom];
}

+ (id)buttonWithType:(TUIButtonType)buttonType
{
	return [[self alloc] initWithFrame:CGRectZero];
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

- (TUIButtonType)buttonType
{
	return _buttonFlags.buttonType;
}

- (TUILabel *)titleLabel
{
	if(!_titleView) {
		_titleView = [[TUILabel alloc] initWithFrame:CGRectZero];
		_titleView.userInteractionEnabled = NO;
		_titleView.backgroundColor = [TUIColor clearColor];
		_titleView.hidden = YES; // we'll be drawing it ourselves
		[self addSubview:_titleView];
	}
	return _titleView;
}

- (TUIImageView *)imageView
{
	if(!_imageView) {
		_imageView = [[TUIImageView alloc] initWithFrame:CGRectZero];
		_imageView.backgroundColor = [TUIColor clearColor];
		_imageView.hidden = YES;
	}
	return _imageView;
}

- (TUIImageView *)backgroundImageView {
	if(!_backgroundImageView) {
		_backgroundImageView = [[TUIImageView alloc] initWithFrame:CGRectZero];
		_backgroundImageView.backgroundColor = [TUIColor clearColor];
        [_backgroundImageView setUserInteractionEnabled:NO];
	} return _backgroundImageView;
}

- (BOOL)dimsInBackground {
	return _buttonFlags.dimsInBackground;
}

- (void)setDimsInBackground:(BOOL)b {
	_buttonFlags.dimsInBackground = b;
    [self setNeedsDisplay];
}

- (BOOL)dimsWhenHighlighted {
	return _buttonFlags.dimsWhenHighlighted;
}

- (void)setDimsWhenHighlighted:(BOOL)b {
	_buttonFlags.dimsWhenHighlighted = b;
    [self setNeedsDisplay];
}

- (BOOL)reversesTitleShadowWhenHighlighted {
	return _buttonFlags.reversesTitleShadowWhenHighlighted;
}

- (void)setReversesTitleShadowWhenHighlighted:(BOOL)reversesTitleShadowWhenHighlighted {
	_buttonFlags.reversesTitleShadowWhenHighlighted = reversesTitleShadowWhenHighlighted;
    [self setNeedsDisplay];
}

- (CGRect)backgroundRectForBounds:(CGRect)bounds
{
	return bounds;
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
	return bounds;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
	return contentRect;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
	return contentRect;
}

static CGRect ButtonRectRoundOrigin(CGRect f)
{
	f.origin.x = roundf(f.origin.x);
	f.origin.y = roundf(f.origin.y);
	return f;
}

static CGRect ButtonRectCenteredInRect(CGRect a, CGRect b)
{
	CGRect r;
	r.size = a.size;
	r.origin.x = b.origin.x + (b.size.width - a.size.width) * 0.5;
	r.origin.y = b.origin.y + (b.size.height - a.size.height) * 0.5;
	return r;
}

static CGRect ButtonRectVerticalCenteredInRect(CGRect a, CGRect b)
{
	CGRect r;
	r.size = a.size;
	r.origin.y = b.origin.y + (b.size.height - a.size.height) * 0.5;
	return r;
}

- (CGSize)sizeThatFits:(CGSize)size {
	return self.currentImage.size;
}

- (void)drawRect:(CGRect)r
{
	if(_buttonFlags.firstDraw) {
		_buttonFlags.firstDraw = 0;
	}
	
    // Set the alpha status.
	CGRect bounds = self.bounds;
	CGFloat alpha = (_buttonFlags.dimsWhenHighlighted && self.state == TUIControlStateHighlighted) ? 1.0 : 0.65;
    if(_buttonFlags.dimsInBackground)
		alpha = [self.nsWindow isKeyWindow] ? alpha : 0.5;
    
    // Fluidly animate the title view alpha changes.
	[TUIView animateWithDuration:(interactionSpeed / 2) animations:^{
        _titleView.alpha = alpha;
    }];
    
    // Fluidly animate the color changes.
	[TUIView animateWithDuration:interactionSpeed animations:^{
        if(self.currentBackgroundColor)
            self.backgroundColor = self.currentBackgroundColor;
        else self.backgroundColor = [TUIColor clearColor];
    }];
	
    // Assign background image to button.
	self.backgroundImageView.alpha = 1.0f;//0.0f;
    self.backgroundImageView.image = self.currentBackgroundImage;
    self.backgroundImageView.frame = [self backgroundRectForBounds:bounds];
    [TUIView animateWithDuration:(interactionSpeed / 2) animations:^{
        //self.backgroundImageView.alpha = alpha;
    }];
    
    // Don't directly draw the background image.
    //UXImage *backgroundImage = self.currentBackgroundImage;
	//[backgroundImage drawInRect:[self backgroundRectForBounds:bounds] blendMode:kCGBlendModeNormal alpha:1.0];
	
    // Assign an available image to button.
    // If none, don't worry about capping it.
	TUIImage *image = self.currentImage;
	if(image) {
		CGRect imageRect;
		if(image.leftCapWidth || image.topCapHeight) {
			// If there are caps, it's a stretchable image.
			imageRect = self.bounds;
		} else {
			// No caps, so it's a standard image.
			imageRect.origin = CGPointZero;
			imageRect.size = [image size];
            
            // Adjust the inset rect.
			CGRect b = self.bounds;
			b.origin.x += _imageEdgeInsets.left;
			b.origin.y += _imageEdgeInsets.bottom;
			b.size.width -= _imageEdgeInsets.left + _imageEdgeInsets.right;
			b.size.height -= _imageEdgeInsets.bottom + _imageEdgeInsets.top;
            
			imageRect = ButtonRectRoundOrigin(ButtonRectVerticalCenteredInRect(imageRect, b));
		}
        
        self.imageView.alpha = 0.0f;
        self.imageView.image = image;
        self.imageView.frame = imageRect;
        [TUIView animateWithDuration:(interactionSpeed / 2) animations:^{
            self.imageView.alpha = alpha;
        }];
        
        // Don't directly draw the image.
        //[image drawInRect:imageRect blendMode:kCGBlendModeNormal alpha:alpha];
	}
	
    if(self.currentTitle) _titleView.text = self.currentTitle;
    if(self.currentTitleColor) _titleView.textColor = self.currentTitleColor;
    
	TUIColor *shadowColor = self.currentTitleShadowColor;
	// they may have manually set the renderer's shadow color, in which case we 
	// don't want to reset it to nothing
	if(shadowColor != nil) {
		_titleView.renderer.shadowColor = shadowColor;
	}
    
    // Draw our new bounds and frame
    // based on the "new" insets.
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	CGContextSaveGState(ctx);
	CGContextTranslateCTM(ctx, _titleEdgeInsets.left, _titleEdgeInsets.bottom);
    
    _titleView.bounds = bounds;
    _titleView.frame = CGRectMake(_titleEdgeInsets.left, 
                                  _titleEdgeInsets.top, 
                                  bounds.size.width - _titleEdgeInsets.left - _titleEdgeInsets.right,
                                  bounds.size.height - _titleEdgeInsets.top - _titleEdgeInsets.bottom);
	CGContextRestoreGState(ctx);
}

- (void)mouseDown:(NSEvent *)event
{
	[super mouseDown:event];

	if(popUpMenu) { // happens even if clickCount is big
		NSMenu *menu = popUpMenu;
		NSPoint p = [self frameInNSView].origin;
		p.x += 6;
		p.y -= 2;
		[menu popUpMenuPositioningItem:nil atLocation:p inView:self.nsView];
		/*
		 after this happens, we never get a mouseUp: in the TUINSView.  this screws up _trackingView
		 for now, fake it with a fake mouseUp:
		 */
		[self.nsView performSelector:@selector(mouseUp:) withObject:event afterDelay:0.0];
		
		_controlFlags.tracking = 0;
		[TUIView animateWithDuration:0.2 animations:^{
			[self redraw];
		}];
	}
}

- (void)_stateDidChange {
	[super _stateDidChange];
	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted {
	if(self.highlighted != highlighted && self.reversesTitleShadowWhenHighlighted) {
		_titleView.renderer.shadowOffset = CGSizeMake(_titleView.renderer.shadowOffset.width, -_titleView.renderer.shadowOffset.height);
	}
	
	[super setHighlighted:highlighted];
}

@end
