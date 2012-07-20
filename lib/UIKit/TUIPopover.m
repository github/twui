#import "TUIPopover.h"

NSString *const TUIPopoverCloseReasonKey = @"_kTUIPopoverCloseReasonKey";
NSString *const TUIPopoverCloseReasonStandard = @"_kTUIPopoverCloseReasonStandard";
NSString *const TUIPopoverCloseReasonDetachToWindow = @"_kTUIPopoverCloseReasonDetachToWindow";

CGFloat const TUIPopoverBackgroundViewBorderRadius = 4.5;
CGFloat const TUIPopoverBackgroundViewArrowHeight = 12.0;
CGFloat const TUIPopoverBackgroundViewArrowWidth = 24.0;

NSTimeInterval const TUIPopoverDefaultAnimationDuration = 0.4;

@interface TUIPopoverFrame : NSView

@property (nonatomic) CGRectEdge arrowDirection;
@property (nonatomic) TUIPopoverAppearance appearance;
@property (nonatomic, retain) TUINSView *nsView;

- (NSBezierPath *)popoverBezierPathWithRect:(CGRect)rect;

@end

@interface TUIPopoverWindow : NSWindow

@property (nonatomic, retain) TUIView *rootView;
@property (nonatomic, readonly) TUIPopoverFrame *frameView;

- (id)initWithContentRect:(CGRect)contentRect;

@end

@interface TUIPopover ()

@property (nonatomic, retain) TUIPopoverWindow *popoverWindow;
@property (nonatomic, assign) id transientEventMonitor;
@property (nonatomic, assign) BOOL animating;
@property (nonatomic, assign) CGSize originalViewSize;

- (void)addEventMonitor;
- (void)removeEventMonitor;

@end

@implementation TUIPopover

@synthesize animates = _animates;
@synthesize appearance = _appearance;
@synthesize behavior = _behavior;
@synthesize contentSize = _contentSize;
@synthesize contentViewController = _contentViewController;
@synthesize positioningRect = _positioningRect;
@synthesize shown = _shown;

@synthesize popoverWindow = _popoverWindow;
@synthesize animating = _animating;
@synthesize originalViewSize = _originalViewSize;

@synthesize willShowBlock;
@synthesize willCloseBlock;
@synthesize didShowBlock;
@synthesize didCloseBlock;

- (id)initWithContentView:(TUIView *)view {
    TUIViewController *vc = [[TUIViewController alloc] init];
    vc.view = view;
	return [self initWithContentViewController:vc];
}

- (id)initWithContentViewController:(TUIViewController *)viewController {
	if((self = [self init])) {
        self.contentViewController = viewController;
    } return self;
}

