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

NSString *const TUIPopoverCloseReasonKey = @"_kTUIPopoverCloseReasonKey";
NSString *const TUIPopoverCloseReasonStandard = @"_kTUIPopoverCloseReasonStandard";
NSString *const TUIPopoverCloseReasonDetachToWindow = @"_kTUIPopoverCloseReasonDetachToWindow";
NSString *const TUIPopoverWillShowNotification = @"_kTUIPopoverWillShowNotification";
NSString *const TUIPopoverDidShowNotification = @"_kTUIPopoverDidShowNotification";
NSString *const TUIPopoverWillCloseNotification = @"_kTUIPopoverWillCloseNotification";
NSString *const TUIPopoverDidCloseNotification = @"_kTUIPopoverDidCloseNotification";

CGFloat const TUIPopoverBackgroundViewBorderRadius = 4.5;
CGFloat const TUIPopoverBackgroundViewArrowInset = 2.0;
CGFloat const TUIPopoverBackgroundViewArrowHeight = 12.0;
CGFloat const TUIPopoverBackgroundViewArrowWidth = 24.0;

NSTimeInterval const TUIPopoverDefaultAnimationDuration = (1.0f / 3.0f);
#define TUIPopoverCurrentAnimationDuration \
((self.animationDuration > 0.0) ? self.animationDuration : TUIPopoverDefaultAnimationDuration)

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

- (id)initWithContentRect:(CGRect)contentRect;

@end

@interface TUIPopover ()

@property (nonatomic, strong) TUIPopoverWindow *popoverWindow;
@property (nonatomic, unsafe_unretained) TUIView *currentPositioningView;
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
        _shown = NO;
		
        self.behavior = TUIPopoverBehaviorApplicationDefined;
		self.animates = YES;
		self.animationDuration = -1.0f;
		
        self.contentViewController = nil;
        self.backgroundViewClass = TUIPopoverBackgroundView.class;
		
		CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeIn.fromValue = @0.0f;
		fadeIn.toValue = @1.0f;
		
		CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeOut.fromValue = @1.0f;
		fadeOut.toValue = @0.0f;
		
		CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		CAKeyframeAnimation *bounce = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
		bounce.values = @[@0.05, @1.11245, @1.0];
		bounce.keyTimes = @[@0, @(4.0/9.0+5.0/18.0), @1.0];
		bounce.timingFunctions = @[easeInOut, easeInOut, easeInOut];
		
		self.showAnimations = @[fadeIn, bounce];
		self.hideAnimations = @[fadeOut];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(parentWindowClosed:)
													 name:NSWindowWillCloseNotification
												   object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(parentWindowClosed:)
													 name:TUIViewWillMoveToWindowNotification
												   object:self];
    }
	return self;
}

- (id)initWithContentViewController:(TUIViewController *)viewController {
	if((self = [self init])) {
        self.contentViewController = viewController;
    }
	return self;
}

