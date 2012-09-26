#import "TUIRefreshControl.h"
#import "TUIActivityIndicatorView.h"
#import "TUICGAdditions.h"
#import "NSColor+TUIExtensions.h"

static CGFloat const TUIRefreshTotalHeight = 350;
static CGFloat const TUIRefreshMinTopPadding = 9;
static CGFloat const TUIRefreshMaxTopPadding = 5;
static CGFloat const TUIRefreshMinTopRadius = 12.5;
static CGFloat const TUIRefreshMaxTopRadius = 16;
static CGFloat const TUIRefreshMinBottomRadius = 3;
static CGFloat const TUIRefreshMaxBottomRadius = 16;
static CGFloat const TUIRefreshMinBottomPadding = 4;
static CGFloat const TUIRefreshMaxBottomPadding = 6;
static CGFloat const TUIRefreshMinArrowSize = 2;
static CGFloat const TUIRefreshMaxArrowSize = 3;
static CGFloat const TUIRefreshMinArrowRadius = 5;
static CGFloat const TUIRefreshMaxArrowRadius = 7;
static CGFloat const TUIRefreshMaxDistance = 53;
static CGFloat const TUIRefreshTableThreshhold = 20;

static inline CGFloat lerp(CGFloat a, CGFloat b, CGFloat p) {
	return a + (b - a) * p;
}

@interface TUIRefreshControl ()

@property (nonatomic, assign, readwrite) BOOL refreshing;

@property (nonatomic, assign) TUITableView *tableView;
@property (nonatomic, strong) TUIActivityIndicatorView *activity;

@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) CAShapeLayer *arrowLayer;

@end

@implementation TUIRefreshControl

- (id)initInTableView:(TUITableView *)tableView {
	if((self = [super initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, TUIRefreshTotalHeight)])) {
		self.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
		
		self.tableView = tableView;
		[self.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
		[self.tableView setPullDownView:self];
		
		self.activity = [[TUIActivityIndicatorView alloc] initWithActivityIndicatorStyle:TUIActivityIndicatorViewStyleGray];
		self.activity.autoresizingMask = TUIViewAutoresizingFlexibleLeftMargin | TUIViewAutoresizingFlexibleRightMargin;
		self.activity.alpha = 0.0f;
		[self addSubview:self.activity];
		
		self.refreshing = NO;
		self.tintColor = [NSColor colorWithCalibratedRed:155.0 / 255.0 green:162.0 / 255.0 blue:172.0 / 255.0 alpha:1.0];
		
		self.shapeLayer = [CAShapeLayer layer];
		self.shapeLayer.fillColor = [_tintColor tui_CGColor];
		self.shapeLayer.strokeColor = [[[NSColor darkGrayColor] colorWithAlphaComponent:0.5] tui_CGColor];
		self.shapeLayer.lineWidth = 0.5;
		self.shapeLayer.shadowColor = [[NSColor blackColor] tui_CGColor];
		self.shapeLayer.shadowOffset = CGSizeMake(0, 1);
		self.shapeLayer.shadowOpacity = 0.4;
		self.shapeLayer.shadowRadius = 0.5;
		[self.layer addSublayer:self.shapeLayer];
		
		self.arrowLayer = [CAShapeLayer layer];
		self.arrowLayer.strokeColor = [[[NSColor darkGrayColor] colorWithAlphaComponent:0.5] tui_CGColor];
		self.arrowLayer.lineWidth = 0.5;
		self.arrowLayer.fillColor = [[NSColor whiteColor] tui_CGColor];
		[self.shapeLayer addSublayer:self.arrowLayer];
	}
	
	return self;
}

- (void)dealloc {
	[self.tableView removeObserver:self forKeyPath:@"contentOffset"];
	self.tableView = nil;
}

- (void)willMoveToSuperview:(TUIView *)newSuperview {
	[super willMoveToSuperview:newSuperview];
	
	if(!newSuperview) {
		[self.tableView removeObserver:self forKeyPath:@"contentOffset"];
		self.tableView = nil;
	}
}

