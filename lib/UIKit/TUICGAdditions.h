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

// A TUIRectCorner represents a maskable corner of a rectangle.
typedef enum TUIRectCorner : NSUInteger {
	TUIRectCornerTopLeft = 1 << 0,
	TUIRectCornerTopRight = 1 << 1,
	TUIRectCornerBottomLeft = 1 << 2,
	TUIRectCornerBottomRight = 1 << 3,
	TUIRectCornerTop = TUIRectCornerTopLeft | TUIRectCornerTopRight,
	TUIRectCornerBottom = TUIRectCornerBottomLeft | TUIRectCornerBottomRight,
	TUIRectCornerAll = TUIRectCornerTopLeft | TUIRectCornerTopRight | TUIRectCornerBottomLeft | TUIRectCornerBottomRight,
	TUIRectCornerNone = 0,
} TUIRectCorner;

#import <Foundation/Foundation.h>

@class TUIView;

extern CGContextRef TUICreateOpaqueGraphicsContext(CGSize size);
extern CGContextRef TUICreateGraphicsContext(CGSize size);
extern CGContextRef TUICreateGraphicsContextWithOptions(CGSize size, BOOL opaque);
extern CGImageRef TUICreateCGImageFromBitmapContext(CGContextRef ctx);

extern CGPathRef TUICGPathCreateRoundedRect(CGRect rect, CGFloat radius);
extern CGPathRef TUICGPathCreateRoundedRectWithCorners(CGRect rect, CGFloat radius, TUIRectCorner corners);
extern void CGContextAddRoundRect(CGContextRef context, CGRect rect, CGFloat radius);
extern void CGContextClipToRoundRect(CGContextRef context, CGRect rect, CGFloat radius);

extern CGRect ABScaleToFill(CGSize s, CGRect r);
extern CGRect ABScaleToFit(CGSize s, CGRect r);
extern CGRect ABRectCenteredInRect(CGRect a, CGRect b);
extern CGRect ABRectRoundOrigin(CGRect f);
extern CGRect ABIntegralRectWithSizeCenteredInRect(CGSize s, CGRect r);

extern void CGContextFillRoundRect(CGContextRef context, CGRect rect, CGFloat radius);
extern void CGContextDrawLinearGradientBetweenPoints(CGContextRef context, CGPoint a, CGFloat color_a[4], CGPoint b, CGFloat color_b[4]);

extern CGContextRef TUIGraphicsGetCurrentContext(void);
extern void TUIGraphicsPushContext(CGContextRef context);
extern void TUIGraphicsPopContext(void);

extern NSImage *TUIGraphicsContextGetImage(CGContextRef ctx);

extern void TUIGraphicsBeginImageContext(CGSize size);
// as in the iOS docs, "if you specify a value of 0.0, the scale factor is set to the scale factor of the device’s main screen."
extern void TUIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale);
extern NSImage *TUIGraphicsGetImageFromCurrentImageContext(void);
extern void TUIGraphicsEndImageContext(void); 

extern NSImage *TUIGraphicsGetImageForView(TUIView *view);

extern NSImage *TUIGraphicsDrawAsImage(CGSize size, void(^draw)(void));

/**
 Draw drawing as a PDF
 @param optionalMediaBox may be NULL
 @returns NSData encapsulating the PDF drawing, suitable for writing to a file or the pasteboard
 */
extern NSData *TUIGraphicsDrawAsPDF(CGRect *optionalMediaBox, void(^draw)(CGContextRef));
