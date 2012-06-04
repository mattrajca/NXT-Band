//
//  RMDDocument.m
//  NXT Band
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "RMDDocument.h"

#import "InputManager.h"
#import "NSUndoManager+Blocks.h"
#import "RMDFile.h"
#import "RMDFile+Playback.h"

#import <mach/mach_time.h>

@interface RMDDocument ()

- (void)setupRoll;

- (BOOL)hasOverlappingNotes;

@end


@implementation RMDDocument {
	uint64_t _recordStartTime;
	NSMutableArray *_recordedNotes;
	RMDNote *_currentNote;
}

#define NOTES 29
#define WIDTH_LEEWAY 2000.0f

@synthesize rollView = _rollView, infoField = _infoField;
@synthesize file = _file;

static uint64_t getUptimeInMilliseconds();

- (id)initWithType:(NSString *)typeName error:(NSError **)outError {
	self = [super initWithType:typeName error:outError];
	if (self) {
		_file = [[RMDFile alloc] init];
		[_file addObserver:self forKeyPath:@"isPlaying" options:0 context:NULL];
	}
	return self;
}

- (void)dealloc {
	[_file stop];
	[_file removeObserver:self forKeyPath:@"isPlaying"];
}

#pragma mark -
#pragma mark UI

- (NSString *)windowNibName {
	return @"RMDDocument";
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if ([menuItem action] == @selector(copy:) || [menuItem action] == @selector(cut:)) {
		return ([[_rollView selectedIndices] count] > 0);
	}
	else if ([menuItem action] == @selector(paste:)) {
		NSArray *classes = [NSArray arrayWithObject:[RMDNote class]];
		NSDictionary *options = [NSDictionary dictionary];
		
		return [[NSPasteboard generalPasteboard] canReadObjectForClasses:classes options:options];
	}
	
	return [super validateMenuItem:menuItem];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
	[super windowControllerDidLoadNib:aController];
	
	[self setupRoll];
}

- (void)setupRoll {
	CGFloat width = [_file totalDuration] / 10.0f + WIDTH_LEEWAY;
	_rollView.frame = NSMakeRect(0.0f, 0.0f, width, NOTES * [MRPianoRollView noteLineHeight]);
	
	[_rollView setDataSource:self];
	[_rollView reloadData];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"isPlaying"]) {
		[[[self windowForSheet] toolbar] validateVisibleItems];
	}
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	if ([theItem action] == @selector(playStop:)) {
		if ([_file isPlaying]) {
			[theItem setImage:[NSImage imageNamed:@"Stop"]];
			[theItem setLabel:@"Stop"];
		}
		else {
			[theItem setImage:[NSImage imageNamed:@"Play"]];
			[theItem setLabel:@"Play"];
		}
		
		return YES;
	}
	else if ([theItem action] == @selector(record:)) {
		return YES;
	}
	
	return NO;
}

#pragma mark -
#pragma mark Saving/Opening

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	if ([self hasOverlappingNotes]) {
		if (outError)
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:-1 userInfo:nil];
		
		return nil;
	}
	
	NSData *data = [_file representation];
	
	if (!data) {
		if (outError)
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:-1 userInfo:nil];
		
		return nil;
	}
	
	return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	_file = [[RMDFile alloc] initWithData:data];
	
	if (!_file) {
		if (outError)
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:-1 userInfo:nil];
		
		return NO;
	}
	
	[self setupRoll];
	
	[_file addObserver:self forKeyPath:@"isPlaying" options:0 context:NULL];
	
	return YES;
}

#pragma mark -
#pragma mark Helper Methods

- (BOOL)hasOverlappingNotes {
	RMDNote *previousNote = nil;
	
	for (RMDNote *note in _file.notes) {
		if (note.timestamp < (previousNote.timestamp + previousNote.duration)) {
			return YES;
		}
		
		previousNote = note;
	}
	
	return NO;
}

- (void)checkForOverlappingNotes {
	[_infoField setHidden:![self hasOverlappingNotes]];
}

#pragma mark -
#pragma mark Note Controller

