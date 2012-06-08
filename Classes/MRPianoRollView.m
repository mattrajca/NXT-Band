//
//  MRPianoRollView.m
//  NoteKit
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "MRPianoRollView.h"

@interface MRPianoRollView ()

- (void)changePitchOfSelectedNotesBy:(int)delta;
- (void)changeTimestampOfSelectedNotesBy:(int)delta;

- (void)deselectAllNotes;
- (void)selectAllNotes;
- (void)deselectNoteAtIndex:(NSUInteger)index;
- (void)selectNoteAtIndex:(NSUInteger)index;

- (NSUInteger)indexOfNoteView:(MRNoteView *)noteView;
- (MRNoteView *)noteViewForNoteAtIndex:(NSUInteger)index;
- (NSArray *)noteViewsForNotesAtIndices:(NSIndexSet *)indices;
- (MRNoteView *)closestNoteViewPastXPosition:(CGFloat)x;
- (void)removeNoteViewsAtIndices:(NSIndexSet *)indices;
- (NSRect)rectForNoteAtIndex:(NSUInteger)index;

@end


@implementation MRPianoRollView {
	NSMutableIndexSet *_selectedIndices;
	
	BOOL _drawingNotePlaceholder;
	NSRect _notePlaceholderRect;
}

#define TIMESCALE 0.1f

#define NOTE_HEIGHT 10.0f
#define NOTE_MARGIN 1.0f
#define NOTE_LINE_HEIGHT (NOTE_HEIGHT + NOTE_MARGIN)

@synthesize allowsNoteCreation = _allowsNoteCreation;
@synthesize dataSource = _dataSource;

#pragma mark -
#pragma mark Initialization

- (void)commonInit {
	_selectedIndices = [[NSMutableIndexSet alloc] init];
}

- (id)initWithFrame:(NSRect)aFrame {
	self = [super initWithFrame:aFrame];
	if (self) {
		[self commonInit];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self commonInit];
	}
	return self;
}

#pragma mark -
#pragma mark Drawing

+ (CGFloat)noteLineHeight {
	return NOTE_LINE_HEIGHT;
}

- (void)drawRect:(NSRect)dirtyRect {
	CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
	NSRect bounds = [self bounds];
	
	for (int x = 25; x < bounds.size.width; x += 25) {
		if (x % 100 == 0) {
			CGContextSetRGBFillColor(ctx, 0.6f, 0.6f, 0.6f, 1.0f);
		}
		else {
			CGContextSetRGBFillColor(ctx, 0.8f, 0.8f, 0.8f, 1.0f);
		}
		
		CGContextFillRect(ctx, CGRectMake(x, 0.0f, 1.0f, bounds.size.height));
	}
	
	for (int y = NOTE_HEIGHT; y < NSHeight(bounds); y += NOTE_LINE_HEIGHT) {
		CGContextSetRGBFillColor(ctx, 0.8f, 0.8f, 0.8f, 1.0f);
		CGContextFillRect(ctx, CGRectMake(0.0f, y, NSWidth(bounds), 1.0f));
	}
	
	if (_drawingNotePlaceholder) {
		CGContextSetRGBFillColor(ctx, 0.2f, 0.1f, 0.8f, 1.0f);
		CGContextFillRect(ctx, NSRectToCGRect(_notePlaceholderRect));
	}
}

#pragma mark -
#pragma mark Data

- (void)reloadData {
	if (!_dataSource)
		return;
	
	[_selectedIndices removeAllIndexes];
	
	[[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	
	NSUInteger notes = [_dataSource numberOfNotesInPianoRollView:self];
	
	for (NSUInteger n = 0; n < notes; n++) {
		NSRect rect = [self rectForNoteAtIndex:n];
		
		MRNoteView *view = [[MRNoteView alloc] initWithFrame:rect];
		[self addSubview:view];
	}
}

- (NSIndexSet *)selectedIndices {
	return [_selectedIndices copy];
}

#pragma mark -
#pragma mark Updation

- (void)reloadNoteAtIndex:(NSUInteger)index {
	MRNoteView *noteView = [[self subviews] objectAtIndex:index];
	noteView.frame = [self rectForNoteAtIndex:index];
}

- (void)changePitchOfSelectedNotesBy:(int)delta {
	if (![_selectedIndices count]) {
		NSBeep();
		return;
	}
	
	[_selectedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		
		id < MRNote > note = [_dataSource noteAtIndex:idx];
		MRNotePitch newPitch = note.pitch + delta;
		
		[_dataSource pianoRollView:self changedPitchOfNoteAtIndex:idx to:newPitch];
		
		MRNoteView *noteView = [self noteViewForNoteAtIndex:idx];
		noteView.frame = [self rectForNoteAtIndex:idx];
		
	}];
}

- (void)changeTimestampOfSelectedNotesBy:(int)delta {
	if (![_selectedIndices count]) {
		NSBeep();
		return;
	}
	
	[_selectedIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		
		id < MRNote > note = [_dataSource noteAtIndex:idx];
		MRTimeInterval newTS = note.timestamp + delta;
		
		[_dataSource pianoRollView:self changedTimestampOfNoteAtIndex:idx to:newTS];
		
		MRNoteView *noteView = [self noteViewForNoteAtIndex:idx];
		noteView.frame = [self rectForNoteAtIndex:idx];
		
	}];
}

