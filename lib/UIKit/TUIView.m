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

#import "TUIView.h"
#import "TUIKit.h"
#import "TUIView+Private.h"
#import "TUIViewController.h"
#import "TUILayoutConstraint.h"
#import <pthread.h>

typedef enum {
    TUIConstraintMin = 1 << 0,
    TUIConstraintMid = 1 << 1,
    TUIConstraintMax = 1 << 2,
    TUIConstraintSize = 1 << 3,
} TUIConstraintAxis;

NSString * const TUIViewWillMoveToWindowNotification = @"TUIViewWillMoveToWindowNotification";
NSString * const TUIViewDidMoveToWindowNotification = @"TUIViewDidMoveToWindowNotification";
NSString * const TUIViewWindow = @"TUIViewWindow";

CGRect(^TUIViewCenteredLayout)(TUIView*) = nil;

@class TUIViewController;

@interface CALayer (TUIViewAdditions)
@property (nonatomic, readonly) TUIView *associatedView;
@property (nonatomic, readonly) TUIView *closestAssociatedView;
@end
@implementation CALayer (TUIViewAdditions)

- (TUIView *)associatedView
{
	id v = self.delegate;
	if([v isKindOfClass:[TUIView class]])
		return v;
	return nil;
}

- (TUIView *)closestAssociatedView
{
	CALayer *l = self;
	do {
		TUIView *v = [self associatedView];
		if(v)
			return v;
	} while((l = l.superlayer));
	return nil;
}

@end


@interface TUIView ()

@property (nonatomic, strong) NSMutableArray *subviews;

@property (nonatomic, retain) NSMutableArray *liveConstraints;
@property (nonatomic, retain) NSMutableArray *nodes;
@property (nonatomic, assign) BOOL queuedConstraintUpdate;

@end

@interface TUIView (CoreLayout_Private)

- (void)updateConstraintsGraph;
- (void)layoutSubviewsOfView:(TUIView *)view;
- (void)solveConstraintsInView:(TUIView *)view;
- (void)solveAxis:(NSArray *)axis inView:(TUIView *)view;
- (CGFloat)axisAttributeValue:(TUIConstraintAxis)axisVal
                      inFrame:(CGRect)frame
                      isYAxis:(BOOL)isYAxis;

@end

@implementation TUIView

@synthesize layout;
@synthesize toolTip;
@synthesize toolTipDelay;
@synthesize drawQueue;
// use the accessor from the main implementation block
@synthesize subviews = _subviews;

- (void)setSubviews:(NSArray *)s
{
	NSMutableArray *toRemove = [NSMutableArray array];
	for(CALayer *sublayer in self.layer.sublayers) {
		TUIView *associatedView = [sublayer associatedView];
		if(associatedView != nil) [toRemove addObject:associatedView];
	}
	[toRemove makeObjectsPerformSelector:@selector(removeFromSuperview)];
	
	for(TUIView *subview in s) {
		[self addSubview:subview];
	}
}

static pthread_key_t TUICurrentContextScaleFactorTLSKey;

+ (void)initialize
{
	if(self == [TUIView class]) {
		pthread_key_create(&TUICurrentContextScaleFactorTLSKey, free);

		TUIViewCenteredLayout = [^(TUIView *v) {
			TUIView *superview = v.superview;
			CGRect b = superview.frame;
			b.origin = CGPointZero;
			CGRect r = ABRectCenteredInRect(v.frame, b);
			r.origin.x = roundf(r.origin.x);
			r.origin.y = roundf(r.origin.y);
			return r;
		} copy];
	}
}

+ (Class)layerClass
{
	return [CALayer class];
}

- (void)dealloc
{
	[self setTextRenderers:nil];
	_layer.delegate = nil;
	if(_context.context) {
		CGContextRelease(_context.context);
		_context.context = NULL;
	}
}

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super init]))
	{
		_viewFlags.clearsContextBeforeDrawing = 1;
		self.frame = frame;
        self.nodes = [NSMutableArray array];
        self.liveConstraints = [NSMutableArray array];
		toolTipDelay = 1.5;
		self.isAccessibilityElement = YES;
		accessibilityFrame = CGRectNull; // null rect means we'll just get the view's frame and use that
	}
	return self;
}

- (CALayer *)layer
{
	if(!_layer) {
		_layer = [[[[self class] layerClass] alloc] init];
		_layer.delegate = self;
		_layer.opaque = YES;
		_layer.needsDisplayOnBoundsChange = YES;
	}
	return _layer;
}

- (void)setLayer:(CALayer *)l
{
	_layer = l;
}

- (BOOL)makeFirstResponder
{
	return [[self nsWindow] tui_makeFirstResponder:self];
}

- (NSInteger)tag
{
	return _tag;
}

- (void)setTag:(NSInteger)t
{
	_tag = t;
}

- (BOOL)isUserInteractionEnabled
{
	return !_viewFlags.userInteractionDisabled;
}

- (void)setUserInteractionEnabled:(BOOL)b
{
	_viewFlags.userInteractionDisabled = !b;
}

- (BOOL)moveWindowByDragging
{
	return _viewFlags.moveWindowByDragging;
}

- (void)setMoveWindowByDragging:(BOOL)b
{
	_viewFlags.moveWindowByDragging = b;
}

- (BOOL)resizeWindowByDragging
{
	return _viewFlags.resizeWindowByDragging;
}