- (void)addNotes:(NSArray *)notes withActionName:(NSString *)actionName {
	[[self undoManager] groupUndoWithActionName:actionName block:^(NSUndoManager *manager) {
		
		[_file addNotes:notes];
		[_file sortNotesByTimestamp];
		
		NSIndexSet *set = [_file.notes indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
			return [notes containsObject:obj];
		}];
		
		[[manager prepareWithInvocationTarget:self] removeNotesAtIndices:set withActionName:@"Delete Notes" updateUI:YES];
		
		[_rollView reloadData];
		
	}];
	
	[self checkForOverlappingNotes];
}

- (void)insertNote:(RMDNote *)note atIndex:(NSUInteger)index {
	[[self undoManager] groupUndoWithActionName:@"Insert Note" block:^(NSUndoManager *manager) {
		
		NSIndexSet *set = [NSIndexSet indexSetWithIndex:index];
		[[manager prepareWithInvocationTarget:self] removeNotesAtIndices:set withActionName:@"Delete Notes" updateUI:YES];
		
		[_file insertNote:note atIndex:index];
		
	}];
	
	[self checkForOverlappingNotes];
}

- (void)removeNotesAtIndices:(NSIndexSet *)indices withActionName:(NSString *)actionName updateUI:(BOOL)flag {
	[[self undoManager] groupUndoWithActionName:actionName block:^(NSUndoManager *manager) {
		
		NSArray *notes = [_file.notes objectsAtIndexes:indices];
		[[manager prepareWithInvocationTarget:self] addNotes:notes withActionName:@"Add Notes"];
		
		if (flag)
			[_rollView deleteNotesAtIndices:indices];
		
		[_file removeNotesAtIndices:indices];
		
	}];
	
	[self checkForOverlappingNotes];
}

- (void)changeDurationOfNoteAtIndex:(NSUInteger)index to:(MRTimeInterval)duration updateUI:(BOOL)flag {
	RMDNote *note = [_file.notes objectAtIndex:index];
	
	[[self undoManager] groupUndoWithActionName:@"Change Duration" block:^(NSUndoManager *manager) {
		
		[[manager prepareWithInvocationTarget:self] changeDurationOfNoteAtIndex:index to:note.duration updateUI:YES];
		
		note.duration = duration;
		
		if (flag)
			[_rollView reloadNoteAtIndex:index];
		
	}];
	
	[self checkForOverlappingNotes];
}

- (void)changePitchOfNoteAtIndex:(NSUInteger)index to:(MRNotePitch)pitch updateUI:(BOOL)flag {
	RMDNote *note = [_file.notes objectAtIndex:index];
	
	[[self undoManager] groupUndoWithActionName:@"Change Pitch" block:^(NSUndoManager *manager) {
		
		[[manager prepareWithInvocationTarget:self] changePitchOfNoteAtIndex:index to:note.pitch updateUI:YES];
		
		note.pitch = pitch;
		
		if (flag)
			[_rollView reloadNoteAtIndex:index];
		
	}];
}

- (void)changeTimestampOfNoteAtIndex:(NSUInteger)index to:(MRTimeInterval)timestamp updateUI:(BOOL)flag {
	RMDNote *note = [_file.notes objectAtIndex:index];
	
	[[self undoManager] groupUndoWithActionName:@"Change Timestamp" block:^(NSUndoManager *manager) {
		
		[[manager prepareWithInvocationTarget:self] changeTimestampOfNoteAtIndex:index to:note.timestamp updateUI:YES];
		
		note.timestamp = timestamp;
		
		if (flag)
			[_rollView reloadNoteAtIndex:index];
		
	}];
}

#pragma mark -
#pragma mark UI Actions

- (IBAction)playStop:(id)sender {
	if ([_file isPlaying]) {
		[_file stop];
	}
	else {
		[_file play];
	}
}

- (IBAction)copy:(id)sender {
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	NSArray *notes = [_file.notes objectsAtIndexes:[_rollView selectedIndices]];
	
	[pasteboard clearContents];
	[pasteboard writeObjects:notes];
}

- (IBAction)cut:(id)sender {
	[self copy:sender];
	
	NSIndexSet *indices = [_rollView selectedIndices];
	[self removeNotesAtIndices:indices withActionName:@"Cut Notes" updateUI:YES];
}

