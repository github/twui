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

#import "TUIView+PasteboardDragging.h"
#import "TUIView+Private.h"
#import "TUINSView+Private.h"

@implementation TUIView (Dragging)

@dynamic draggingTypes;

- (NSArray *)registeredDraggingTypes {
	return self.draggingTypes;
}

- (void)registerForDraggedTypes:(NSArray *)draggingTypes {
	self.draggingTypes = draggingTypes;
	[self updateRegisteredDraggingTypes];
}

- (void)unregisterDraggedTypes {
	self.draggingTypes = nil;
}

- (void)updateRegisteredDraggingTypes {
	if(self.draggingTypes)
		[self.nsView registerForDraggedTypes:self.draggingTypes forView:self];
}

- (void)dragImage:(NSImage *)anImage at:(NSPoint)viewLocation
		   offset:(NSSize)initialOffset event:(NSEvent *)event
	   pasteboard:(NSPasteboard *)pboard source:(id)sourceObj
		slideBack:(BOOL)slideFlag {
	
	[self.nsView dragImage:anImage at:viewLocation
					offset:initialOffset event:event
				pasteboard:pboard source:sourceObj
				 slideBack:slideFlag];
}

- (BOOL)dragFile:(NSString *)filename fromRect:(NSRect)rect
	   slideBack:(BOOL)aFlag event:(NSEvent *)event {
	
	return [self.nsView dragFile:filename fromRect:rect
					   slideBack:aFlag event:event];
}

- (BOOL)dragPromisedFilesOfTypes:(NSArray *)typeArray
						fromRect:(NSRect)rect source:(id)sourceObject
					   slideBack:(BOOL)aFlag event:(NSEvent *)event {
	
	return [self.nsView dragPromisedFilesOfTypes:typeArray
										fromRect:rect source:sourceObject
									   slideBack:aFlag event:event];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	return [self draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
	
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	
}

- (void)updateDraggingItemsForDrag:(id <NSDraggingInfo>)sender {
	
}

@end