- (void)setResizeWindowByDragging:(BOOL)b
{
	_viewFlags.resizeWindowByDragging = b;
}

- (BOOL)subpixelTextRenderingEnabled
{
	return !_viewFlags.disableSubpixelTextRendering;
}

- (void)setSubpixelTextRenderingEnabled:(BOOL)b
{
	_viewFlags.disableSubpixelTextRendering = !b;
}

- (BOOL)needsDisplayWhenWindowsKeyednessChanges
{
	return _viewFlags.needsDisplayWhenWindowsKeyednessChanges;
}

- (void)setNeedsDisplayWhenWindowsKeyednessChanges:(BOOL)needsDisplay
{
	_viewFlags.needsDisplayWhenWindowsKeyednessChanges = needsDisplay;
}

- (void)windowDidBecomeKey
{
	if(self.needsDisplayWhenWindowsKeyednessChanges) {
		[self setNeedsDisplay];
	}
	
	[self.subviews makeObjectsPerformSelector:@selector(windowDidBecomeKey)];
}

- (void)windowDidResignKey
{
	if(self.needsDisplayWhenWindowsKeyednessChanges) {
		[self setNeedsDisplay];
	}
	
	[self.subviews makeObjectsPerformSelector:@selector(windowDidResignKey)];
}

- (id<TUIViewDelegate>)viewDelegate
{
	return _viewDelegate;
}

- (void)setViewDelegate:(id <TUIViewDelegate>)d
{
	_viewDelegate = d;
	_viewFlags.delegateMouseEntered = [_viewDelegate respondsToSelector:@selector(view:mouseEntered:)];
	_viewFlags.delegateMouseExited = [_viewDelegate respondsToSelector:@selector(view:mouseExited:)];
	_viewFlags.delegateWillDisplayLayer = [_viewDelegate respondsToSelector:@selector(viewWillDisplayLayer:)];
}

/*
 ********* CALayer delegate methods ************
 */

// actionForLayer:forKey: implementetd in TUIView+Animation

- (BOOL)_disableDrawRect
{
	return NO;
}

- (CGContextRef)_CGContext
{
	CGRect b = self.bounds;
	NSInteger w = b.size.width;
	NSInteger h = b.size.height;
	BOOL o = self.opaque;
	CGFloat currentScale = [self.layer respondsToSelector:@selector(contentsScale)] ? self.layer.contentsScale : 1.0f;
	
	if(_context.context) {
		// kill if we're a different size
		if(w != _context.lastWidth || 
		   h != _context.lastHeight ||
		   o != _context.lastOpaque ||
		   fabs(currentScale - _context.lastContentsScale) > 0.1f) 
		{
			CGContextRelease(_context.context);
			_context.context = NULL;
		}
	}
	
	if(!_context.context) {
		// create a new context with the correct parameters
		_context.lastWidth = w;
		_context.lastHeight = h;
		_context.lastOpaque = o;
		_context.lastContentsScale = currentScale;

		b.size.width *= currentScale;
		b.size.height *= currentScale;
		if(b.size.width < 1) b.size.width = 1;
		if(b.size.height < 1) b.size.height = 1;
		CGContextRef ctx = TUICreateGraphicsContextWithOptions(b.size, o);
		_context.context = ctx;
	}
	
	return _context.context;
}

CGFloat TUICurrentContextScaleFactor(void)
{
	/*
	 Key is set up in +initialize
	 Use TLS rather than a simple global so drawsInBackground should continue to work (views in the same process may be drawing destined for different windows on different screens with different scale factors).
	 */
	CGFloat *v = pthread_getspecific(TUICurrentContextScaleFactorTLSKey);
	if(v)
		return *v;
	return 1.0;
}

static void TUISetCurrentContextScaleFactor(CGFloat s)
{
	CGFloat *v = pthread_getspecific(TUICurrentContextScaleFactorTLSKey);
	if(!v) {
		v = malloc(sizeof(CGFloat));
		pthread_setspecific(TUICurrentContextScaleFactorTLSKey, v);
	}
	*v = s;
}

