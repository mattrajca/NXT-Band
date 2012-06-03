//
//  RMDNote.m
//  NXT Band
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "RMDNote.h"

@implementation RMDNote

static NSString *const kNoteType = @"com.MattRajca.RMD.Note";

static NSString *const kTimestampKey = @"timestamp";
static NSString *const kDurationKey = @"duration";
static NSString *const kPitchKey = @"pitch";

@synthesize timestamp = _timestamp, duration = _duration, pitch = _pitch;

- (NSString *)description {
	return [NSString stringWithFormat:@"<RMDNote 0x%x | duration=%d, pitch=%d>",
			self, self.duration, self.pitch];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	if (self) {
		self.timestamp = (MRTimeInterval) [aDecoder decodeInt64ForKey:kTimestampKey];
		self.duration = (MRTimeInterval) [aDecoder decodeInt64ForKey:kDurationKey];
		self.pitch = (MRNotePitch) [aDecoder decodeIntForKey:kPitchKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt64:self.timestamp forKey:kTimestampKey];
	[aCoder encodeInt64:self.duration forKey:kDurationKey];
	[aCoder encodeInt:self.pitch forKey:kPitchKey];
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
	return [NSArray arrayWithObject:kNoteType];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
	return NSPasteboardReadingAsKeyedArchive;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
	return [NSArray arrayWithObject:kNoteType];
}

- (id)pasteboardPropertyListForType:(NSString *)type {
	if ([type isEqualToString:kNoteType]) {
		return [NSKeyedArchiver archivedDataWithRootObject:self];
	}
	
	return nil;
}

@end
