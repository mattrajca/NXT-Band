//
//  RMDFile+Playback.m
//  NXT Band
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

#import "RMDFile+Playback.h"

#import "RMDFile+Private.h"

@implementation RMDFile (Playback)

#define C3 60

- (void)play {
	if (![self.notes count])
		return;
	
	[self stop];
	
	NewMusicSequence(&_sequence);
	MusicSequenceSetSequenceType(_sequence, kMusicSequenceType_Seconds);
	
	MusicTrack track;
	MusicSequenceNewTrack(_sequence, &track);
	
	for (RMDNote *note in self.notes) {
		MIDINoteMessage message;
		message.channel = 0;
		message.duration = note.duration / 1000.0f;
		message.note = note.pitch + C3;
		message.velocity = 127;
		
		MusicTrackNewMIDINoteEvent(track, note.timestamp / 1000.0, &message);
	}
	
	RMDNote *lastNote = [self.notes lastObject];
	_lastNoteOffTimestamp = (lastNote.timestamp + lastNote.duration) / 1000.0 + 1.0; // add 1s...
	
	NewMusicPlayer(&_player);
	MusicPlayerSetSequence(_player, _sequence);
	MusicPlayerPreroll(_player);
	MusicPlayerStart(_player);
	
	_reserved1 = [NSTimer scheduledTimerWithTimeInterval:1.0
												  target:self
												selector:@selector(checkPlayback:)
												userInfo:nil
												 repeats:YES];
}

- (void)checkPlayback:(NSTimer *)timer {
	MusicTimeStamp outTime;
	MusicPlayerGetTime(_player, &outTime);
	
	if (outTime > _lastNoteOffTimestamp) {
		[self stop];
		[timer invalidate];
	}
}

- (void)stop {
	[_reserved1 invalidate];
	_reserved1 = nil;
	
	MusicPlayerStop(_player);
	
	DisposeMusicPlayer(_player);
	_player = NULL;
	
	DisposeMusicSequence(_sequence);
	_sequence = NULL;
}

@end
