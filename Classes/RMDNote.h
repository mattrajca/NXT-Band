//
//  RMDNote.h
//  NXT Band
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "MRNote.h"

@interface RMDNote : NSObject < NSCoding, NSPasteboardReading, NSPasteboardWriting, MRNote >

@property (nonatomic, assign) MRTimeInterval timestamp;
@property (nonatomic, assign) MRTimeInterval duration;
@property (nonatomic, assign) MRNotePitch pitch;

@end
