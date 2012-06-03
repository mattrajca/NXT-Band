//
//  MRNoteView.m
//  NoteKit
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "MRNoteView.h"

#import "MRPianoRollView+Private.h"

@implementation MRNoteView {
	NSPoint _lastMouseLocation;
	NSRect _resizeHandleRect;
	BOOL _resizing;
}

#define RESIZE_HANDLE_WIDTH 5.0f
#define SELECTION_INSET 2.0f

@synthesize selected = _selected;

- (MRPianoRollView *)pianoRollView {
	NSAssert([[self superview] isKindOfClass:[MRPianoRollView class]],
			 @"The superview of all MRNoteViews should be a MRPianoRollView");
	
	return (MRPianoRollView *) [self superview];
}

- (void)resetCursorRects {
	_resizeHandleRect = NSMakeRect(NSWidth([self bounds]) - RESIZE_HANDLE_WIDTH, 0.0f,
								   RESIZE_HANDLE_WIDTH, NSHeight([self bounds]));
	
	[self addCursorRect:_resizeHandleRect cursor:[NSCursor resizeRightCursor]];
}

- (void)drawRect:(NSRect)dirtyRect {
	CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
	CGRect bounds = NSRectToCGRect([self bounds]);
	
	bounds.size.width -= 1.0f;
	
	CGContextSetRGBFillColor(ctx, 0.2f, 0.1f, 0.8f, 1.0f);
	CGContextFillRect(ctx, bounds);
	
	if (_selected) {
		CGContextSetRGBFillColor(ctx, 0.7f, 0.1f, 0.2f, 1.0f);
		CGContextFillRect(ctx, CGRectInset(bounds, SELECTION_INSET, SELECTION_INSET));
	}
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	_lastMouseLocation = [[self pianoRollView] convertPoint:[theEvent locationInWindow] fromView:nil];
	
	if (NSPointInRect(point, _resizeHandleRect)) {
		_resizing = YES;
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (_resizing) {
		NSPoint location = [[self pianoRollView] convertPoint:[theEvent locationInWindow] fromView:nil];
		CGFloat deltaX = location.x - _lastMouseLocation.x;
		_lastMouseLocation = location;
		
		NSSize frameSize = [self frame].size;
		frameSize.width += deltaX;
		
		if (frameSize.width < 5.0f) {
			frameSize.width = 5.0f;
		}
		
		[self setFrameSize:frameSize];
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
	if (_resizing) {
		_resizing = NO;
		
		[[self pianoRollView] pr_changedNoteViewWidth:self];
		[[self window] invalidateCursorRectsForView:self];
		
		return;
	}
	
	self.selected = !_selected;
	
	[[self pianoRollView] pr_selectedNoteView:self];
}

- (void)setSelected:(BOOL)selected {
	if (_selected != selected) {
		[self willChangeValueForKey:@"selected"];
		_selected = selected;
		[self didChangeValueForKey:@"selected"];
		
		[self setNeedsDisplay:YES];
	}
}

@end
