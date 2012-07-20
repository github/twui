#import "TUIPanel.h"

CGFloat const TUIPanelCornerRadius = 4.5f;
CGFloat const TUIPanelTitlebarHeight = 22.0f;
NSSize const TUIPanelButtonSize = (NSSize){15.0f, 15.0f};
CGFloat const TUIPanelButtonMargin = 5.0f;

@interface TUIWindowButtonCell : NSButtonCell
@end

@interface TUIPanelFrame : NSView
@property (nonatomic, retain) TUINSView *nsView;
@end

@interface TUIPanel ()
@property (nonatomic, readonly) TUIPanelFrame *frameView;
@end

@implementation TUIPanel {
    TUIView *_popoverRootView;
    NSView *_popoverContentView;
    TUIPanelFrame *frameView;
}

- (id)initWithContentRect:(CGRect)contentRect {
    if((self = [super initWithContentRect:contentRect
                                styleMask:NSResizableWindowMask | NSClosableWindowMask
                                  backing:NSBackingStoreBuffered
                                    defer:YES])) {
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setHasShadow:YES];
        
        [self setReleasedWhenClosed:NO];
        [self setHidesOnDeactivate:YES];
        [self setExcludedFromWindowsMenu:YES];
        
        [self blurWindow];
    } return self;
}

- (void)setTitle:(NSString *)aString {
    [super setTitle:aString];
    [[super contentView] setNeedsDisplay:YES];
}

- (void)setStyleMask:(NSUInteger)styleMask {
    [self setFloatingPanel:styleMask & NSUtilityWindowMask];
    [super setStyleMask:styleMask];
}

- (void)setFloatingPanel:(BOOL)flag {
    [self setLevel:flag ? NSFloatingWindowLevel : NSNormalWindowLevel];
}

- (BOOL)isFloatingPanel	{
    return [self level] == NSFloatingWindowLevel;
}

+ (BOOL)hasMainMenuForStyleMask:(NSUInteger)styleMask {
    return NO;
}

