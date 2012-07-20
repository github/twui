#import "TUIView.h"
#import "TUINSWindow.h"
#import "TUIViewController.h"
#import "CAAnimation+TUIExtensions.h"

#define CGRectNoEdge (CGRectEdge)-1

@class TUIPopover;
@class TUIPopoverWindow;

typedef enum {
    TUIPopoverBehaviorApplicationDefined = 0,
    TUIPopoverBehaviorTransient = 1,
    
    // Currently not supported, here for forwards compatibility purposes.
    TUIPopoverBehaviorSemiTransient = 2
} TUIPopoverBehavior;

typedef enum {
    TUIPopoverAppearanceMinimal = 0,
    TUIPopoverAppearanceHUD = 1
} TUIPopoverAppearance;

typedef void (^TUIPopoverDelegateBlock)(TUIPopover *popover);

extern NSString *const TUIPopoverCloseReasonKey;
extern NSString *const TUIPopoverCloseReasonStandard;
extern NSString *const TUIPopoverCloseReasonDetachToWindow;

// Notes:
//
// - Window Blurring using CGSPrivate.
// Hmm, doesn't seem to be working for some odd reason. Also need to add a define
// macro to disable this if the application is a Mac App Store applicant.
//
// - Pop In Animation.
// There has to be a better and simpler way, using CAKeyframeAnimations to
// somehow animate the window's transform/scale to create the NSPopover's
// usual "pop in" effect. This is all I could think of for now.
//
// - Content Inset.
// There's some odd wonky behavior with the content inset for the container view.
// Not sure why, or how to fix it yet. I assume it's with an NSInsetRect()?
//
// - Tracking View frame changes.
// Right now, the popover doesn't move with the view. i.e, if I launch a popover
// from a table view cell, and then scroll, the popover remains in the same place.
// I assume we could make the views KVO compliant and observe changes to do this.
//
// - HUD Appearance.
// Does NOT look the same as the standard NSPopover... I wish I knew how to get it to
// look the same. Looks more like the Dock stacks popups.

@interface TUIPopover : TUIResponder

@property (nonatomic, retain) IBOutlet TUIViewController *contentViewController;

// CGSizeZero uses the size of the view on contentViewController.
@property (nonatomic, assign) CGSize contentSize;

@property (nonatomic, assign) BOOL animates;
@property (nonatomic, assign) TUIPopoverAppearance appearance;
@property (nonatomic, assign) TUIPopoverBehavior behavior;
@property (nonatomic, readonly, getter = isShown) BOOL shown;
@property (nonatomic, readonly) CGRect positioningRect;

@property (nonatomic, copy) TUIPopoverDelegateBlock willCloseBlock;
@property (nonatomic, copy) TUIPopoverDelegateBlock didCloseBlock;

@property (nonatomic, copy) TUIPopoverDelegateBlock willShowBlock;
@property (nonatomic, copy) TUIPopoverDelegateBlock didShowBlock;

- (id)initWithContentViewController:(TUIViewController *)viewController;
- (id)initWithContentView:(TUIView *)view;

- (void)showRelativeToRect:(CGRect)positioningRect ofView:(TUIView *)positioningView preferredEdge:(CGRectEdge)preferredEdge;

- (void)close;
- (void)closeWithFadeoutDuration:(NSTimeInterval)duration;
- (IBAction)performClose:(id)sender;

@end
