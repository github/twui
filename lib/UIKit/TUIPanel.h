#import <Foundation/Foundation.h>
#import "TUINSView.h"

// Notes:
// 
// - Window Blurring using CGSPrivate.
// Hmm, doesn't seem to be working for some odd reason. Also need to add a define 
// macro to disable this if the application is a Mac App Store applicant.
//
// - Custom Buttons.
// NSPanels have close, resize, and zoom buttons, but I've only added the close
// button. Shouldn't be too difficult, but we need the other two buttons too.
//
// - HUD Appearance.
// This panel looks mostly like the NSPopover, but not anchored with an arrow, and
// has a small close button. I'll be adding appearance containers soon to allow for
// the usual Cocoa utility panels and HUD windows as well.
//
// - Corner Clipping.
// I'm not sure how, but there has to be a way to clip subviews to the same corner
// radius that the theme frame uses. This also causes the resize pointer not to appear.

@interface TUIPanel : NSWindow

@property (nonatomic, assign, getter = isFloatingPanel) BOOL floatingPanel;
@property (nonatomic, assign) BOOL becomesKeyOnlyIfNeeded;
@property (nonatomic, assign) BOOL worksWhenModal;

@property (nonatomic, retain) TUIView *rootView;

- (id)initWithContentRect:(CGRect)contentRect;

@end