- (id)init {
    if((self = [super init])) {
        self.animates = YES;
        self.appearance = TUIPopoverAppearanceMinimal;
        self.behavior = TUIPopoverBehaviorApplicationDefined;
        self.contentViewController = nil;
        
        _shown = NO;
    } return self;
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

- (void)showRelativeToRect:(CGRect)newPositioningRect ofView:(TUIView *)positioningView preferredEdge:(CGRectEdge)preferredEdge {
    if(_shown) return;
    
    [self.contentViewController viewWillAppear:YES];
    if(self.willShowBlock != nil)
        self.willShowBlock(self);
    
    if(self.behavior != TUIPopoverBehaviorApplicationDefined) {
		if(self.transientEventMonitor)
            [self removeEventMonitor];
        [self addEventMonitor];
    }
    
    CGSize contentViewSize = (CGSizeEqualToSize(self.contentSize, CGSizeZero) ?
                              self.contentViewController.view.frame.size : self.contentSize);
    _positioningRect = CGRectEqualToRect(newPositioningRect, CGRectZero) ? positioningView.bounds : newPositioningRect;
    self.originalViewSize = self.contentViewController.view.frame.size;
    
    CGRect (^popoverRectForEdge)(CGRectEdge) = ^(CGRectEdge popoverEdge) {
        CGRect basePositioningRect = [positioningView convertRect:_positioningRect toView:nil];
        CGRect windowRelativeRect = [positioningView.nsView convertRect:basePositioningRect toView:nil];
        CGPoint screenPositioningPoint = [positioningView.nsWindow convertBaseToScreen:windowRelativeRect.origin];
        
        CGFloat yPos = screenPositioningPoint.y;
        CGFloat xPos = screenPositioningPoint.x;
        
        switch (popoverEdge) {
            case CGRectMinYEdge:
                xPos += _positioningRect.origin.x + (_positioningRect.size.width * 0.5)  - (contentViewSize.width * 0.5);
                yPos += _positioningRect.origin.y + (_positioningRect.size.height * 0.5) - contentViewSize.height - TUIPopoverBackgroundViewArrowHeight;
                break;
            case CGRectMaxYEdge:
                xPos += _positioningRect.origin.x + (_positioningRect.size.width * 0.5)  - (contentViewSize.width * 0.5);
                yPos += _positioningRect.origin.y + _positioningRect.size.height;
                break;
            case CGRectMinXEdge:
                yPos += _positioningRect.origin.y + (_positioningRect.size.height * 0.5)  - (contentViewSize.height * 0.5);
                xPos += _positioningRect.origin.x - contentViewSize.width;
                break;
            case CGRectMaxXEdge:
                yPos += _positioningRect.origin.y + (_positioningRect.size.height * 0.5)  - (contentViewSize.height * 0.5);
                xPos += _positioningRect.origin.x + _positioningRect.size.width;
                break;
        }
        
        return NSMakeRect(xPos, yPos, contentViewSize.width, contentViewSize.height);
    };
    
    CGRect (^initialPopoverRectForEdge)(CGRectEdge, CGRect) = ^(CGRectEdge direction, CGRect finishRect) {
        CGRect retFrame = NSMakeRect(0.0, 0.0, 0.0, 0.0);
        switch(direction) {
            case CGRectMinYEdge:
                retFrame.origin.x = finishRect.origin.x + (finishRect.size.width * 0.5);
                retFrame.origin.y = finishRect.origin.y + (finishRect.size.height * 1.0);
                break;
            case CGRectMaxYEdge:
                retFrame.origin.x = finishRect.origin.x + (finishRect.size.width * 0.5);
                retFrame.origin.y = finishRect.origin.y + (finishRect.size.height * 0.0);
                break;
            case CGRectMinXEdge:
                retFrame.origin.x = finishRect.origin.x + (finishRect.size.width * 1.0);
                retFrame.origin.y = finishRect.origin.y + (finishRect.size.height * 0.5);
                break;
            case CGRectMaxXEdge:
                retFrame.origin.x = finishRect.origin.x + (finishRect.size.width * 0.0);
                retFrame.origin.y = finishRect.origin.y + (finishRect.size.height * 0.5);
                break;
        } return retFrame;
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
    
    CGRect popoverFrame = popoverRect();
    CGRect originalRect = _contentViewController.view.frame;
    originalRect.size = contentViewSize;
    _contentViewController.view.frame = originalRect;
    
    _popoverWindow = [[TUIPopoverWindow alloc] initWithContentRect:NSZeroRect];
    _popoverWindow.frameView.arrowDirection = popoverEdge;
    _popoverWindow.rootView = _contentViewController.view;
    [positioningView.nsWindow addChildWindow:_popoverWindow ordered:NSWindowAbove];
    [_popoverWindow makeKeyAndOrderFront:nil];
    
    [[_popoverWindow contentView] setAlphaValue:0.0];
    [_popoverWindow setAlphaValue:0.0];
    [_popoverWindow setFrame:initialPopoverRectForEdge(popoverEdge, popoverFrame) display:YES];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:TUIPopoverDefaultAnimationDuration];
    CAMediaTimingFunction *popIn = [CAMediaTimingFunction functionWithControlPoints:0.97 :0.00 :0.45 :1.00];
    [[NSAnimationContext currentContext] setTimingFunction:popIn];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        self.animating = NO;
        _shown = YES;
        
        [self.contentViewController viewDidAppear:YES];
        if(self.didShowBlock)
            self.didShowBlock(self);
    }];
    
    [[[_popoverWindow contentView] animator] setAlphaValue:1.0];
    [[_popoverWindow animator] setAlphaValue:1.0];
    [[_popoverWindow animator] setFrame:popoverFrame display:YES];
    
    self.animating = YES;
    [NSAnimationContext endGrouping];
}

- (void)close {
    [self closeWithFadeoutDuration:TUIPopoverDefaultAnimationDuration * 0.75];
}

- (void)closeWithFadeoutDuration:(NSTimeInterval)duration {
    if(self.animating || !_shown) return;
    
    if(self.transientEventMonitor)
		[self removeEventMonitor];
    if(self.willCloseBlock != nil)
        self.willCloseBlock(self);
    
    CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"alphaValue"];
    fadeOutAnimation.duration = duration;
    fadeOutAnimation.tui_completionBlock = ^ {
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

- (IBAction)performClose:(id)sender {
    [self close];
}

- (void)addEventMonitor {
    self.transientEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyUpMask) handler: ^(NSEvent *event)
                                  {
                                      if(self.popoverWindow == nil)
                                          return event;
                                      
                                      static NSUInteger escapeKey = 53;
                                      BOOL shouldClose = (event.type == NSLeftMouseDown || event.type == NSRightMouseDown ? (!NSPointInRect([NSEvent mouseLocation], self.popoverWindow.frame) && self.behavior == TUIPopoverBehaviorTransient) : event.keyCode == escapeKey);
                                      
                                      if(shouldClose) [self close];
                                      return event;
                                  }];
}