- (void)displayLayer:(CALayer *)layer
{
	if(_viewFlags.delegateWillDisplayLayer)
		[_viewDelegate viewWillDisplayLayer:self];
	
	typedef void (*DrawRectIMP)(id,SEL,CGRect);
	SEL drawRectSEL = @selector(drawRect:);
	DrawRectIMP drawRectIMP = (DrawRectIMP)[self methodForSelector:drawRectSEL];
	DrawRectIMP dontCallThisBasicDrawRectIMP = (DrawRectIMP)[TUIView instanceMethodForSelector:drawRectSEL];

#if 0
#define CA_COLOR_OVERLAY_DEBUG \
if(self.opaque) CGContextSetRGBFillColor(context, 0, 1, 0, 0.3); \
else CGContextSetRGBFillColor(context, 1, 0, 0, 0.3); CGContextFillRect(context, b);
#else
#define CA_COLOR_OVERLAY_DEBUG
#endif

#define PRE_DRAW \
	CGRect b = self.bounds; \
	CGContextRef context = [self _CGContext]; \
	TUIGraphicsPushContext(context); \
	if(_viewFlags.clearsContextBeforeDrawing) \
		CGContextClearRect(context, b); \
	CGFloat scale = [self.layer respondsToSelector:@selector(contentsScale)] ? self.layer.contentsScale : 1.0f; \
	TUISetCurrentContextScaleFactor(scale); \
	CGContextScaleCTM(context, scale, scale); \
	CGContextSetAllowsAntialiasing(context, true); \
	CGContextSetShouldAntialias(context, true); \
	CGContextSetShouldSmoothFonts(context, !_viewFlags.disableSubpixelTextRendering);
	
#define POST_DRAW \
	CA_COLOR_OVERLAY_DEBUG \
	TUIImage *image = TUIGraphicsGetImageFromCurrentImageContext(); \
	layer.contents = (id)image.CGImage; \
	CGContextScaleCTM(context, 1.0f / scale, 1.0f / scale); \
	TUIGraphicsPopContext(); \
	if(self.drawInBackground) [CATransaction flush];

	CGRect rectToDraw = self.bounds;
	if(!CGRectEqualToRect(_context.dirtyRect, CGRectZero)) {
		rectToDraw = _context.dirtyRect;
		_context.dirtyRect = CGRectZero;
	}
	
	void (^drawBlock)(void) = ^{
		if(drawRect) {
			// drawRect is implemented via a block
			PRE_DRAW
			drawRect(self, rectToDraw);
			POST_DRAW
		} else if((drawRectIMP != dontCallThisBasicDrawRectIMP) && ![self _disableDrawRect]) {
			// drawRect is overridden by subclass
			PRE_DRAW
			drawRectIMP(self, drawRectSEL, rectToDraw);
			POST_DRAW
		} else {
			// drawRect isn't overridden by subclass, don't call, let the CA machinery just handle backgroundColor (fast path)
		}
	};
	
	if(self.drawInBackground) {
		layer.contents = nil;
		
		if(self.drawQueue != nil) {
			[self.drawQueue addOperationWithBlock:drawBlock];
		} else {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), drawBlock);
		}
	} else {
		drawBlock();
	}
}

- (void)_blockLayout
{
	for(TUIView *v in self.subviews) {
		if(v.layout) {
			v.frame = v.layout(v);
		}
	}
}

- (void)setLayout:(TUIViewLayout)l
{
	self.autoresizingMask = TUIViewAutoresizingNone;
	layout = [l copy];
	[self _blockLayout];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [self layoutSubviewsOfView:self];
	[self layoutSubviews];
	[self _blockLayout];
}

- (BOOL)drawInBackground
{
	return _viewFlags.drawInBackground;
}

- (void)setDrawInBackground:(BOOL)drawInBackground
{
	_viewFlags.drawInBackground = drawInBackground;
}

- (NSTimeInterval)toolTipDelay
{
	return toolTipDelay;
}

- (TUIViewContentMode)contentMode
{
	if(_layer.contentsGravity == kCAGravityCenter) {
		return TUIViewContentModeCenter;
	} else if(_layer.contentsGravity == kCAGravityTop) {
		return TUIViewContentModeTop;
	} else if(_layer.contentsGravity == kCAGravityBottom) {
		return TUIViewContentModeBottom;
	} else if(_layer.contentsGravity == kCAGravityLeft) {
		return TUIViewContentModeLeft;
	} else if(_layer.contentsGravity == kCAGravityRight) {
		return TUIViewContentModeRight;
	} else if(_layer.contentsGravity == kCAGravityTopLeft) {
		return TUIViewContentModeTopLeft;
	} else if(_layer.contentsGravity == kCAGravityTopRight) {
		return TUIViewContentModeTopRight;
	} else if(_layer.contentsGravity == kCAGravityBottomLeft) {
		return TUIViewContentModeBottomLeft;
	} else if(_layer.contentsGravity == kCAGravityBottomRight) {
		return TUIViewContentModeBottomRight;
	} else if(_layer.contentsGravity == kCAGravityResize) {
		return TUIViewContentModeScaleToFill;
	} else if(_layer.contentsGravity == kCAGravityResizeAspect) {
		return TUIViewContentModeScaleAspectFit;
	} else if(_layer.contentsGravity == kCAGravityResizeAspectFill) {
		return TUIViewContentModeScaleAspectFill;
	} else {
		return TUIViewContentModeScaleToFill;
	}
}

- (void)setContentMode:(TUIViewContentMode)contentMode
{
	if(contentMode == TUIViewContentModeCenter) {
		_layer.contentsGravity = kCAGravityCenter;
	} else if(contentMode == TUIViewContentModeTop) {
		_layer.contentsGravity = kCAGravityTop;
	} else if(contentMode == TUIViewContentModeBottom) {
		_layer.contentsGravity = kCAGravityBottom;
	} else if(contentMode == TUIViewContentModeLeft) {
		_layer.contentsGravity = kCAGravityLeft;
	} else if(contentMode == TUIViewContentModeRight) {
		_layer.contentsGravity = kCAGravityRight;
	} else if(contentMode == TUIViewContentModeTopLeft) {
		_layer.contentsGravity = kCAGravityTopLeft;
	} else if(contentMode == TUIViewContentModeTopRight) {
		_layer.contentsGravity = kCAGravityTopRight;
	} else if(contentMode == TUIViewContentModeBottomLeft) {
		_layer.contentsGravity = kCAGravityBottomLeft;
	} else if(contentMode == TUIViewContentModeBottomRight) {
		_layer.contentsGravity = kCAGravityBottomRight;
	} else if(contentMode == TUIViewContentModeScaleToFill) {
		_layer.contentsGravity = kCAGravityResize;
	} else if(contentMode == TUIViewContentModeScaleAspectFit) {
		_layer.contentsGravity = kCAGravityResizeAspect;
	} else if(contentMode == TUIViewContentModeScaleAspectFill) {
		_layer.contentsGravity = kCAGravityResizeAspectFill;
	} else {
		NSAssert1(NO, @"%u is not a valid contentMode.", contentMode);
	}
}

