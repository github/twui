#import "ExampleSectionHeaderView.h"

@implementation ExampleSectionHeaderView

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		self.labelRenderer = [[TUITextRenderer alloc] init];
		self.textRenderers = @[self.labelRenderer];
		self.opaque = YES;
		
		// Add a switch to ourselves, as a simple demo.
		self.switchControl = [[TUISwitch alloc] initWithFrame:CGRectZero];
		[self addSubview:self.switchControl];
		
		// Randomize the switch type as a showcase.
		// The default is configured as a modern switch.
		if(arc4random() % 2)
			[self.switchControl configureClassicSwitch];
		
		// Add a nice bevel effect to the switch.
		self.switchControl.layer.shadowColor = [NSColor whiteColor].CGColor;
		self.switchControl.layer.shadowOffset = CGSizeMake(0, -1);
		self.switchControl.layer.shadowRadius = 1.0f;
		self.switchControl.layer.shadowOpacity = 1.0f;
	}
	return self;
}

// The header will be pinned.
- (void)headerWillBecomePinned {
	[super headerWillBecomePinned];
	
	self.opaque = NO;
	self.switchControl.on = YES;
}

// The header will be unpinned.
- (void)headerWillBecomeUnpinned {
	[super headerWillBecomeUnpinned];
	
	self.opaque = YES;
	self.switchControl.on = NO;
}

- (void)drawRect:(CGRect)rect {
	
	// If we're not pinned, don't be transparent.
	if(!self.pinnedToViewport) {
		[[NSColor whiteColor] set];
		NSRectFill(self.bounds);
    }
    
	// Draw a gradient, slightly opaque.
    NSColor *start = [NSColor colorWithCalibratedWhite:0.8 alpha:0.9];
    NSColor *end = [NSColor colorWithCalibratedWhite:0.9 alpha:0.9];
	NSGradient *gradient = [[NSGradient alloc] initWithColors:@[start, end]];
    [gradient drawInRect:self.bounds angle:90.0f];
    
	// Stroke a 1 point border at the base.
    [[start shadowWithLevel:0.1] set];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
    
	// Layout our section label and draw it.
    CGFloat labelHeight = 18;
    self.labelRenderer.frame = CGRectMake(15, roundf((self.bounds.size.height - labelHeight) / 2.0),
										  self.bounds.size.width - 30, labelHeight);
    [self.labelRenderer draw];
}

- (void)layoutSubviews {
	
	// Since we've been told to layout our subviews, layout our switch.
	// Right in the middle. The switchSize allows us to elongate or fatten
	// the switch, without mucking with the frame creation below.
	CGSize switchSize = CGSizeMake(64, 24);
	self.switchControl.frame = (CGRect) {
		.origin.x = CGRectGetMidX(self.bounds) - (switchSize.width / 2),
		.origin.y = CGRectGetMidY(self.bounds) - (switchSize.height / 2),
		.size = switchSize
	};
}

@end
