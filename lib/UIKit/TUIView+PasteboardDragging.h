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

// Returns or sets the types registered for a view. Each element of the array
// is a uniform type identifier. The returned elements are in no particular
// order, but the array is guaranteed not to contain duplicate entries.
// Registering an TUIView object for dragged types automatically makes it a
// candidate destination object for a dragging session. As such, it must
// properly implement some or all of the NSDraggingDestination protocol
// methods. As a convenience, TUIView provides default implementations of
// these methods. See the NSDraggingDestination protocol for details.
// To unregister all dragging types, set this property's value to nil.
@property (nonatomic, copy, getter = registeredDraggingTypes, setter = registerForDraggedTypes:) NSArray *draggingTypes;

// Initiates a dragging operation from the view, allowing the user to drag
// arbitrary data with a specified icon into any application that has window
// or view objects that accept dragged data. The image is the NSImage to be
// dragged. The viewLocation is the location of the image’s lower-left corner,
// in the view's coordinate system. It determines the placement of the dragged
// image under the cursor. When determining the image location you should use
// the mouse down coordinate, provided in the event, rather than the current
// mouse location. The event is the left mouse-down event that triggered the
// dragging operation. The pasteboard that is passed holds the data to be
// transferred to the destination. The source is the object that serves as
// the controller of the dragging operation. It must conform to the
// NSDraggingSource informal protocol and is typically the view itself or
// its NSWindow object. The slideBack boolean determines whether the drag
// image should slide back if it’s rejected. The image slides back to viewLocation
// if slideBack is YES and the image isn’t accepted by the dragging destination.
// If NO, the image doesn't slide back. This method must be invoked only within
// an implementation of the mouseDown: or mouseDragged: methods. Before invoking
// this method, you must place the data to be transferred on the pasteboard. To
// do this, get the drag pasteboard (NSDragPboard), declare the types of the
// data, and then put the data on the pasteboard. This code fragment initiates
// a dragging operation on an image itself (that is, the image is the data to
// be transferred).
- (void)dragImage:(NSImage *)image at:(NSPoint)viewLocation
		   event:(NSEvent *)event pasteboard:(NSPasteboard *)pasteboard
		   source:(id)source slideBack:(BOOL)slideFlag;

// Initiates a dragging operation from the view, allowing the user to drag a
// file icon to any application that has window or view objects that accept
// files. The fullPath is a string that specifies the absolute path for the file
// that is dragged. The passed rect describes the position of the icon in the
// view's coordinate system. The slideBack boolean indicates whether the icon
// being dragged should slide back to its position in the view if the file
// isn’t accepted. The icon slides back to the initial rect if slideBack is
// YES, the file is not accepted by the dragging destination, and the user has
// not disabled icon animation; otherwise it simply disappears. The passed
// event is the mouse-down event from which to initiate the drag operation.
// In particular, its mouse location is used for the offset of the icon being
// dragged. Returns YES if the view successfully initiates the dragging
// operation (which doesn’t necessarily mean the dragging operation concluded
// successfully). Otherwise returns NO. This method must be invoked only within
// an implementation of the mouseDown: method.
- (BOOL)dragFile:(NSString *)filename fromRect:(NSRect)rect
	   slideBack:(BOOL)aFlag event:(NSEvent *)event;

// Initiates a dragging operation from the view, allowing the user to drag
// one or more promised files or directories into any application that has
// window or view objects that accept promised file data. The typeArray is an
// array of file types being promised. The array elements can consist of file
// extensions and HFS types encoded with the NSFileTypeForHFSTypeCode function.
// If promising a directory of files, only include the top directory in the array.
// The passed rect describes the position of the icon in the view's coordinate
// system. The sourceObject serves as the controller of the dragging operation.
// It must conform to the NSDraggingSource informal protocol, and is typically
// the view itself or its NSWindow object. The slideBack boolean indicates
// whether the icon being dragged should slide back to its position in the
// view if the file isn’t accepted. The icon slides back to the initial rect
// if slideBack is YES, the promised files are not accepted by the dragging
// destination, and the user has not disabled icon animation; otherwise it
// simply disappears. The passed event is a mouse-down event object from which
// to initiate the drag operation. In particular, its mouse location is used for
// the offset of the icon being dragged. Returns YES if the drag operation is
// initiated successfully, NO otherwise. This method must be invoked only within
// an implementation of the mouseDown: method. Promised files are files that do
// not exist, yet, but that the drag source promises to create at a file system
// location specified by the drag destination when the drag is successfully dropped.
- (BOOL)dragPromisedFilesOfTypes:(NSArray *)typeArray
						fromRect:(NSRect)rect source:(id)sourceObject
					   slideBack:(BOOL)aFlag event:(NSEvent *)event;

