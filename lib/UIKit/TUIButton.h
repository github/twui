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

#import "TUIControl.h"
#import "TUIGeometry.h"

@class TUILabel;
@class TUIImageView;

typedef enum TUIButtonType : NSUInteger {
	// Creates a completely unstyled custom button.
	// Does not respond to the tintColor property.
	TUIButtonTypeCustom,
	
	// Creates a rounded rectangle tintable button that
	// has a drop shadow and a light beveling effect.
	TUIButtonTypeStandard,
	
	// Creates a rounded rectangle tintable button
	// that has a light emboss effect with a flat color.
	TUIButtonTypeFlat,
	
	// Creates a rounded rectangle button that cannot
	// be tinted, but is transparent and attains the
	// base color from the button's superview.
	TUIButtonTypeClear,
	
	// Creates a rounded pill shaped button that has
	// a light border with a light gradient color.
	TUIButtonTypeMinimal,
	
	// Creates a specialized inline button that cannot
	// be styled, but can be used to inline text as
	// selectable. Overrides selectable property as YES.
	TUIButtonTypeInline,
} TUIButtonType;

// An instance of the TUIButton class implements a button on the screen.
// A button intercepts touch events and sends an action message to a
// target object when clicked. Methods for setting the target and action
// are inherited from TUIControl. This class provides methods for setting
// the title, image, and other appearance properties of a button. By using
// these accessors, you can specify a different appearance for each state.
@interface TUIButton : TUIControl

// Indicates the current button type. See TUIButtonType for the possible values.
@property (nonatomic, assign, readonly) TUIButtonType buttonType;

// Use this property to resize and reposition the effective drawing
// rectangle for the button content. The content comprises the button 
// image and button title. The default is TUIEdgeInsetsZero.
@property (nonatomic, assign) TUIEdgeInsets contentEdgeInsets;

// Use this property to resize and reposition the effective drawing
// rectangle for the button title. The default value is UIEdgeInsetsZero.
// The insets you specify are applied to the title rectangle after
// that rectangle has been sized to fit the button’s text. Thus,
// positive inset values may actually clip the title text.
@property (nonatomic, assign) TUIEdgeInsets titleEdgeInsets;

// Use this property to resize and reposition the effective drawing
// rectangle for the button image. The default value is UIEdgeInsetsZero.
@property (nonatomic, assign) TUIEdgeInsets imageEdgeInsets;

// If YES, the button is drawn lighter when the window is not key. The default value is YES.
@property (nonatomic, assign) BOOL dimsInBackground;

// If YES, the image is drawn lighter when the button is highlighted. The default value is YES.
@property (nonatomic, assign) BOOL adjustsImageWhenHighlighted;

// If YES, the image is drawn darker when the button is disabled. The default value is YES.
@property (nonatomic, assign) BOOL adjustsImageWhenDisabled;

// If YES, the shadow changes from engrave to emboss appearance when highlighted. The default value is NO.
@property (nonatomic, assign) BOOL reversesTitleShadowWhenHighlighted;

// If YES, the button can be triggered into a stable selected state and back. The default is NO.
@property (nonatomic, assign, getter = isSelectable) BOOL selectable;

@property (nonatomic, strong, readonly) TUILabel *titleLabel;
@property (nonatomic, strong, readonly) TUIImageView *imageView;

// Allows a pop up menu to be displayed if the button is pressed.
// Setting this overrides selectable property as YES.
@property (nonatomic, strong) NSMenu *menu;

// The button tint color and factor. Depending on the button type, these
// values may be used to tint the button into a different color. The factor
// is used to determine the gradient difference between the start and
// the end color, positioning the tintColor in the center.
@property (nonatomic, strong) NSColor *tintColor;
@property (nonatomic, assign) CGFloat tintFactor;

// This method is a convenience constructor for creating button objects
// with specific configurations. It you subclass TUIButton, this method
// does not return an instance of your subclass. If you want to create
// an instance of a specific subclass, you must alloc/init the button
// directly or override this class method to return your button's newly
// initialized object. You must always call the superclass implementation
// if you are not returning a new button object. When creating a button
// the frame of the button is set to CGRectZero initially. Before adding
// the button to your interface, you should update the frame.
+ (instancetype)buttonWithType:(TUIButtonType)buttonType;

// The default implementation of this method returns the value in the bounds
// parameter. This rectangle represents the area in which the button draws
// its standard background content. Subclasses that provide custom background
// adornments can override this method and return a modified bounds rectangle
// to prevent the button from drawing over any custom content.
- (CGRect)backgroundRectForBounds:(CGRect)bounds;

// The content rectangle is the area needed to display the image and title
// including any padding and adjustments for alignment and other settings.
- (CGRect)contentRectForBounds:(CGRect)bounds;

// The rectangle in which the receiver draws its title.
- (CGRect)titleRectForContentRect:(CGRect)contentRect;

// The rectangle in which the receiver draws its image.
- (CGRect)imageRectForContentRect:(CGRect)contentRect;

@end

@interface TUIButton (Content)

@property (nonatomic, strong, readonly) NSString *currentTitle;
@property (nonatomic, strong, readonly) NSColor *currentTitleColor;
@property (nonatomic, strong, readonly) NSColor *currentTitleShadowColor;
@property (nonatomic, strong, readonly) NSImage *currentImage;
@property (nonatomic, strong, readonly) NSImage *currentBackgroundImage;

- (NSString *)titleForState:(TUIControlState)state;
- (NSColor *)titleColorForState:(TUIControlState)state;
- (NSColor *)titleShadowColorForState:(TUIControlState)state;
- (NSImage *)imageForState:(TUIControlState)state;
- (NSImage *)backgroundImageForState:(TUIControlState)state;

// In general, if a property is not specified for a state, the default
// is to use the TUIControlStateNormal value. If the TUIControlStateNormal
// value is not set, then the property defaults to a system value.
// Therefore, at a minimum, you should set the value for the normal state.

// Set the title for the button. The title derives its formatting from
// the button’s associated label.
- (void)setTitle:(NSString *)title forState:(TUIControlState)state;

// Set the title color for the button. The color derives its formatting
// from the button’s associated label.
- (void)setTitleColor:(NSColor *)color forState:(TUIControlState)state;

// Set the shadow color for the button. The shadow color derives its
// formatting from the button’s associated label.
- (void)setTitleShadowColor:(NSColor *)color forState:(TUIControlState)state;

// Set the image for the button.
- (void)setImage:(NSImage *)image forState:(TUIControlState)state;

// Set the background image for the button.
- (void)setBackgroundImage:(NSImage *)image forState:(TUIControlState)state;

@end
