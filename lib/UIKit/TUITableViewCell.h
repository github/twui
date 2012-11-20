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

typedef enum TUITableViewCellStyle : NSUInteger {
	
	// A basic table view cell with no additional styles or formats.
	TUITableViewCellStyleDefault,
} TUITableViewCellStyle;

typedef enum TUITableViewCellSeparatorStyle : NSUInteger {
	
	// The cell has no distinct separator style.
	TUITableViewCellSeparatorStyleNone,
	
	// The cell has a single gray separator line at its base.
	TUITableViewCellSeparatorStyleLine,
	
	// The cell has double lines running across its width, giving it
	// an etched or embossed look. The upper line is white, while
	// the lower line is gray. This is the default value.
	TUITableViewCellSeparatorStyleEtched,
	
	// This style is similar to TUITableViewCellSeparatorStyleEtched,
	// but swaps the line colors on the top and bottom.
	TUITableViewCellSeparatorStyleEtchedReversed
} TUITableViewCellSeparatorStyle;

typedef enum TUITableViewCellColorStyle : NSUInteger {
	
	// The cell has no distinct color style for this state. Instead,
	// if custom colors are provided, they will be used.
	TUITableViewCellColorStyleNone,
	
	// The cell either has a blue, graphite, or gray background.
	TUITableViewCellColorStyleBlue,
	TUITableViewCellColorStyleGraphite,
	TUITableViewCellColorStyleGray,
} TUITableViewCellColorStyle;

@class TUITableView;

// The TUITableViewCell class defines the attributes and behavior of
// the cells that appear in TUITableViews. A table cell includes
// properties and methods for managing cell selection, highlighted
// state, and content indentation.
// It also has predefined cell styles that position elements of the
// cell in certain locations and with certain attributes. You can still
// extend the standard TUITableViewCell by adding subviews to it, or
// subclassing it to obtain custom cell characteristics and behavior.
// If you do wish to customize TUITableViewCell, to apply custom drawing,
// it is advisable to use the customization methods and blocks below.
//
// Features not yet supported fully:
//		- Pasteboard Dragging
//		- Editing Mode
//		- Accessories
//		- Pre-styled label and image views.
@interface TUITableViewCell : TUIView

// The reuse identifier is associated with a TUITableViewCell that
// the table view’s delegate creates with the intent to reuse it as
// the basis for multiple rows of a table view. It is assigned to the
// cell object in initWithFrame:reuseIdentifier: and cannot be changed
// thereafter. A table view maintains a list of the currently reusable
// cells, each with its own reuse identifier, and makes them available
// to the delegate in the dequeueReusableCellWithIdentifier: method.
@property (nonatomic, copy, readonly) NSString *reuseIdentifier;

// A weak accessor to the table view this cell is currently managed by.
@property (nonatomic, unsafe_unretained, readonly) TUITableView *tableView;

// The current index path, if on screen, of this cell in the table view.
@property (nonatomic, strong, readonly) NSIndexPath *indexPath;

// The style of this cell. It cannot be changed after initialization.
@property (nonatomic, assign, readonly) TUITableViewCellStyle style;

// The cell can animate changes when its state changes, or when any
// of its style elements changes. The default value is YES. To avoid
// overhead or complexities in subclasses, you may disable this.
@property (nonatomic, assign) BOOL animatesAppearanceChanges;

// The separator style of this cell. Defaults to TUITableViewCellSeparatorStyleNone.
@property (nonatomic, assign) TUITableViewCellSeparatorStyle separatorStyle;

// The color the cell draws when highlighted or selected. If the color
// style is set to TUITableViewCellColorStyleNone, and these colors are
// not set to nil, they will be used to draw the cell. Defaults to nil.
// If no style or colors are set, the background color is used everywhere.
@property (nonatomic, strong) NSColor *highlightColor;
@property (nonatomic, strong) NSColor *selectionColor;

