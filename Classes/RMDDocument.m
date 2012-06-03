//
//  RMDDocument.m
//  NXT Band
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "RMDDocument.h"

#import "NSUndoManager+Blocks.h"
#import "RMDFile.h"
#import "RMDFile+Playback.h"

@interface RMDDocument ()

- (void)setupRoll;

- (BOOL)hasOverlappingNotes;

@end


@implementation RMDDocument

#define NOTES 29
#define WIDTH_LEEWAY 2000.0f

@synthesize rollView = _rollView, infoField = _infoField;
@synthesize file = _file;

- (id)initWithType:(NSString *)typeName error:(NSError **)outError {
	self = [super initWithType:typeName error:outError];
	if (self) {
		_file = [[RMDFile alloc] init];
	}
	return self;
}

- (void)dealloc {
	[_file stop];
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

- (void)addNotes:(NSArray *)notes {
	[_file addNotes:notes];
	[_file sortNotesByTimestamp];
	
	[_rollView reloadData];
	
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
		[manager registerUndoWithTarget:self selector:@selector(addNotes:) object:notes];
		
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

#pragma mark -
#pragma mark UI Actions

- (IBAction)play:(id)sender {
	[_file play];
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
	NSLog(@"%@", notes);
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

@end