@end


@implementation TUIView (TUIViewGeometry)

- (CGRect)frame
{
	return self.layer.frame;
}

- (void)setFrame:(CGRect)f
{
	self.layer.frame = f;
}

- (CGRect)bounds
{
	return self.layer.bounds;
}

- (void)setBounds:(CGRect)b
{
	self.layer.bounds = b;
}

- (void)setCenter:(CGPoint)c
{
	CGRect f = self.frame;
	f.origin.x = c.x - f.size.width / 2;
	f.origin.y = c.y - f.size.height / 2;
	self.frame = f;
}

- (CGPoint)center
{
	CGRect f = self.frame;
	return CGPointMake(f.origin.x + (f.size.width / 2), f.origin.y + (f.size.height / 2));
}

- (CGAffineTransform)transform
{
	return [self.layer affineTransform];
}

- (void)setTransform:(CGAffineTransform)t
{
	[self.layer setAffineTransform:t];
}

- (NSArray *)sortedSubviews // back to front order
{
	return [self.subviews sortedArrayWithOptions:NSSortStable usingComparator:(NSComparator)^NSComparisonResult(TUIView *a, TUIView *b) {
		CGFloat x = a.layer.zPosition;
		CGFloat y = b.layer.zPosition;
		if(x > y)
			return NSOrderedDescending;
		else if(x < y)
			return NSOrderedAscending;
		return NSOrderedSame;
	}];
}