- (void)setEnabled:(BOOL)enabled {
	super.enabled = enabled;
	self.shapeLayer.hidden = !self.enabled;
}

- (void)setTintColor:(NSColor *)tintColor {
	_tintColor = tintColor;
	self.shapeLayer.fillColor = [_tintColor tui_CGColor];
}

- (void)beginRefreshing {
	if(!self.refreshing) {
		CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		alphaAnimation.duration = 0.1f;
		alphaAnimation.toValue = [NSNumber numberWithFloat:0.0f];
		alphaAnimation.fillMode = kCAFillModeForwards;
		alphaAnimation.removedOnCompletion = NO;
		[self.shapeLayer addAnimation:alphaAnimation forKey:nil];
		[self.arrowLayer addAnimation:alphaAnimation forKey:nil];
		
		CGFloat offset = self.tableView.pullOffset.y + self.tableView.bounceOffset.y;
		self.activity.frame = CGRectMake(self.bounds.size.width / 2 - self.activity.bounds.size.width / 2,
										 MAX(TUIRefreshTableThreshhold, -offset + TUIRefreshTableThreshhold),
										 self.activity.bounds.size.width, self.activity.bounds.size.height);
		
		[TUIView animateWithDuration:0.2 animations:^{
			self.activity.alpha = 1.0f;
			[self.activity startAnimating];
		} completion:^(BOOL finished) {
			self.refreshing = YES;
			[self sendActionsForControlEvents:TUIControlEventValueChanged];
		}];
	}
}

