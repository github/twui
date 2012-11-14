//
//  TUINavigationController.h
//  TwUI
//
//  Created by Max Goedjen on 11/12/12.
//
//

#import <Foundation/Foundation.h>
#import "TUIViewController.h"

@class TUINavigationController;

@protocol TUINavigationControllerDelegate  <NSObject>

- (void)navigationController:(TUINavigationController *)navigationController willShowViewController:(TUIViewController *)viewController animated:(BOOL)animated;
- (void)navigationController:(TUINavigationController *)navigationController didShowViewController:(TUIViewController *)viewController animated:(BOOL)animated;

@end

@interface TUINavigationController : TUIViewController

@property (nonatomic, readonly) TUIViewController *topViewController;
@property (nonatomic, readonly) NSArray *viewControllers;

@property (nonatomic, assign) id <TUINavigationControllerDelegate> delegate;

- (id)initWithRootViewController:(TUIViewController *)viewController;

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated;
- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated;
- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

- (TUIViewController *)popViewControllerAnimated:(BOOL)animated;
- (TUIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated;
- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;


@end
