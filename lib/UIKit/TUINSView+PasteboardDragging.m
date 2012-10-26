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
#import "TUINSView+Private.h"

@implementation TUINSView (PasteboardDragging)

@dynamic draggingTypesByViews;

- (void)dragImage:(NSImage *)anImage at:(NSPoint)viewLocation
		   offset:(NSSize)initialOffset event:(NSEvent *)event
	   pasteboard:(NSPasteboard *)pboard source:(id)sourceObj
		slideBack:(BOOL)slideFlag {
	
	NSImage *dragImage = anImage;
	NSPoint dragLocation = viewLocation;
	if(self.promisedFileDraggingView) {
		dragImage = [self.promisedFileDraggingView dragImageForPromisedFilesOfTypes:self.promisedFileDraggingTypes];
		
		dragLocation.x -= dragImage.size.width / 2;
		dragLocation.y -= dragImage.size.height / 2;
		
		self.promisedFileDraggingView = nil;
		self.promisedFileDraggingTypes = nil;
	}
	
	[super dragImage:dragImage ?: anImage at:dragLocation offset:initialOffset
			   event:event pasteboard:pboard source:sourceObj
		   slideBack:slideFlag];
}

- (BOOL)dragPromisedFilesOfTypes:(NSArray *)typeArray fromRect:(NSRect)rect
						  source:(id)sourceObject slideBack:(BOOL)aFlag event:(NSEvent *)event {
	
	if(self.promisedFileDraggingView) {
		self.promisedFileDraggingTypes = typeArray;
		return [super dragPromisedFilesOfTypes:typeArray fromRect:rect
										source:sourceObject slideBack:aFlag event:event];
	} else {
		return NO;
	}
}

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
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(self.currentDraggingView != view) {
		[self.currentDraggingView draggingExited:sender];
		self.currentDraggingView = nil;
	}
	
	if(view) {
		if(self.currentDraggingView != view) {
			self.currentDraggingView = view;
			return [self.currentDraggingView draggingEntered:sender];
		} else
			return [view draggingUpdated:sender];
	}
	return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	if(self.currentDraggingView) {
		[self.currentDraggingView draggingExited:sender];
		self.currentDraggingView = nil;
	}
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
	if(self.currentDraggingView) {
		[self.currentDraggingView draggingEnded:sender];
		self.currentDraggingView = nil;
	}
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

@end
