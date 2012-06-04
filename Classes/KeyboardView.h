//
//  KeyboardView.h
//  NXT Band
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

@protocol KeyboardViewDelegate;

@interface KeyboardView : NSView

@property (nonatomic, unsafe_unretained) id < KeyboardViewDelegate > delegate;

@end


@protocol KeyboardViewDelegate

- (void)keyboardView:(KeyboardView *)keyboardView noteOn:(int)value;
- (void)keyboardView:(KeyboardView *)keyboardView noteOff:(int)value;

@end
