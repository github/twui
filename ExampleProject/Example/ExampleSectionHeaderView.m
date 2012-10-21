#import "ExampleSectionHeaderView.h"

@implementation ExampleSectionHeaderView

@synthesize labelRenderer = _labelRenderer;

/**
 * Clean up
 */

/**
 * Initialize
 */
-(id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		_labelRenderer = [[TUITextRenderer alloc] init];
		self.textRenderers = [NSArray arrayWithObjects:_labelRenderer, nil];
		self.opaque = TRUE;
		
		self.switchControl = [[TUISwitch alloc] initWithFrame:CGRectZero];
		self.switchControl.layer.shadowColor = [NSColor whiteColor].CGColor;
		self.switchControl.layer.shadowOffset = CGSizeMake(0, -1);
		self.switchControl.layer.shadowRadius = 1.0f;
		self.switchControl.layer.shadowOpacity = 1.0f;
		[self addSubview:self.switchControl];
	}
	return self;
}

/**
 * @brief The header will become pinned
 */
-(void)headerWillBecomePinned {
  self.opaque = FALSE;
  [super headerWillBecomePinned];
	[self.switchControl setOn:NO animated:YES];
}

/**
 * @brief The header will become unpinned
 */
-(void)headerWillBecomeUnpinned {
  self.opaque = TRUE;
	[super headerWillBecomeUnpinned];
	[self.switchControl setOn:YES animated:YES];
}

/**
 * Drawing
 */
-(void)drawRect:(CGRect)rect {
  
  CGContextRef g;
  if((g = TUIGraphicsGetCurrentContext()) != nil){
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:g flipped:FALSE]];
    
    if(!self.pinnedToViewport){
      [[NSColor whiteColor] set];
      NSRectFill(self.bounds);
    }
    
    NSColor *start = [NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.8 alpha:0.9];
    NSColor *end = [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha:0.9];
    NSGradient *gradient = nil;
    
    gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
    [gradient drawInRect:self.bounds angle:90];
    
    [[start shadowWithLevel:0.1] set];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
    
    CGFloat labelHeight = 18;
    self.labelRenderer.frame = CGRectMake(15, roundf((self.bounds.size.height - labelHeight) / 2.0), self.bounds.size.width - 30, labelHeight);
    [self.labelRenderer draw];
  }
  
}

- (void)layoutSubviews {
	CGSize switchSize = CGSizeMake(64, 24);
	self.switchControl.frame = (CGRect) {
		.origin.x = CGRectGetMidX(self.bounds) - (switchSize.width / 2),
		.origin.y = CGRectGetMidY(self.bounds) - (switchSize.height / 2),
		.size = switchSize
	};
}

@end
