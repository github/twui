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

#import "TUIGeometry.h"

const TUIEdgeInsets TUIEdgeInsetsZero = { .top = 0.0f, .left = 0.0f, .bottom = 0.0f, .right = 0.0f };

NSString* NSStringFromTUIEdgeInsets(TUIEdgeInsets insets) {
	return [NSString stringWithFormat:@"{%lg, %lg, %lg, %lg}", insets.top, insets.left, insets.bottom, insets.right];
}

TUIEdgeInsets TUIEdgeInsetsFromNSString(NSString *string) {
	TUIEdgeInsets result = TUIEdgeInsetsZero;
	
	if(string != nil) {
		double top, left, bottom, right;
		sscanf(string.UTF8String, "{%lg, %lg, %lg, %lg}", &top, &left, &bottom, &right);
		result = TUIEdgeInsetsMake(top, left, bottom, right);
	}
	
	return result;
}

@implementation NSValue (TUIExtensions)

+ (NSValue *)tui_valueWithTUIEdgeInsets:(TUIEdgeInsets)insets {
	return [NSValue valueWithBytes:&insets objCType:@encode(TUIEdgeInsets)];
}

- (TUIEdgeInsets)tui_TUIEdgeInsetsValue {
	TUIEdgeInsets insets = TUIEdgeInsetsZero;
	[self getValue:&insets];
	return insets;
}

@end