- (void)removeEventMonitor {
    [NSEvent removeMonitor:self.transientEventMonitor];
	self.transientEventMonitor = nil;
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
        [self setHasShadow:YES];
        [self setReleasedWhenClosed:NO];
        [self blurWindow];
    } return self;
}

- (void)blurWindow {
    typedef void* CGSConnectionID;
    typedef uint32_t CGSWindowFilterRef;
    
    extern OSStatus CGSNewConnection(const void **attr, CGSConnectionID *id);
    extern CGError CGSNewCIFilterByName(CGSConnectionID cid, CFStringRef filterName, CGSWindowFilterRef *outFilter);
    extern CGError CGSSetCIFilterValuesFromDictionary(CGSConnectionID cid, CGSWindowFilterRef filter, CFDictionaryRef filterValues);
    extern CGError CGSAddWindowFilter(CGSConnectionID cid, long wid, CGSWindowFilterRef filter, int flags);
    
    CGSConnectionID _myConnection;
    uint32_t __compositingFilter;
    int __compositingType = 1;
    
    CGSNewConnection(NULL , &_myConnection);
    CGSNewCIFilterByName(_myConnection, (CFStringRef)@"CIGaussianBlur", &__compositingFilter);
    NSDictionary *optionsDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:3.0] forKey:@"inputRadius"];
    CGSSetCIFilterValuesFromDictionary(_myConnection, __compositingFilter, (__bridge CFDictionaryRef)optionsDict);
    CGSAddWindowFilter(_myConnection, [self windowNumber], __compositingFilter, __compositingType);
}

- (CGRect)contentRectForFrameRect:(CGRect)windowFrame {
    windowFrame.origin = NSZeroPoint;
    return NSInsetRect(windowFrame, TUIPopoverBackgroundViewArrowHeight, TUIPopoverBackgroundViewArrowHeight);
}

- (CGRect)frameRectForContentRect:(CGRect)contentRect {
    return NSInsetRect(contentRect, -TUIPopoverBackgroundViewArrowHeight, -TUIPopoverBackgroundViewArrowHeight);
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

- (TUIPopoverFrame *)frameView {
    return (TUIPopoverFrame *)[super contentView];
}

- (void)setRootView:(TUIView *)aView {
    if([_popoverRootView isEqualTo:aView])
        return;
    
	CGRect bounds = self.frame;
	bounds.origin = NSZeroPoint;
    
	TUIPopoverFrame *frameView = [super contentView];
	if(!frameView) {
		frameView = [[TUIPopoverFrame alloc] initWithFrame:bounds];
		[super setContentView:frameView];
	}
    
	if(_popoverRootView)
        [_popoverRootView removeFromSuperview];
	_popoverRootView = aView;
    
	[frameView.nsView setRootView:_popoverRootView];
}

- (void)setContentView:(NSView *)aView {
	if([_popoverContentView isEqualTo:aView])
        return;
    
	CGRect bounds = [self frame];
	bounds.origin = NSZeroPoint;
    
	TUIPopoverFrame *frameView = [super contentView];
	if(!frameView) {
		frameView = [[TUIPopoverFrame alloc] initWithFrame:bounds];
		[super setContentView:frameView];
	}
    
	if(_popoverContentView)
        [_popoverContentView removeFromSuperview];
	_popoverContentView = aView;
    
	[_popoverContentView setFrame:[self contentRectForFrameRect:bounds]];
	[_popoverContentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[frameView addSubview:_popoverContentView];
}

@end

@implementation TUIPopoverFrame

@synthesize arrowDirection = _arrowDirection;
@synthesize appearance = _appearance;
@synthesize nsView;

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
        self.arrowDirection = CGRectNoEdge;
        [self setAppearance:TUIPopoverAppearanceMinimal];
        
        CGFloat inset = TUIPopoverBackgroundViewBorderRadius + TUIPopoverBackgroundViewArrowHeight;
        CGRect drawingRect = NSInsetRect(self.bounds, inset, inset);
        
        self.nsView = [[TUINSView alloc] initWithFrame:drawingRect];
        [nsView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [nsView tui_setOpaque:NO];
        [self addSubview:nsView];
    } return self;
}

- (void)drawRect:(CGRect)dirtyRect {
    NSBezierPath *path = [self popoverBezierPathWithRect:self.bounds];
    CGContextTranslateCTM([[NSGraphicsContext currentContext] graphicsPort], 0.5, 0.5);
    
    NSGradient *borderGradient = nil;
    if(self.appearance == TUIPopoverAppearanceHUD) {
        borderGradient = [[NSGradient alloc] initWithColorsAndLocations:
                          [NSColor colorWithCalibratedWhite:0.12 alpha:0.90], 0.0,
                          [NSColor colorWithCalibratedWhite:0.15 alpha:0.90], 1.0, nil];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] set];
    } else if(self.appearance == TUIPopoverAppearanceMinimal) {
        borderGradient = [[NSGradient alloc] initWithColorsAndLocations:
                          [NSColor colorWithCalibratedWhite:1.00 alpha:0.925], 0.0,
                          [NSColor colorWithCalibratedWhite:0.95 alpha:0.925], 1.0, nil];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] set];
    }
    
    [borderGradient drawInBezierPath:path angle:-90];
    [path setLineWidth:1.0];
    [path stroke];
}