- (void)deleteNotesAtIndices:(NSIndexSet *)indices {
	[self removeNoteViewsAtIndices:indices];
	
	[_selectedIndices removeIndexes:indices];
}

#pragma mark -
#pragma mark First Responder

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if ([menuItem action] == @selector(delete:)) {
		return ([_selectedIndices count] > 0);
	}
	else if ([menuItem action] == @selector(selectAll:)) {
		return YES;
	}
	
	return [super validateMenuItem:menuItem];
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent {
	if (!_allowsNoteCreation)
		return;
	
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	CGFloat y = [self gridAlignedYPosition:point.y];
	
	_notePlaceholderRect = NSMakeRect(point.x, y, 0.0f, NOTE_HEIGHT);
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (!_allowsNoteCreation)
		return;
	
	CGFloat x = [self convertPoint:[theEvent locationInWindow] fromView:nil].x;
	
	_drawingNotePlaceholder = YES;
	_notePlaceholderRect.size.width = MAX(x - NSMinX(_notePlaceholderRect), 5);
	
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
	if (_drawingNotePlaceholder) {
		_drawingNotePlaceholder = NO;
		
		MRNoteView *view = [[MRNoteView alloc] initWithFrame:_notePlaceholderRect];
		MRNoteView *relativeView = [self closestNoteViewPastXPosition:NSMinX(_notePlaceholderRect)];
		
		[self addSubview:view positioned:NSWindowAbove relativeTo:relativeView];
		
		NSUInteger index = [[self subviews] indexOfObject:view];
		NSUInteger currentNoteCount = [_dataSource numberOfNotesInPianoRollView:self];
		
		[_dataSource pianoRollView:self
			   insertedNoteAtIndex:index
					 withTimestamp:_notePlaceholderRect.origin.x / TIMESCALE
						  duration:_notePlaceholderRect.size.width / TIMESCALE
							 pitch:_notePlaceholderRect.origin.y / NOTE_LINE_HEIGHT];
		
		NSAssert((currentNoteCount + 1) == [_dataSource numberOfNotesInPianoRollView:self],
				 @"The newly-inserted note was not added to your model");
		
		[self setNeedsDisplay:YES];
	}
	else {
		[self deselectAllNotes];
	}
}

