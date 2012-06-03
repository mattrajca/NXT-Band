//
//  KeyboardWindowController.m
//  NXT Band
//
//  Copyright Matt Rajca 2011. All rights reserved.
//

#import "KeyboardWindowController.h"

@implementation KeyboardWindowController

+ (id)sharedKeyboard {
	static KeyboardWindowController *sharedWC = nil;
	
	if (!sharedWC) {
		sharedWC = [[KeyboardWindowController alloc] init];
	}
	
	return sharedWC;
}

- (id)init {
	return [super initWithWindowNibName:@"KeyboardWindow"];
}

@end
