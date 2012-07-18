#import "TUIView.h"

@class TUIView;

/* No support for relations yet.
 
 enum {
 TUILayoutRelationLessThanOrEqual = -1,
 TUILayoutRelationEqual = 0,
 TUILayoutRelationGreaterThanOrEqual = 1,
 }; typedef NSInteger TUILayoutRelation;
 */

enum {
    TUILayoutAttributeLeft = 1 << 0,
    TUILayoutAttributeCenterX = 1 << 1,
    TUILayoutAttributeRight = 1 << 2,
    TUILayoutAttributeWidth = 1 << 3,
    TUILayoutAttributeBottom = 1 << 4,
    TUILayoutAttributeCenterY = 1 << 5,
    TUILayoutAttributeTop = 1 << 6,
    TUILayoutAttributeHeight = 1 << 7,
    
    /* What the heck do these do again?
     
     TUILayoutAttributeLeading = 1 << 8,
     TUILayoutAttributeTrailing = 1 << 9,
     TUILayoutAttributeBaseline = 1 << 10,
     */
    
    TUILayoutAttributeNotAnAttribute = 1 << 20
}; typedef NSInteger TUILayoutAttribute;

enum {
    TUILayoutFormatAlignAllLeft = TUILayoutAttributeLeft,
    TUILayoutFormatAlignAllRight = TUILayoutAttributeRight,
    TUILayoutFormatAlignAllTop = TUILayoutAttributeTop,
    TUILayoutFormatAlignAllBottom = TUILayoutAttributeBottom,
    TUILayoutFormatAlignAllCenterX = TUILayoutAttributeCenterX,
    TUILayoutFormatAlignAllCenterY = TUILayoutAttributeCenterY,
    
    /* What the heck do these do again?
     
     TUILayoutFormatAlignAllLeading = TUILayoutAttributeLeading,
     TUILayoutFormatAlignAllTrailing = TUILayoutAttributeTrailing,
     TUILayoutFormatAlignAllBaseline = TUILayoutAttributeBaseline,
     */
    
    TUILayoutFormatAlignmentMask = 0xFF,
    
    TUILayoutFormatDirectionLeadingToTrailing = 0 << 8,
    TUILayoutFormatDirectionLeftToRight = 1 << 8,
    TUILayoutFormatDirectionRightToLeft = 2 << 8,
    
    TUILayoutFormatDirectionMask = 0x3 << 8,
};
typedef NSUInteger TUILayoutFormatOptions;

enum {
    TUILayoutConstraintOrientationHorizontal = 0,
    TUILayoutConstraintOrientationVertical = 1
};
typedef NSInteger TUILayoutConstraintOrientation;

enum {
    TUILayoutPriorityRequired = 1000,
    TUILayoutPriorityDefaultHigh = 750,
    TUILayoutPriorityDragThatCanResizeWindow = 510,
    TUILayoutPriorityWindowSizeStayPut = 500,
    TUILayoutPriorityDragThatCannotResizeWindow = 490,
    TUILayoutPriorityDefaultLow = 250,
    TUILayoutPriorityFittingSizeCompression = 50,
};
typedef float TUILayoutPriority;

@interface TUILayoutConstraint : NSObject

/* I wish this would be possible, but it would need a bit of smart
 parsing to identify the elements, layouts, and constraint IDs.
 
 + (NSArray *)constraintsWithVisualFormat:(NSString *)format
 options:(TUILayoutFormatOptions)opts
 metrics:(NSDictionary *)metrics
 views:(NSDictionary *)views;
 */

+ (id)constraintWithItem:(NSString *)firstItem
               attribute:(TUILayoutAttribute)firstAttribute
//relatedBy:(TUILayoutRelation)relation
                  toItem:(NSString *)secondItem
               attribute:(TUILayoutAttribute)secondAttribute
              multiplier:(CGFloat)multiplier
                constant:(CGFloat)constant;

- (CGFloat)relativeValueInView:(TUIView *)view;

/* No priorities or relations yet.
 
 @property TUILayoutPriority priority;
 @property (readonly) TUILayoutRelation relation;
 */

@property (nonatomic, readonly, copy) NSString *firstItem;
@property (nonatomic, readonly, copy) NSString *secondItem;
@property (nonatomic, readonly, assign) TUILayoutAttribute firstAttribute;
@property (nonatomic, readonly, assign) TUILayoutAttribute secondAttribute;
@property (nonatomic, readonly, assign) CGFloat multiplier;
@property (nonatomic, readonly, assign) CGFloat constant;

@end