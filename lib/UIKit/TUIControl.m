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
#import "TUIControl+Private.h"
#import "TUIView+Accessibility.h"
#import "TUINSView.h"

@implementation TUIControl

- (id)initWithFrame:(CGRect)rect
{
	self = [super initWithFrame:rect];
	if(self == nil) {
		return nil;
	}
	
	self.accessibilityTraits |= TUIAccessibilityTraitButton;
	
	return self;
}


- (BOOL)isEnabled
{
	return !_controlFlags.disabled;
}

- (void)setEnabled:(BOOL)e
{
	[self _stateWillChange];
	_controlFlags.disabled = !e;
	[self _stateDidChange];
	[self setNeedsDisplay];
}

- (BOOL)isTracking
{
	return _controlFlags.tracking;
}

- (TUIControlState)state
{
	// Start with the normal state, then OR in an implicit
	// state that is based on other properties.
	TUIControlState actual = TUIControlStateNormal;
	
	if(_controlFlags.disabled)			actual |= TUIControlStateDisabled;
	if(_controlFlags.selected)			actual |= TUIControlStateSelected;
	if(_controlFlags.tracking)			actual |= TUIControlStateHighlighted;
	if(_controlFlags.highlighted)		actual |= TUIControlStateHighlighted;
	if(![self.nsView isWindowKey])		actual |= TUIControlStateNotKey;
	
	return actual;
}

/**
 * @brief Determine if this control is in a selected state
 * 
 * Not all controls have a selected state and the meaning of "selected" is left
 * to individual control implementations to define.
 * 
 * @return selected or not
 * 
 * @note This is a convenience interface to the #state property.
 * @see #state
 */
-(BOOL)selected {
  return _controlFlags.selected;
}

/**
 * @brief Specify whether this control is in a selected state
 * 
 * Not all controls have a selected state and the meaning of "selected" is left
 * to individual control implementations to define.
 * 
 * @param selected selected or not
 * 
 * @see #state
 */
-(void)setSelected:(BOOL)selected {
	[self _stateWillChange];
	_controlFlags.selected = selected;
	[self _stateDidChange];
	[self setNeedsDisplay];
}

- (BOOL)highlighted {
	return _controlFlags.highlighted;
}

- (void)setHighlighted:(BOOL)highlighted {
	[self _stateWillChange];
	_controlFlags.highlighted = highlighted;
	[self _stateDidChange];
	[self setNeedsDisplay];
}

- (BOOL)acceptsFirstMouse
{
	return _controlFlags.acceptsFirstMouse;
}

- (void)setAcceptsFirstMouse:(BOOL)s
{
	_controlFlags.acceptsFirstMouse = s;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return self.acceptsFirstMouse;
}

- (void)mouseDown:(NSEvent *)event {
	if(_controlFlags.disabled)
		return;
	[super mouseDown:event];
	
	BOOL track = [self beginTrackingWithEvent:event];
	if(track && !_controlFlags.tracking) {
		[self _stateWillChange];
		_controlFlags.tracking = 1;
		[self _stateDidChange];
	} else if(!track) {
		[self _stateWillChange];
		_controlFlags.tracking = 0;
		[self _stateDidChange];
	}
	
	if(_controlFlags.tracking) {
		TUIControlEvents currentEvents = (([event clickCount] >= 2) ?
										  TUIControlEventMouseDownRepeat :
										  TUIControlEventMouseDown);
		
		[self sendActionsForControlEvents:currentEvents];
		[self setNeedsDisplay];
	}
}

- (void)mouseDragged:(NSEvent *)event {
	if(_controlFlags.disabled)
		return;
	[super mouseDragged:event];
	
	if(_controlFlags.tracking) {
		BOOL track = [self continueTrackingWithEvent:event];
		if(track) {
			[self _stateWillChange];
			_controlFlags.tracking = 1;
			[self _stateDidChange];
		} else {
			[self _stateWillChange];
			_controlFlags.tracking = 0;
			[self _stateDidChange];
		}
		
		if(_controlFlags.tracking) {
			TUIControlEvents currentEvents = (([self eventInside:event])?
											  TUIControlEventMouseDragInside :
											  TUIControlEventMouseDragOutside);
			
			[self sendActionsForControlEvents:currentEvents];
			[self setNeedsDisplay];
		}
	}
	
}

- (void)mouseUp:(NSEvent *)event {
	if(_controlFlags.disabled)
		return;
	[super mouseUp:event];
	
	if(_controlFlags.tracking) {
		[self endTrackingWithEvent:event];
		
		TUIControlEvents currentEvents = (([self eventInside:event])?
										  TUIControlEventMouseUpInside :
										  TUIControlEventMouseUpOutside);
		
		[self sendActionsForControlEvents:currentEvents];
		[self setNeedsDisplay];
		
		[self _stateWillChange];
		_controlFlags.tracking = 0;
		[self _stateDidChange];
	}
}

// Support tracking cancelation.
- (void)willMoveToSuperview:(TUIView *)newSuperview {
	if(!_controlFlags.disabled && _controlFlags.tracking) {
		[self _stateWillChange];
		_controlFlags.tracking = 0;
		[self _stateDidChange];

		[self cancelTrackingWithEvent:nil];
		[self setNeedsDisplay];
	}
}

- (void)willMoveToWindow:(TUINSWindow *)newWindow {
	if(!_controlFlags.disabled && _controlFlags.tracking) {
		[self _stateWillChange];
		_controlFlags.tracking = 0;
		[self _stateDidChange];

		[self cancelTrackingWithEvent:nil];
		[self setNeedsDisplay];
	}
}

- (void)windowDidResignKey {
	if(!_controlFlags.disabled && _controlFlags.tracking) {
		[self _stateWillChange];
		_controlFlags.tracking = 0;
		[self _stateDidChange];
		
		[self cancelTrackingWithEvent:nil];
		[self setNeedsDisplay];
	}
}

// Override.
- (BOOL)beginTrackingWithEvent:(NSEvent *)event {
	return YES;
}

- (BOOL)continueTrackingWithEvent:(NSEvent *)event {
	return YES;
}

- (void)endTrackingWithEvent:(NSEvent *)event {
	return;
}

- (void)cancelTrackingWithEvent:(NSEvent *)event {
	return;
}

@end
