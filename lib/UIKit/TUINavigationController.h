//
//  TUINavigationController.h
//  TUINavigationController
//
//  Created by Robert Widmann on 10/6/12.
//  Copyright (c) 2012 CodaFi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TUIViewController.h"
#import "TUIGeometry.h"
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

/*!
 TUINavigationController manages a stack of view controllers and a navigation bar.
 It performs horizontal view transitions for pushed and popped views while keeping the navigation bar in sync.
 */

//Custom animation block for TUINavigationController's -pushViewController:withAnimationBlock;
//Animates all methods called within it for the default duration of a push animation, then cleans up after itself
//Do not call view removal methods on any of the block's parameters, they will be performed for you at the end of animation
typedef void (^TUINavigationAnimationBlock)(TUIViewController *pushingFrom, TUIViewController *pushingTo, CGRect suggestedFrame);

@protocol TUINavigationControllerDelegate;

@interface TUINavigationController : TUIViewController

- (id)initWithRootViewController:(TUIViewController *)rootViewController; // Convenience method pushes the root view controller without animation.

- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated; // Uses a horizontal slide transition. Has no effect if the view controller is already in the stack.

- (void)pushViewController:(TUIViewController *)viewController withAnimationBlock:(TUINavigationAnimationBlock)block; // Uses a pre-defined block transition. Has no effect if the view controller is already in the stack.

- (TUIViewController *)popViewControllerAnimated:(BOOL)animated; // Returns the popped controller.
- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated; // Pops view controllers until the one specified is on top. Returns the popped controllers.
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated; // Pops until there's only a single view controller left on the stack. Returns the popped controllers.

@property(nonatomic,readonly,retain) TUIViewController *topViewController; // The top view controller on the stack.
@property(nonatomic,readonly,retain) TUIViewController *visibleViewController; // Return modal view controller if it exists. Otherwise the top view controller.

@property (nonatomic,strong) NSMutableArray *viewControllers; // The current view controller stack.
- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated; // If animated is YES, then simulate a push or pop depending on whether the new top view controller was previously in the stack.

@property(nonatomic, assign) id<TUINavigationControllerDelegate> delegate;

@end

@protocol TUINavigationControllerDelegate <NSObject>

@optional

// Called when the navigation controller shows a new top view controller via a push, pop or setting of the view controller stack.
- (void)navigationController:(TUINavigationController *)navigationController willShowViewController:(TUIViewController *)viewController animated:(BOOL)animated;
- (void)navigationController:(TUINavigationController *)navigationController didShowViewController:(TUIViewController *)viewController animated:(BOOL)animated;

@end

@interface TUIViewController (TUINavigationControllerItem)

@property(nonatomic,readonly,retain) TUINavigationController *navigationController; // If this view controller has been pushed onto a navigation controller, return it.

@end
