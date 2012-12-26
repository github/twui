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

#import "TUIControl.h"
#import "TUIView+Accessibility.h"
#import "TUINSView.h"

#pragma mark - Target Action Container

@interface TUIControlTargetAction : NSObject

@property (nonatomic, unsafe_unretained) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, copy) void(^block)(void);
@property (nonatomic, assign) TUIControlEvents controlEvents;

@end

@implementation TUIControlTargetAction
@end

#pragma mark - 

@interface TUIControl () {
	struct {
		unsigned int tracking:1;
		unsigned int acceptsFirstMouse:1;
		unsigned int disabled:1;
		unsigned int selected:1;
		unsigned int highlighted:1;
		unsigned int hover:1;
	} _controlFlags;
}

@property (nonatomic, strong) NSMutableArray *targetActions;

@end

@implementation TUIControl

#pragma mark - Object Lifecycle

- (id)initWithFrame:(CGRect)rect {
	if ((self = [super initWithFrame:rect])) {
		self.periodicDelay = 0.075f;
		self.targetActions = [NSMutableArray array];
		self.accessibilityTraits |= TUIAccessibilityTraitButton;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(controlTintUpdated:)
													 name:NSControlTintDidChangeNotification
												   object:nil];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSControlTintDidChangeNotification
												  object:nil];
}

#pragma mark - Control State and Notifications

- (void)controlTintUpdated:(NSNotification *)note {
	[self systemControlTintChanged];
}

- (void)systemControlTintChanged {
	if (self.animateStateChange) {
		[TUIView animateWithDuration:0.25f animations:^{
			[self redraw];
		}];
	} else [self setNeedsDisplay];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
	return self.acceptsFirstMouse;
}

- (TUIControlState)state {
	TUIControlState actual = TUIControlStateNormal;
	
	if (_controlFlags.disabled)
		actual |= TUIControlStateDisabled;
	if (![self.nsView isWindowKey])
		actual |= TUIControlStateNotKey;
	if (_controlFlags.hover)
		actual |= TUIControlStateHover;
	if (_controlFlags.tracking || _controlFlags.highlighted)
		actual = (actual & ~TUIControlStateHover) | TUIControlStateHighlighted;
	if (_controlFlags.selected)
		actual |= TUIControlStateSelected;
	
	return actual;
}

#pragma mark - Properties

- (BOOL)acceptsFirstMouse {
	return _controlFlags.acceptsFirstMouse;
}

- (void)setAcceptsFirstMouse:(BOOL)s {
	_controlFlags.acceptsFirstMouse = s;
}

- (BOOL)isEnabled {
	return !_controlFlags.disabled;
}

- (void)setEnabled:(BOOL)e {
	[self applyStateChangeAnimated:self.animateStateChange block:^{
		_controlFlags.disabled = !e;
	}];
}

- (BOOL)isTracking {
	return _controlFlags.tracking;
}

- (void)setTracking:(BOOL)t {
	_controlFlags.tracking = t;
}

- (BOOL)isSelected {
	return _controlFlags.selected;
}

- (void)setSelected:(BOOL)selected {
	[self applyStateChangeAnimated:self.animateStateChange block:^{
		_controlFlags.selected = selected;
	}];
}

- (BOOL)isHighlighted {
	return _controlFlags.highlighted;
}

- (void)setHighlighted:(BOOL)highlighted {
	[self applyStateChangeAnimated:self.animateStateChange block:^{
		_controlFlags.highlighted = highlighted;
	}];
}

#pragma mark - User Interaction

- (void)mouseEntered:(NSEvent *)theEvent {
	_controlFlags.hover = 1;
	[self sendActionsForControlEvents:TUIControlEventMouseHoverBegan];
	[self setNeedsDisplay];
}

- (void)mouseExited:(NSEvent *)theEvent {
	_controlFlags.hover = 0;
	[self sendActionsForControlEvents:TUIControlEventMouseHoverEnded];
	[self setNeedsDisplay];
}

- (void)mouseDown:(NSEvent *)event {
	if (_controlFlags.disabled)
		return;
	[super mouseDown:event];
	
	BOOL track = [self beginTrackingWithEvent:event];
	[self applyStateChangeAnimated:self.animateStateChange block:^{
		if (track && !_controlFlags.tracking)
			_controlFlags.tracking = 1;
		else if (!track)
			_controlFlags.tracking = 0;
	}];
	
	if (_controlFlags.tracking) {
		TUIControlEvents currentEvents = (([event clickCount] >= 2) ?
										  TUIControlEventMouseDownRepeat :
										  TUIControlEventMouseDown);
		
		[self sendActionsForControlEvents:currentEvents];
	}
}

- (void)mouseDragged:(NSEvent *)event {
	if (_controlFlags.disabled)
		return;
	[super mouseDragged:event];
	
	if (_controlFlags.tracking) {
		BOOL track = [self continueTrackingWithEvent:event];
		[self applyStateChangeAnimated:self.animateStateChange block:^{
			if (track)
				_controlFlags.tracking = 1;
			else if (!track)
				_controlFlags.tracking = 0;
		}];
		
		if (_controlFlags.tracking) {
			TUIControlEvents currentEvents = (([self eventInside:event])?
											  TUIControlEventMouseDragInside :
											  TUIControlEventMouseDragOutside);
			
			[self sendActionsForControlEvents:currentEvents];
		}
	}
	
}

