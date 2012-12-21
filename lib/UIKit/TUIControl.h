/*
 Copyright 2011 Twitter, Inc.
 
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

typedef enum TUIControlEvents : NSUInteger {
	
	// A mouse down event in the control.
	TUIControlEventMouseDown			= 1 << 0,
	
	// A mouse down multi-click event in the control.
	// -[NSEvent clickCount] will return > 1.
	TUIControlEventMouseDownRepeat		= 1 << 1,
	
	// A mouse drag within the bounds of the control.
	TUIControlEventMouseDragInside		= 1 << 2,
	
	// A mouse drag that leaves the bounds of the control.
	TUIControlEventMouseDragOutside		= 1 << 3,
	
	/*
	 Does not support:
	 TUIControlEventMouseDragEnter		= 1 << 4,
	 TUIControlEventMouseDragExit		= 1 << 5,
	 */
	
	// A mouse up event inside the control.
	TUIControlEventMouseUpInside		= 1 << 6,
	
	// A mouse up event outside the control.
	TUIControlEventMouseUpOutside		= 1 << 7,
	
	// A canceled mouse up event, due to system reasons.
	TUIControlEventMouseCancel			= 1 << 8,
	
	// A mouse hover begin event that a control is tracking.
	TUIControlEventMouseHoverBegan		= 1 << 9,
	
	// A mouse hover end event that a control stops tracking.
	TUIControlEventMouseHoverEnded		= 1 << 10,
	
	// A manipulated control caused to emit a series of different values.
	TUIControlEventValueChanged			= 1 << 12,
	
	// A TUITextField editing session was begun, changed, or ended.
	TUIControlEventEditingDidBegin		= 1 << 16,
	TUIControlEventEditingChanged		= 1 << 17,
	TUIControlEventEditingDidEnd		= 1 << 18,
	TUIControlEventEditingDidEndOnExit	= 1 << 19,
	
	// All mouse events.
	TUIControlEventAllMouseEvents		= 0x00000FFF,
	
	// All TUITextField editing session events.
	TUIControlEventAllEditingEvents		= 0x000F0000,
	
	// A range of control-event values available for application use.
	TUIControlEventApplicationReserved	= 0x0F000000,
	
	// A range of control-event values reserved for framework use.
	TUIControlEventSystemReserved		= 0xF0000000,
	
	// All events, including reserved system events.
	TUIControlEventAllEvents			= 0xFFFFFFFF
} TUIControlEvents;

typedef enum TUIControlState : NSUInteger {
	
	// The default state of a control. It is enabled, but not selected or highlighted.
	TUIControlStateNormal			= 0,
	
	// The highlighted state of a control. A control enters this
	// state when a mouse enters and exits during tracking and
	// when there is a mouse up event. You can retrieve and set
	// this value through the highlighted property.
	TUIControlStateHighlighted		= 1 << 0,
	
	// the disabled state of a control. This state indicates that
	// the control is currently disabled. You can retrieve and
	// set this value through the enabled property.
	TUIControlStateDisabled			= 1 << 1,
	
	// The selected state of a control. For many controls, this
	// state has no effect on behavior or appearance. But other
	// subclasses may have different appearance depending on
	// their selected state. You can retrieve and set this value
	// through the selected property.
	TUIControlStateSelected			= 1 << 2,
	
	// The state of a control when a mouse cursor is hovering upon
	// it. This state can also be read through the tracking property.
	TUIControlStateHover			= 1 << 3,
	
	TUIControlStateNotKey			= 1 << 11,
	
	// Additional control-state flags available for application use.
	TUIControlStateApplication		= 0x00FF0000,
	
	// Additional control-state flags reserved for framework use.
	TUIControlStateReserved			= 0xFF000000
} TUIControlState;

// TUIControl is the base class for control objects such as
// buttons and sliders that convey user intent to the application.
// You cannot use the TUIControl class directly to instantiate
// controls. It instead defines the common interface and behavioral
// structure for all its subclasses. The main role of TUIControl is
// to define an interface and base implementation for preparing
// action messages and initially dispatching them to their targets
// when certain events occur. The TUIControl class also includes
// methods for getting and setting control state—for example,
// for determining whether a control is enabled or highlighted—and
// it defines methods for tracking the mouse within a control. These
// tracking methods are overridden by TUIControl subclasses.
@interface TUIControl : TUIView

// One or more TUIControlState bit-mask constants that specify the
// state of the TUIControl object. Note that the control can be in
// more than one state, for example, both disabled and selected.
@property (nonatomic, readonly) TUIControlState state;

// Allows the control to accept the window-activating mouse click
// as a mouse event as well. The default value is NO.
@property (nonatomic, assign) BOOL acceptsFirstMouse;