- (BOOL)canBecomeKeyWindow {
    if(self.becomesKeyOnlyIfNeeded)
		 return [self needsPanelToBecomeKey:self.contentView];
    else return YES;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (TUIView *)rootView {
    return _popoverRootView;
}

- (NSView *)contentView {
    return _popoverContentView;
}

- (TUIPanelFrame *)frameView {
    return (TUIPanelFrame *)[super contentView];
}

- (NSRect)contentRectForFrameRect:(NSRect)windowFrame {
    windowFrame.origin = NSZeroPoint;
    windowFrame.size.height -= TUIPanelTitlebarHeight;
    return windowFrame;
}

+ (NSRect)frameRectForContentRect:(NSRect)windowContentRect
                        styleMask:(NSUInteger)windowStyle {
    windowContentRect.size.height += TUIPanelTitlebarHeight;
    return windowContentRect;
}

- (NSRect)frameRectForContentRect:(NSRect)windowContent {
    windowContent.size.height += TUIPanelTitlebarHeight;
    return windowContent;
}

- (void)setRootView:(TUIView *)aView {
    if([_popoverRootView isEqualTo:aView]) return;
    [self initializeFrame];
    
	if(_popoverRootView)
        [_popoverRootView removeFromSuperview];
	_popoverRootView = aView;
    
	[frameView.nsView setRootView:_popoverRootView];
}

- (void)setContentView:(NSView *)aView {
	if([_popoverContentView isEqualTo:aView]) return;
    [self initializeFrame];
    
	if(_popoverContentView)
        [_popoverContentView removeFromSuperview];
	_popoverContentView = aView;
    
	[_popoverContentView setFrame:[self contentRectForFrameRect:self.frame]];
	[_popoverContentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[frameView addSubview:_popoverContentView];
}

- (void)initializeFrame {
    CGRect bounds = self.frame;
	bounds.origin = NSZeroPoint;
    
	frameView = [super contentView];
	if(!frameView) {
		frameView = [[TUIPanelFrame alloc] initWithFrame:bounds];
        if(self.styleMask & NSClosableWindowMask) {
            NSSize buttonSize = TUIPanelButtonSize;
            NSRect buttonRect = NSMakeRect(TUIPanelButtonMargin,
                                           NSMaxY(frameView.bounds) - (TUIPanelButtonMargin + buttonSize.height),
                                           buttonSize.width, buttonSize.height);
            NSButton *closeButton = [[NSButton alloc] initWithFrame:buttonRect];
            [closeButton setCell:[[TUIWindowButtonCell alloc] init]];
            [closeButton setButtonType:NSMomentaryChangeButton];
            [closeButton setTarget:self];
            [closeButton setAction:@selector(close)];
            [closeButton setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
            [frameView addSubview:closeButton];
        }
        
		[super setContentView:frameView];
	}
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

/* disabled
- (void)keyDown:(NSEvent *)event {
	if([@"\e" isEqualToString:[event charactersIgnoringModifiers]] &&
       ([self styleMask] & NSClosableWindowMask) == NSClosableWindowMask)
		 [self close];
	else [super keyDown:event];
}//*/

- (void)mouseDown:(NSEvent *)event {
    NSRect titleBarRect = NSMakeRect(0.f, NSMaxY(frameView.bounds) - TUIPanelTitlebarHeight,
                                     frameView.bounds.size.width, TUIPanelTitlebarHeight);
	NSPoint originalMouseLocation = [self convertBaseToScreen:[event locationInWindow]];
	NSRect originalFrame = [self frame];
    
    if(NSPointInRect([event locationInWindow], titleBarRect)) {
        while(YES) {
            NSEvent *newEvent = [self nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
            if([newEvent type] == NSLeftMouseUp)
                break;
            
            NSPoint newMouseLocation = [self convertBaseToScreen:[newEvent locationInWindow]];
            NSPoint delta = NSMakePoint(newMouseLocation.x - originalMouseLocation.x,
                                        newMouseLocation.y - originalMouseLocation.y);
            
            NSRect newFrame = originalFrame;
            newFrame.origin.x += delta.x;
            newFrame.origin.y += delta.y;
            
            [self setFrame:newFrame display:YES animate:NO];
        }
    }
}

- (void)center {
	[self setFrame:NSOffsetRect(self.frame, NSMidX(self.screen.visibleFrame) - NSMidX(self.frame), 
                                NSMidY(self.screen.visibleFrame) - NSMidY(self.frame)) display:YES];
}

- (BOOL)needsPanelToBecomeKey:(NSView *)v {
	NSEnumerator *e;
	if([v needsPanelToBecomeKey])
		return YES;
	e = [[v subviews] objectEnumerator];
	while((v = [e nextObject]))
		if([self needsPanelToBecomeKey:v])
			return YES;
	return NO;
}

@end

@implementation TUIPanelFrame

@synthesize nsView;

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
        self.nsView = [[TUINSView alloc] initWithFrame:NSMakeRect(0.f, 0.f, self.bounds.size.width,
                                                                 self.bounds.size.height - TUIPanelTitlebarHeight)];
        [nsView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [nsView tui_setOpaque:NO];
        [self addSubview:nsView];
    } return self;
}

- (void)drawRect:(CGRect)dirtyRect {
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 0.5f, 0.5f)
                                                         xRadius:TUIPanelCornerRadius
                                                         yRadius:TUIPanelCornerRadius];
    NSGradient *borderGradient = [[NSGradient alloc] initWithColorsAndLocations:
                                  [NSColor colorWithCalibratedWhite:1.00 alpha:0.925], 0.0,
                                  [NSColor colorWithCalibratedWhite:0.95 alpha:0.925], 1.0, nil];
    
    [NSGraphicsContext saveGraphicsState];
    [path addClip];
    [borderGradient drawInBezierPath:path angle:-90];
    [self drawTitleInRect:NSMakeRect(0.f, NSMaxY(self.bounds) - TUIPanelTitlebarHeight,
                                     self.bounds.size.width, TUIPanelTitlebarHeight)];
    [NSGraphicsContext restoreGraphicsState];
    
    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] set];
    [path stroke];
}

