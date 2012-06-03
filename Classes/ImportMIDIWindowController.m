//
//  ImportMIDIWindowController.m
//  NXT Band
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "ImportMIDIWindowController.h"

#import "FreqTable.h"
#import "RMDFile.h"

@interface ImportMIDIWindowController ()

- (void)processSequence;
- (void)stopPlayingTrack;
- (UInt32)selectedTrackIdx;
- (BOOL)hasNextEvent:(MusicEventIterator)iterator;

@end

@implementation ImportMIDIWindowController

#define NAME_KEY @"name"
#define IDX_KEY @"index"

#define C3 60

@synthesize tracksController = _tracksController;
@synthesize file;

- (id)init {
	return [self initWithPath:nil];
}

- (id)initWithPath:(NSString *)path {
	NSParameterAssert(path != nil);
	
	self = [super initWithWindowNibName:@"ImportMIDIWindow"];
	if (self) {
		NSURL *url = [NSURL fileURLWithPath:path];
		
		NewMusicSequence(&_sequence);
		
		if (MusicSequenceFileLoad(_sequence, (__bridge CFURLRef) url, 0, 0) != noErr)
			return nil;
		
		_playingTrack = -1;
	}
	return self;
}

- (void)finalize {
	DisposeMusicSequence(_sequence);
	_sequence = NULL;
	
	DisposeMusicPlayer(_player);
	_player = NULL;
	
	[super finalize];
}

- (void)awakeFromNib {
	[self processSequence];
}

- (void)processSequence {
	UInt32 tracksCount = 0;
	if (MusicSequenceGetTrackCount(_sequence, &tracksCount) != noErr)
		return;
	
	for (UInt32 n = 0; n < tracksCount; n++) {
		MusicTrack track = NULL;
		MusicSequenceGetIndTrack(_sequence, n, &track);
		
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithUnsignedInt:n], IDX_KEY,
							  [NSString stringWithFormat:@"Track %d", n], NAME_KEY, nil];
		
		[self.tracksController addObject:dict];
	}
}

- (void)stopPlayingTrack {
	if (_playingTrack) {
		MusicPlayerStop(_player);
		
		MusicTrack track;
		MusicSequenceGetIndTrack(_sequence, _playingTrack, &track);
		
		boolean_t val = false;
		MusicTrackSetProperty(track, kSequenceTrackProperty_SoloStatus, &val, sizeof(val));
		
		_playingTrack = -1;
	}
}

- (UInt32)selectedTrackIdx {
	NSDictionary *trackDict = [[self.tracksController selectedObjects] objectAtIndex:0];
	return [[trackDict objectForKey:IDX_KEY] unsignedIntValue];
}

- (BOOL)hasNextEvent:(MusicEventIterator)iterator {
	Boolean hasNext = false;
	MusicEventIteratorHasNextEvent(iterator, &hasNext);
	
	return (BOOL) hasNext;
}

- (IBAction)preview:(id)sender {
	if (!_player) {
		NewMusicPlayer(&_player);
		MusicPlayerSetSequence(_player, _sequence);
	}
	
	[self stopPlayingTrack];
	
	UInt32 idx = [self selectedTrackIdx];
	
	MusicTrack track;
	MusicSequenceGetIndTrack(_sequence, idx, &track);
	
	boolean_t val = true;
	MusicTrackSetProperty(track, kSequenceTrackProperty_SoloStatus, &val, sizeof(val));
	
	MusicPlayerStart(_player);
	
	_playingTrack = idx;
}

- (IBAction)cancel:(id)sender {
	file = nil;
	
	[self close];
	[NSApp stopModal];
}

- (IBAction)select:(id)sender {
	[self stopPlayingTrack];
	
	UInt32 idx = [self selectedTrackIdx];
	
	MusicTrack track = NULL;
	MusicSequenceGetIndTrack(_sequence, idx, &track);
	
	MusicEventIterator iterator = NULL;
	NewMusicEventIterator(track, &iterator);
	
	file = [[RMDFile alloc] init];
	uint64_t currentTimestamp = 0;
	
	while ([self hasNextEvent:iterator]) {
		MusicEventIteratorNextEvent(iterator);
		
		MusicTimeStamp timestamp = 0.0f;
		MusicEventType eventType = 0;
		const void *eventData = NULL;
		UInt32 eventDataSize = 0;
		
		MusicEventIteratorGetEventInfo(iterator, &timestamp, &eventType, &eventData, &eventDataSize);
		
		if (eventType == kMusicEventType_MIDINoteMessage) {
			const MIDINoteMessage *noteMessage = (const MIDINoteMessage *) eventData;
			
			uint64_t actualTimestamp = (uint64_t) (timestamp * 1000.0f);
			uint16_t duration = (uint16_t) (noteMessage->duration * 1000.0f);
			
			// check for overlap
			if (actualTimestamp < currentTimestamp) {
				currentTimestamp = actualTimestamp + duration;
				continue;
			}
			
			MRNotePitch pitch = noteMessage->note - C3;
			
			RMDNote *note = [[RMDNote alloc] init];
			note.timestamp = currentTimestamp;
			note.duration = duration;
			note.pitch = pitch;
			
			[file addNote:note];
			
			currentTimestamp = actualTimestamp + duration;
		}
	}
	
	DisposeMusicEventIterator(iterator);
	
	[self close];
	[NSApp stopModal];
}

@end