// If a control should animate changes between its previous state,
// and its current state, set this property to YES. The default
// value varies per control, but is initially NO.
@property (nonatomic, assign) BOOL animateStateChange;

// The value is YES if the receiver is tracking mouse events; otherwise NO.
@property (nonatomic, readonly, getter = isTracking) BOOL tracking;

// If the control's enabled state is NO, the control ignores
// events and subclasses may draw differently.
@property (nonatomic, assign, getter = isEnabled) BOOL enabled;

// For many controls, this state has no effect on behavior or
// appearance. But other subclasses or the application object
// might read or set this control state.
@property (nonatomic, assign, getter = isSelected) BOOL selected;

// By default, a control is not highlighted. TUIControl automatically
// sets and clears this state automatically when the mouse enters
// and exits during tracking and when there is a mouse up.
@property (nonatomic, assign, getter = isHighlighted) BOOL highlighted;

// If a control sends TUIControlEventValueChanged actions, then the
// value of this property is used to determine whether the action
// is sent periodically on an interval, or discretely, only when the
// action has been finalized. The default value is NO.
@property (nonatomic, assign, getter = isContinuous) BOOL continuous;

// If a control's .continuous property value is set to YES, the
// .periodicDelay property corresponds to the periodic delay
// between each sent action. The default value is 75ms (0.075 seconds).
@property (nonatomic, assign) NSTimeInterval periodicDelay;

// These methods should be used to react to a state change.
// The default method implementation does nothing, but if you
// are subclassing a subclass of TUIControl, such as TUIButton,
// you must call the superclass implementation of the method.
- (void)stateWillChange;
- (void)stateDidChange;

// If the user changed the global control tint (presumably from
// within the System Preferences application), this method will be
// called to allow the TUIControl object to adjust itself.
- (void)systemControlTintChanged;

// As your custom control changes a state property, it is
// recommended the control assign the state using this method.
// This automatically invokes -stateWillChange and -stateDidChange,
// and calls -setNeedsDisplay or animates -redraw if required.
- (void)applyStateChangeAnimated:(BOOL)animated block:(void (^)(void))block;

// When control tracking begins, usually by mouse down or
// swipe start, this method is called to validate the event.
// If YES is returned, tracking will continue, otherwise
// if NO is returned, tracking ends there itself.
- (BOOL)beginTrackingWithEvent:(NSEvent *)event;

// If the control opts to continue tracking, then this method
// will be continuously called to validate each event in the
// chain of tracking events, and should be used to update the
// control view to reflect tracking changes. If YES is returned,
// the control continues to receive tracking events. If NO
// is returned, tracking ends there itself.
- (BOOL)continueTrackingWithEvent:(NSEvent *)event;

// When control tracking ends, this method is called to allow
// the control to clean up. It is NOT called when the control
// opts to cancel it - only when the user cancels the tracking.
- (void)endTrackingWithEvent:(NSEvent *)event;

// Add target/action for a particular event. You can call this
// multiple times and you can specify multiple target/actions
// for a particular event. Passing in nil as the target goes
// up the responder chain. The action may optionally include
// the sender and the event as parameters, in that order.
// Ex: - (void)method:(id)sender event:(NSEvent *)event;
// 
// The action cannot be NULL. You may also choose to submit a block
// as an action for a control event mask. You may add any
// number of blocks as well.
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents;
- (void)addActionForControlEvents:(TUIControlEvents)controlEvents block:(void(^)(void))action;

// Remove the target and action for a set of events. Pass NULL
// for the action to remove all actions for that target. You
// may not, however, remove a block target, due to its unidentifiablity.
- (void)removeTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents;

// Get all targets, actions, and control events registered.
// May include NSNull to indicate at least one nil target.
- (NSSet *)allTargets;
- (TUIControlEvents)allControlEvents;

// Returns an NSArray of NSString selectors names or nil if none.
- (NSArray *)actionsForTarget:(id)target forControlEvent:(TUIControlEvents)controlEvent;

// As a TUIControl subclass, these methods enable you to dispatch
// actions when an event occurs.
// The first -sendAction:to:forEvent: method call is for the event
// and is a point at which you can observe or override behavior.
// It is then called repeately after the second call to this method.
// To observe or modify the dispatch of action messages to targets
// for particular events, override sendAction:to:forEvent:, evaluate
// the passed-in selector, target object, or TUIControlEvents bit
// mask, and proceed as required.
- (void)sendAction:(SEL)action to:(id)target forEvent:(NSEvent *)event;

// TUIControl implements this method to send all action messages associated
// with controlEvents, repeatedly invoking sendAction:to:forEvent: in the
// process. The list of targets and actions it looks up is constructed from
// prior invocations of addTarget:action:forControlEvents:.
- (void)sendActionsForControlEvents:(TUIControlEvents)controlEvents;

@end
