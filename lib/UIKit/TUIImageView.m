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

#import "TUIImageView.h"
#import "TUINSView.h"
#import "NSImage+TUIExtensions.h"
#import "TUIStretchableImage.h"

@implementation TUIImageView

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;
        self.opaque = NO;
		self.editable = NO;
		self.editingSizesToFit = NO;
    }
    return self;
}

- (id)initWithImage:(NSImage *)image {
	if((self = [self initWithFrame:image ? CGRectMake(0, 0, image.size.width, image.size.height) : CGRectZero])) {
		self.image = image;
	}
	return self;
}

- (id)initWithImage:(NSImage *)image highlightedImage:(NSImage *)highlightedImage {
	if((self = [self initWithImage:image])) {
		self.highlightedImage = highlightedImage;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	if(!self.image)
		return;
    
    [self.image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)startAnimating {
    NSArray *images = _highlighted ? _highlightedAnimationImages : _animationImages;
	
	NSMutableArray *CGImages = [NSMutableArray array];
	for(NSImage *image in images) {
		[CGImages addObject:(__bridge id)image.tui_CGImage];
	}
	
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    animation.calculationMode = kCAAnimationDiscrete;
    animation.fillMode = kCAFillModeBoth;
    animation.removedOnCompletion = NO;
    animation.duration = self.animationDuration ?: ([images count] * (1/30.0));
    animation.repeatCount = self.animationRepeatCount ?: HUGE_VALF;
    animation.values = CGImages;
	
    [self.layer addAnimation:animation forKey:@"contents"];
}

- (void)stopAnimating {
    [self.layer removeAnimationForKey:@"contents"];
}

- (BOOL)isAnimating {
    return [self.layer animationForKey:@"contents"] != nil;
}

- (void)setImage:(NSImage *)image {
	if([_image isEqual:image])
		return;
	
	_image = image;
	if(!(self.highlighted && self.highlightedImage))
		[self setNeedsDisplay];
}

- (void)setHighlightedImage:(NSImage *)newImage {
    if([_highlightedImage isEqual:newImage])
		return;
	
	_highlightedImage = newImage;
	if(self.highlighted)
		[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)h {
	if(_highlighted == h)
		return;
	
    _highlighted = h;
	if([TUIView isInAnimationContext])
		[self redraw];
	else [self setNeedsDisplay];
	
	if([self isAnimating])
		[self startAnimating];
}

- (void)setEditable:(BOOL)editable {
	_editable = editable;
	if(editable)
		[self registerForDraggedTypes:@[NSPasteboardTypePDF,
		 NSPasteboardTypeTIFF,
		 NSPasteboardTypePNG,
		 NSFilenamesPboardType,
		 NSPostScriptPboardType,
		 NSTIFFPboardType,
		 NSFileContentsPboardType,
		 NSPDFPboardType]];
	else self.draggingTypes = nil;
}

- (void)displayIfSizeChangedFrom:(CGSize)oldSize to:(CGSize)newSize {
    if(!CGSizeEqualToSize(newSize, oldSize) && [self.image.class isKindOfClass:TUIStretchableImage.class]) {
        [self setNeedsDisplay];
    }
}

- (void)setFrame:(CGRect)newFrame {
	BOOL needsDisplay = !CGSizeEqualToSize(self.frame.size, newFrame.size);
	[super setFrame:newFrame];
	
	if(needsDisplay && ![self.image.class isKindOfClass:TUIStretchableImage.class]) {
		if([TUIView isInAnimationContext])
			[self redraw];
		else [self setNeedsDisplay];
	}
}

- (void)setBounds:(CGRect)newBounds {
	BOOL needsDisplay = !CGSizeEqualToSize(self.bounds.size, newBounds.size);
	[super setBounds:newBounds];
	
	if(needsDisplay && ![self.image.class isKindOfClass:TUIStretchableImage.class]) {
		if([TUIView isInAnimationContext])
			[self redraw];
		else [self setNeedsDisplay];
	}
}

- (CGSize)sizeThatFits:(CGSize)size {
	return self.image? self.image.size : CGSizeZero;
}

- (void)sizeToFit {
	CGSize fittingSize = [self sizeThatFits:CGSizeZero];
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
							fittingSize.width, fittingSize.height);
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if(![sender.draggingSource isEqual:self] && self.editable && [NSImage canInitWithPasteboard:sender.draggingPasteboard]) {
		self.highlighted = YES;
		return NSDragOperationCopy;
	} else {
		return NSDragOperationNone;
	}
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	self.highlighted = NO;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return (![sender.draggingSource isEqual:self] && self.editable);
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	NSImage *image = [[NSImage alloc] initWithPasteboard:sender.draggingPasteboard];
	
	if(image) {
		self.image = image;
		if(self.editingSizesToFit)
			[self sizeToFit];
	}
	
	return image == nil;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	self.highlighted = NO;
}

@end
