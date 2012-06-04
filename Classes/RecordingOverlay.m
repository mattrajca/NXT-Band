//
//  RecordingOverlay.m
//  NXT Band
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

#import "RecordingOverlay.h"

@implementation RecordingOverlay

- (BOOL)acceptsFirstResponder {
	return ![self isHidden];
}

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor blackColor] set];
	NSRectFill([self bounds]);
	
	NSString *text = @"Recording...";
	
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	[style setAlignment:NSCenterTextAlignment];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								style, NSParagraphStyleAttributeName,
								[NSFont boldSystemFontOfSize:22.0f], NSFontAttributeName,
								[NSColor whiteColor], NSForegroundColorAttributeName, nil];
	
	[text drawInRect:NSInsetRect([self bounds], 20.0f, 120.0f) withAttributes:attributes];
}

@end
