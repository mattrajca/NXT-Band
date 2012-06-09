//
//  RMDFile.h
//  NXT Band
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "RMDNote.h"

@interface RMDFile : NSObject {
  @private
	NSMutableArray *_notes;
	id _reserved1;
}

@property (nonatomic, readonly) uint64_t totalDuration;

@property (nonatomic, readonly) NSArray *notes;

- (id)initWithData:(NSData *)data;

- (NSData *)representation;

- (void)addNote:(RMDNote *)note;
- (void)addNotes:(NSArray *)notes;
- (void)insertNote:(RMDNote *)note atIndex:(NSUInteger)index;
- (void)removeNotesAtIndices:(NSIndexSet *)indices;

- (void)sortNotesByTimestamp;

@end
