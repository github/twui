/*
 Copyright 2012 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TUIView.h"

@class TUIPopover;
@class TUIViewController;
@protocol TUIPopoverDelegate;

typedef void (^TUIPopoverDelegateBlock)(TUIPopover *popover);
typedef NSWindow * (^TUIPopoverWindowBlock)(TUIPopover *popover);
typedef BOOL (^TUIPopoverConfirmationBlock)();

// The userInfo key containing the reason for the TUIPopoverWillCloseNotification.
// It can currently be either TUIPopoverCloseReasonStandard or
// TUIPopoverCloseReasonDetachToWindow, although more reasons for closing
// may be added in the future.
extern NSString *const TUIPopoverCloseReasonKey;

// Specifies that the popover has been closed because of its behavior.
extern NSString *const TUIPopoverCloseReasonStandard;

// Specifies that the popover has been closed because it is being detached to a window.
extern NSString *const TUIPopoverCloseReasonDetachToWindow;

// Sent before the popover is shown.
extern NSString *const TUIPopoverWillShowNotification;

// Sent after the popover has finished animating onscreen.
extern NSString *const TUIPopoverDidShowNotification;

// Sent before the popover is closed. The userInfo key TUIPopoverCloseReasonKey
// specifies the reason for closing. It can currently be either
// TUIPopoverCloseReasonStandard or TUIPopoverCloseReasonDetachToWindow, although
// more reasons for closing may be added in the future.
extern NSString *const TUIPopoverWillCloseNotification;

// Sent after the popover has finished animating offscreen. This notification
// has the same user info keys as TUIPopoverWillCloseNotification.
extern NSString *const TUIPopoverDidCloseNotification;

typedef enum {
	
	// The application assumes responsibility for closing the popover.
	// The popover will still close itself in a limited number of
	// circumstances. For instance, the popover will attempt to close
	// itself when the window of its positioningView is closed.
	// If escape is pressed, the delegate method or block shouldClose is
	// asked to confirm whether the popover should close or not.
    TUIPopoverBehaviorApplicationDefined,
	
	// The popover will close itself the when the user interacts with
	// interface elements outside the popover or escape is pressed.
	// If escape is pressed, the delegate method or block shouldClose is
	// asked to confirm whether the popover should close or not.
    TUIPopoverBehaviorTransient,
	
	// The popover will close itself when the user interacts with interface
	// elements in the positioning view's window or escape is pressed.
	// If escape is pressed, the delegate method or block shouldClose is
	// asked to confirm whether the popover should close or not.
    TUIPopoverBehaviorSemitransient
} TUIPopoverBehavior;

// The TUIPopover provides a means to display additional content related
// to existing content on the screen. The popover is automatically positioned
// relative to its positioning view and is moved whenever its positioning
// view's window moves. A positioning rectangle within the view can be
// specified for additional granularity. An anchor is used to express the
// relation between these two units of content. A popover has an appearance
// that specifies its visual characteristics, as well as a behavior that
// determines which user interactions will cause the popover to close. A
// transient popover is closed in response to most user interactions,
// whereas a semi-transient popovers is closed when the user interacts
// with the window containing the popover's positioning view. Popovers with
// application-defined behavior are not usually closed on the developer's
// behalf. All popovers will be automatically closed if the positioning view
// is removed from a window. Popovers can be detached to become a separate
// window when they are dragged by implementing a delegate method or block.
//
// UNSUPPORTED FEATURES:
// - Popover to window detaching is currently unsupported.
@interface TUIPopover : NSResponder

// The view controller that manages the content of the popover. You must set
// the content view controller of the popover before the popover is shown.
// Changes to the popover's content view controller while the popover is
// shown will cause the popover to animate if the animates property is YES.
@property (nonatomic, strong) TUIViewController *contentViewController;

// Must be a subclass of TUIPopoverBackgroundView.
@property (nonatomic, unsafe_unretained) Class backgroundViewClass;

// The content size of the popover. The popover's content size is set to
// match the size of the content view when the content view controller is
// set. Changes to the content size of the popover will cause the popover
// to animate while it is shown if the animates property is YES. CGSizeZero
// uses the size of the content view in the contentViewController.
@property (nonatomic, assign) CGSize contentSize;

// Specifies the behavior of the popover.
// The default value is TUIPopoverBehaviorApplicationDefined.
@property (nonatomic, unsafe_unretained) TUIPopoverBehavior behavior;

// Specifies if the popover is to be animated. A popover may be animated
// when it shows, closes, moves, or appears to transition to a detachable
// window. This property also controls whether the popover animates when
// the content view or content size changes. The system does not guarantee
// which behaviors will be animated or that this property will be respected;
// it is regarded as a hint.
@property (nonatomic, assign) BOOL animates;

// The display state of the popover. The value is YES if the popover is
// being shown, NO otherwise. The popover is considered to be shown from
// the point when showRelativeToRect:ofView:preferredEdge: is invoked. A
// popover is closed in response to either close or performClose:.
@property (nonatomic, readonly, getter = isShown) BOOL shown;

// The content size of the popover. Popovers are positioned relative to a
// positioning view and are automatically moved when the location or size
// of the positioning view changes.
@property (nonatomic, readonly) CGRect positioningRect;

// Set the custom popover animations to use when animating in or out. These
// properties are only read when the popover needs to either show or hide.
@property (nonatomic, strong) NSArray *showAnimations;
@property (nonatomic, strong) NSArray *hideAnimations;

// Set the popover animation duration. If the popover animates, this duration
// will be used for its animations. If it is set to a negative value,
// the default duration will be used.
@property (nonatomic, assign) NSTimeInterval animationDuration;

// You can optionally use block callbacks instead of a delegate, in which
// case, both the delegate method and the block will be called. For
// information on the usage of these delegate blocks, refer to the delegate
// methods below. The shouldClose and detachableWindow blocks take priority
// over delegate method calls.
@property (nonatomic, copy) TUIPopoverConfirmationBlock shouldClose;
@property (nonatomic, copy) TUIPopoverWindowBlock detachableWindow;
@property (nonatomic, copy) TUIPopoverDelegateBlock willShowBlock;
@property (nonatomic, copy) TUIPopoverDelegateBlock didShowBlock;
@property (nonatomic, copy) TUIPopoverDelegateBlock willCloseBlock;
@property (nonatomic, copy) TUIPopoverDelegateBlock didCloseBlock;

// The delegate of the popover.
@property (nonatomic, unsafe_unretained) id <TUIPopoverDelegate> delegate;

// Initialize the popover with a view controller, whose view will be used
// as the content view inside the popover.
- (id)initWithContentViewController:(TUIViewController *)viewController;

// Shows the popover anchored to the specified view. The positioningRect
// is the rectangle within positioningView relative to which the popover
// should be positioned. Normally set to the bounds of positioningView.
// May be an empty rectangle, which will default to the bounds of positioningView.
// The positioningView is the view relative to which the popover should be
// positioned. Causes the method to raise NSInvalidArgumentException if nil.
// The preferredEdge is the edge of positioningView the popover should prefer
// to be anchored to. This method raises NSInternalInconsistencyException if
// contentViewController or the view controller’s view is nil.
// If the popover is already being shown, this method does nothing.
- (void)showRelativeToRect:(CGRect)positioningRect
					ofView:(TUIView *)positioningView
			 preferredEdge:(CGRectEdge)preferredEdge;

// Forces the popover to close without consulting its delegate. Any popovers
// nested within the popovers will also receive a close message. When a window
// is closed in response to the close message being sent, all of its popovers
// are closed. The popover animates out when closed unless the animates
// property is set to NO.
- (void)close;

// Attempts to close the popover. The popover will not be closed if it has a
// delegate and the delegate implements the returns popoverShouldClose: method
// returning NO. The operation will fail if the popover is displaying a nested
// popover or if it has a child window. A window will attempt to close its
// popovers when it receives a performClose: message. The popover animates out
// when closed unless the animates property is NO.
- (IBAction)performClose:(id)sender;

@end

@interface TUIPopoverBackgroundView : TUIView

// Returns the size of the background either outset or inset from the
// contentSize provided, and the popoverEdge of the popover.
+ (CGSize)sizeForBackgroundViewWithContentSize:(CGSize)contentSize
								   popoverEdge:(CGRectEdge)popoverEdge;

// Returns the content view frame inset within the frame by an amount
// taking into account the popoverEdge of the popover.
+ (CGRect)contentViewFrameForBackgroundFrame:(CGRect)frame
								 popoverEdge:(CGRectEdge)popoverEdge;

// Returns a popover window offset for the given background frame and
// popover edge, which will shift the popover frame by the returned point.
+ (CGPoint)popoverOffsetForBackgroundFrame:(CGRect)frame
							   popoverEdge:(CGRectEdge)popoverEdge;

// Intitializes a popover background view with a given frame and origin
// screen rectangle in the screen coordinate space, and the popover edge.
- (id)initWithFrame:(CGRect)frame popoverEdge:(CGRectEdge)popoverEdge originScreenRect:(CGRect)originScreenRect;

// Returns a popover background view path for the given popover edge and
// background view frame. Override in subclasses to change the shape of
// the popover, but still use the default drawing. To change the drawing
// of the popover, override the standard drawRect: and add an invocation
// to this method to retrieve the popover path and draw with it.
- (CGPathRef)popoverPathForEdge:(CGRectEdge)popoverEdge inFrame:(CGRect)frame;

@end

@protocol TUIPopoverDelegate <NSObject>
@optional

// Returns YES if the popover should close, NO otherwise. The popover invokes
// this method on its delegate whenever it is about to close to give the
// delegate a chance to veto the close.  If the delegate returns YES,
// -popoverShouldClose: will also be invoked on the popover to allow the
// popover to veto the close.
- (BOOL)popoverShouldClose:(TUIPopover *)popover;

// Return a window to which the popover should be detached.  You should not
// remove the popover's content view as part of your implementation of this
// method. The popover and the detachable window may be shown at the same
// time and therefore cannot share a content view (or a content view controller).
// If the popover and the detachable window should have the same content, you
// should define the content in a separate nib file and use a view controller
// to instantiate separate copies of the content for the popover and the
// detachable window.  The popover will animate to appear as though it morphs
// into the detachable window (unless the animates property is set to NO. The
// exact animation used is not guaranteed).  Subclasses of TUIPopover may also
// implement this method, in which case the subclass method will be invoked
// only if the delegate does not implement the method.
- (NSWindow *)detachableWindowForPopover:(TUIPopover *)popover;

// Invoked on the delegate when the TUIPopoverWillShowNotification
// notification is sent.  This method will also be invoked on the popover.
- (void)popoverWillShow:(NSNotification *)notification;

// Invoked on the delegate when the TUIPopoverDidShowNotification
// notification is sent.  This method will also be invoked on the popover.
- (void)popoverDidShow:(NSNotification *)notification;

// Invoked on the delegate when the TUIPopoverWillCloseNotification
// notification is sent.  This method will also be invoked on the popover.
- (void)popoverWillClose:(NSNotification *)notification;

// Invoked on the delegate when the TUIPopoverDidCloseNotification
// notification is sent.  This method will also be invoked on the popover.
- (void)popoverDidClose:(NSNotification *)notification;

@end
