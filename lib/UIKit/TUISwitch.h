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

@interface TUISwitch : TUIControl

@property (nonatomic, assign, getter = isOn) BOOL on;
@property (nonatomic, readonly, getter = knobIsGripped) BOOL knobGripped;

@property (nonatomic, copy) CGFloat (^knobInset)(void);
@property (nonatomic, copy) CGFloat (^knobWidth)(void);
@property (nonatomic, copy) CGPathRef (^knobTrackMask)(void);
@property (nonatomic, copy) TUIViewDrawRect drawTrack;
@property (nonatomic, copy) TUIViewDrawRect drawTrackOutline;
@property (nonatomic, copy) TUIViewDrawRect drawKnob;

- (void)setOn:(BOOL)on animated:(BOOL)animated;

- (void)configureModernSwitch;
- (void)configureClassicSwitch;

@end