- (void)drawTitleInRect:(NSRect)titleBarRect {
    NSString *title = [[self window] title];
    if(!title) return;
    
    NSShadow *shadow = [NSShadow new];
    [shadow setShadowColor:[NSColor whiteColor]];
    [shadow setShadowOffset:NSMakeSize(0.f, -1.f)];
    [shadow setShadowBlurRadius:2.0f];
    
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    [style setAlignment:NSCenterTextAlignment];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSColor colorWithDeviceWhite:0.15 alpha:0.8], NSForegroundColorAttributeName,
                                [NSFont systemFontOfSize:12.f], NSFontAttributeName,
                                shadow, NSShadowAttributeName,
                                style, NSParagraphStyleAttributeName, nil];
    
    NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:title attributes:attributes];
    NSSize titleSize = attrTitle.size;
    NSRect titleRect = NSMakeRect(0.f, NSMidY(titleBarRect) - (titleSize.height / 2.f),
                                  titleBarRect.size.width, titleSize.height);
    [attrTitle drawInRect:NSIntegralRect(titleRect)];
}

@end

@implementation TUIWindowButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect drawingRect = NSInsetRect(cellFrame, 1.5f, 1.5f);
    drawingRect.origin.y = 0.5f;
    NSRect dropShadowRect = drawingRect;
    dropShadowRect.origin.y += 1.f;
    
    NSBezierPath *dropShadow = [NSBezierPath bezierPathWithOvalInRect:dropShadowRect];
    [[NSColor colorWithDeviceWhite:1.0 alpha:0.6] set];
    [dropShadow stroke];
    
    NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:drawingRect];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.7 alpha:1.0]
                                                         endingColor:[NSColor colorWithDeviceWhite:0.5 alpha:1.0]];
    [gradient drawInBezierPath:circle angle:270.f];
    
    if([self isHighlighted]) {
        [[NSColor colorWithDeviceWhite:0.0 alpha:0.3] set];
        [circle fill];
    }
    
    NSBezierPath *cross = [NSBezierPath bezierPath];
    CGFloat boxDimension = floor(drawingRect.size.width * cos(45.f)) - 1.0f;
    CGFloat origin = round((drawingRect.size.width - boxDimension) / 2.f);
    NSRect boxRect = NSMakeRect(1.f + origin, origin, boxDimension, boxDimension);
    NSPoint bottomLeft = NSMakePoint(boxRect.origin.x, NSMaxY(boxRect));
    NSPoint topRight = NSMakePoint(NSMaxX(boxRect), boxRect.origin.y);
    NSPoint bottomRight = NSMakePoint(topRight.x, bottomLeft.y);
    NSPoint topLeft = NSMakePoint(bottomLeft.x, topRight.y);
    
    [cross moveToPoint:bottomLeft];
    [cross lineToPoint:topRight];
    [cross moveToPoint:bottomRight];
    [cross lineToPoint:topLeft];
    
    [[NSColor colorWithDeviceWhite:0.95 alpha:1.0] set];
    [cross setLineWidth:2.f];
    [cross stroke];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:0.3 alpha:0.2]];
    [shadow setShadowBlurRadius:1.0f];
    [shadow setShadowOffset:NSMakeSize(0.f, -1.f)];
    
    NSRect shadowRect = drawingRect;
    shadowRect.size.height = origin;
    [NSGraphicsContext saveGraphicsState];
    [NSBezierPath clipRect:shadowRect];
    [NSGraphicsContext saveGraphicsState];
	
	NSSize offset = shadow.shadowOffset;
	NSSize originalOffset = offset;
	CGFloat radius = shadow.shadowBlurRadius;
    
	NSRect bounds = NSInsetRect(circle.bounds, -(ABS(offset.width) + radius), -(ABS(offset.height) + radius));
	offset.height += bounds.size.height;
	shadow.shadowOffset = offset;
    
	NSAffineTransform *transform = [NSAffineTransform transform];
	if([[NSGraphicsContext currentContext] isFlipped])
		 [transform translateXBy:0 yBy:bounds.size.height];
	else [transform translateXBy:0 yBy:-bounds.size.height];
	
	NSBezierPath *drawingPath = [NSBezierPath bezierPathWithRect:bounds];
	[drawingPath setWindingRule:NSEvenOddWindingRule];
	[drawingPath appendBezierPath:circle];
	[drawingPath transformUsingAffineTransform:transform];
	
	[circle addClip];
	[shadow set];
	[[NSColor blackColor] set];
	[drawingPath fill];
	
	shadow.shadowOffset = originalOffset;
	[NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext restoreGraphicsState];
}

@end