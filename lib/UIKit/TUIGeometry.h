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

#import <Foundation/Foundation.h>

// A TUIEdgeInset represents the insetting distance for a rectangle
// represented in CGFloats for the top, left, bottom, and right edges.
typedef struct TUIEdgeInsets {
	CGFloat top, left, bottom, right;
} TUIEdgeInsets;

extern const TUIEdgeInsets TUIEdgeInsetsZero;

// Converts from TUIEdgeInsets into NSString and back.
extern TUIEdgeInsets TUIEdgeInsetsFromNSString(NSString *string);
extern NSString* NSStringFromTUIEdgeInsets(TUIEdgeInsets insets);

// A function initializer for a TUIEdgeInsets structure.
static inline TUIEdgeInsets TUIEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right) {
	return (TUIEdgeInsets){.top = top, .left = left, .bottom = bottom, .right = right};
}

// Insets and returns the given CGRect by the given TUIEdgeInsets.
static inline CGRect TUIEdgeInsetsInsetRect(CGRect rect, TUIEdgeInsets insets) {
	rect.origin.x    += insets.left;
	rect.origin.y    += insets.top;
	rect.size.width  -= (insets.left + insets.right);
	rect.size.height -= (insets.top  + insets.bottom);
	return rect;
}

// Checks member-to-member equality of two TUIEdgeInsets structures.
static inline BOOL TUIEdgeInsetsEqualToEdgeInsets(TUIEdgeInsets insets1, TUIEdgeInsets insets2) {
    return (insets1.left == insets2.left &&
			insets1.top == insets2.top &&
			insets1.right == insets2.right &&
			insets1.bottom == insets2.bottom);
}

// Constrains a point to a rectangular region. If the point
// lies outside the rect, it is adjusted to the nearest point
// that lies inside the rect, then constrained.
static inline CGPoint CGPointConstrainToRect(CGPoint point, CGRect rect) {
	return CGPointMake(MAX(rect.origin.x, MIN((rect.origin.x + rect.size.width), point.x)),
					   MAX(rect.origin.y, MIN((rect.origin.y + rect.size.height), point.y)));
}

@interface NSValue (TUIExtensions)

// Allows NSValue boxing and unboxing of TUIEdgeInsets.
+ (NSValue *)tui_valueWithTUIEdgeInsets:(TUIEdgeInsets)insets;
- (TUIEdgeInsets)tui_TUIEdgeInsetsValue;

@end