- (void)endRefreshing {
	if(self.refreshing) {
		self.refreshing = NO;
		
		[TUIView animateWithDuration:0.4 animations:^{
			self.activity.alpha = 0.0f;
			[self.activity stopAnimating];
			
			[self.tableView scrollToRowAtIndexPath:self.tableView.indexPathForFirstRow
								  atScrollPosition:TUITableViewScrollPositionTop
										  animated:YES];
		} completion:^(BOOL finished) {
			[self.shapeLayer removeAllAnimations];
			[self.arrowLayer removeAllAnimations];
			
			TUIEdgeInsets preInset = self.tableView.contentInset;
			preInset.top = self.bounds.origin.y;
			self.tableView.contentInset = preInset;
			
			self.shapeLayer.position = CGPointZero;
			
			self.shapeLayer.path = nil;
			self.shapeLayer.shadowPath = nil;
			self.arrowLayer.path = nil;
		}];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if(![keyPath isEqualToString:@"contentOffset"])
		return;
	BOOL refreshTriggered = NO;
	
	CGFloat offset = self.tableView.pullOffset.y + self.tableView.bounceOffset.y;
	CGFloat inset = self.bounds.origin.y - offset;
	
	CGFloat verticalShift = MAX(0, -((TUIRefreshMaxTopRadius + TUIRefreshMaxBottomRadius + TUIRefreshMaxTopPadding + TUIRefreshMaxBottomPadding) + offset));
	CGFloat distance = MIN(TUIRefreshMaxDistance, fabs(verticalShift));
	
	if(self.refreshing) {
		CGRect rect = self.activity.frame;
		rect.origin.y = MAX(TUIRefreshTableThreshhold, -offset + TUIRefreshTableThreshhold);
		self.activity.frame = rect;
		
		return;
	}
	
	CGFloat percentage = 1 - (distance / TUIRefreshMaxDistance);
	CGFloat radius = lerp(TUIRefreshMinBottomRadius, TUIRefreshMaxBottomRadius, 0.2);
	
	CGFloat currentTopPadding = lerp(TUIRefreshMinTopPadding, TUIRefreshMaxTopPadding, percentage);
	CGFloat currentTopRadius = lerp(TUIRefreshMinTopRadius, TUIRefreshMaxTopRadius, percentage);
	CGFloat currentBottomRadius = lerp(TUIRefreshMinBottomRadius, TUIRefreshMaxBottomRadius, percentage);
	CGFloat currentBottomPadding =  lerp(TUIRefreshMinBottomPadding, TUIRefreshMaxBottomPadding, percentage);
	
	CGFloat currentArrowSize = lerp(TUIRefreshMinArrowSize, TUIRefreshMaxArrowSize, percentage);
	CGFloat currentArrowRadius = lerp(TUIRefreshMinArrowRadius, TUIRefreshMaxArrowRadius, percentage);
	CGFloat arrowBigRadius = currentArrowRadius + (currentArrowSize / 2);
	CGFloat arrowSmallRadius = currentArrowRadius - (currentArrowSize / 2);
	
	CGPoint topOrigin = CGPointMake(roundf(self.bounds.size.width / 2),
									inset - currentTopPadding - currentTopRadius);
	CGPoint bottomOrigin = topOrigin;
	if(distance != 0) {
		bottomOrigin = CGPointMake(roundf(self.bounds.size.width / 2),
								   inset + offset + currentBottomPadding + currentBottomRadius);
		if(percentage == 0) {
			topOrigin.y -= (fabs(verticalShift) - TUIRefreshMaxDistance);
			refreshTriggered = YES;
		}
	}
	
	CGFloat topY = MAX(TUIRefreshTableThreshhold, topOrigin.y);
	CGFloat bottomY = MAX(TUIRefreshTableThreshhold, bottomOrigin.y);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddArc(path, NULL, topOrigin.x, topY, currentTopRadius, 0, M_PI, NO);
	CGPoint leftCp1 = CGPointMake(lerp((topOrigin.x - currentTopRadius),
									   (bottomOrigin.x - currentBottomRadius), 0.1),
								  lerp(topY, bottomY, 0.2));
	CGPoint leftCp2 = CGPointMake(lerp((topOrigin.x - currentTopRadius),
									   (bottomOrigin.x - currentBottomRadius), 0.9),
								  lerp(topY, bottomY, 0.2));
	CGPoint leftDestination = CGPointMake(bottomOrigin.x - currentBottomRadius, bottomY);
	CGPathAddCurveToPoint(path, NULL, leftCp1.x, leftCp1.y, leftCp2.x, leftCp2.y, leftDestination.x, leftDestination.y);
	
	CGPathAddArc(path, NULL, bottomOrigin.x, bottomY, currentBottomRadius, M_PI, 0, NO);
	CGPoint rightCp2 = CGPointMake(lerp((topOrigin.x + currentTopRadius),
										(bottomOrigin.x + currentBottomRadius), 0.1),
								   lerp(topY, bottomY, 0.2));
	CGPoint rightCp1 = CGPointMake(lerp((topOrigin.x + currentTopRadius),
										(bottomOrigin.x + currentBottomRadius), 0.9),
								   lerp(topY, bottomY, 0.2));
	CGPoint rightDestination = CGPointMake(topOrigin.x + currentTopRadius, topY);
	CGPathAddCurveToPoint(path, NULL, rightCp1.x, rightCp1.y, rightCp2.x, rightCp2.y, rightDestination.x, rightDestination.y);
	CGPathCloseSubpath(path);
	
	CGMutablePathRef arrowPath = CGPathCreateMutable();
	CGPathAddArc(arrowPath, NULL, topOrigin.x, topY, arrowBigRadius, -3 *  M_PI_2, 0, NO);
	CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x,
						 topY + arrowBigRadius - currentArrowSize-3);
	CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x + (2 * currentArrowSize),
						 topY + arrowBigRadius + (currentArrowSize / 2)-3);
	CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x,
						 topY + arrowBigRadius + (2 * currentArrowSize) -3);
	CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x,
						 topY + arrowBigRadius - currentArrowSize-3);
	CGPathAddArc(arrowPath, NULL, topOrigin.x, topY, arrowSmallRadius, 0, -3 *  M_PI_2, YES);
	
	self.shapeLayer.path = path;
	self.arrowLayer.path = arrowPath;
	
	if(refreshTriggered) {
		CGMutablePathRef toPath = CGPathCreateMutable();
		CGPathAddArc(toPath, NULL, topOrigin.x, topOrigin.y, radius, 0, M_PI, YES);
		CGPathAddCurveToPoint(toPath, NULL, topOrigin.x - radius, topOrigin.y,
							  topOrigin.x - radius, topOrigin.y,
							  topOrigin.x - radius, topOrigin.y);
		CGPathAddArc(toPath, NULL, topOrigin.x, topOrigin.y, radius, M_PI, 0, YES);
		CGPathAddCurveToPoint(toPath, NULL, topOrigin.x + radius, topOrigin.y,
							  topOrigin.x + radius, topOrigin.y,
							  topOrigin.x + radius, topOrigin.y);
		CGPathCloseSubpath(toPath);
		
		CGMutablePathRef shotPath = CGPathCreateMutable();
		CGPathMoveToPoint(shotPath, NULL, 0, 0);
		CGPathAddLineToPoint(shotPath, NULL, 0, MAX(TUIRefreshTableThreshhold, -(offset / 2) + TUIRefreshTableThreshhold));
		CGPathCloseSubpath(shotPath);
		
		CABasicAnimation *pathMorph = [CABasicAnimation animationWithKeyPath:@"path"];
		pathMorph.duration = 3.0f;
		pathMorph.fillMode = kCAFillModeForwards;
		pathMorph.removedOnCompletion = NO;
		pathMorph.toValue = (__bridge id)toPath;
		
		CAKeyframeAnimation *shootPathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
		shootPathAnimation.duration = 0.3f;
		shootPathAnimation.path = shotPath;
		shootPathAnimation.calculationMode = kCAAnimationPaced;
		
		CABasicAnimation *shapeAlphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		shapeAlphaAnimation.duration = 0.1f;
		shapeAlphaAnimation.beginTime = CACurrentMediaTime() + 0.1f;
		shapeAlphaAnimation.toValue = [NSNumber numberWithFloat:0.0f];
		shapeAlphaAnimation.fillMode = kCAFillModeForwards;
		shapeAlphaAnimation.removedOnCompletion = NO;
		
		CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		alphaAnimation.duration = 0.1f;
		alphaAnimation.toValue = [NSNumber numberWithFloat:0.0f];
		alphaAnimation.fillMode = kCAFillModeForwards;
		alphaAnimation.removedOnCompletion = NO;
		
		[self.shapeLayer addAnimation:pathMorph forKey:nil];
		[self.shapeLayer addAnimation:shapeAlphaAnimation forKey:nil];
		[self.arrowLayer addAnimation:alphaAnimation forKey:nil];
		[self.shapeLayer addAnimation:shootPathAnimation forKey:nil];
		
		TUIEdgeInsets preInset = self.tableView.contentInset;
		preInset.top = -(self.bounds.origin.y - TUIRefreshMaxDistance);
		self.tableView.contentInset = preInset;
		
		[TUIView animateWithDuration:0.2f animations:^{
			self.activity.alpha = 1.0f;
			self.activity.frame = CGRectMake(self.bounds.size.width / 2 - self.activity.bounds.size.width / 2,
											 MAX(TUIRefreshTableThreshhold, -offset + TUIRefreshTableThreshhold),
											 self.activity.bounds.size.width, self.activity.bounds.size.height);
			[self.activity startAnimating];
			
		}];
		
		self.refreshing = YES;
		[self sendActionsForControlEvents:TUIControlEventValueChanged];
		
		CGPathRelease(toPath);
		CGPathRelease(shotPath);
	}
	
	CGPathRelease(path);
	CGPathRelease(arrowPath);
}

@end