- (TUIView *)hitTest:(CGPoint)point withEvent:(id)event
{
	if((self.userInteractionEnabled == NO) || (self.hidden == YES) || (self.alpha <= 0.0f))
		return nil;
	
	if([self pointInside:point withEvent:event]) {
		NSArray *s = [self sortedSubviews];
		for(TUIView *v in [s reverseObjectEnumerator]) {
			TUIView *hit = [v hitTest:[self convertPoint:point toView:v] withEvent:event];
			if(hit)
				return hit;
		}
		return self; // leaf
	}
	return nil;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(id)event
{
	return [self.layer containsPoint:point];
}

- (CGPoint)convertPoint:(CGPoint)point toView:(TUIView *)view
{
	return [self.layer convertPoint:point toLayer:view.layer];
}

- (CGPoint)convertPoint:(CGPoint)point fromView:(TUIView *)view
{
	return [self.layer convertPoint:point fromLayer:view.layer];
}

- (CGRect)convertRect:(CGRect)rect toView:(TUIView *)view
{
	return [self.layer convertRect:rect toLayer:view.layer];
}

- (CGRect)convertRect:(CGRect)rect fromView:(TUIView *)view
{
	return [self.layer convertRect:rect fromLayer:view.layer];
}

- (TUIViewAutoresizing)autoresizingMask
{
	return (TUIViewAutoresizing)self.layer.autoresizingMask;
}

- (void)setAutoresizingMask:(TUIViewAutoresizing)m
{
	self.layer.autoresizingMask = (unsigned int)m;
}

- (CGSize)sizeThatFits:(CGSize)size
{
	return self.bounds.size;
}

- (void)sizeToFit
{
	CGRect b = self.bounds;
	b.size = [self sizeThatFits:self.bounds.size];
	self.bounds = b;
}

@end

@implementation TUIView (TUIViewHierarchy)

@dynamic subviews;

- (TUIView *)superview
{
	return [self.layer.superlayer closestAssociatedView];
}

- (NSInteger)deepNumberOfSubviews
{
	NSInteger n = [self.subviews count];
	for(TUIView *s in self.subviews)
		n += s.deepNumberOfSubviews;
	return n;
}

- (void)_cleanupResponderChain // called when a view is about to be removed from the heirarchy
{
	[self.subviews makeObjectsPerformSelector:@selector(_cleanupResponderChain)]; // call this first because subviews may pass first responder responsibility up to the superview
	
	NSWindow *window = [self nsWindow];
	if([window firstResponder] == self) {
		[window tui_makeFirstResponder:self.superview];
	} else if([_textRenderers containsObject:[window firstResponder]]) {
		[window tui_makeFirstResponder:self.superview];
	}
}

- (void)removeFromSuperview // everything should go through this
{
	[self _cleanupResponderChain];
	
	TUIView *superview = [self superview];
	if(superview) {
		[superview willRemoveSubview:self];
		[self willMoveToSuperview:nil];

		[superview.subviews removeObjectIdenticalTo:self];
		[self.layer removeFromSuperlayer];
		self.nsView = nil;

		[self didMoveToSuperview];
	}
}

- (BOOL)_canRespondToEvents
{
	if((self.userInteractionEnabled == NO) || (self.hidden == YES))
		return NO;
	return YES;
}

- (void)keyDown:(NSEvent *)event
{
	if(![self _canRespondToEvents])
		return;
	
	if([self performKeyAction:event])
		return;
	
	if([[self nextResponder] isKindOfClass:[TUIViewController class]])
		if([[self nextResponder] respondsToSelector:@selector(performKeyAction:)])
			if([(TUIResponder *)[self nextResponder] performKeyAction:event])
				return;
	
	// if all else fails, try performKeyActions on the next responder
	[[self nextResponder] keyDown:event];
}

- (BOOL)performKeyEquivalent:(NSEvent *)event
{
	if(![self _canRespondToEvents])
		return NO;
	
	if([[self nextResponder] isKindOfClass:[TUIViewController class]]) {
		// give associated view controller a chance to do something
		if([[self nextResponder] performKeyEquivalent:event])
			return YES;
	}
	
	for(TUIView *v in self.subviews) { // propogate down through subviews
		if([v performKeyEquivalent:event])
			return YES;
	}
	
	return NO;
}

- (void)setNextResponder:(NSResponder *)r
{
	NSResponder *nextResponder = [self nextResponder];
	if([nextResponder isKindOfClass:[TUIViewController class]]) {
		// keep view controller in chain
		[nextResponder setNextResponder:r];
	} else {
		[super setNextResponder:r];
	}
}

#define PRE_ADDSUBVIEW(index) \
	if (!_subviews) \
		_subviews = [[NSMutableArray alloc] init]; \
	\
	if (index == NSUIntegerMax) {\
		[self.subviews addObject:view]; \
	} else {\
		[self.subviews insertObject:view atIndex:index];\
	}\
 	[view removeFromSuperview]; /* will call willAdd:nil and didAdd (nil) */ \
	[view willMoveToSuperview:self]; \
	view.nsView = _nsView;

#define POST_ADDSUBVIEW \
	[self didAddSubview:view]; \
	[view didMoveToSuperview]; \
	[view setNextResponder:self]; \
	[self _blockLayout];

- (void)addSubview:(TUIView *)view // everything should go through this
{
	if(!view)
		return;
	PRE_ADDSUBVIEW(NSUIntegerMax)
	[self.layer addSublayer:view.layer];
	POST_ADDSUBVIEW
}

- (void)insertSubview:(TUIView *)view atIndex:(NSInteger)index
{
	PRE_ADDSUBVIEW(index)
	[self.layer insertSublayer:view.layer atIndex:(unsigned int)index];
	POST_ADDSUBVIEW
}

- (void)insertSubview:(TUIView *)view belowSubview:(TUIView *)siblingSubview
{
	NSUInteger siblingIndex = [self.subviews indexOfObject:siblingSubview];
	if (siblingIndex == NSNotFound)
		return;
	
	PRE_ADDSUBVIEW(siblingIndex + 1)
	[self.layer insertSublayer:view.layer below:siblingSubview.layer];
	POST_ADDSUBVIEW
}

- (void)insertSubview:(TUIView *)view aboveSubview:(TUIView *)siblingSubview
{
	NSUInteger siblingIndex = [self.subviews indexOfObject:siblingSubview];
	if (siblingIndex == NSNotFound)
		return;
	
	PRE_ADDSUBVIEW(siblingIndex)
	[self.layer insertSublayer:view.layer above:siblingSubview.layer];
	POST_ADDSUBVIEW
}

- (TUIView *)_topSubview
{
	return [self.subviews lastObject];
}

- (TUIView *)_bottomSubview
{
	NSArray *s = self.subviews;
	if([s count] > 0)
		return [self.subviews objectAtIndex:0];
	return nil;
}

- (void)bringSubviewToFront:(TUIView *)view
{
	if([self.subviews containsObject:view]) {
		[view removeFromSuperview];
		TUIView *top = [self _topSubview];
		if(top)
			[self insertSubview:view aboveSubview:top];
		else
			[self addSubview:view];
	}
}

- (void)sendSubviewToBack:(TUIView *)view
{
	if([self.subviews containsObject:view]) {
		[view removeFromSuperview];
		TUIView *bottom = [self _bottomSubview];
		if(bottom)
			[self insertSubview:view belowSubview:bottom];
		else
			[self addSubview:view];
	}
}

- (void)willMoveToWindow:(TUINSWindow *)newWindow {
	for(TUIView *subview in self.subviews) {
		[subview willMoveToWindow:newWindow];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TUIViewWillMoveToWindowNotification object:self userInfo:newWindow != nil ? [NSDictionary dictionaryWithObject:newWindow forKey:TUIViewWindow] : nil];
}

- (void)didMoveToWindow {
	[self _updateLayerScaleFactor];
	
	[self.subviews makeObjectsPerformSelector:_cmd];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TUIViewDidMoveToWindowNotification object:self userInfo:self.nsView.window != nil ? [NSDictionary dictionaryWithObject:self.nsView.window forKey:TUIViewWindow] : nil];
}
- (void)didAddSubview:(TUIView *)subview {}
- (void)willRemoveSubview:(TUIView *)subview {}
- (void)willMoveToSuperview:(TUIView *)newSuperview {}
- (void)didMoveToSuperview {}

