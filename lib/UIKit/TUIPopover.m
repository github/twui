/*
 Copyright 2012 Twitter, Inc.
 
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

#import "TUIPopover.h"
#import "CAAnimation+TUIExtensions.h"
#import "NSColor+TUIExtensions.h"
#import "NSBezierPath+TUIExtensions.h"
#import "TUICGAdditions.h"
#import "TUINSView.h"
#import "TUINSWindow.h"
#import "TUIViewController.h"

CGFloat const TUIPopoverBackgroundViewBorderRadius = 5.0;
CGFloat const TUIPopoverBackgroundViewArrowInset = 2.0;
CGFloat const TUIPopoverBackgroundViewArrowHeight = 17.0;
CGFloat const TUIPopoverBackgroundViewArrowWidth = 35.0;

NSTimeInterval const TUIPopoverDefaultAnimationDuration = 0.3;

@interface TUIPopoverBackgroundView ()

@property (nonatomic, assign) CGRect screenOriginRect;
@property (nonatomic, assign) CGRectEdge popoverEdge;

- (void)updateMaskLayer;

@end

@interface TUIPopoverWindowContentView : NSView

@property (nonatomic, readonly) TUINSView *nsView;
@property (nonatomic, assign) CGRectEdge arrowEdge;

@end

@interface TUIPopoverWindow : NSWindow

@property (nonatomic, strong) TUIView *rootView;
@property (nonatomic, readonly) TUIPopoverWindowContentView *frameView;

- (id)initWithContentRect:(CGRect)contentRect;

@end

@interface TUIPopover ()

@property (nonatomic, strong) TUIPopoverWindow *popoverWindow;
@property (nonatomic, unsafe_unretained) id transientEventMonitor;
@property (nonatomic, assign) BOOL animating;
@property (nonatomic, assign) CGSize originalViewSize;

- (void)addEventMonitor;
- (void)removeEventMonitor;

@end

@implementation TUIPopover

- (id)init {
    if((self = [super init])) {
        self.animates = YES;
        self.behaviour = TUIPopoverViewControllerBehaviourApplicationDefined;
        self.contentViewController = nil;
        self.backgroundViewClass = TUIPopoverBackgroundView.class;
		
        _shown = NO;
    }
	return self;
}

- (id)initWithContentViewController:(TUIViewController *)viewController {
	if((self = [self init])) {
        self.contentViewController = viewController;
    }
	return self;
}

- (void)showRelativeToRect:(CGRect)newPositioningRect ofView:(TUIView *)positioningView preferredEdge:(CGRectEdge)preferredEdge {
    if(_shown)
		return;
    
    [self.contentViewController viewWillAppear:YES];
    if(self.willShowBlock != nil)
        self.willShowBlock(self);
    
    if(self.behaviour != TUIPopoverViewControllerBehaviourApplicationDefined) {
		if(self.transientEventMonitor)
            [self removeEventMonitor];
        [self addEventMonitor];
    }
	
	CGSize contentViewSize = (CGSizeEqualToSize(self.contentSize, CGSizeZero) ?
                              self.contentViewController.view.frame.size : self.contentSize);
    _positioningRect = CGRectEqualToRect(newPositioningRect, CGRectZero) ? positioningView.bounds : newPositioningRect;
    self.originalViewSize = self.contentViewController.view.frame.size;
	
    CGRect basePositioningRect = [positioningView convertRect:_positioningRect toView:nil];
    NSRect windowRelativeRect = [positioningView.nsView convertRect:basePositioningRect toView:nil];
    CGRect screenPositioningRect = windowRelativeRect;
	screenPositioningRect.origin = [positioningView.nsWindow convertBaseToScreen:windowRelativeRect.origin];
    
    CGRect (^popoverRectForEdge)(CGRectEdge) = ^(CGRectEdge popoverEdge) {
        CGFloat xPos = screenPositioningRect.origin.x;
        CGFloat yPos = screenPositioningRect.origin.y;
        
        switch (popoverEdge) {
            case CGRectMinYEdge:
                xPos += _positioningRect.origin.x + (_positioningRect.size.width * 0.5) - (contentViewSize.width * 0.5);
                yPos += _positioningRect.origin.y + (_positioningRect.size.height * 0.5) - contentViewSize.height - TUIPopoverBackgroundViewArrowHeight;
                break;
            case CGRectMaxYEdge:
                xPos += _positioningRect.origin.x + (_positioningRect.size.width * 0.5) - (contentViewSize.width * 0.5);
                yPos += _positioningRect.origin.y + _positioningRect.size.height;
                break;
            case CGRectMinXEdge:
                yPos += _positioningRect.origin.y + (_positioningRect.size.height * 0.5) - (contentViewSize.height * 0.5);
                xPos += _positioningRect.origin.x - contentViewSize.width;
                break;
            case CGRectMaxXEdge:
                yPos += _positioningRect.origin.y + (_positioningRect.size.height * 0.5) - (contentViewSize.height * 0.5);
                xPos += _positioningRect.origin.x + _positioningRect.size.width;
                break;
        }
        
        return NSMakeRect(xPos, yPos, contentViewSize.width, contentViewSize.height);
    };

    BOOL (^checkPopoverSizeForScreenWithPopoverEdge)(CGRectEdge) = ^(CGRectEdge popoverEdge) {
        CGRect popoverRect = popoverRectForEdge(popoverEdge);
        return NSContainsRect(positioningView.nsWindow.screen.visibleFrame, popoverRect);
    };
    
    __block CGRectEdge popoverEdge = preferredEdge;
    CGRect (^popoverRect)() = ^{
        CGRectEdge (^nextEdgeForEdge)(CGRectEdge) = ^(CGRectEdge currentEdge) {
            if(currentEdge == CGRectMaxXEdge) {
                return (CGRectEdge)(preferredEdge == CGRectMinXEdge ? CGRectMaxYEdge : CGRectMinXEdge);
            } else if(currentEdge == CGRectMinXEdge) {
                return (CGRectEdge)(preferredEdge == CGRectMaxXEdge ? CGRectMaxYEdge : CGRectMaxXEdge);
            } else if(currentEdge == CGRectMaxYEdge) {
                return (CGRectEdge)(preferredEdge == CGRectMinYEdge ? CGRectMaxXEdge : CGRectMinYEdge);
            } else if(currentEdge == CGRectMinYEdge) {
                return (CGRectEdge)(preferredEdge == CGRectMaxYEdge ? CGRectMaxXEdge : CGRectMaxYEdge);
            } return currentEdge;
        };
		
		CGRect (^fitRectToScreen)(CGRect) = ^(CGRect proposedRect) {
			CGRect screenRect = positioningView.nsWindow.screen.visibleFrame;
			if(proposedRect.origin.y < CGRectGetMinY(screenRect))
				proposedRect.origin.y = CGRectGetMinY(screenRect);
			if(proposedRect.origin.x < CGRectGetMinX(screenRect))
				proposedRect.origin.x = CGRectGetMinX(screenRect);
			if(CGRectGetMaxY(proposedRect) > CGRectGetMaxY(screenRect))
				proposedRect.origin.y = (CGRectGetMaxY(screenRect) - CGRectGetHeight(proposedRect));
			if(CGRectGetMaxX(proposedRect) > CGRectGetMaxX(screenRect))
				proposedRect.origin.x = (CGRectGetMaxX(screenRect) - CGRectGetWidth(proposedRect));
			return proposedRect;
		};
        
        NSUInteger attemptCount = 0;
        while(!checkPopoverSizeForScreenWithPopoverEdge(popoverEdge)) {
            if(attemptCount > 4) {
				popoverEdge = preferredEdge;
				return fitRectToScreen(popoverRectForEdge(popoverEdge));
				break;
			}
            
            popoverEdge = nextEdgeForEdge(popoverEdge);
            attemptCount++;
        } return (CGRect)popoverRectForEdge(popoverEdge);
    };
	
    CGRect popoverScreenRect = popoverRect();
    TUIPopoverBackgroundView *backgroundView = [self.backgroundViewClass backgroundViewForContentSize:contentViewSize
																						  popoverEdge:popoverEdge
																					 originScreenRect:screenPositioningRect];
    CGRect contentViewFrame = [self.backgroundViewClass contentViewFrameForBackgroundFrame:backgroundView.bounds
																			   popoverEdge:popoverEdge];
    _contentViewController.view.frame = contentViewFrame;
	
    _popoverWindow = [[TUIPopoverWindow alloc] initWithContentRect:popoverScreenRect];
    TUIPopoverWindowContentView *contentView = [[TUIPopoverWindowContentView alloc] initWithFrame:backgroundView.bounds];
	contentView.arrowEdge = popoverEdge;
    contentView.nsView.rootView = backgroundView;
    self.popoverWindow.contentView = contentView;
    [backgroundView addSubview:self.contentViewController.view];
    [positioningView.nsWindow addChildWindow:_popoverWindow ordered:NSWindowAbove];
	[backgroundView updateMaskLayer];
	
    CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fade.duration = TUIPopoverDefaultAnimationDuration;
	fade.fromValue = @0.0f;
	fade.toValue = @1.0f;
	
	CAKeyframeAnimation *bounce = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
	bounce.duration = TUIPopoverDefaultAnimationDuration;
	bounce.values = @[@0.05, @1.11245, @0.951807, @1.0];
	bounce.keyTimes = @[@0, @(4.0/9.0), @(4.0/9.0+5.0/18.0), @1.0];
	bounce.timingFunctions = @[easeInOut, easeInOut, easeInOut, easeInOut];
	
	CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
	group.animations = @[fade, bounce];
	group.duration = TUIPopoverDefaultAnimationDuration;
	group.tui_completionBlock = ^{
		self.animating = NO;
		_shown = YES;
		NSLog(@"showing");
		[self.contentViewController viewDidAppear:YES];
		if(self.didShowBlock)
			self.didShowBlock(self);
	};
	
	self.animating = YES;
	[_popoverWindow.frameView.layer addAnimation:group forKey:nil];
    [_popoverWindow makeKeyAndOrderFront:nil];
}

- (void)closeWithFadeoutDuration:(NSTimeInterval)duration {
    if(self.animating || !_shown)
		return;
    
    if(self.transientEventMonitor)
		[self removeEventMonitor];
    if(self.willCloseBlock != nil)
        self.willCloseBlock(self);
    
    CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"alphaValue"];
    fadeOutAnimation.duration = duration;
    fadeOutAnimation.tui_completionBlock = ^{
        [self.popoverWindow.parentWindow removeChildWindow:self.popoverWindow];
        [self.popoverWindow close];
        
        self.popoverWindow.contentView = nil;
        self.animating = NO;
        _shown = NO;
        
        if(self.didCloseBlock != nil)
            self.didCloseBlock(self);
        
        self.contentViewController.view.frame = CGRectMake(self.contentViewController.view.frame.origin.x,
                                                           self.contentViewController.view.frame.origin.y,
                                                           self.originalViewSize.width,
                                                           self.originalViewSize.height);
    };
    
    self.popoverWindow.animations = [NSDictionary dictionaryWithObject:fadeOutAnimation forKey:@"alphaValue"];
    self.animating = YES;
    [self.popoverWindow.animator setAlphaValue:0.0];
}

- (void)close {
    [self closeWithFadeoutDuration:TUIPopoverDefaultAnimationDuration];
}

- (IBAction)performClose:(id)sender {
    [self close];
}

- (void)addEventMonitor {
    self.transientEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyUpMask) handler: ^(NSEvent *event)
	{
		if(self.popoverWindow == nil)
			return event;
		
		static NSUInteger escapeKey = 53;
		BOOL shouldClose = (event.type == NSLeftMouseDown || event.type == NSRightMouseDown ? (!NSPointInRect([NSEvent mouseLocation], self.popoverWindow.frame) && self.behaviour == TUIPopoverViewControllerBehaviourTransient) : event.keyCode == escapeKey);
		
		if(shouldClose) [self close];
		return event;
	}];
}

- (void)removeEventMonitor {
	[NSEvent removeMonitor:self.transientEventMonitor];
	self.transientEventMonitor = nil;
}

- (void)setBehavior:(TUIPopoverViewControllerBehaviour)behaviour {
    _behaviour = behaviour;
    if(_shown) {
        if(_behaviour == TUIPopoverViewControllerBehaviourApplicationDefined && self.transientEventMonitor)
            [self removeEventMonitor];
        else if(!self.transientEventMonitor)
            [self addEventMonitor];
    }
}

@end

@implementation TUIPopoverBackgroundView

+ (CGSize)sizeForBackgroundViewWithContentSize:(CGSize)contentSize popoverEdge:(CGRectEdge)popoverEdge {
    CGSize returnSize = contentSize;
    if (popoverEdge == CGRectMaxXEdge || popoverEdge == CGRectMinXEdge) {
        returnSize.width += TUIPopoverBackgroundViewArrowHeight;
    } else {
        returnSize.height += TUIPopoverBackgroundViewArrowHeight;
    }
    
    returnSize.width++;
    returnSize.height++;
    
    return returnSize;
}

+ (CGRect)contentViewFrameForBackgroundFrame:(CGRect)backgroundFrame popoverEdge:(CGRectEdge)popoverEdge {
    CGRect returnFrame = NSInsetRect(backgroundFrame, 1.0, 1.0);
    switch (popoverEdge) {
        case CGRectMinXEdge:
            returnFrame.size.width -= TUIPopoverBackgroundViewArrowHeight;
            break;
        case CGRectMinYEdge:
            returnFrame.size.height -= TUIPopoverBackgroundViewArrowHeight;
            break;
        case CGRectMaxXEdge:
            returnFrame.size.width -= TUIPopoverBackgroundViewArrowHeight;
            returnFrame.origin.x += TUIPopoverBackgroundViewArrowHeight;
            break;
        case CGRectMaxYEdge:
            returnFrame.size.height -= TUIPopoverBackgroundViewArrowHeight;
            returnFrame.origin.y += TUIPopoverBackgroundViewArrowHeight;
            break;
        default:
            break;
    }
    
    return returnFrame;
}

+ (TUIPopoverBackgroundView *)backgroundViewForContentSize:(CGSize)contentSize
											   popoverEdge:(CGRectEdge)popoverEdge
										  originScreenRect:(CGRect)originScreenRect {
	
    CGSize size = [self sizeForBackgroundViewWithContentSize:contentSize popoverEdge:popoverEdge];
    TUIPopoverBackgroundView *returnView = [[self.class alloc] initWithFrame:NSMakeRect(0.0, 0.0, size.width, size.height)
																 popoverEdge:popoverEdge
															originScreenRect:originScreenRect];
	
    return returnView;
}

- (CGPathRef)newPopoverPathForEdge:(CGRectEdge)popoverEdge inFrame:(CGRect)rect {
	NSBezierPath *path = [NSBezierPath bezierPath];
    
    CGFloat radius = TUIPopoverBackgroundViewBorderRadius;
    CGFloat inset = radius + TUIPopoverBackgroundViewArrowHeight;
	CGFloat insetArrowHeight = TUIPopoverBackgroundViewArrowHeight - TUIPopoverBackgroundViewArrowInset;
    CGRect drawingRect = NSInsetRect(rect, inset, inset);
    
    CGFloat minX = CGRectGetMinX(drawingRect);
    CGFloat maxX = CGRectGetMaxX(drawingRect);
    CGFloat minY = CGRectGetMinY(drawingRect);
    CGFloat maxY = CGRectGetMaxY(drawingRect);
    
    // Bottom left corner.
    [path appendBezierPathWithArcWithCenter:NSMakePoint(minX, minY) radius:radius startAngle:180.0 endAngle:270.0];
    if(self.popoverEdge == CGRectMaxYEdge) {
        CGFloat midX = NSMidX(drawingRect);
        NSPoint points[3];
        points[0] = NSMakePoint(floor(midX - (TUIPopoverBackgroundViewArrowWidth / 2.0)), minY - radius);
        points[1] = NSMakePoint(floor(midX), points[0].y - insetArrowHeight + 1);
        points[2] = NSMakePoint(floor(midX + (TUIPopoverBackgroundViewArrowWidth / 2.0)), points[0].y);
        [path appendBezierPathWithPoints:points count:3];
    }
    
    // Bottom right corner.
    [path appendBezierPathWithArcWithCenter:NSMakePoint(maxX, minY) radius:radius startAngle:270.0 endAngle:360.0];
    if(self.popoverEdge == CGRectMinXEdge) {
        CGFloat midY = NSMidY(drawingRect);
        NSPoint points[3];
        points[0] = NSMakePoint(maxX + radius, floor(midY - (TUIPopoverBackgroundViewArrowWidth / 2.0)));
        points[1] = NSMakePoint(points[0].x + insetArrowHeight, floor(midY));
        points[2] = NSMakePoint(points[0].x, floor(midY + (TUIPopoverBackgroundViewArrowWidth / 2.0)));
        [path appendBezierPathWithPoints:points count:3];
    }
    
    // Top right corner.
    [path appendBezierPathWithArcWithCenter:NSMakePoint(maxX, maxY) radius:radius startAngle:0.0 endAngle:90.0];
    if(self.popoverEdge == CGRectMinYEdge) {
        CGFloat midX = NSMidX(drawingRect);
        NSPoint points[3];
        points[0] = NSMakePoint(floor(midX + (TUIPopoverBackgroundViewArrowWidth / 2.0)), maxY + radius);
        points[1] = NSMakePoint(floor(midX), points[0].y + insetArrowHeight - 1);
        points[2] = NSMakePoint(floor(midX - (TUIPopoverBackgroundViewArrowWidth / 2.0)), points[0].y);
        [path appendBezierPathWithPoints:points count:3];
    }
    
    // Top left corner.
    [path appendBezierPathWithArcWithCenter:NSMakePoint(minX, maxY) radius:radius startAngle:90.0 endAngle:180.0];
    if(self.popoverEdge == CGRectMaxXEdge) {
        CGFloat midY = NSMidY(drawingRect);
        NSPoint points[3];
        points[0] = NSMakePoint(minX - radius, floor(midY + (TUIPopoverBackgroundViewArrowWidth / 2.0)));
        points[1] = NSMakePoint(points[0].x - insetArrowHeight, floor(midY));
        points[2] = NSMakePoint(points[0].x, floor(midY - (TUIPopoverBackgroundViewArrowWidth / 2.0)));
        [path appendBezierPathWithPoints:points count:3];
    }
    
    [path closePath];
    return [path CGPath];
}

- (id)initWithFrame:(CGRect)frame popoverEdge:(CGRectEdge)popoverEdge originScreenRect:(CGRect)originScreenRect {	
	if((self = [super initWithFrame:frame])) {
		_popoverEdge = popoverEdge;
		_screenOriginRect = originScreenRect;
		
		__block __unsafe_unretained TUIPopoverBackgroundView *weakSelf = self;
		self.drawRect = ^(TUIView *view, CGRect rect) {
			TUIPopoverBackgroundView *strongSelf = weakSelf;
			CGPathRef cgPath = [strongSelf newPopoverPathForEdge:popoverEdge inFrame:CGRectInset(view.bounds, 0.5, 0.5)];
			NSBezierPath *path = [NSBezierPath bezierPathWithCGPath:cgPath];
			CGPathRelease(cgPath);
			
			NSGradient *gradient = [[NSGradient alloc] initWithColors:@[[NSColor colorWithCalibratedWhite:1.00 alpha:0.90],
									[NSColor colorWithCalibratedWhite:0.95 alpha:0.90]]];
			[gradient drawInBezierPath:path angle:-90];
			[[NSColor whiteColor] set];
			[path strokeInside];
			
			[[NSColor colorWithCalibratedWhite:0.0 alpha:0.3] set];
			[path stroke];
		};
	}
	return self;
}

- (void)updateMaskLayer {
	CAShapeLayer *maskLayer = [CAShapeLayer layer];
    CGPathRef path = [self newPopoverPathForEdge:self.popoverEdge inFrame:self.bounds];
    maskLayer.path = path;
    maskLayer.fillColor = CGColorGetConstantColor(kCGColorBlack);
    CGPathRelease(path);
	
    self.layer.mask = maskLayer;
}

@end

@implementation TUIPopoverWindowContentView

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
        self.arrowEdge = CGRectNoEdge;
		
        _nsView = [[TUINSView alloc] initWithFrame:self.bounds];
        [_nsView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [_nsView tui_setOpaque:NO];
        [self addSubview:_nsView];
    }
	return self;
}

- (BOOL)isOpaque {
	return NO;
}

- (void)viewDidMoveToWindow {
    [self setWantsLayer:YES];
	
	// Set a layer shadow because we lose the window shadow.
	self.layer.shadowColor = [NSColor shadowColor].CGColor;
	self.layer.shadowOpacity = 0.4f;
	self.layer.shadowOffset = CGSizeMake(0.0f, -4.0f);
	self.layer.shadowRadius = 5.0f;
	
	self.layer.borderColor = [NSColor blueColor].CGColor;
	self.layer.borderWidth = 1.0f;
}

- (void)setArrowEdge:(CGRectEdge)arrowEdge {
    _arrowEdge = arrowEdge;
	
	// Set the layer anchor point, so animations act accordingly.
	switch(arrowEdge) {
		case CGRectMinXEdge:
			self.layer.anchorPoint = CGPointMake(1.0, 0.5);
			break;
		case CGRectMaxXEdge:
			self.layer.anchorPoint = CGPointMake(0.0, 0.5);
			break;
		case CGRectMinYEdge:
			self.layer.anchorPoint = CGPointMake(0.5, 1.0);
			break;
		case CGRectMaxYEdge:
			self.layer.anchorPoint = CGPointMake(0.5, 0.0);
			break;
		default:
			break;
	}
	
	// Anchor Point correction.
	CALayer *layer = self.layer;
	CGPoint correctPosition = CGPointMake(layer.position.x + layer.bounds.size.width * (layer.anchorPoint.x - 0.5),
										  layer.position.y + layer.bounds.size.height * (layer.anchorPoint.y - 0.5));
	[layer setPosition:correctPosition];
}

@end

@implementation TUIPopoverWindow {
    TUIView *_popoverRootView;
    NSView *_popoverContentView;
}

- (id)initWithContentRect:(CGRect)contentRect {
    if((self = [super initWithContentRect:contentRect
                                styleMask:NSBorderlessWindowMask
                                  backing:NSBackingStoreBuffered
                                    defer:YES])) {
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
		[self setReleasedWhenClosed:NO];
    } return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}

- (TUIView *)rootView {
    return _popoverRootView;
}

- (NSView *)contentView {
    return _popoverContentView;
}

- (TUIPopoverWindowContentView *)frameView {
    return (TUIPopoverWindowContentView *)[super contentView];
}

@end
