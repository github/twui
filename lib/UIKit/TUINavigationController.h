//
//  TUINavigationController.h
//  TwUI
//
//  Created by Max Goedjen on 11/12/12.
//
//

#import <Foundation/Foundation.h>
#import "TUIViewController.h"

@interface TUINavigationController : TUIViewController

@property (nonatomic, readonly) TUIViewController *topViewController;
@property (nonatomic, readonly) NSArray *viewControllers;

- (id)initWithRootViewController:(TUIViewController *)viewController;

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated;

- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated;
- (TUIViewController *)popViewControlerAnimated:(BOOL)animated;
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;
- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated;


@end
