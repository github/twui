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

#import "NSShadow+TUIExtensions.h"

@implementation NSShadow (TUIExtensions)

+ (NSShadow *)tui_shadowWithRadius:(CGFloat)radius offset:(CGSize)offset color:(NSColor *)color {
	CGFloat scale = 1.0f;
	if([NSScreen instancesRespondToSelector:@selector(backingScaleFactor)])
		scale = [[NSScreen mainScreen] backingScaleFactor];
	
	NSShadow *shadow = [[self.class alloc] init];
	shadow.shadowBlurRadius = radius * scale;
	shadow.shadowOffset = CGSizeMake(offset.width * scale, offset.height * scale);
	shadow.shadowColor = color;
	
	return shadow;
}

@end