#define EACH_SUBVIEW(SUBVIEW_VAR) \
	for(CALayer *_sublayer in self.layer.sublayers) { \
	TUIView *SUBVIEW_VAR = [_sublayer associatedView]; \
	if(!SUBVIEW_VAR) continue;

#define END_EACH_SUBVIEW }

- (BOOL)isDescendantOfView:(TUIView *)view
{
	TUIView *v = self;
	do {
		if(v == view)
			return YES;
	} while((v = [v superview]));
	return NO;
}

- (TUIView *)viewWithTag:(NSInteger)tag
{
	if(self.tag == tag)
		return self;
	EACH_SUBVIEW(subview)
	{
		TUIView *v = [subview viewWithTag:tag];
		if(v)
			return v;
	}
	END_EACH_SUBVIEW
	return nil;
}

- (TUIView *)firstSuperviewOfClass:(Class)c
{
	if([self isKindOfClass:c])
		return self;
	return [self.superview firstSuperviewOfClass:c];
}

- (void)setNeedsLayout
{
	[self.layer setNeedsLayout];
}

- (void)layoutIfNeeded
{
	[self.layer layoutIfNeeded];
}

- (void)layoutSubviews
{
	// subclasses override
}

@end


@implementation TUIView (TUIViewRendering)

- (void)redraw
{
	BOOL s = [TUIView willAnimateContents];
	[TUIView setAnimateContents:YES];
	[self displayLayer:self.layer];
	[TUIView setAnimateContents:s];
}

// drawRect isn't called (by -displayLayer:) unless it's overridden by subclasses (which may then call [super drawRect:])
- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	[self.backgroundColor set];
	CGContextFillRect(ctx, self.bounds);
}

- (TUIViewDrawRect)drawRect
{
	return drawRect;
}

- (void)setDrawRect:(TUIViewDrawRect)d
{
	drawRect = [d copy];
	[self setNeedsDisplay];
}

- (void)setEverythingNeedsDisplay
{
	[self setNeedsDisplay];
	[self.subviews makeObjectsPerformSelector:@selector(setEverythingNeedsDisplay)];
}

- (void)setNeedsDisplay
{
	[self.layer setNeedsDisplay];
}

- (void)setNeedsDisplayInRect:(CGRect)rect
{
	_context.dirtyRect = rect;
	[self.layer setNeedsDisplayInRect:rect];
}

- (BOOL)clipsToBounds
{
	return self.layer.masksToBounds;
}

- (void)setClipsToBounds:(BOOL)b
{
	self.layer.masksToBounds = b;
}

- (CGFloat)alpha
{
	return self.layer.opacity;
}

- (void)setAlpha:(CGFloat)a
{
	self.layer.opacity = a;
}

- (BOOL)isOpaque
{
	return self.layer.opaque;
}

- (void)setOpaque:(BOOL)o
{
	self.layer.opaque = o;
}

- (BOOL)isHidden
{
	return self.layer.hidden;
}

- (void)setHidden:(BOOL)h
{
	self.layer.hidden = h;
}

- (TUIColor *)backgroundColor
{
	return [TUIColor colorWithCGColor:self.layer.backgroundColor];
}

- (void)setBackgroundColor:(TUIColor *)color
{
	self.layer.backgroundColor = color.CGColor;
	if(color.alphaComponent < 1.0)
		self.opaque = NO;
	[self setNeedsDisplay];
}

- (BOOL)clearsContextBeforeDrawing
{
	return _viewFlags.clearsContextBeforeDrawing;
}

- (void)setClearsContextBeforeDrawing:(BOOL)newValue
{
	_viewFlags.clearsContextBeforeDrawing = newValue;
}

@end

#import "TUINSView.h"

@implementation TUIView (TUIViewAppKit)

- (void)setNSView:(TUINSView *)n
{
	if(n != _nsView) {
		[self willMoveToWindow:(TUINSWindow *)[n window]];
		[[NSNotificationCenter defaultCenter] postNotificationName:TUIViewWillMoveToWindowNotification object:self userInfo:[n window] ? [NSDictionary dictionaryWithObject:[n window] forKey:TUIViewWindow] : nil];
		_nsView = n;
		[self.subviews makeObjectsPerformSelector:@selector(setNSView:) withObject:n];
		[self didMoveToWindow];
		[[NSNotificationCenter defaultCenter] postNotificationName:TUIViewDidMoveToWindowNotification object:self userInfo:[n window] ? [NSDictionary dictionaryWithObject:[n window] forKey:TUIViewWindow] : nil];
	}
}

- (TUINSView *)nsView
{
	return _nsView;
}

- (TUINSWindow *)nsWindow
{
	return (TUINSWindow *)[self.nsView window];
}

- (CGRect)globalFrame
{
	TUIView *v = self;
	CGRect f = self.frame;
	while((v = v.superview)) {
		CGRect o = v.frame;
		CGRect o2 = v.bounds;
		f.origin.x += o.origin.x - o2.origin.x;
		f.origin.y += o.origin.y - o2.origin.y;
	}
	return f;
}

- (NSRect)frameInNSView
{
	CGRect f = [self globalFrame];
	NSRect r = (NSRect){f.origin.x, f.origin.y, f.size.width, f.size.height};
	return r;
}

- (NSRect)frameOnScreen
{
	CGRect r = [self globalFrame];
	CGRect w = [self.nsWindow frame];
	return NSMakeRect(w.origin.x + r.origin.x, w.origin.y + r.origin.y, r.size.width, r.size.height);
}

- (CGPoint)localPointForLocationInWindow:(NSPoint)locationInWindow
{
	NSPoint p = [self.nsView convertPoint:locationInWindow fromView:nil];
	CGRect r = [self globalFrame];
	return CGPointMake(p.x - r.origin.x, p.y - r.origin.y);
}

