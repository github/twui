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

#import "TUIView+Private.h"
#import "TUITextRenderer.h"
#import "TUINSWindow.h"

@implementation TUIView (Private)

- (NSArray *)textRenderers
{
	return _textRenderers;
}

- (void)setTextRenderers:(NSArray *)renderers
{
	_currentTextRenderer = nil;
	
	for(TUITextRenderer *renderer in _textRenderers) {
		renderer.view = nil;
		[renderer setNextResponder:nil];
	}
	
	_textRenderers = renderers;

	for(TUITextRenderer *renderer in _textRenderers) {
		[renderer setNextResponder:self];
		renderer.view = self;
	}
}

- (TUITextRenderer *)textRendererAtPoint:(CGPoint)point
{
	for(TUITextRenderer *r in _textRenderers) {
		if(CGRectContainsPoint(r.frame, point))
			return r;
	}
	return nil;
}

- (void)_updateLayerScaleFactor
{
	if([self nsWindow] != nil) {
		[self.subviews makeObjectsPerformSelector:_cmd];
		
		CGFloat scale = 1.0f;
		if([[self nsWindow] respondsToSelector:@selector(backingScaleFactor)]) {
			scale = [[self nsWindow] backingScaleFactor];
		}
		
		if([self.layer respondsToSelector:@selector(setContentsScale:)]) {
			self.layer.contentsScale = scale;
			[self setNeedsDisplay];
		}
	}
}

@end

@implementation TUIConstraintNode

@synthesize constraints = _constraints;
@synthesize incomingEdges = _incomingEdges;
@synthesize outgoingEdges = _outgoingEdges;

+ (id)nodeWithConstraints:(NSArray *)theConstraints {
    return [[TUIConstraintNode alloc] initWithConstraints:theConstraints];
}

- (id)initWithConstraints:(NSArray *)theConstraints {
    if((self = [super init])) {
        _constraints = theConstraints;
        _outgoingEdges = [NSMutableArray array];
        _incomingEdges = [NSMutableArray array];
    } return self;
}

- (void)addIncoming:(TUIConstraintNode *)aNode {
    if(![self.incomingEdges containsObject:aNode])
        [(NSMutableArray *)self.incomingEdges addObject:aNode];
}

- (void)addOutgoing:(TUIConstraintNode *)aNode {
    if(![self.outgoingEdges containsObject:aNode])
        [(NSMutableArray *)self.outgoingEdges addObject:aNode];
}

- (void)removeOutgoing:(TUIConstraintNode *)aNode {
    if([self.outgoingEdges containsObject:aNode])
        [(NSMutableArray *)self.outgoingEdges removeObject:aNode];
}

- (void)removeIncoming:(TUIConstraintNode *)aNode {
    if([self.incomingEdges containsObject:aNode])
        [(NSMutableArray *)self.incomingEdges removeObject:aNode];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Node %p constrains: %@", self, self.constraints];
}

@end