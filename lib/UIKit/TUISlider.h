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

// A TUISlider is a visual control used to select a single value
// from a continuous range of values. Sliders are always displayed as
// horizontal or vertical bars. An indicator, or thumb, notes the current
// value of the slider and can be moved by the user to change the setting.
@interface TUISlider : TUIControl
// If you change the value of this property, and the current value of
// the receiver is below the new minimum, the current value is adjusted
// to match the new minimum value automatically.
// The default value of this property is 0.0.
@property (nonatomic, assign) CGFloat minimumValue;

// If you change the value of this property, and the current value of
// the receiver is above the new maximum, the current value is adjusted
// to match the new maximum value automatically.
// The default value of this property is 1.0.
@property (nonatomic, assign) CGFloat maximumValue;

// Setting this property causes the receiver to redraw itself using
// the new value. If you try to set a value that is below the minimum
// or above the maximum value, the minimum or maximum value is set
// instead. The default value of this property is 0.0.
@property (nonatomic, assign) CGFloat value;

// The thickness of the slider knob. The thickness is defined to be the
// extent of the knob along the long dimension of the bar. In a vertical
// slider, then, a knob’s thickness is its height; in a horizontal slider,
// a knob’s thickness is its width. The default value of this property is 0.0.
@property (nonatomic, assign) CGFloat knobThickness;

// The number of the slider's tick marks. The tick marks assigned to
// the minimum and maximum values are included.
@property (nonatomic, assign) NSUInteger numberOfTickMarks;

// Draw the tick marks on the alternate side of the slider - for a
// vertical slider, this draws the ticks on the top, and for a horizontal
// slider, this draws the ticks on the right side instead of left.
// This method has no effect if no tick marks have been assigned (that
// is, numberOfTickMarks returns 0).
@property (nonatomic, assign) BOOL drawTickMarksOnAlternateSide;

// Set YES if the slider's values should be fixed to the values represented
// by its tick marks; otherwise NO. For example, if a slider has a minimum
// value of 0, a maximum value of 100, and five markers, the allowable
// values are 0, 25, 50, 75, and 100. When users move the slider’s knob, it
// jumps to the tick mark nearest the cursor when the mouse button is released.
// This method has no effect if the slider has no tick marks.
@property (nonatomic, assign) BOOL snapsToTickMarks;

// To customize the drawing of the slider, override both the drawTrack and
// drawKnob blocks, or subclass and override the methods in the new class.
@property (nonatomic, copy) TUIViewDrawRect drawTrack;
@property (nonatomic, copy) TUIViewDrawRect drawKnob;

- (void)drawTrack:(CGRect)rect;
- (void)drawKnob:(CGRect)rect;

// To adjust how the mouse position is evaluated on the slider, subclass and
// override this method, and keep into account the .snapToTickMarks property.
- (CGFloat)sliderValueForPoint:(CGPoint)point;

@end
