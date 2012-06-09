//
//  RMDFile.m
//  NXT Band
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "RMDFile.h"

#import "FreqTable.h"
#import "RMDFile+Private.h"

@implementation RMDFile

#define PREFIX_LEN 8
#define IDENTIFIER 1536

#define NOTE_LEN 4

@dynamic totalDuration;
@synthesize notes = _notes;

- (id)init {
	self = [super init];
	if (self) {
		_notes = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithData:(NSData *)data {
	NSParameterAssert(data != nil);
	
	self = [self init];
	if (self) {
		if (![self loadData:data]) {
			return nil;
		}
	}
	return self;
}

- (uint64_t)totalDuration {
	RMDNote *lastNote = [_notes lastObject];
	
	if (!lastNote)
		return 0;
	
	return lastNote.timestamp + lastNote.duration;
}

- (BOOL)loadData:(NSData *)data {
	uint16_t identifier;
	[data getBytes:&identifier range:NSMakeRange(0, sizeof(identifier))];
	
	identifier = OSSwapBigToHostInt16(identifier);
	
	if (identifier != IDENTIFIER) {
		NSLog(@"Invalid RMD file: unknown identifier");
		return NO;
	}
	
	uint16_t payloadSize;
	[data getBytes:&payloadSize range:NSMakeRange(2, sizeof(payloadSize))];
	
	payloadSize = OSSwapBigToHostInt16(payloadSize);
	
	if (payloadSize != ([data length] - PREFIX_LEN)) {
		NSLog(@"Invalid RMD file: wrong payload size");
		return NO;
	}
	
	uint64_t timestamp = 0;
	uint16_t notes = payloadSize / NOTE_LEN;
	
	for (uint16_t n = 0; n < notes; n++) {
		uint16_t frequency;
		
		[data getBytes:&frequency range:NSMakeRange(PREFIX_LEN + n * NOTE_LEN, sizeof(frequency))];
		frequency = OSSwapBigToHostInt16(frequency);
		
		uint16_t duration;
		
		[data getBytes:&duration range:NSMakeRange(PREFIX_LEN + 2 + n * NOTE_LEN, sizeof(duration))];
		duration = OSSwapBigToHostInt16(duration);
		
		if (frequency == 0) {
			timestamp += duration;
			continue;
		}
		
		RMDNote *note = [[RMDNote alloc] init];
		note.timestamp = timestamp;
		note.duration = duration;
		note.pitch = idx_for_note_freq(frequency);
		
		[_notes addObject:note];
		
		timestamp += duration;
	}
	
	return YES;
}

- (NSData *)representation {
	NSMutableData *data = [[NSMutableData alloc] init];
	
	uint16_t identifier = OSSwapHostToBigInt16(IDENTIFIER);
	[data appendBytes:&identifier length:sizeof(identifier)];
	
	uint32_t empty = 0;
	[data appendBytes:&empty length:2];
	[data appendBytes:&empty length:4];
	
	uint16_t entries = 0;
	uint64_t currentTimestamp = 0;
	
	for (RMDNote *note in _notes) {
		if (note.timestamp > currentTimestamp) {
			uint16_t freq = 0;
			uint16_t duration = OSSwapHostToBigInt16(note.timestamp - currentTimestamp);
			
			[data appendBytes:&freq length:sizeof(freq)];
			[data appendBytes:&duration length:sizeof(duration)];
			
			entries++;
		}
		
		uint16_t freq = OSSwapHostToBigInt16(freq_for_note(note.pitch));
		uint16_t duration = OSSwapHostToBigInt16(note.duration);
		
		[data appendBytes:&freq length:sizeof(freq)];
		[data appendBytes:&duration length:sizeof(duration)];
		
		currentTimestamp = note.timestamp + note.duration;
		entries++;
	}
	
	uint16_t payloadSize = OSSwapHostToBigInt16(entries * NOTE_LEN);
	
	[data replaceBytesInRange:NSMakeRange(sizeof(identifier), sizeof(payloadSize))
					withBytes:&payloadSize];
	
	return [data copy];
}

- (void)addNote:(RMDNote *)note {
	[_notes addObject:note];
}

- (void)addNotes:(NSArray *)notes {
	[_notes addObjectsFromArray:notes];
}

- (void)insertNote:(RMDNote *)note atIndex:(NSUInteger)index {
	[_notes insertObject:note atIndex:index];
}

- (void)removeNotesAtIndices:(NSIndexSet *)indices {
	[_notes removeObjectsAtIndexes:indices];
}

- (void)sortNotesByTimestamp {
	[_notes sortUsingComparator:^NSComparisonResult(RMDNote *note1, RMDNote *note2) {
		
		if (note1.timestamp < note2.timestamp) {
			return NSOrderedAscending;
		}
		else if (note1.timestamp > note2.timestamp) {
			return NSOrderedDescending;
		}
		
		return NSOrderedSame;
		
	}];
}

@end
