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

#import "TUICGAdditions.h"
#import "NSShadow+TUIExtensions.h"

@interface NSBezierPath (TUIExtensions)

// Converts a CGPathRef into an NSBezierPath object and back.
+ (NSBezierPath *)tui_bezierPathWithCGPath:(CGPathRef)pathRef;
- (CGPathRef)tui_CGPath CF_RETURNS_RETAINED;

// Fills the given shadow inside the bezier path.
- (void)tui_fillWithInnerShadow:(NSShadow *)shadow;

// Draws a blurred "shadow" inside the bezier path with a color and radius.
- (void)tui_drawBlurWithColor:(NSColor *)color radius:(CGFloat)radius;

// Returns a bezier path with a rounded rectangle in the given
// rect with the selected corners rounded at the given corner radii.
+ (NSBezierPath *)tui_bezierPathWithRoundedRect:(CGRect)rect
                              byRoundingCorners:(TUIRectCorner)corners
                                    cornerRadii:(CGSize)cornerRadii;

// Strokes the bezier path on the inside, instead of the standard outside stroke.
- (void)tui_strokeInside;

// Strokes the bezier path inside a clipped rectangle within the path's bounds.
- (void)tui_strokeInsideWithinRect:(NSRect)clipRect;

@end