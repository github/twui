//
//  TUINavigationController.m
//  TwUI
//
//  Created by Max Goedjen on 11/12/12.
//
//

#import "TUINavigationController.h"
#import "TUIView.h"

@interface TUINavigationController ()

@property (nonatomic) NSMutableArray *stack;

@end

static CGFloat const TUINavigationControllerAnimationDuration = 0.25f;

@implementation TUINavigationController

- (id)initWithRootViewController:(TUIViewController *)viewController {
	self = [super init];
	if (self) {
		_stack = [@[] mutableCopy];
		[_stack addObject:viewController];
		viewController.navigationController = self;
		self.view.clipsToBounds = YES;
	}
	return self;
}

- (void)loadView {
	self.view = [[TUIView alloc] initWithFrame:CGRectZero];
	self.view.backgroundColor = [NSColor lightGrayColor];
	
	TUIViewController *visible = [self topViewController];
	
	[visible viewWillAppear:NO];
	if ([self.delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
		[self.delegate navigationController:self willShowViewController:visible animated:NO];
	}
	
	[self.view addSubview:visible.view];
	visible.view.frame = self.view.bounds;
	visible.view.autoresizingMask = TUIViewAutoresizingFlexibleSize;
	
	[visible viewDidAppear:YES];
	if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
		[self.delegate navigationController:self didShowViewController:visible animated:NO];
	}

}

#pragma mark - Properties

- (NSArray *)viewControllers {
	return [NSArray arrayWithArray:_stack];
}

- (TUIViewController *)topViewController {
	return [_stack lastObject];
}

#pragma mark - Methods
- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
	[self setViewControllers:viewControllers animated:animated completion:nil];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {	
	CGFloat duration = (animated ? TUINavigationControllerAnimationDuration : 0);

	TUIViewController *viewController = [viewControllers lastObject];
	BOOL containedAlready = ([_stack containsObject:viewController]);
	
	[CATransaction begin];
	//Push if it's not in the stack, pop back if it is
	[self.view addSubview:viewController.view];
	viewController.view.frame = (containedAlready ? TUINavigationOffscreenLeftFrame(self.view.bounds) : TUINavigationOffscreenRightFrame(self.view.bounds));
	[CATransaction flush];
	[CATransaction commit];

	TUIViewController *last = [self topViewController];

	for (TUIViewController *controller in _stack) {
		controller.navigationController = nil;
	}
	[_stack removeAllObjects];
	[_stack addObjectsFromArray:viewControllers];
	for (TUIViewController *controller in viewControllers) {
		controller.navigationController = self;
	}
	
	[TUIView animateWithDuration:duration animations:^{
		last.view.frame = (containedAlready ? TUINavigationOffscreenRightFrame(self.view.bounds) : TUINavigationOffscreenLeftFrame(self.view.bounds));
		viewController.view.frame = self.view.bounds;
	} completion:^(BOOL finished) {
		[last.view removeFromSuperview];
		
		[viewController viewDidAppear:animated];
		if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
			[self.delegate navigationController:self didShowViewController:viewController animated:animated];
		}
		
		[last viewDidDisappear:animated];
		
		if (completion) {
			completion(finished);
		}
		
	}];
}

- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated {
	[self pushViewController:viewController animated:animated completion:nil];
}

- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {

	TUIViewController *last = [self topViewController];
	[_stack addObject:viewController];
	viewController.navigationController = self;

	CGFloat duration = (animated ? TUINavigationControllerAnimationDuration : 0);
		
	[last viewWillDisappear:animated];
	
	
	[viewController viewWillAppear:animated];
	if ([self.delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
		[self.delegate navigationController:self willShowViewController:viewController animated:animated];
	}
	
	[self.view addSubview:viewController.view];
	
	//Make sure the app draws the frame offscreen instead of just 'popping' it in
	[CATransaction begin];
	viewController.view.frame = TUINavigationOffscreenRightFrame(self.view.bounds);
	[CATransaction flush];
	[CATransaction commit];

	[TUIView animateWithDuration:duration animations:^{
		last.view.frame = TUINavigationOffscreenLeftFrame(self.view.bounds);
		viewController.view.frame = self.view.bounds;
	} completion:^(BOOL finished) {
		[last.view removeFromSuperview];
		
		[viewController viewDidAppear:animated];
		if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
			[self.delegate navigationController:self didShowViewController:viewController animated:animated];
		}

		[last viewDidDisappear:animated];
		
		if (completion) {
			completion(finished);
		}
		
	}];
}

- (TUIViewController *)popViewControllerAnimated:(BOOL)animated {
	return [self popViewControllerAnimated:animated completion:nil];
}

- (TUIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
	if ([_stack count] <= 1) {
		NSLog(@"Not enough view controllers on stack to pop");
		return nil;
	}
	TUIViewController *popped = [_stack lastObject];
	[self popToViewController:_stack[([_stack count] - 2)] animated:animated completion:completion];
	return popped;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
	return [self popToRootViewControllerAnimated:animated completion:nil];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
	if ([[self topViewController] isEqual:_stack[0]] == YES) {
		return @[];
	}
	return [self popToViewController:_stack[0] animated:animated completion:completion];
}

- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated {
	return [self popToViewController:viewController animated:animated completion:nil];
}

- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
	if ([_stack containsObject:viewController] == NO) {
		NSLog(@"View controller %@ is not in stack", viewController);
		return @[];
	}
	
	TUIViewController *last = [_stack lastObject];
	
	NSMutableArray *popped = [@[] mutableCopy];
	while ([viewController isEqual:[_stack lastObject]] == NO) {
		[popped addObject:[_stack lastObject]];
		[(TUIViewController *)[_stack lastObject] setNavigationController:nil];
		[_stack removeLastObject];
	}
	
	
	[self.view addSubview:viewController.view];
	viewController.view.frame = TUINavigationOffscreenLeftFrame(self.view.bounds);
	
	CGFloat duration = (animated ? TUINavigationControllerAnimationDuration : 0);

	[last viewWillDisappear:animated];
	
	[viewController viewWillAppear:animated];
	if ([self.delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
		[self.delegate navigationController:self willShowViewController:viewController animated:animated];
	}
	
	[TUIView animateWithDuration:duration animations:^{
		last.view.frame = TUINavigationOffscreenRightFrame(self.view.bounds);
		viewController.view.frame = self.view.bounds;
	} completion:^(BOOL finished) {
		[last.view removeFromSuperview];
		
		[viewController viewDidAppear:animated];
		if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
			[self.delegate navigationController:self didShowViewController:viewController animated:animated];
		}

		[last viewDidDisappear:animated];
		
		if (completion) {
			completion(finished);
		}
		
	}];

	
	return popped;
}

#pragma mark - Private

static inline CGRect TUINavigationOffscreenLeftFrame(CGRect bounds) {
	CGRect offscreenLeft = bounds;
	offscreenLeft.origin.x -= bounds.size.width;
	return offscreenLeft;
}

static inline CGRect TUINavigationOffscreenRightFrame(CGRect bounds) {
	CGRect offscreenRight = bounds;
	offscreenRight.origin.x += bounds.size.width;
	return offscreenRight;
}

@end