- (void)setDelegate:(id<TUIPopoverDelegate>)delegate {
	_delegate = delegate;
	
	if([delegate respondsToSelector:@selector(popoverWillShow:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:self.delegate
												 selector:@selector(popoverWillShow:)
													 name:TUIPopoverWillShowNotification
												   object:self];
	}
	
	if([delegate respondsToSelector:@selector(popoverDidShow:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:self.delegate
												 selector:@selector(popoverDidShow:)
													 name:TUIPopoverDidShowNotification
												   object:self];
	}
	
	if([delegate respondsToSelector:@selector(popoverWillClose:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:self.delegate
												 selector:@selector(popoverWillClose:)
													 name:TUIPopoverWillCloseNotification
												   object:self];
	}
	
	if([delegate respondsToSelector:@selector(popoverDidClose:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:self.delegate
												 selector:@selector(popoverDidClose:)
													 name:TUIPopoverDidCloseNotification
												   object:self];
	}
}

- (void)setContentViewController:(TUIViewController *)controller {
	if(self.shown) {
		TUIPopoverBackgroundView *backgroundView = (TUIPopoverBackgroundView *)[self.popoverWindow.contentView nsView].rootView;
		CGSize contentViewSize = (CGSizeEqualToSize(self.contentSize, CGSizeZero) ?
								  controller.view.frame.size : self.contentSize);
		
		CGSize backgroundSize = [self.backgroundViewClass sizeForBackgroundViewWithContentSize:contentViewSize
																				   popoverEdge:backgroundView.popoverEdge];
		CGRect backgroundRect = backgroundView.frame;
		backgroundRect.size = backgroundSize;
		
		void (^updateBlock)(void) = ^{
			backgroundView.frame = backgroundRect;
			CGRect contentViewFrame = [self.backgroundViewClass contentViewFrameForBackgroundFrame:backgroundRect
																					   popoverEdge:backgroundView.popoverEdge];
			controller.view.frame = contentViewFrame;
			if(self.animates)
				[[self.popoverWindow.contentView animator] setFrame:backgroundView.bounds];
			else
				[self.popoverWindow.contentView setFrame:backgroundView.bounds];
			
			[_contentViewController.view removeFromSuperview];
			[backgroundView addSubview:controller.view];
		};
		
		if(self.animates) {
			[TUIView animateWithDuration:TUIPopoverCurrentAnimationDuration animations:^{
				updateBlock();
			}];
		} else updateBlock();
	}
	
	_contentViewController = controller;
}

- (void)setContentSize:(CGSize)size {
	if(self.shown) {
		TUIPopoverBackgroundView *backgroundView = (TUIPopoverBackgroundView *)[self.popoverWindow.contentView nsView].rootView;
		CGSize contentViewSize = (CGSizeEqualToSize(size, CGSizeZero) ? self.contentViewController.view.frame.size : size);
		
		CGSize backgroundSize = [self.backgroundViewClass sizeForBackgroundViewWithContentSize:contentViewSize
																				   popoverEdge:backgroundView.popoverEdge];
		CGRect backgroundRect = backgroundView.frame;
		backgroundRect.size = backgroundSize;
		
		
		void (^updateBlock)(void) = ^{
			backgroundView.frame = backgroundRect;
			CGRect contentViewFrame = [self.backgroundViewClass contentViewFrameForBackgroundFrame:backgroundRect
																					   popoverEdge:backgroundView.popoverEdge];
			self.contentViewController.view.frame = contentViewFrame;
			if(self.animates)
				[[self.popoverWindow.contentView animator] setFrame:backgroundView.bounds];
			else
				[self.popoverWindow.contentView setFrame:backgroundView.bounds];
		};
		
		if(self.animates) {
			[TUIView animateWithDuration:TUIPopoverCurrentAnimationDuration animations:^{
				updateBlock();
			}];
		} else updateBlock();
	}
	
	_contentSize = size;
}

- (void)showRelativeToRect:(CGRect)newPositioningRect ofView:(TUIView *)positioningView preferredEdge:(CGRectEdge)preferredEdge {
    if(self.shown)
		return;
	
	if(!positioningView) {
		[NSException raise:NSInvalidArgumentException format:@"TUIPopover positioningView cannot be nil!"];
		return;
	}
	
	if(!self.contentViewController || !self.contentViewController.view) {
		[NSException raise:NSInternalInconsistencyException format:@"TUIPopover contentViewController view cannot be nil!"];
		return;
	}
    
    [self.contentViewController viewWillAppear:YES];
    if(self.willShowBlock != nil)
        self.willShowBlock(self);
	[[NSNotificationCenter defaultCenter] postNotificationName:TUIPopoverWillShowNotification
														object:self
													  userInfo:nil];
    
    if(self.behavior != TUIPopoverBehaviorApplicationDefined) {
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
    __block CGRectEdge popoverEdge = preferredEdge;
	
    CGRect (^popoverRect)() = ^{
		CGRect (^popoverRectForEdge)(CGRectEdge) = ^(CGRectEdge popoverEdge) {
			CGSize popoverSize = [self.backgroundViewClass sizeForBackgroundViewWithContentSize:contentViewSize
																					popoverEdge:popoverEdge];
			CGRect returnRect = NSMakeRect(0.0, 0.0, popoverSize.width, popoverSize.height);
			
			if (popoverEdge == CGRectMinYEdge) {
				CGFloat xOrigin = CGRectGetMidX(screenPositioningRect) - floor(popoverSize.width / 2.0);
				CGFloat yOrigin = CGRectGetMinY(screenPositioningRect) - popoverSize.height;
				returnRect.origin = CGPointMake(xOrigin, yOrigin);
			} else if (popoverEdge == CGRectMaxYEdge) {
				CGFloat xOrigin = CGRectGetMidX(screenPositioningRect) - floor(popoverSize.width / 2.0);
				returnRect.origin = CGPointMake(xOrigin, CGRectGetMaxY(screenPositioningRect));
			} else if (popoverEdge == CGRectMinXEdge) {
				CGFloat xOrigin = CGRectGetMinX(screenPositioningRect) - popoverSize.width;
				CGFloat yOrigin = CGRectGetMidY(screenPositioningRect) - floor(popoverSize.height / 2.0);
				returnRect.origin = CGPointMake(xOrigin, yOrigin);
			} else if (popoverEdge == CGRectMaxXEdge) {
				CGFloat yOrigin = CGRectGetMidY(screenPositioningRect) - floor(popoverSize.height / 2.0);
				returnRect.origin = CGPointMake(CGRectGetMaxX(screenPositioningRect), yOrigin);
			} else {
				returnRect = CGRectZero;
			}
			
			return returnRect;
		};
		
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
		
		BOOL (^checkPopoverSizeForScreenWithPopoverEdge)(CGRectEdge) = ^(CGRectEdge popoverEdge) {
			CGRect popoverRect = popoverRectForEdge(popoverEdge);
			return NSContainsRect(positioningView.nsWindow.screen.visibleFrame, popoverRect);
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
    [backgroundView addSubview:self.contentViewController.view];
	
    _popoverWindow = [[TUIPopoverWindow alloc] initWithContentRect:popoverScreenRect];
    TUIPopoverWindowContentView *contentView = [[TUIPopoverWindowContentView alloc] initWithFrame:backgroundView.bounds];
    self.popoverWindow.contentView = contentView;
    contentView.nsView.rootView = backgroundView;
	
	contentView.arrowEdge = popoverEdge;
	[backgroundView updateMaskLayer];
	
	void (^completionBlock)(void) = ^{
		self.currentPositioningView = positioningView;
		self.animating = NO;
		_shown = YES;
		
		[self.contentViewController viewDidAppear:YES];
		[[NSNotificationCenter defaultCenter] postNotificationName:TUIPopoverDidShowNotification
															object:self
														  userInfo:nil];
		if(self.didShowBlock)
			self.didShowBlock(self);
	};
	
	if(self.animates) {
		for(CAAnimation *animation in self.showAnimations) {
			animation.fillMode = kCAFillModeForwards;
			animation.removedOnCompletion = YES;
			animation.duration = TUIPopoverCurrentAnimationDuration;
		}
		
		CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
		group.animations = self.showAnimations;
		group.fillMode = kCAFillModeForwards;
		group.removedOnCompletion = YES;
		group.duration = TUIPopoverCurrentAnimationDuration;
		group.tui_completionBlock = completionBlock;
		
		self.animating = YES;
		CALayer *viewLayer = ((NSView *)_popoverWindow.contentView).layer;
		[viewLayer addAnimation:group forKey:nil];
	}
	
	[positioningView.nsWindow addChildWindow:_popoverWindow ordered:NSWindowAbove];
	[_popoverWindow makeKeyAndOrderFront:nil];
	
	if(!self.animates)
		completionBlock();
}

- (void)close {
    if(self.animating || !self.shown)
		return;
    
    if(self.transientEventMonitor)
		[self removeEventMonitor];
	
	[self.contentViewController viewWillDisappear:YES];
    if(self.willCloseBlock != nil)
        self.willCloseBlock(self);
	[[NSNotificationCenter defaultCenter] postNotificationName:TUIPopoverWillCloseNotification
														object:self
													  userInfo:@{TUIPopoverCloseReasonKey : TUIPopoverCloseReasonStandard}];
	
	void (^completionBlock)(void) = ^{
        [self.popoverWindow close];
		self.currentPositioningView = nil;
        self.popoverWindow.contentView = nil;
        [self.popoverWindow.parentWindow removeChildWindow:self.popoverWindow];
        
        self.animating = NO;
        _shown = NO;
        
		[self.contentViewController viewDidDisappear:YES];
        if(self.didCloseBlock != nil)
            self.didCloseBlock(self);
		[[NSNotificationCenter defaultCenter] postNotificationName:TUIPopoverDidCloseNotification
															object:self
														  userInfo:@{TUIPopoverCloseReasonKey : TUIPopoverCloseReasonStandard}];
        
        self.contentViewController.view.frame = CGRectMake(self.contentViewController.view.frame.origin.x,
                                                           self.contentViewController.view.frame.origin.y,
                                                           self.originalViewSize.width,
                                                           self.originalViewSize.height);
    };
	
	if(self.animates) {
		for(CAAnimation *animation in self.hideAnimations) {
			animation.fillMode = kCAFillModeForwards;
			animation.removedOnCompletion = NO;
			animation.duration = TUIPopoverCurrentAnimationDuration;
		}
		
		CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
		group.animations = self.hideAnimations;
		group.fillMode = kCAFillModeForwards;
		group.removedOnCompletion = NO;
		group.duration = TUIPopoverCurrentAnimationDuration;
		group.tui_completionBlock = completionBlock;
		
		self.animating = YES;
		CALayer *viewLayer = ((NSView *)self.popoverWindow.contentView).layer;
		[viewLayer addAnimation:group forKey:nil];
	} else {
		completionBlock();
	}
}

- (IBAction)performClose:(id)sender {
	if(self.shouldClose != nil) {
		if(self.shouldClose(self))
			[self close];
	} else if([self.delegate respondsToSelector:@selector(popoverShouldClose:)]) {
		if([self.delegate popoverShouldClose:self])
			[self close];
	} else {
		[self close];
	}
}

- (void)parentWindowClosed:(NSNotification *)notification {
	if([notification.object isEqual:self.contentViewController.view.nsWindow])
		[self close];
}

- (void)addEventMonitor {
	NSEventMask mask = (NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyUpMask);
    self.transientEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:mask handler:^(NSEvent *event) {
		if(self.popoverWindow == nil)
			return event;
		
		static NSUInteger const escapeKey = 53;
		BOOL mouseInPopover = NSPointInRect([NSEvent mouseLocation], self.popoverWindow.frame);
		BOOL mouseInWindow = NSPointInRect([NSEvent mouseLocation], self.popoverWindow.parentWindow.frame);
		
		if((event.type == NSLeftMouseDown) || (event.type == NSRightMouseDown)) {
			if((self.behavior == TUIPopoverBehaviorTransient) && !mouseInPopover) {
				[self close];
			} else if((self.behavior == TUIPopoverBehaviorSemitransient) && mouseInWindow) {
				[self close];
			}
		} else if(event.keyCode == escapeKey) {
			if(self.shouldClose != nil) {
				if(self.shouldClose())
					[self close];
			} else if([self.delegate respondsToSelector:@selector(popoverShouldClose:)]) {
				if([self.delegate popoverShouldClose:self])
					[self close];
			}
		}
		
		return event;
	}];
}

- (void)removeEventMonitor {
	[NSEvent removeMonitor:self.transientEventMonitor];
	self.transientEventMonitor = nil;
}

- (void)setBehavior:(TUIPopoverBehavior)behavior {
    _behavior = behavior;
    if(_shown) {
        if(_behavior == TUIPopoverBehaviorApplicationDefined && self.transientEventMonitor)
            [self removeEventMonitor];
        else if(!self.transientEventMonitor)
            [self addEventMonitor];
    }
}

@end

@implementation TUIPopoverBackgroundView

+ (CGSize)sizeForBackgroundViewWithContentSize:(CGSize)contentSize popoverEdge:(CGRectEdge)popoverEdge {
	contentSize.width += TUIPopoverBackgroundViewArrowHeight;
    contentSize.height += TUIPopoverBackgroundViewArrowHeight * 2;
    
    return contentSize;
}

+ (CGRect)contentViewFrameForBackgroundFrame:(CGRect)backgroundFrame popoverEdge:(CGRectEdge)popoverEdge {
	CGFloat inset = TUIPopoverBackgroundViewArrowHeight + TUIPopoverBackgroundViewBorderRadius;
	
    return ABRectRoundOrigin(CGRectInset(backgroundFrame, inset, inset));
}

+ (TUIPopoverBackgroundView *)backgroundViewForContentSize:(CGSize)contentSize
											   popoverEdge:(CGRectEdge)popoverEdge
										  originScreenRect:(CGRect)originScreenRect {
	
    CGSize size = [self sizeForBackgroundViewWithContentSize:contentSize popoverEdge:popoverEdge];
    return [[self.class alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
								 popoverEdge:popoverEdge
							originScreenRect:originScreenRect];
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
		self.opaque = NO;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	CGPathRef cgPath = [self newPopoverPathForEdge:self.popoverEdge inFrame:CGRectInset(self.bounds, 0.5, 0.5)];
	NSBezierPath *path = [NSBezierPath bezierPathWithCGPath:cgPath];
	CGPathRelease(cgPath);
	
	NSGradient *gradient = [[NSGradient alloc] initWithColors:@[[NSColor colorWithCalibratedWhite:0.95 alpha:0.95],
																[NSColor colorWithCalibratedWhite:0.90 alpha:0.95]]];
	[gradient drawInBezierPath:path angle:-90];
	[[NSColor whiteColor] set];
	[path strokeInside];
	
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.3] set];
	[path stroke];
}

- (void)updateMaskLayer {
	CAShapeLayer *maskLayer = [CAShapeLayer layer];
    CGPathRef path = [self newPopoverPathForEdge:self.popoverEdge inFrame:CGRectInset(self.bounds, -1.0, -1.0)];
    maskLayer.path = path;
    maskLayer.fillColor = CGColorGetConstantColor(kCGColorBlack);
    CGPathRelease(path);
	
    self.layer.mask = maskLayer;
}

@end

@implementation TUIPopoverWindowContentView

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		[self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		
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

@implementation TUIPopoverWindow

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

@end