- (void)mouseUp:(NSEvent *)event {
	if (_controlFlags.disabled)
		return;
	[super mouseUp:event];
	
	if (_controlFlags.tracking) {
		[self endTrackingWithEvent:event];
		
		TUIControlEvents currentEvents = (([self eventInside:event])?
										  TUIControlEventMouseUpInside :
										  TUIControlEventMouseUpOutside);
		
		[self sendActionsForControlEvents:currentEvents];
		[self applyStateChangeAnimated:self.animateStateChange block:^{
			_controlFlags.tracking = 0;
		}];
	}
}

- (void)willMoveToSuperview:(TUIView *)newSuperview {
	if (!_controlFlags.disabled && _controlFlags.tracking) {
		[self applyStateChangeAnimated:self.animateStateChange block:^{
			_controlFlags.tracking = 0;
		}];
		
		[self endTrackingWithEvent:nil];
		[self setNeedsDisplay];
	}
}

- (void)willMoveToWindow:(TUINSWindow *)newWindow {
	if (!_controlFlags.disabled && _controlFlags.tracking) {
		[self applyStateChangeAnimated:self.animateStateChange block:^{
			_controlFlags.tracking = 0;
		}];
		
		[self endTrackingWithEvent:nil];
		[self setNeedsDisplay];
	}
}

- (BOOL)beginTrackingWithEvent:(NSEvent *)event {
	return YES;
}

- (BOOL)continueTrackingWithEvent:(NSEvent *)event {
	return YES;
}

- (void)endTrackingWithEvent:(NSEvent *)event {
	// Implemented by subclasses.
}

#pragma mark - State Change Application

- (void)applyStateChangeAnimated:(BOOL)animated block:(void (^)(void))block {
	[self stateWillChange];
	block();
	[self stateDidChange];
	
	if (animated) {
		[TUIView animateWithDuration:0.25f animations:^{
			[self redraw];
		}];
	} else {
		[self setNeedsDisplay];
	}
}

// Override.
- (void)stateWillChange {
	return;
}

- (void)stateDidChange {
	return;
}

#pragma mark - Target Action Interoptability

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents {
	if (action != nil) {
		TUIControlTargetAction *t = [[TUIControlTargetAction alloc] init];
		t.target = target;
		t.action = action;
		t.controlEvents = controlEvents;
		[self.targetActions addObject:t];
	}
}

- (void)addActionForControlEvents:(TUIControlEvents)controlEvents block:(void(^)(void))block {
	if (block != nil) {
		TUIControlTargetAction *t = [[TUIControlTargetAction alloc] init];
		t.block = block;
		t.controlEvents = controlEvents;
		[self.targetActions addObject:t];
	}
}

- (void)removeTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents {
	NSMutableArray *targetActionsToRemove = [NSMutableArray array];
	for (TUIControlTargetAction *t in self.targetActions) {
		
		BOOL actionMatches = (action == t.action);
		BOOL targetMatches = [target isEqual:t.target];
		BOOL controlMatches = (controlEvents == t.controlEvents);
		
		if ((action && targetMatches && actionMatches && controlMatches) ||
		   (!action && targetMatches && controlMatches))
			[targetActionsToRemove addObject:t];
	}
	
	[self.targetActions removeObjectsInArray:targetActionsToRemove];
}

- (NSSet *)allTargets {
	NSMutableSet *targets = [NSMutableSet set];
	
	for (TUIControlTargetAction *t in self.targetActions)
		[targets addObject:t.target ?: [NSNull null]];
	
	return targets;
}

- (TUIControlEvents)allControlEvents {
	TUIControlEvents e = 0;
	
	for (TUIControlTargetAction *t in self.targetActions)
		e |= t.controlEvents;
	
	return e;
}

- (NSArray *)actionsForTarget:(id)target forControlEvent:(TUIControlEvents)controlEvent {
	NSMutableArray *actions = [NSMutableArray array];
	
	for (TUIControlTargetAction *t in self.targetActions) {
		if ([target isEqual:t.target] && controlEvent == t.controlEvents)
			[actions addObject:NSStringFromSelector(t.action)];
	}
	
	return (actions.count ? actions : nil);
}

- (void)sendAction:(SEL)action to:(id)target forEvent:(NSEvent *)event {
	[NSApp sendAction:action to:target from:self];
}

- (void)sendActionsForControlEvents:(TUIControlEvents)controlEvents {
	for (TUIControlTargetAction *t in self.targetActions) {
		if (t.controlEvents == controlEvents) {
			if (t.target && t.action)
				[self sendAction:t.action to:t.target forEvent:nil];
			else if (t.block)
				t.block();
		}
	}
}

#pragma mark -

@end
