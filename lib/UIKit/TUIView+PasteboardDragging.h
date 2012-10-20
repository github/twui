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

#import "TUIView.h"

@interface TUIView (Dragging)

@property (nonatomic, copy, getter = registeredDraggingTypes, setter = registerForDraggedTypes:) NSArray *draggingTypes;

- (void)unregisterDraggedTypes;
- (void)updateRegisteredDraggingTypes;

- (void)dragImage:(NSImage *)anImage at:(NSPoint)viewLocation
		   offset:(NSSize)initialOffset event:(NSEvent *)event
	   pasteboard:(NSPasteboard *)pboard source:(id)sourceObj
		slideBack:(BOOL)slideFlag;

- (BOOL)dragFile:(NSString *)filename fromRect:(NSRect)rect
	   slideBack:(BOOL)aFlag event:(NSEvent *)event;

- (BOOL)dragPromisedFilesOfTypes:(NSArray *)typeArray
						fromRect:(NSRect)rect source:(id)sourceObject
					   slideBack:(BOOL)aFlag event:(NSEvent *)event;

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender;
- (void)draggingExited:(id <NSDraggingInfo>)sender;
- (void)draggingEnded:(id <NSDraggingInfo>)sender;

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;

// While a destination may change the dragging images at any time,
// it is recommended to wait until this method is called before
// updating the dragging image. This allows the system to delay
// changing the dragging images until it is likely that the user
// will drop on this destination. Otherwise, the dragging images
// will change too often during the drag which would be distracting
// to the user. The destination may update the dragging images by
// calling one of the -enumerateDraggingItems methods on the sender.
- (void)updateDraggingItemsForDrag:(id <NSDraggingInfo>)sender;

@end
