//
//  InputManager.m
//  NXT Band
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

#import "InputManager.h"

NSString *const InputManagerNoteOnNotification = @"InputManagerNoteOnNotification";
NSString *const InputManagerNoteOffNotification = @"InputManagerNoteOffNotification";

NSString *const NoteValueKey = @"NoteValueKey";

@implementation InputManager

+ (id)sharedManager {
	static InputManager *sharedManager = nil;
	
	if (!sharedManager) {
		sharedManager = [[InputManager alloc] init];
	}
	
	return sharedManager;
}

- (void)simulateNoteOn:(int)value {
	NSDictionary *info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:value] forKey:NoteValueKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:InputManagerNoteOnNotification
														object:nil
													  userInfo:info];
}

- (void)simulateNoteOff:(int)value {
	NSDictionary *info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:value] forKey:NoteValueKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:InputManagerNoteOffNotification
														object:nil
													  userInfo:info];
}

@end
