//
//  KeyboardWindowController.m
//  NXT Band
//
//  Copyright Matt Rajca 2011. All rights reserved.
//

#import "KeyboardWindowController.h"

#import "InputManager.h"

@implementation KeyboardWindowController

@synthesize keyboardView = _keyboardView;

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

- (void)awakeFromNib {
	_keyboardView.delegate = self;
}

- (void)keyboardView:(KeyboardView *)keyboardView noteOn:(int)value {
	[[InputManager sharedManager] simulateNoteOn:value];
}

- (void)keyboardView:(KeyboardView *)keyboardView noteOff:(int)value {
	[[InputManager sharedManager] simulateNoteOff:value];
}

@end
