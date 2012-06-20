#import "TUIColor.h"

// Allows for color space modification, string, hex, and decimal colors,
// and color blending and mapping. Not sure where I picked this up from :\

@implementation TUIColor (Expanded)

- (BOOL)isEqualToColor:(TUIColor *)otherColor {
    CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
    
    TUIColor *(^convertColorToRGBSpace)(TUIColor*) = ^(TUIColor *color) {
        if(CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
            const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
            CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
            return [TUIColor colorWithCGColor:CGColorCreate(colorSpaceRGB, components)];
        } else
            return color;
    };
    
    TUIColor *selfColor = convertColorToRGBSpace(self);
    otherColor = convertColorToRGBSpace(otherColor);
    CGColorSpaceRelease(colorSpaceRGB);
    
    return [selfColor isEqual:otherColor];
}

// Get the color space model in use.
- (CGColorSpaceModel)colorSpaceModel {
	return CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
}

// Get the string representation of the color space model.
- (NSString *)colorSpaceString {
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelUnknown:
			return @"kCGColorSpaceModelUnknown";
		case kCGColorSpaceModelMonochrome:
			return @"kCGColorSpaceModelMonochrome";
		case kCGColorSpaceModelRGB:
			return @"kCGColorSpaceModelRGB";
		case kCGColorSpaceModelCMYK:
			return @"kCGColorSpaceModelCMYK";
		case kCGColorSpaceModelLab:
			return @"kCGColorSpaceModelLab";
		case kCGColorSpaceModelDeviceN:
			return @"kCGColorSpaceModelDeviceN";
		case kCGColorSpaceModelIndexed:
			return @"kCGColorSpaceModelIndexed";
		case kCGColorSpaceModelPattern:
			return @"kCGColorSpaceModelPattern";
		default:
			return @"Not a valid color space";
	}
}

// Return YES if color space model supports RGB.
- (BOOL)canProvideRGBComponents {
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelRGB:
		case kCGColorSpaceModelMonochrome:
			return YES;
		default:
			return NO;
	}
}

// Return an array with RGBA components.
- (NSArray *)arrayFromRGBAComponents {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -arrayFromRGBAComponents.");

	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [NSArray arrayWithObjects:
			[NSNumber numberWithFloat:r],
			[NSNumber numberWithFloat:g],
			[NSNumber numberWithFloat:b],
			[NSNumber numberWithFloat:a],
			nil];
}

// Return YES if it matches UXColor.
- (BOOL)red:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha {
	const CGFloat *components = CGColorGetComponents(self.CGColor);
	
	CGFloat r,g,b,a;
	
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelMonochrome:
			r = g = b = components[0];
			a = components[1];
			break;
		case kCGColorSpaceModelRGB:
			r = components[0];
			g = components[1];
			b = components[2];
			a = components[3];
			break;
		default: // We don't know how to handle this model.
			return NO;
	}
	
	if (red) *red = r;
	if (green) *green = g;
	if (blue) *blue = b;
	if (alpha) *alpha = a;
	
	return YES;
}

- (CGFloat)red {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -red.");
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	return c[0];
}

- (CGFloat)green {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -green.");
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
	return c[1];
}

- (CGFloat)blue {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -blue.");
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
	return c[2];
}

- (CGFloat)white {
	NSAssert(self.colorSpaceModel == kCGColorSpaceModelMonochrome, @"Must be a Monochrome color to use -white.");
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	return c[0];
}

- (CGFloat)alpha {
	return CGColorGetAlpha(self.CGColor);
}

- (UInt32)rgbHex {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use rgbHex.");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return 0;
	
	r = MIN(MAX(self.red, 0.0f), 1.0f);
	g = MIN(MAX(self.green, 0.0f), 1.0f);
	b = MIN(MAX(self.blue, 0.0f), 1.0f);
	
	return (((int)roundf(r * 255)) << 16)
	     | (((int)roundf(g * 255)) << 8)
	     | (((int)roundf(b * 255)));
}

