//
//  RMDFile+Private.h
//  NXT Band
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

#import "RMDFile.h"

#import <AudioToolbox/AudioToolbox.h>

@interface RMDFile () {
	MusicSequence _sequence;
	MusicPlayer _player;
	MusicTimeStamp _lastNoteOffTimestamp;
}

- (BOOL)loadData:(NSData *)data;

@end
