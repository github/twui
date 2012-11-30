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
CGFloat const TUIPopoverBackgroundViewArrowHeight = 12.0;
CGFloat const TUIPopoverBackgroundViewArrowWidth = 24.0;

NSTimeInterval const TUIPopoverDefaultAnimationDuration = 0.25f;
#define TUIPopoverCurrentAnimationDuration \
((self.animationDuration > 0.0) ? self.animationDuration : TUIPopoverDefaultAnimationDuration)

@interface TUIPopoverBackgroundView ()

@property (nonatomic, assign) CGRect screenOriginRect;
@property (nonatomic, assign) CGRectEdge popoverEdge;

+ (TUIPopoverBackgroundView *)backgroundViewForContentSize:(CGSize)contentSize
											   popoverEdge:(CGRectEdge)popoverEdge
										  originScreenRect:(CGRect)originScreenRect;
- (void)updateMaskLayer;

@end

@interface TUIPopoverWindowContentView : TUINSView

@property (nonatomic, assign) CGRectEdge popoverEdge;

- (void)popoverWantsShadow:(BOOL)shadow;

@end

@interface TUIPopoverWindow : NSWindow

@property (nonatomic, strong) TUIPopoverWindowContentView *frameView;

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
		
		CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		CAKeyframeAnimation *bounce = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
		bounce.values = @[@0.05f, @1.11245f, @1.00f];
		bounce.timingFunctions = @[easeInOut, easeInOut, easeInOut];
		
		CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeIn.fromValue = @0.0f;
		fadeIn.toValue = @1.0f;
		CAAnimationGroup *popIn = [CAAnimationGroup animation];
		popIn.animations = @[fadeIn, bounce];
		
		CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeOut.fromValue = @1.0f;
		fadeOut.toValue = @0.0f;
		
		self.showAnimation = popIn;
		self.hideAnimation = fadeOut;
		
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

- (void)setContentViewController:(TUIViewController *)controller {
	if(self.shown) {
		TUIPopoverBackgroundView *backgroundView = (TUIPopoverBackgroundView *)self.popoverWindow.frameView.rootView;
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
				[_contentViewController viewWillDisappear:YES];
				[controller viewWillAppear:YES];
				updateBlock();
				[_contentViewController viewDidDisappear:YES];
				[controller viewDidAppear:YES];
			}];
		} else {
			[_contentViewController viewWillDisappear:YES];
			[controller viewWillAppear:YES];
			updateBlock();
			[_contentViewController viewDidDisappear:YES];
			[controller viewDidAppear:YES];
		}
	}
	
	_contentViewController = controller;
}