- (IBAction)paste:(id)sender {
	NSArray *classes = [NSArray arrayWithObject:[RMDNote class]];
	NSDictionary *options = [NSDictionary dictionary];
	
	NSArray *notes = [[NSPasteboard generalPasteboard] readObjectsForClasses:classes options:options];
	[self addNotes:notes withActionName:@"Paste Notes"];
	
	NSIndexSet *set = [_file.notes indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		return [notes containsObject:obj];
	}];
	
	[_rollView selectNotesAtIndices:set];
}

- (IBAction)record:(id)sender {
	if (_recordStartTime == 0) {
		// start recording
		_recordStartTime = getUptimeInMilliseconds();
		_recordedNotes = [NSMutableArray new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(noteOn:)
													 name:InputManagerNoteOnNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(noteOff:)
													 name:InputManagerNoteOffNotification
												   object:nil];
	}
	else {
		// stop recording
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		_recordStartTime = 0;
		
		[self addNotes:_recordedNotes withActionName:@"Recording"];
		
		_recordedNotes = nil;
	}
}

#pragma mark -
#pragma mark Recording

- (void)noteOn:(NSNotification *)notification {
	if (_recordStartTime == 0 || _currentNote != nil)
		return;
	
#warning TODO: delegate time to sender
	
	_currentNote = [[RMDNote alloc] init];
	_currentNote.timestamp = (getUptimeInMilliseconds() - _recordStartTime);
	_currentNote.pitch = [[[notification userInfo] objectForKey:NoteValueKey] intValue];
}

- (void)noteOff:(NSNotification *)notification {
	if (_recordStartTime == 0 || _currentNote == nil)
		return;
	
	_currentNote.duration = getUptimeInMilliseconds() - _recordStartTime - _currentNote.timestamp;
	
	[_recordedNotes addObject:_currentNote];
	_currentNote = nil;
}

#pragma mark -
#pragma mark Piano Roll View

- (NSUInteger)numberOfNotesInPianoRollView:(MRPianoRollView *)view {
	return [_file.notes count];
}

- (id < MRNote >)noteAtIndex:(NSUInteger)index {
	return [_file.notes objectAtIndex:index];
}

- (void)pianoRollView:(MRPianoRollView *)view changedDurationOfNoteAtIndex:(NSUInteger)index to:(MRTimeInterval)duration {
	[self changeDurationOfNoteAtIndex:index to:duration updateUI:NO];
}

- (void)pianoRollView:(MRPianoRollView *)view changedPitchOfNoteAtIndex:(NSUInteger)index to:(MRNotePitch)pitch {
	[self changePitchOfNoteAtIndex:index to:pitch updateUI:NO];
}

- (void)pianoRollView:(MRPianoRollView *)view changedTimestampOfNoteAtIndex:(NSUInteger)index to:(MRTimeInterval)timestamp {
	[self changeTimestampOfNoteAtIndex:index to:timestamp updateUI:NO];
}

- (void)pianoRollView:(MRPianoRollView *)view insertedNoteAtIndex:(NSUInteger)index withTimestamp:(MRTimeInterval)timestamp duration:(MRTimeInterval)duration pitch:(MRNotePitch)pitch {
	
	RMDNote *note = [[RMDNote alloc] init];
	note.timestamp = timestamp;
	note.duration = duration;
	note.pitch = pitch;
	
	[self insertNote:note atIndex:index];
}

- (void)pianoRollView:(MRPianoRollView *)view deletedNotesAtIndices:(NSIndexSet *)indices {
	[self removeNotesAtIndices:indices withActionName:@"Delete Notes" updateUI:NO];
}

#pragma mark -
#pragma mark Utilities

uint64_t getUptimeInMilliseconds() {
	static const int64_t kOneMillion = 1000 * 1000;
	static mach_timebase_info_data_t s_timebase_info;
	
	if (s_timebase_info.denom == 0) {
		mach_timebase_info(&s_timebase_info);
	}
	
	return ((mach_absolute_time() * s_timebase_info.numer) / (kOneMillion * s_timebase_info.denom));
}

#pragma mark -

@end
