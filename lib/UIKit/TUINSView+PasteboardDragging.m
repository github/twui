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

#import "TUINSView+PasteboardDragging.h"

@implementation TUINSView (PasteboardDragging)

@dynamic draggingTypesByViews;

- (void)registerForDraggedTypes:(NSArray *)draggedTypes forView:(TUIView *)view {
	[self.draggingTypesByViews removeObjectForKey:@(view.hash)];
	if(draggedTypes)
		[self.draggingTypesByViews setObject:draggedTypes forKey:@(view.hash)];
	
	NSMutableArray *types = [NSMutableArray array];
	NSArray *keys = [self.draggingTypesByViews allKeys];
	
	for(NSObject *key in keys) {
		NSArray *viewTypes = [self.draggingTypesByViews objectForKey:key];
		
		for(NSObject *type in viewTypes) {
			if(![types containsObject:type])
				[types addObject:type];
		}
	}
	
	[self registerForDraggedTypes:types];
}

- (TUIView *)viewForDraggingInfo:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForLocationInWindow:sender.draggingLocation];
	
	while(view) {
		NSArray *types = [self.draggingTypesByViews objectForKey:@(view.hash)];
		if(types && [sender.draggingPasteboard availableTypeFromArray:types])
			return view;
		
		view = view.superview;
	}
	
	return nil;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(view)
		return [view draggingEntered:sender];
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(view)
		return [view draggingUpdated:sender];
	return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(view)
		[view draggingExited:sender];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(view)
		[view draggingEnded:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(view)
		return [view prepareForDragOperation:sender];
	return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(view)
		return [view performDragOperation:sender];
	return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(view)
		[view concludeDragOperation:sender];
}

- (void)updateDraggingItemsForDrag:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(view)
		[view updateDraggingItemsForDrag:sender];
}

@end