- (void)setContentSize:(CGSize)size {
	if(self.shown) {
		TUIPopoverBackgroundView *backgroundView = (TUIPopoverBackgroundView *)self.popoverWindow.frameView.rootView;
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
	if(!positioningView) {
		[NSException raise:NSInvalidArgumentException format:@"TUIPopover positioningView cannot be nil!"];
		return;
	}
	
	if(!self.contentViewController || !self.contentViewController.view) {
		[NSException raise:NSInternalInconsistencyException format:@"TUIPopover contentViewController view cannot be nil!"];
		return;
	}
	
	if(self.shown || [self.popoverWindow isVisible])
		return;
	
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
	
	// Get the popover screen rectangle and create a background view
	// for the popover with the adjusted content size and popover offset.
	CGRect popoverScreenRect = popoverRect();
	TUIPopoverBackgroundView *backgroundView = [self.backgroundViewClass backgroundViewForContentSize:contentViewSize
																						  popoverEdge:popoverEdge
																					 originScreenRect:screenPositioningRect];
	CGPoint popoverOffset = [self.backgroundViewClass popoverOffsetForBackgroundFrame:backgroundView.bounds
																		  popoverEdge:popoverEdge];
	
	// Adjust the window rect again with the offset for the shadow.
	CGRect windowRect = popoverScreenRect;
	windowRect.origin.x += popoverOffset.x;
	windowRect.origin.y += popoverOffset.y;
	
	// Create the popover window and add the content view and root view.
	_popoverWindow = [[TUIPopoverWindow alloc] initWithContentRect:windowRect];
	TUIPopoverWindowContentView *contentView = [[TUIPopoverWindowContentView alloc] initWithFrame:backgroundView.bounds];
	self.popoverWindow.frameView = contentView;
	contentView.rootView = backgroundView;
	
	// Adjust the background view frame so the popover path auto-adjusts.
	// Cache the previous bounds and offset it so the content sits inside.
	CGRect contentFrame = backgroundView.bounds;
	CGRect backgroundFrame = backgroundView.frame;
	switch(popoverEdge) {
		case CGRectMinXEdge:
			backgroundFrame.size.width -= popoverOffset.x;
			break;
		case CGRectMaxXEdge:
			backgroundFrame.origin.x -= popoverOffset.x;
			backgroundFrame.size.width += popoverOffset.x;
			
			contentFrame.origin.x += popoverOffset.x;
			break;
		case CGRectMinYEdge:
			backgroundFrame.size.height -= popoverOffset.y;
			break;
		case CGRectMaxYEdge:
			backgroundFrame.origin.y -= popoverOffset.y;
			backgroundFrame.size.height += popoverOffset.y;
			
			contentFrame.origin.y += popoverOffset.y;
			break;
		default:
			break;
	}
	backgroundView.frame = backgroundFrame;
	
	// Set the content view frame and add it to the popover background view.
	CGRect contentViewFrame = [self.backgroundViewClass contentViewFrameForBackgroundFrame:contentFrame
																			   popoverEdge:popoverEdge];
	_contentViewController.view.frame = contentViewFrame;
	[backgroundView addSubview:self.contentViewController.view];
	
	// Apply the popover edge and update the drawing mask.
	[contentView popoverWantsShadow:[self.backgroundViewClass requiresBackgroundShadow]];
	contentView.popoverEdge = popoverEdge;
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
		CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
		group.animations = @[self.showAnimation];
		group.fillMode = kCAFillModeForwards;
		group.removedOnCompletion = YES;
		group.duration = TUIPopoverCurrentAnimationDuration;
		group.tui_completionBlock = completionBlock;
		
		self.animating = YES;
		CALayer *viewLayer = _popoverWindow.frameView.layer;
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
		self.popoverWindow = nil;
		
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
		CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
		group.animations = @[self.hideAnimation];
		group.fillMode = kCAFillModeForwards;
		group.removedOnCompletion = NO;
		group.duration = TUIPopoverCurrentAnimationDuration;
		group.tui_completionBlock = completionBlock;
		
		self.animating = YES;
		CALayer *viewLayer = self.popoverWindow.frameView.layer;
		[viewLayer addAnimation:group forKey:nil];
	} else {
		completionBlock();
	}
}

