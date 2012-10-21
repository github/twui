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

typedef void (^TUIImageViewHandler)(void);

@interface TUIImageView : TUIView

// The initial value of this property is the image passed into the
// initWithImage: method or nil if you initialized the receiver using
// a different method. If the animationImages property contains a
// value other than nil, the contents of this property are not used.
// Setting the image property does not change the size of a TUIImageView.
// Call sizeToFit to adjust the size of the view to match the image.
@property (nonatomic, strong) NSImage *image;

// The initial value of this property is the image passed into the
// initWithImage:highlightedImage: method or nil if you initialized
// the receiver using a different method. If the highlightedAnimationImages
// property contains a value other than nil, it is not used.
@property (nonatomic, strong) NSImage *highlightedImage;

// This property determines whether the regular or highlighted
// images are used. When highlighted is set to YES, a non-animated
// image will use the highlightedImage property and an animated
// image will use the highlightedAnimationImages. If both of those
// properties are set to nil or if highlighted is set to NO, it
// will use the image and animationImages properties.
@property (nonatomic, assign, getter = isHighlighted) BOOL highlighted;

// Set whether or not to allow a new image to be dragged into the frame.
// If YES, the user can drag a new image into the image view's frame, and
// overwrite the old image, otherwise, NO. The default value is NO.
@property (nonatomic, assign, getter = isEditable) BOOL editable;

// Set whether or not to allow drag-to-desktop saving of the image view's
// image. If YES, the user can drag the image out to the desktop, and save it
// using the specified filename as a Portable Network Graphics [PNG] file.
// The default value is NO;
@property (nonatomic, assign, getter = isSavable) BOOL savable;

// Set whether a newly dragged image causes the image view to resize itself
// to fit. If NO, the image is scaled to fit the bounds. The default is NO.
@property (nonatomic, assign) BOOL editingSizesToFit;

// If the image view is allowed to save the file, the savedFilename is
// used as the file name of the saved image with the savedFileType extension.
// By default, it is set to "Photo". If a file with this name already exists,
// it is not overwritten, but a count extension is added to the file.
// i.e. "Photo.png" exists, so "Photo (n).png" is used, where n is the
// number of pre-existing files with  an identical filename.
@property (nonatomic, strong) NSString *savedFilename;

// If the image view is allowed to save the file, the savedFiletype is
// used as the file type of the saved image. The default is NSPNGFileType.
@property (nonatomic, assign) NSBitmapImageFileType savedFiletype;

// An array of NSImages to use for an animation. The array must contain
// NSImage objects. You may use the same image object more than once in
// the array. Setting this property to a value other than nil hides the
// image represented by the image property. Defaults to nil.
@property (nonatomic, copy) NSArray *animationImages;

// An array of NSImages to use for an animation when the view is highlighted.
// The array must contain NSImage objects. You may use the same image more than
// once in the array. Setting this property to a value other than nil hides the
// image represented by the highlightedImage property. Defaults to nil.
@property (nonatomic, copy) NSArray *highlightedAnimationImages;

// The amount of time it takes to go through one cycle of the images.
// The time duration is measured in seconds. The default value of this
// property is equal to the number of images multiplied by 1/30th of
// a second. Thus, if you had 30 images, the value would be 1 second.
@property (nonatomic, assign) NSTimeInterval animationDuration;

// Specifies the number of times to repeat the animation. The default
// value is 0, which specifies to repeat the animation indefinitely.
@property (nonatomic, assign) NSInteger animationRepeatCount;

// Block-based callbacks that allow you to be notified of when the image view
// has been edited, by dragging in a new image, or when it has been saved,
// by dragging it out to the desktop.
@property (nonatomic, copy) TUIImageViewHandler imageEditedHandler;
@property (nonatomic, copy) TUIImageViewHandler imageSavedHandler;

// Returns an image view initialized with the specified image. This method
// adjusts the frame of the receiver to match the size of the specified image.
// It also disables user interactions for the image view by default.
- (id)initWithImage:(NSImage *)image;

// Returns an image view initialized with the specified regular and
// highlighted images. This method adjusts the frame of the receiver to
// match the size of the specified image. It also disables user
// interactions for the image view by default.
- (id)initWithImage:(NSImage *)image highlightedImage:(NSImage *)highlightedImage;

// Starts animating the images in animationImages, always starting the
// animation from the first image in the array.
- (void)startAnimating;

// Stops animating the images in the animationImages.
- (void)stopAnimating;

// Returns YES if the image view animation is running; otherwise, NO.
- (BOOL)isAnimating;

@end