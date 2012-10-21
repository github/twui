#import <Cocoa/Cocoa.h>

#import "TUIKit.h"

@interface ExampleSectionHeaderView : TUITableViewSectionHeader {
  
  TUITextRenderer * _labelRenderer;
  
}

@property (readonly) TUITextRenderer  * labelRenderer;

@property (nonatomic, strong) TUISwitch *switchControl;

@end

