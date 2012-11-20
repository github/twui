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

#import "NSAffineTransform+TUIExtensions.h"

@implementation NSAffineTransform (TUIExtensions)

+ (NSAffineTransform *)tui_transformWithCGAffineTransform:(CGAffineTransform)transform {
	NSAffineTransform *affineTransform = [NSAffineTransform transform];
	affineTransform.transformStruct = (NSAffineTransformStruct) {
		.m11 = transform.a,
		.m12 = transform.b,
		.m21 = transform.c,
		.m22 = transform.d,
		.tX = transform.tx,
		.tY = transform.ty
	};
	
	return affineTransform;
}

- (CGAffineTransform)tui_CGAffineTransform {
	NSAffineTransformStruct transform = self.transformStruct;
	
	return (CGAffineTransform) {
		.a = transform.m11,
		.b = transform.m12,
		.c = transform.m21,
		.d = transform.m22,
		.tx = transform.tX,
		.ty = transform.tY
	};
}

@end