- (TUIColor *)colorByLuminanceMapping {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations.");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	// Y = 0.2126 R + 0.7152 G + 0.0722 B
	return [UXColor colorWithWhite:(r * 0.2126f) + (g * 0.7152f) + (b * 0.0722f)
							 alpha:a];
	
}

- (TUIColor *)colorByMultiplyingByRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations.");

	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
		
	return [UXColor colorWithRed:MAX(0.0, MIN(1.0, r * red))
						   green:MAX(0.0, MIN(1.0, g * green)) 
							blue:MAX(0.0, MIN(1.0, b * blue))
						   alpha:MAX(0.0, MIN(1.0, a * alpha))];
}

- (TUIColor *)colorByAddingRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations.");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [UXColor colorWithRed:MAX(0.0, MIN(1.0, r + red))
						   green:MAX(0.0, MIN(1.0, g + green)) 
							blue:MAX(0.0, MIN(1.0, b + blue))
						   alpha:MAX(0.0, MIN(1.0, a + alpha))];
}

- (TUIColor *)colorByLighteningToRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations.");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
		
	return [UXColor colorWithRed:MAX(r, red)
						   green:MAX(g, green)
							blue:MAX(b, blue)
						   alpha:MAX(a, alpha)];
}

- (TUIColor *)colorByDarkeningToRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations.");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [UXColor colorWithRed:MIN(r, red)
						   green:MIN(g, green)
							blue:MIN(b, blue)
						   alpha:MIN(a, alpha)];
}

- (TUIColor *)colorByMultiplyingBy:(CGFloat)f {
	return [self colorByMultiplyingByRed:f green:f blue:f alpha:1.0f];
}

- (TUIColor *)colorByAdding:(CGFloat)f {
	return [self colorByMultiplyingByRed:f green:f blue:f alpha:0.0f];
}

- (TUIColor *)colorByLighteningTo:(CGFloat)f {
	return [self colorByLighteningToRed:f green:f blue:f alpha:0.0f];
}

- (TUIColor *)colorByDarkeningTo:(CGFloat)f {
	return [self colorByDarkeningToRed:f green:f blue:f alpha:1.0f];
}

- (TUIColor *)colorByMultiplyingByColor:(TUIColor *)color {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [self colorByMultiplyingByRed:r green:g blue:b alpha:1.0f];
}

- (TUIColor *)colorByAddingColor:(TUIColor *)color {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [self colorByAddingRed:r green:g blue:b alpha:0.0f];
}

- (TUIColor *)colorByLighteningToColor:(TUIColor *)color {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
		
	return [self colorByLighteningToRed:r green:g blue:b alpha:0.0f];
}

- (TUIColor *)colorByDarkeningToColor:(TUIColor *)color {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [self colorByDarkeningToRed:r green:g blue:b alpha:1.0f];
}

- (NSString *)stringFromColor {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -stringFromColor.");
	NSString *result;
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelRGB:
			result = [NSString stringWithFormat:@"{%0.3f, %0.3f, %0.3f, %0.3f}", self.red, self.green, self.blue, self.alpha];
			break;
		case kCGColorSpaceModelMonochrome:
			result = [NSString stringWithFormat:@"{%0.3f, %0.3f}", self.white, self.alpha];
			break;
		default:
			result = nil;
	}
	return result;
}

- (NSString *)hexStringFromColor {
	return [NSString stringWithFormat:@"%0.6X", self.rgbHex];
}

