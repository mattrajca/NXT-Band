//
//  SpaceApplication.m
//  NXT Band
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

#import "SpaceApplication.h"

@implementation SpaceApplication

- (void)sendEvent:(NSEvent *)event {
	if ([event type] == NSKeyDown) {
		NSString *str = [event characters];
		
		if ([str characterAtIndex:0] == 0x20) {
			[super sendAction:@selector(handleSpacebar:) to:nil from:self];
			return;
		}
	}
	
	[super sendEvent:event];
}

@end