- (NSBezierPath *)popoverBezierPathWithRect:(CGRect)rect {
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    CGFloat radius = TUIPopoverBackgroundViewBorderRadius;
    CGFloat inset = radius + TUIPopoverBackgroundViewArrowHeight;
    CGRect drawingRect = NSInsetRect(rect, inset, inset);
    
    CGFloat minX = CGRectGetMinX(drawingRect);
    CGFloat maxX = CGRectGetMaxX(drawingRect);
    CGFloat minY = CGRectGetMinY(drawingRect);
    CGFloat maxY = CGRectGetMaxY(drawingRect);
    
    // Bottom left corner.
    [path appendBezierPathWithArcWithCenter:NSMakePoint(minX, minY) radius:radius startAngle:180.0 endAngle:270.0];
    if(self.arrowDirection == CGRectMaxYEdge) {
        CGFloat midX = NSMidX(drawingRect);
        NSPoint points[3];
        points[0] = NSMakePoint(floor(midX - (TUIPopoverBackgroundViewArrowWidth / 2.0)), minY - radius);
        points[1] = NSMakePoint(floor(midX), points[0].y - TUIPopoverBackgroundViewArrowHeight + 1);
        points[2] = NSMakePoint(floor(midX + (TUIPopoverBackgroundViewArrowWidth / 2.0)), points[0].y);
        [path appendBezierPathWithPoints:points count:3];
    }
    
    // Bottom right corner.
    [path appendBezierPathWithArcWithCenter:NSMakePoint(maxX, minY) radius:radius startAngle:270.0 endAngle:360.0];
    if(self.arrowDirection == CGRectMinXEdge) {
        CGFloat midY = NSMidY(drawingRect);
        NSPoint points[3];
        points[0] = NSMakePoint(maxX + radius, floor(midY - (TUIPopoverBackgroundViewArrowWidth / 2.0)));
        points[1] = NSMakePoint(points[0].x + TUIPopoverBackgroundViewArrowHeight, floor(midY));
        points[2] = NSMakePoint(points[0].x, floor(midY + (TUIPopoverBackgroundViewArrowWidth / 2.0)));
        [path appendBezierPathWithPoints:points count:3];
    }
    
    // Top right corner.
    [path appendBezierPathWithArcWithCenter:NSMakePoint(maxX, maxY) radius:radius startAngle:0.0 endAngle:90.0];
    if(self.arrowDirection == CGRectMinYEdge) {
        CGFloat midX = NSMidX(drawingRect);
        NSPoint points[3];
        points[0] = NSMakePoint(floor(midX + (TUIPopoverBackgroundViewArrowWidth / 2.0)), maxY + radius);
        points[1] = NSMakePoint(floor(midX), points[0].y + TUIPopoverBackgroundViewArrowHeight - 1);
        points[2] = NSMakePoint(floor(midX - (TUIPopoverBackgroundViewArrowWidth / 2.0)), points[0].y);
        [path appendBezierPathWithPoints:points count:3];
    }
    
    // Top left corner.
    [path appendBezierPathWithArcWithCenter:NSMakePoint(minX, maxY) radius:radius startAngle:90.0 endAngle:180.0];
    if(self.arrowDirection == CGRectMaxXEdge) {
        CGFloat midY = NSMidY(drawingRect);
        NSPoint points[3];
        points[0] = NSMakePoint(minX - radius, floor(midY + (TUIPopoverBackgroundViewArrowWidth / 2.0)));
        points[1] = NSMakePoint(points[0].x - TUIPopoverBackgroundViewArrowHeight, floor(midY));
        points[2] = NSMakePoint(points[0].x, floor(midY - (TUIPopoverBackgroundViewArrowWidth / 2.0)));
        [path appendBezierPathWithPoints:points count:3];
    }
    
    [path closePath];
    return path;
}

- (void)setArrowDirection:(CGRectEdge)arrowDirection {
    _arrowDirection = arrowDirection;
    [self setNeedsDisplay:YES];
}

- (void)setAppearance:(TUIPopoverAppearance)appearance {
    _appearance = appearance;
    [self setNeedsDisplay:YES];
}

@end