+ (TUIColor *)colorWithString:(NSString *)stringToConvert {
	NSScanner *scanner = [NSScanner scannerWithString:stringToConvert];
	if (![scanner scanString:@"{" intoString:NULL]) return nil;
	const NSUInteger kMaxComponents = 4;
	float c[kMaxComponents];
	NSUInteger i = 0;
	if (![scanner scanFloat:&c[i++]]) return nil;
	while (1) {
		if ([scanner scanString:@"}" intoString:NULL]) break;
		if (i >= kMaxComponents) return nil;
		if ([scanner scanString:@"," intoString:NULL]) {
			if (![scanner scanFloat:&c[i++]]) return nil;
		} else {
			// Error condition occured.
			return nil;
		}
	}
	if (![scanner isAtEnd]) return nil;
	UXColor *color;
	switch (i) {
		case 2: // Grayscale.
			color = [UXColor colorWithWhite:c[0] alpha:c[1]];
			break;
		case 4: // RGBA.
			color = [UXColor colorWithRed:c[0] green:c[1] blue:c[2] alpha:c[3]];
			break;
		default: // Error.
			color = nil;
	}
	return color;
}

+ (TUIColor *)randomColor {
	return [UXColor colorWithRed:(CGFloat)(arc4random() % 255)
						   green:(CGFloat)(arc4random() % 255)
							blue:(CGFloat)(arc4random() % 255)
						   alpha:1.0f];
}

+ (TUIColor *)colorWithRGBHex:(UInt32)hex {
	int r = (hex >> 16) & 0xFF;
	int g = (hex >> 8) & 0xFF;
	int b = (hex) & 0xFF;
	
	return [UXColor colorWithRed:r / 255.0f
						   green:g / 255.0f
							blue:b / 255.0f
						   alpha:1.0f];
}

// Returns a UXColor by scanning the string for a hex number and passing that to +[UXColor colorWithRGBHex:].
+ (TUIColor *)colorWithHexString:(NSString *)stringToConvert {
	NSScanner *scanner = [NSScanner scannerWithString:stringToConvert];
	unsigned hexNum;
    
	if (![scanner scanHexInt:&hexNum]) return nil;
	return [UXColor colorWithRGBHex:hexNum];
}

- (TUIColor *)colorByDarkeningColorBy:(CGFloat)factor {
    CGFloat *oldComponents = (CGFloat *)CGColorGetComponents([self CGColor]);
    CGFloat newComponents[4];
    
    int numComponents = (int)CGColorGetNumberOfComponents([self CGColor]);
    
    switch (numComponents) {
        case 2: { // Grayscale.
            newComponents[0] = oldComponents[0]*factor;
            newComponents[1] = oldComponents[0]*factor;
            newComponents[2] = oldComponents[0]*factor;
            newComponents[3] = oldComponents[1];
            break;
        } case 4: { // RGBA.
            newComponents[0] = oldComponents[0]*factor;
            newComponents[1] = oldComponents[1]*factor;
            newComponents[2] = oldComponents[2]*factor;
            newComponents[3] = oldComponents[3];
            break;
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef newColor = CGColorCreate(colorSpace, newComponents);
    CGColorSpaceRelease(colorSpace);
    
    UXColor *retColor = [UXColor colorWithCGColor:newColor];
    CGColorRelease(newColor);
    
    return retColor;
}

- (TUIColor *)colorByLighteningColorBy:(CGFloat)factor {
    CGFloat *oldComponents = (CGFloat *)CGColorGetComponents([self CGColor]);
    CGFloat newComponents[4];
    
    int numComponents = (int)CGColorGetNumberOfComponents([self CGColor]);
    
    switch (numComponents) {
        case 2: { // Grayscale.
            newComponents[0] = oldComponents[0]/factor;
            newComponents[1] = oldComponents[0]/factor;
            newComponents[2] = oldComponents[0]/factor;
            newComponents[3] = oldComponents[1];
            break;
        } case 4: { // RGBA.
            newComponents[0] = oldComponents[0]/factor;
            newComponents[1] = oldComponents[1]/factor;
            newComponents[2] = oldComponents[2]/factor;
            newComponents[3] = oldComponents[3];
            break;
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef newColor = CGColorCreate(colorSpace, newComponents);
    CGColorSpaceRelease(colorSpace);
    
    UXColor *retColor = [UXColor colorWithCGColor:newColor];
    CGColorRelease(newColor);
    
    return retColor;
}

@end