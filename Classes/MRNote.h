//
//  MRNote.h
//  NoteKit
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

typedef uint64_t MRTimeInterval;
typedef unsigned int MRNotePitch;

@protocol MRNote < NSObject >

- (MRTimeInterval)timestamp;
- (MRTimeInterval)duration;
- (MRNotePitch)pitch;

@end