- (void)keyDown:(NSEvent *)theEvent {
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

- (void)delete:(id)sender {
	[self deleteBackward:sender];
}

- (void)deleteBackward:(id)sender {
	if (![_selectedIndices count]) {
		NSBeep();
		return;
	}
	
	[self removeNoteViewsAtIndices:_selectedIndices];
	
	[_dataSource pianoRollView:self deletedNotesAtIndices:[self selectedIndices]];
	
	[_selectedIndices removeAllIndexes];
}

- (void)moveUp:(id)sender {
	[self changePitchOfSelectedNotesBy:1];
}

- (void)moveDown:(id)sender {
	[self changePitchOfSelectedNotesBy:-1];
}

- (void)moveLeft:(id)sender {
	[self changeTimestampOfSelectedNotesBy:-200];
}

- (void)moveRight:(id)sender {
	[self changeTimestampOfSelectedNotesBy:200];
}

- (void)selectAll:(id)sender {
	[self selectAllNotes];
}

#pragma mark -
#pragma mark Selection

- (void)deselectAllNotes {
	[_selectedIndices removeAllIndexes];
	
	for (MRNoteView *noteView in [self subviews]) {
		noteView.selected = NO;
	}
}

- (void)selectAllNotes {
	NSUInteger notes = [_dataSource numberOfNotesInPianoRollView:self];
	[_selectedIndices addIndexesInRange:NSMakeRange(0, notes)];
	
	for (MRNoteView *noteView in [self subviews]) {
		noteView.selected = YES;
	}
}

- (void)deselectNoteAtIndex:(NSUInteger)index {
	[_selectedIndices removeIndex:index];
	
	[[self noteViewForNoteAtIndex:index] setSelected:NO];
}

- (void)selectNoteAtIndex:(NSUInteger)index {
	[_selectedIndices addIndex:index];
	
	[[self noteViewForNoteAtIndex:index] setSelected:YES];
}

- (void)selectNotesAtIndices:(NSIndexSet *)indices {
	[_selectedIndices addIndexes:indices];
	
	for (MRNoteView *view in [self noteViewsForNotesAtIndices:indices]) {
		[view setSelected:YES];
	}
}

#pragma mark -
#pragma mark Utility

- (NSUInteger)indexOfNoteView:(MRNoteView *)noteView {
	return [[self subviews] indexOfObject:noteView];
}

- (MRNoteView *)noteViewForNoteAtIndex:(NSUInteger)index {
	return [[self subviews] objectAtIndex:index];
}

- (NSArray *)noteViewsForNotesAtIndices:(NSIndexSet *)indices {
	return [[self subviews] objectsAtIndexes:indices];
}

- (MRNoteView *)closestNoteViewPastXPosition:(CGFloat)x {
	NSArray *subviews = [self subviews];
	
	if ([subviews count] == 0)
		return nil;
	
	if ([subviews count] == 1) {
		MRNoteView *currentView = [subviews objectAtIndex:0];
		
		if (currentView.frame.origin.x < x)
			return currentView;
		else
			return nil;
	}
	
	for (NSUInteger n = 0; n < [subviews count] - 1; n++) {
		MRNoteView *currentView = [subviews objectAtIndex:n];
		MRNoteView *nextView = [subviews objectAtIndex:n+1];
		
		if (currentView.frame.origin.x < x && nextView.frame.origin.x > x)
			return currentView;
	}
	
	return nil;
}

- (void)removeNoteViewsAtIndices:(NSIndexSet *)indices {
	__block NSUInteger removedCount = 0;
	
	[indices enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
		NSUInteger finalIndex = index - removedCount;
		
		MRNoteView *noteView = [self noteViewForNoteAtIndex:finalIndex];
		[noteView removeFromSuperview];
		
		removedCount++;
	}];
}

- (NSRect)rectForNoteAtIndex:(NSUInteger)index {
	id < MRNote > note = [_dataSource noteAtIndex:index];
	
	return NSMakeRect([note timestamp] * TIMESCALE, [note pitch] * NOTE_LINE_HEIGHT, [note duration] * TIMESCALE, NOTE_HEIGHT);
}

- (CGFloat)gridAlignedYPosition:(CGFloat)y {
	return floorf(y / NOTE_LINE_HEIGHT) * NOTE_LINE_HEIGHT;
}

- (MRNotePitch)pitchOfNoteView:(MRNoteView *)view {
	return floorf(view.frame.origin.y / NOTE_LINE_HEIGHT);
}

#pragma mark -
#pragma mark Private

- (void)pr_selectedNoteView:(MRNoteView *)noteView {
	NSUInteger index = [self indexOfNoteView:noteView];
	
	if ([NSEvent modifierFlags] & NSShiftKeyMask) {
		if (noteView.selected) {
			[self selectNoteAtIndex:index];
		}
		else {
			[self deselectNoteAtIndex:index];
		}
	}
	else {
		[self deselectAllNotes];
		[self selectNoteAtIndex:index];
	}
}

- (void)pr_changedNoteViewWidth:(MRNoteView *)noteView {
	NSUInteger index = [self indexOfNoteView:noteView];
	MRTimeInterval newDuration = (MRTimeInterval) (noteView.bounds.size.width / TIMESCALE);
	
	[_dataSource pianoRollView:self changedDurationOfNoteAtIndex:index to:newDuration];
}

- (void)pr_changedNoteViewX:(MRNoteView *)noteView {
	NSUInteger index = [self indexOfNoteView:noteView];
	MRTimeInterval newTimestamp = (MRTimeInterval) (noteView.frame.origin.x / TIMESCALE);
	
	[_dataSource pianoRollView:self changedTimestampOfNoteAtIndex:index to:newTimestamp];
}

- (void)pr_changedNoteViewY:(MRNoteView *)noteView {
	NSUInteger index = [self indexOfNoteView:noteView];
	MRNotePitch newPitch = [self pitchOfNoteView:noteView];
	
	[_dataSource pianoRollView:self changedPitchOfNoteAtIndex:index to:newPitch];
}

#pragma mark -

@end