// The color styles for each state for the cell. If the backgroundStyle
// is set to TUITableViewCellColorStyleNone, the background color is used.
// All styles default to TUITableViewCellColorStyleNone.
@property (nonatomic, assign) TUITableViewCellColorStyle backgroundStyle;
@property (nonatomic, assign) TUITableViewCellColorStyle highlightStyle;
@property (nonatomic, assign) TUITableViewCellColorStyle selectionStyle;

// Every other cell may also draw each of its states in an alternate color,
// if the corresponding alternating color for the state is set. If it
// is set to nil, then this is alternation is disabled. Defaults to nil.
// Only applicable if the color style is TUITableViewCellColorStyleNone.
@property (nonatomic, strong) NSColor *alternateBackgroundColor;
@property (nonatomic, strong) NSColor *alternateHighlightColor;
@property (nonatomic, strong) NSColor *alternateSelectionColor;

// The floating value affects the appearance of the cell. The default
// value is NO. If the table view supports dragging, and the cell is
// dragged, the floating state is set to YES. It is a temporary
// attribute set when the cell is floating above other cells.
// A floating state is still displayed as a highlighted state, so if
// you are using custom drawing blocks or methods, then you may want
// to check this property to render the cell properly in context.
@property (nonatomic, readonly, getter = isFloating) BOOL floating;

// The highlighting affects the appearance of the cell. The default
// value is is NO. If you set the highlighted state to YES through
// this property, the transition to the new state appearance is not
// animated. For animated highlighted-state transitions, see
// the setHighlighted:animated: method.
@property (nonatomic, assign, getter = isHighlighted) BOOL highlighted;

// The selection affects the appearance of the cell. The default
// value is is NO. If you set the selected state to YES through
// this property, the transition to the new state appearance is not
// animated. For animated selected-state transitions, see
// the setSelected:animated: method.
@property (nonatomic, assign, getter = isSelected) BOOL selected;

// This method is the designated initializer for the class. The
// reuse identifier is associated with those cells of a table view
// that have the same general configuration, minus cell content.
// In its implementation of tableView:cellForRowAtIndexPath:, the
// table view's delegate calls the TUITableView method
// dequeueReusableCellWithIdentifier:, passing in a reuse identifier,
// to obtain the cell object to use as the basis for the current row.
// If you want a table cell that has a configuration different that
// those defined by TUITableViewCell for style, you must subclass.
- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

// If the cell is reusable (has a reuseIdentifier), this method
// is called just before the cell is returned from the table view
// method dequeueReusableCellWithIdentifier:. If you override this
// method, you MUST call the super method.
- (void)prepareForReuse;

// This method is called after frame is set, but before it is
// brought on screen. If overriden, it should call the super method.
- (void)prepareForDisplay;

// Highlighted is set upon mouse down, and selected upon mouse up,
// selected upon mouse up. Setting selected state triggers a
// didSelectRowAtPath: delegate method call. You may override these
// methods with a super method call to add custom behavior.
- (void)setSelected:(BOOL)s animated:(BOOL)animated;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;

// If you are subclassing to draw a custom table view cell, consider
// overridding these methods instead of -drawRect. -drawBackground:
// draws the standard background for the cell, -drawHighlightedBackground:
// draws the highlighted background, and -drawSelectedBackground: draws
// the selected background. -drawSeparators: draws the seperators for
// the cell. The default implementations of these methods take into
// account the cell style properties set. 
- (void)drawBackground:(CGRect)rect;
- (void)drawHighlightedBackground:(CGRect)rect;
- (void)drawSelectedBackground:(CGRect)rect;
- (void)drawSeparators:(CGRect)rect;

// These blocks perform the same function as the methods above, but
// without the added load of subclassing the cell. If you provide blocks
// instead, but still override methods, the blocks will take priority.
@property (nonatomic, copy) TUIViewDrawRect drawBackground;
@property (nonatomic, copy) TUIViewDrawRect drawHighlightedBackground;
@property (nonatomic, copy) TUIViewDrawRect drawSelectedBackground;
@property (nonatomic, copy) TUIViewDrawRect drawSeparators;

@end
