//
//  KeyboardWindowController.h
//  NXT Band
//
//  Copyright Matt Rajca 2011. All rights reserved.
//

#import "KeyboardView.h"

@interface KeyboardWindowController : NSWindowController < KeyboardViewDelegate >

@property (nonatomic, unsafe_unretained) IBOutlet KeyboardView *keyboardView;

+ (id)sharedKeyboard;

@end
