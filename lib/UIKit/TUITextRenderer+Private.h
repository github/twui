#import "TUITextRenderer.h"

@interface TUITextRenderer ()

- (CTFramesetterRef)ctFramesetter;
- (CTFrameRef)ctFrame;
- (CGPathRef)ctPath;
- (CFRange)_selectedRange;
- (void)_resetFramesetter;

@end

@interface TUITextRenderer (KeyBindings)

- (void)_scrollToIndex:(long)index;

@end
