//
//  InputManager.h
//  NXT Band
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

extern NSString *const InputManagerNoteOnNotification;
extern NSString *const InputManagerNoteOffNotification;

extern NSString *const NoteValueKey;

@interface InputManager : NSObject

+ (id)sharedManager;

- (void)simulateNoteOn:(int)value;
- (void)simulateNoteOff:(int)value;

@end
