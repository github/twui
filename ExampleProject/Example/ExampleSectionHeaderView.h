#import <Cocoa/Cocoa.h>

#import "TUIKit.h"

@interface ExampleSectionHeaderView : TUITableViewSectionHeader

@property (nonatomic, strong) TUITextRenderer *labelRenderer;
@property (nonatomic, strong) TUISwitch *switchControl;

@end