- (IBAction)performClose:(id)sender {
	if(self.shouldClose != nil) {
		if(self.shouldClose(self))
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
	CGFloat inset = TUIPopoverBackgroundViewArrowHeight + TUIPopoverBackgroundViewBorderRadius;
	
	// Add padding on all widths so the shadow shows and
	// make up for the border radius.
	contentSize.width += inset * 2;
	contentSize.height += inset * 2;
	
	// Adjust the drawing board so the shadow isn't clipped.
	switch(popoverEdge) {
		case CGRectMinXEdge:
		case CGRectMaxXEdge:
			contentSize.width += TUIPopoverBackgroundViewArrowHeight * 2;
			break;
		case CGRectMinYEdge:
		case CGRectMaxYEdge:
			contentSize.height += TUIPopoverBackgroundViewArrowHeight * 2;
			break;
		default:
			break;
	}
	
	return contentSize;
}

+ (CGRect)contentViewFrameForBackgroundFrame:(CGRect)backgroundFrame popoverEdge:(CGRectEdge)popoverEdge {
	CGFloat inset = TUIPopoverBackgroundViewArrowHeight + TUIPopoverBackgroundViewBorderRadius;
	
	// Adjust the drawing board so the shadow isn't clipped.
	switch(popoverEdge) {
		case CGRectMinXEdge:
		case CGRectMaxXEdge:
			backgroundFrame.origin.x += TUIPopoverBackgroundViewArrowHeight;
			backgroundFrame.size.width -= TUIPopoverBackgroundViewArrowHeight * 2;
			break;
		case CGRectMinYEdge:
		case CGRectMaxYEdge:
			backgroundFrame.origin.y += TUIPopoverBackgroundViewArrowHeight;
			backgroundFrame.size.height -= TUIPopoverBackgroundViewArrowHeight * 2;
			break;
		default:
			break;
	}
	
	// Inset the content so it doesn't get masked out.
	return CGRectIntegral(CGRectInset(backgroundFrame, inset, inset));
}

+ (CGPoint)popoverOffsetForBackgroundFrame:(CGRect)frame popoverEdge:(CGRectEdge)popoverEdge {
	CGPoint returnOffset = CGPointZero;
	
	// Adjust the drawing board so the shadow isn't clipped.
	switch(popoverEdge) {
		case CGRectMinXEdge:
			returnOffset.x += TUIPopoverBackgroundViewArrowHeight;
			break;
		case CGRectMaxXEdge:
			returnOffset.x -= TUIPopoverBackgroundViewArrowHeight;
			break;
		case CGRectMinYEdge:
			returnOffset.y += TUIPopoverBackgroundViewArrowHeight;
			break;
		case CGRectMaxYEdge:
			returnOffset.y -= TUIPopoverBackgroundViewArrowHeight;
			break;
		default:
			break;
	}
	
	return returnOffset;
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
	CGFloat insetArrowHeight = TUIPopoverBackgroundViewArrowHeight;
	CGRect drawingRect = CGRectInset(rect, inset, inset);
	
	switch(popoverEdge) {
		case CGRectMinXEdge:
			drawingRect.origin.x += TUIPopoverBackgroundViewArrowHeight;
		case CGRectMaxXEdge:
			drawingRect.size.width -= TUIPopoverBackgroundViewArrowHeight;
			break;
		case CGRectMinYEdge:
			drawingRect.origin.y += TUIPopoverBackgroundViewArrowHeight;
		case CGRectMaxYEdge:
			drawingRect.size.height -= TUIPopoverBackgroundViewArrowHeight;
			break;
		default:
			break;
	}
	
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
	return [path tui_CGPath];
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
	CGPathRef cgPath = [self newPopoverPathForEdge:self.popoverEdge inFrame:CGRectInset(self.bounds, 0.5f, 0.5f)];
	NSBezierPath *path = [NSBezierPath tui_bezierPathWithCGPath:cgPath];
	CGPathRelease(cgPath);
	
	NSGradient *gradient = [[NSGradient alloc] initWithColors:@[[NSColor colorWithCalibratedWhite:0.95f alpha:0.95f],
																[NSColor colorWithCalibratedWhite:0.90f alpha:0.95f]]];
	[gradient drawInBezierPath:path angle:270.0f];
	[[NSColor highlightColor] set];
	[path tui_strokeInside];
	
	[[NSColor colorWithCalibratedWhite:0.0f alpha:0.25f] set];
	[path stroke];
}

- (void)updateMaskLayer {
	CAShapeLayer *maskLayer = [CAShapeLayer layer];
	CGPathRef path = [self newPopoverPathForEdge:self.popoverEdge inFrame:CGRectInset(self.bounds, -1, -1)];
	maskLayer.path = path;
	maskLayer.fillColor = CGColorGetConstantColor(kCGColorBlack);
	CGPathRelease(path);
	
	self.layer.mask = maskLayer;
}

+ (BOOL)requiresBackgroundShadow {
	return YES;
}

@end

@implementation TUIPopoverWindowContentView

- (void)viewDidMoveToWindow {
	[self tui_setOpaque:NO];
	
	// Set a layer shadow because we lose the window shadow.
	self.layer.shadowColor = [NSColor shadowColor].CGColor;
	self.layer.shadowOffset = CGSizeMake(0.0f, -3.0f);
	self.layer.shadowRadius = 5.0f;
}

- (void)popoverWantsShadow:(BOOL)shadow {
	self.layer.shadowOpacity = shadow ? 0.5f : 0.0f;
}

- (void)setPopoverEdge:(CGRectEdge)popoverEdge {
	_popoverEdge = popoverEdge;
	
	// Set the layer anchor point, so animations act accordingly.
	switch(popoverEdge) {
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
	[self.layer setPosition:correctPosition];
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
		[self setMovableByWindowBackground:NO];
		[self setExcludedFromWindowsMenu:YES];
	} return self;
}

- (BOOL)canBecomeKeyWindow {
	return YES;
}

- (BOOL)canBecomeMainWindow {
	return NO;
}

- (BOOL)isExcludedFromWindowsMenu {
	return YES;
}

- (TUIPopoverWindowContentView *)frameView {
	return (TUIPopoverWindowContentView *)self.contentView;
}

- (void)setFrameView:(TUIPopoverWindowContentView *)frameView {
	[self setContentView:frameView];
}

@end
