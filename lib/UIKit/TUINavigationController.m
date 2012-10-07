//
//  TUINavigationController.m
//  TUINavigationController
//
//  Created by Robert Widmann on 10/6/12.
//  Copyright (c) 2012 CodaFi. All rights reserved.
//

#import "TUINavigationController.h"
#import <TwUI/TUIKit.h>

typedef enum {
	_TUINavigationControllerVisibleControllerTransitionNone = 0,
	_TUINavigationControllerVisibleControllerTransitionPushAnimated,
	_TUINavigationControllerVisibleControllerTransitionPopAnimated
} _TUINavigationControllerVisibleControllerTransition;

static const NSTimeInterval kAnimationDuration = 0.5;

@interface TUINavigationController () {
	_TUINavigationControllerVisibleControllerTransition _visibleViewControllerTransition;
}
@property(nonatomic,retain) TUIViewController *topViewController; // The top view controller on the stack.
@property(nonatomic,retain) TUIViewController *visibleViewController; // Return modal view controller if it exists. Otherwise the top view controller.

@property (nonatomic,assign) BOOL visibleViewControllerNeedsUpdate;
@end

@implementation TUINavigationController

- (id)initWithRootViewController:(TUIViewController *)rootViewController {
	if ((self=[super init])) {
        self.viewControllers = [NSMutableArray arrayWithObject:rootViewController];
		[rootViewController setParentViewController:self];
		[self setVisibleViewController:rootViewController];
    }
    return self;
}

- (void)loadView
{
    self.view = [[TUIView alloc] initWithFrame:CGRectMake(0,0,320,480)];
	[self.view setDrawRect:^(TUIView *v, CGRect rect) {
		[[NSColor clearColor]set];
		NSRectFill(rect);
	}];
	[self.view setAutoresizingMask:TUIViewAutoresizingFlexibleSize];
    
    TUIViewController *viewController = self.visibleViewController;
    viewController.view.frame = [self _controllerFrameForTransition:_TUINavigationControllerVisibleControllerTransitionNone];
    viewController.view.autoresizingMask = TUIViewAutoresizingFlexibleSize;
	
    [self.view addSubview:viewController.view];
}

-(TUIViewController*)topViewController {
	return [self.viewControllers lastObject];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.visibleViewController viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.visibleViewController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.visibleViewController viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.visibleViewController viewDidDisappear:animated];
}

- (CGRect)_controllerFrameForTransition:(_TUINavigationControllerVisibleControllerTransition)transition
{
    CGRect controllerFrame = self.view.bounds;
    
    if (transition == _TUINavigationControllerVisibleControllerTransitionPushAnimated) {
        controllerFrame = CGRectOffset(controllerFrame, controllerFrame.size.width, 0);
    } else if (transition == _TUINavigationControllerVisibleControllerTransitionPopAnimated) {
        controllerFrame = CGRectOffset(controllerFrame, -controllerFrame.size.width, 0);
    }
    
    return controllerFrame;
}

- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated
{
	//no duplicate view controllers allowed.
    assert(![_viewControllers containsObject:viewController]);
	
	if (viewController == nil) {
		NSLog(@"Application attempted to push nil view controller onto target %@", self);
		return;
	}
	
    // override the animated property based on current state
    animated = animated && _visibleViewController;
    
	[viewController.view setAutoresizingMask:TUIViewAutoresizingFlexibleSize];

    // push on to controllers stack
    [_viewControllers addObject:viewController];
    
    // take ownership responsibility
    [viewController setParentViewController:self];
    
	// if animated and on screen, begin part of the transition immediately, specifically, get the new view
    // on screen asap and tell the new controller it's about to be made visible in an animated fashion
	if (animated) {
		_visibleViewControllerTransition = _TUINavigationControllerVisibleControllerTransitionPushAnimated;
		
		viewController.view.frame = [self _controllerFrameForTransition:_visibleViewControllerTransition];
        
		[_visibleViewController viewWillDisappear:YES];
		[viewController viewWillAppear:YES];
        
        if ([_delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
            [_delegate navigationController:self willShowViewController:viewController animated:YES];
        }
		
		[self.view insertSubview:viewController.view atIndex:0];
	}
    
	[self _setVisibleViewControllerNeedsUpdate];
}

- (TUIViewController *)popViewControllerAnimated:(BOOL)animated
{
    // don't allow popping the rootViewController
    if ([_viewControllers count] <= 1) {
        return nil;
    }
    
    TUIViewController *formerTopViewController = self.topViewController;
	
	
	// pop the controller stack
    [_viewControllers removeLastObject];
    
    // give up ownership of the view controller
    [formerTopViewController setParentViewController:nil];
    
	// if animated, begin part of the transition immediately, specifically, get the new top view on screen asap
	// and tell the old visible controller it's about to be disappeared in an animated fashion
	if (animated) {
        // note the new top here so we don't have to use the accessor method all the time
        TUIViewController *topController = self.topViewController;
		
		_visibleViewControllerTransition = _TUINavigationControllerVisibleControllerTransitionPopAnimated;
		
		// if we never updated the visible controller, we need to add the formerTopViewController
		// on to the screen so we can see it disappear since we're attempting to animate this
		if (!_visibleViewController) {
			_visibleViewController = formerTopViewController;
			_visibleViewController.view.frame = [self _controllerFrameForTransition:_TUINavigationControllerVisibleControllerTransitionNone];
			[self.view insertSubview:_visibleViewController.view atIndex:0];
		}
        
		topController.view.frame = [self _controllerFrameForTransition:_visibleViewControllerTransition];
        
		[_visibleViewController viewWillDisappear:YES];
		[topController viewWillAppear:YES];
		
        if ([_delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
            [_delegate navigationController:self willShowViewController:topController animated:YES];
        }
		
		[self.view insertSubview:topController.view atIndex:0];
		
	}
    
	[self _setVisibleViewControllerNeedsUpdate];
	
	return formerTopViewController;
}

- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated
{
    NSMutableArray *popped = [[NSMutableArray alloc] init];
	
    if ([_viewControllers containsObject:viewController]) {
        while (self.topViewController != viewController) {
            TUIViewController *poppedController = [self popViewControllerAnimated:animated];
            if (poppedController) {
                [popped addObject:poppedController];
            } else {
                break;
            }
        }
    }
    
    return [popped copy];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
    return [self popToViewController:[_viewControllers objectAtIndex:0] animated:animated];
}

- (void)setViewControllers:(NSArray *)newViewControllers animated:(BOOL)animated {
	assert([newViewControllers count] >= 1);
	
    if (![newViewControllers isEqualToArray:_viewControllers]) {
        // remove them all in bulk
        [_viewControllers makeObjectsPerformSelector:@selector(_setParentViewController:) withObject:nil];
        [_viewControllers removeAllObjects];
        
        // add them back in one-by-one and only apply animation to the last one (if any)
        for (TUIViewController *controller in newViewControllers) {
            [self pushViewController:controller animated:(animated && (controller == [newViewControllers lastObject]))];
        }
    }
}

- (void)_setVisibleViewControllerNeedsUpdate
{
	// schedules a deferred method to run
	if (!_visibleViewControllerNeedsUpdate) {
		_visibleViewControllerNeedsUpdate = YES;
		[self performSelector:@selector(_updateVisibleViewController) withObject:nil afterDelay:0];
	}
}

- (void)_updateVisibleViewController
{
	// do some bookkeeping
	_visibleViewControllerNeedsUpdate = NO;
    TUIViewController *topViewController = self.topViewController;
    
	// make sure the new top view is both loaded and set to appear in the correct place
	topViewController.view.frame = [self _controllerFrameForTransition:_visibleViewControllerTransition];
    
	if (_visibleViewControllerTransition == _TUINavigationControllerVisibleControllerTransitionNone) {
		[_visibleViewController viewWillDisappear:NO];
		[topViewController viewWillAppear:NO];
        
        if ([_delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
            [_delegate navigationController:self willShowViewController:topViewController animated:NO];
        }
        
		[_visibleViewController.view removeFromSuperview];
		[self.view insertSubview:topViewController.view atIndex:0];
        
		[_visibleViewController viewDidDisappear:NO];
		[topViewController viewDidAppear:NO];
		
        if ([_delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
            [_delegate navigationController:self didShowViewController:topViewController animated:NO];
        }
    } else {
        const CGRect visibleControllerFrame = (_visibleViewControllerTransition == _TUINavigationControllerVisibleControllerTransitionPushAnimated)
		? [self _controllerFrameForTransition:_TUINavigationControllerVisibleControllerTransitionPopAnimated]
		: [self _controllerFrameForTransition:_TUINavigationControllerVisibleControllerTransitionPushAnimated];
		
        const CGRect topControllerFrame = [self _controllerFrameForTransition:_TUINavigationControllerVisibleControllerTransitionNone];
        
        TUIViewController *previouslyVisibleViewController = _visibleViewController;
        
        [TUIView animateWithDuration:kAnimationDuration
                         animations:^(void) {
                             previouslyVisibleViewController.view.frame = visibleControllerFrame;
                             topViewController.view.frame = topControllerFrame;
                         }
                         completion:^(BOOL finished) {
                             [previouslyVisibleViewController.view removeFromSuperview];
                             [previouslyVisibleViewController viewDidDisappear:YES];
                             [topViewController viewDidAppear:YES];
                             
                             if ([_delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
                                 [_delegate navigationController:self didShowViewController:topViewController animated:YES];
                             }
                         }];
	}
    
	_visibleViewController = topViewController;
    
}

@end
