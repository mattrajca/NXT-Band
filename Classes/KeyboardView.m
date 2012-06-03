//
//  KeyboardView.m
//  NXT Band
//
//  Copyright Matt Rajca 2011. All rights reserved.
//

#import "KeyboardView.h"

@implementation KeyboardView

#define KEY_WIDTH 30.0f

- (void)drawRect:(NSRect)dirtyRect {
	CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
	NSRect bounds = [self bounds];
	
	CGContextSetRGBFillColor(ctx, 1.0f, 1.0f, 1.0f, 1.0f);
	CGContextFillRect(ctx, NSRectToCGRect(bounds));
	
	CGContextSetRGBFillColor(ctx, 0.6f, 0.6f, 0.6f, 1.0f);
	
	for (CGFloat x = KEY_WIDTH; x < bounds.size.width; x += KEY_WIDTH) {
		CGContextFillRect(ctx, CGRectMake(x, 0.0f, 1.0f, bounds.size.height));
	}
}

@end
