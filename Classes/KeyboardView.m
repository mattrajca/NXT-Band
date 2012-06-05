//
//  KeyboardView.m
//  NXT Band
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "KeyboardView.h"

@interface Key : NSObject

@property (nonatomic, assign, getter=isWhite) BOOL white;
@property (nonatomic, assign) NSRect frame;

@property (nonatomic, assign) int value;

@end


@implementation Key

@synthesize white, value, frame;

@end


@implementation KeyboardView {
	NSMutableArray *_keys;
	Key *_selectedKey;
}

#define BLACK_KEY_OFFSET 14.0f
#define BLACK_KEY_HEIGHT_OFFSET 70.0f
#define BLACK_KEY_WIDTH 26.0f

#define WHITE_KEY_WIDTH 30.0f

#define WHITE_KEYS_IN_SCALE 12
#define BLACK_KEYS_IN_SCALE 7

#define NOTES 29

@synthesize delegate = _delegate;

- (BOOL)isKeyBlack:(int)value {
	int rem = value % WHITE_KEYS_IN_SCALE;
	
	return (rem == 1 || rem == 3 || rem == 6 || rem == 8 || rem == 10);
}

- (void)viewDidMoveToSuperview {
	[self populateKeys];
}

- (void)populateKeys {
	_keys = [[NSMutableArray alloc] init];
	
	CGFloat height = NSHeight([self bounds]);
	int blackKey = 0, whiteKey = 0;
	
	for (int note = 0; note < NOTES; note++) {
		Key *key = [[Key alloc] init];
		key.value = note;
		
		if ([self isKeyBlack:note]) {
			key.frame = NSMakeRect(BLACK_KEY_OFFSET + blackKey * (BLACK_KEY_WIDTH + 4.0f), BLACK_KEY_HEIGHT_OFFSET, BLACK_KEY_WIDTH, height - BLACK_KEY_HEIGHT_OFFSET);
			key.white = NO;
			
			blackKey++;
			
			if (blackKey % BLACK_KEYS_IN_SCALE == 2 || blackKey % BLACK_KEYS_IN_SCALE == 6)
				blackKey++;
		}
		else {
			key.frame = NSMakeRect(whiteKey * WHITE_KEY_WIDTH, 0.0f, WHITE_KEY_WIDTH - 1.0f, height);
			key.white = YES;
			
			whiteKey++;
		}
		
		[_keys addObject:key];
	}
	
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor colorWithCalibratedWhite:0.4f alpha:1.0f] set];
	NSRectFill([self bounds]);
	
	for (Key *key in _keys) {
		if (key.white) {
			[[NSColor whiteColor] set];
			NSRectFill(key.frame);
			
			if (key == _selectedKey) {
				[[NSColor blueColor] set];
				NSRectFill(key.frame);
			}
		}
	}
	
	for (Key *key in _keys) {
		if (!key.white) {
			[[NSColor blackColor] set];
			NSRectFill(key.frame);
			
			if (key == _selectedKey) {
				[[NSColor blueColor] set];
				NSRectFill(NSInsetRect(key.frame, 2.0f, 2.0f));
			}
		}
	}
}

- (Key *)keyWithEvent:(NSEvent *)event {
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	
	for (Key *key in _keys) {
		if (!key.white && NSPointInRect(point, key.frame))
			return key;
	}
	
	for (Key *key in _keys) {
		if (key.white && NSPointInRect(point, key.frame))
			return key;
	}
	
	return nil;
}

- (void)mouseDown:(NSEvent *)theEvent {
	_selectedKey = [self keyWithEvent:theEvent];
	
	if (_selectedKey)
		[_delegate keyboardView:self noteOn:_selectedKey.value];
	
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
	if (_selectedKey) {
		[_delegate keyboardView:self noteOff:_selectedKey.value];
		_selectedKey = nil;
	}
	
	[self setNeedsDisplay:YES];
}

@end
