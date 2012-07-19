#import "TUIView.h"

@class TUILayoutConstraint;

@interface TUILayoutManager : NSObject

+ (id)sharedLayoutManager;

- (void)addLayoutConstraint:(TUILayoutConstraint *)constraint toView:(TUIView *)view;
- (void)removeLayoutConstraintsFromView:(TUIView *)view;

- (NSArray *)layoutConstraintsOnView:(TUIView *)view;
- (void)removeAllLayoutConstraints;

- (NSString *)layoutNameForView:(TUIView *)view;
- (void)setLayoutName:(NSString *)name forView:(TUIView *)view;

- (void)beginProcessingView:(TUIView *)aView;

@end