// Invoked when the dragged image enters destination bounds or frame; delegate
// returns dragging operation to perform. Returns one (and only one) of the dragging
// NSDragOperation constants. The default return value (if this method is not
// implemented by the destination) is the value returned by the previous
// draggingEntered: message. Invoked when a dragged image enters the destination
// but only if the destination has registered for the pasteboard data type involved
// in the drag operation. Specifically, this method is invoked when the mouse
// pointer enters the destination’s bounds rectangle (if it is a view object) or
// its frame rectangle (if it is a window object). This method must return a
// value that indicates which dragging operation the destination will perform
// when the image is released. In deciding which dragging operation to return,
// the method should evaluate the overlap between both the dragging operations
// allowed by the source (obtained from sender with the draggingSourceOperationMask
// method) and the dragging operations and pasteboard data types the destination
// itself supports. If none of the operations is appropriate, this method should
// return NSDragOperationNone (this is the default response if the method is not
// implemented by the destination). A destination will still receive draggingUpdated:
// and draggingExited: even if NSDragOperationNone is returned by this method.
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;

// Invoked periodically as the image is held within the destination area, allowing
// modification of the dragging operation or mouse-pointer position. Returns one
// (and only one) of the dragging operation constants described in NSDragOperation
// in the NSDraggingInfo reference. The default return value (if this method is not
// implemented by the destination) is the value returned by the previous draggingEntered:
// message. For this to be invoked, the destination must have registered for the
// pasteboard data type involved in the drag operation. The messages continue until
// the image is either released or dragged out of the window or view. This method
// provides the destination with an opportunity to modify the dragging operation
// depending on the position of the mouse pointer inside of the destination view
// or window object. For example, you may have several graphics or areas of text
// contained within the same view and wish to tailor the dragging operation, or
// to ignore the drag event completely, depending upon which object is underneath
// the mouse pointer at the time when the user releases the dragged image and the
// performDragOperation: method is invoked. You typically examine the contents of
// the pasteboard in the draggingEntered: method, where this examination is performed
// only once, rather than in the draggingUpdated: method, which is invoked multiple
// times. Only one destination at a time receives a sequence of draggingUpdated:
// messages. If the mouse pointer is within the bounds of two overlapping views
// that are both valid destinations, the uppermost view receives these messages
// until the image is either released or dragged out.
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender;

// Invoked when the dragged image exits the view's bounds rectangle.
- (void)draggingExited:(id <NSDraggingInfo>)sender;

// Implement this method to be notified when a drag operation ends in some other
// destination. This method might be used by a destination doing auto-expansion
// in order to collapse any auto-expands.
- (void)draggingEnded:(id <NSDraggingInfo>)sender;

// Invoked when the image is released, allowing the receiver to agree to or
// refuse drag operation. Returns YES if the receiver agrees to perform the drag
// operation and NO if not. This method is invoked only if the most recent
// draggingEntered: or draggingUpdated: message returned an acceptable drag-operation
// value. If you want the drag items to animate from their current location on
// screen to their final location in your view, set the sender object’s
// animatesToDestination property to YES in your implementation of this method.
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;

// Invoked after the released image has been removed from the screen, signaling the
// receiver to import the pasteboard data. If the destination accepts the data,
// it returns YES; otherwise it returns NO. The default is to return NO. For
// this method to be invoked, the previous prepareForDragOperation: message must
// have returned YES. The destination should implement this method to do the real
// work of importing the pasteboard data represented by the image. If the sender
// object’s animatesToDestination was set to YES in prepareForDragOperation:,
// then setup any animation to arrange space for the drag items to animate to.
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;

// Invoked when the dragging operation is complete, signaling the view to perform
// any necessary clean-up. For this method to be invoked, the previous
// performDragOperation: must have returned YES. The destination implements this method
// to perform any tidying up that it needs to do, such as updating its visual
// representation now that it has incorporated the dragged data. This message is the
// last message sent from sender to the destination during a dragging session. If the
// sender object’s animatesToDestination property was set to YES in
// prepareForDragOperation:, then the drag image is still visible. At this point you
// should draw the final visual representation in the view. When this method returns,
// the drag image is removed form the screen. If your final visual representation
// matches the visual representation in the drag, this is a seamless transition.
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;

// While a destination may change the dragging images at any time, it is recommended
// to wait until this method is called before updating the dragging image. This
// allows the system to delay changing the dragging images until it is likely that
// the user will drop on this destination. Otherwise, the dragging images will change
// too often during the drag which would be distracting to the user. The destination
// may update the dragging images by calling one of the sender's enumeration methods.
- (void)updateDraggingItemsForDrag:(id <NSDraggingInfo>)sender;

@end