- (CGPoint)localPointForEvent:(NSEvent *)event
{
	return [self localPointForLocationInWindow:[event locationInWindow]];
}

- (BOOL)eventInside:(NSEvent *)event
{
	return [self pointInside:[self localPointForEvent:event] withEvent:event];
}

@end

@implementation TUIView (CoreLayout)

@dynamic constraintIdentifier;

/* My original injection method to "allow" layout constraints. Here for posterity. Remove it when it works?

static void INTERNAL_layoutSubviews(TUIView *self, SEL _cmd) {
    Class superclass = class_getSuperclass([self class]);
    IMP superLayout = class_getMethodImplementation(superclass, _cmd);
    
    [self layoutSubviewsOfView:self];
    superLayout(self, _cmd);
}

- (void)initializeInternal {
    static BOOL configured = NO;
    if(configured) return;
    
    if(![NSStringFromClass(self.class) hasPrefix:@"TUILayoutConstraint_"]) {
        NSString *subclassName = [NSString stringWithFormat:@"TUILayoutConstraint_%@", NSStringFromClass(self.class)];
        Class subclass = NSClassFromString(subclassName);
        
        if(subclass == nil) {
            subclass = objc_allocateClassPair(self.class, [subclassName UTF8String], 0);
            Method layoutSubviews = class_getInstanceMethod(self.class, @selector(layoutSubviews));
            class_addMethod(subclass, @selector(layoutSubviews), (IMP)INTERNAL_layoutSubviews, method_getTypeEncoding(layoutSubviews));
            objc_registerClassPair(subclass);
        }
        
        object_setClass(self, subclass);
        configured = YES;
    }
}

*/

- (void)layoutSubviewsOfView:(TUIView *)view {
    if(self.queuedConstraintUpdate)
        [self updateConstraintsGraph];
    [self solveConstraintsInView:view];
}

- (void)setNeedsUpdateConstraints {
    self.queuedConstraintUpdate = YES;
}

- (NSArray *)constraints {
    return [NSArray arrayWithArray:self.liveConstraints];
}

- (void)addConstraint:(TUILayoutConstraint *)constraint {
    [self.liveConstraints addObject:constraint];
    [self setNeedsUpdateConstraints];
}

- (void)removeConstraint:(TUILayoutConstraint *)constraint {
    [self.liveConstraints removeObject:constraint];
    [self setNeedsUpdateConstraints];
}

- (void)addConstraints:(NSArray *)constraintList {
    for(TUILayoutConstraint *constraint in constraintList)
        [self addConstraint:constraint];
}

- (void)removeConstraints:(NSArray *)constraintList {
    for(TUILayoutConstraint *constraint in constraintList)
        [self removeConstraint:constraint];
}

static int attribute_to_axis(TUILayoutAttribute attribute) {
    return ((attribute == TUILayoutAttributeLeft) ||
            (attribute == TUILayoutAttributeCenterX) || 
            (attribute == TUILayoutAttributeRight) || 
            (attribute == TUILayoutAttributeWidth)) ? 0 : 1;
}

- (void)updateConstraintsGraph {
    CFMutableDictionaryRef viewConstraintsDict = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    
    for (TUILayoutConstraint *constraint in self.constraints) {
        NSArray *viewConstraintsAxis = [(__bridge id)viewConstraintsDict objectForKey:constraint.firstItem];
        if(!viewConstraintsAxis) {
            viewConstraintsAxis = [NSArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], nil];
            CFDictionarySetValue(viewConstraintsDict, (__bridge const void *)(constraint.firstItem), (__bridge const void *)(viewConstraintsAxis));
        }
        
        [[viewConstraintsAxis objectAtIndex:attribute_to_axis(constraint.firstAttribute)] addObject:constraint];
    }
    
    [self.nodes removeAllObjects];
    for (NSArray *axii in [(__bridge id)viewConstraintsDict allValues]) {
        if ([[axii objectAtIndex:0] count])
            [self.nodes addObject:[TUIConstraintNode nodeWithConstraints:[axii objectAtIndex:0]]];
        if ([[axii objectAtIndex:1] count])
            [self.nodes addObject:[TUIConstraintNode nodeWithConstraints:[axii objectAtIndex:1]]];
    }
    
    CFRelease(viewConstraintsDict);
    
    for (TUIConstraintNode *node in self.nodes) {
        for (TUILayoutConstraint * constraint in [node constraints]) {
            for (TUIConstraintNode *otherNode in self.nodes) {
                if(otherNode == node)
                    continue;
                
                for(TUILayoutConstraint *constraint2 in [otherNode constraints]) {
                    if (constraint.secondItem == constraint2.firstItem && 
                        attribute_to_axis(constraint.secondAttribute) == attribute_to_axis(constraint2.firstAttribute)) {
                        [
                         node addOutgoing:otherNode];
                        [otherNode addIncoming:node];
                        break;
                    }
                }
            }
        }
    }
    
    NSMutableArray *queue = [NSMutableArray array];
    for (TUIConstraintNode *n in self.nodes) {
        if ([[n incomingEdges] count] == 0)
            [queue addObject:n];
    }
    
    NSMutableArray *allNodes = [NSArray arrayWithArray:self.nodes];
    [self.nodes removeAllObjects];
    
    while ([queue count]) {
        TUIConstraintNode *node = [queue objectAtIndex:0];
        [queue removeObjectAtIndex:0];
        [self.nodes insertObject:node atIndex:0];
        
        for (TUIConstraintNode *outgoing in [node outgoingEdges]) {
            [node removeOutgoing:outgoing];
            [outgoing removeIncoming:node];
            if([[outgoing incomingEdges] count] == 0)
                [queue addObject:outgoing];
        }
    }
    
    for (TUIConstraintNode *node in allNodes) {
        if ([[node outgoingEdges] count] || [[node incomingEdges] count])
            [[NSException exceptionWithName:@"TUIInvalidConstraint"
                                     reason:@"There is a cycle in the specified constraints"
                                   userInfo:nil] raise];
    }
    
    self.queuedConstraintUpdate = NO;
}

- (void)solveConstraintsInView:(TUIView *)view; {
    for(TUIConstraintNode *node in self.nodes)
        [self solveAxis:[node constraints] inView:view];
}

- (CGFloat)axisAttributeValue:(TUIConstraintAxis)axisVal inFrame:(CGRect)frame isYAxis:(BOOL)isYAxis {
    CGFloat val = 0.0f;
    
    TUILayoutAttribute attribute = axisVal << (isYAxis ? 4 : 0);
    switch (attribute) {
        case TUILayoutAttributeLeft:
            return CGRectGetMinX(frame);
        case TUILayoutAttributeCenterX:
            return CGRectGetMidX(frame);
        case TUILayoutAttributeRight:
            return CGRectGetMaxX(frame);
        case TUILayoutAttributeWidth:
            return CGRectGetWidth(frame);
        case TUILayoutAttributeBottom:
            return CGRectGetMinY(frame);
        case TUILayoutAttributeCenterY:
            return CGRectGetMidY(frame);
        case TUILayoutAttributeTop:
            return CGRectGetMaxY(frame);
        case TUILayoutAttributeHeight:
            return CGRectGetHeight(frame);
    } return val;
}

- (void)solveAxis:(NSArray *)axis inView:(TUIView *)superview {
    uint8_t combined = 0x00;
    
    TUIView *view = [superview subviewWithConstraintIdentifier:[[axis objectAtIndex:0] firstItem]];
    CGRect rect = [view frame];
    
    CGFloat minR = CGFLOAT_MAX;
    CGFloat midR = CGFLOAT_MAX;
    CGFloat maxR = CGFLOAT_MAX;
    CGFloat sizeR = CGFLOAT_MAX;
    
    for(TUILayoutConstraint *constraint in axis) {
        combined |= constraint.firstAttribute;
        
        CGFloat rel = [constraint relativeValueInView:superview];
        switch (constraint.firstAttribute >= 1 << 4 ? constraint.firstAttribute >> 4 : constraint.firstAttribute) {
            case TUIConstraintMin:
                minR = rel;
                break;
            case TUIConstraintMid:
                midR = rel;
                break;
            case TUIConstraintMax:
                maxR = rel;
                break;
            case TUIConstraintSize:
                sizeR = rel;
                break;
        }
    }
    
    BOOL isYAxis = combined >= 1 << 4;
    if(isYAxis) combined >>= 4;
    CGFloat min = [self axisAttributeValue:TUIConstraintMin inFrame:rect isYAxis:isYAxis];
    CGFloat mid = [self axisAttributeValue:TUIConstraintMid inFrame:rect isYAxis:isYAxis];
    CGFloat max = [self axisAttributeValue:TUIConstraintMax inFrame:rect isYAxis:isYAxis];
    CGFloat size = [self axisAttributeValue:TUIConstraintSize inFrame:rect isYAxis:isYAxis];
    
    switch (combined) {
        case TUIConstraintMin: {
            CGFloat minDiff = minR - min;
            min += minDiff;
        }
            break;
        case TUIConstraintMid: {
            CGFloat midDiff = midR - mid;
            min += midDiff;
        }
            break;
        case TUIConstraintMax: {
            CGFloat maxDiff = maxR - max;
            min += maxDiff;
        }
            break;
        case TUIConstraintSize:
            size = sizeR;
            break;
        case TUIConstraintMin | TUIConstraintMid:
            min = minR;
            mid = midR;
            max = mid + (mid - min);
            size = max - min;
            break;
        case TUIConstraintMin | TUIConstraintMax:
            min = minR;
            size = maxR - minR;
            break;
        case TUIConstraintMin | TUIConstraintSize:
            min = minR;
            size = sizeR;
            break;
        case TUIConstraintMid | TUIConstraintMax:
            mid = midR;
            max = maxR;
            min = mid - (max - mid);
            size = max - min;
            break;
        case TUIConstraintMid | TUIConstraintSize:
            mid = midR;
            size = sizeR;
            CGFloat hSize = size / 2.0;
            min = mid - hSize;
            break;
        case TUIConstraintMax | TUIConstraintSize:
            max = maxR;
            size = sizeR;
            min = max - size;
            break;
        default:
            NSAssert(NO, @"Invalid axis, constraint building failed");
            break;
    }
    
    if (isYAxis) {
        rect.origin.y = min;
        rect.size.height = size;
    } else {
        rect.origin.x = min;
        rect.size.width = size;
    }
    
    [view setFrame:rect];
}

- (TUIView *)subviewWithConstraintIdentifier:(NSString *)identifier {
    for (TUIView *subview in [self subviews])
        if([[subview constraintIdentifier] isEqualToString:identifier])
            return subview;
    return nil;
}

@end
