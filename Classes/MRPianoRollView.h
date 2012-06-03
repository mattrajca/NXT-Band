//
//  MRPianoRollView.h
//  NoteKit
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "MRNote.h"
#import "MRNoteView.h"

@protocol MRPianoRollViewDataSource;

@interface MRPianoRollView : NSView

@property (nonatomic, assign) BOOL allowsNoteCreation;

@property (nonatomic, weak) id < MRPianoRollViewDataSource > dataSource;

+ (CGFloat)noteLineHeight;

- (void)reloadData;

- (NSIndexSet *)selectedIndices;

// updation methods
- (void)reloadNoteAtIndex:(NSUInteger)index;
- (void)deleteNotesAtIndices:(NSIndexSet *)indices;

@end


@protocol MRPianoRollViewDataSource < NSObject >

- (NSUInteger)numberOfNotesInPianoRollView:(MRPianoRollView *)view;
- (id < MRNote >)noteAtIndex:(NSUInteger)index;

- (void)pianoRollView:(MRPianoRollView *)view changedDurationOfNoteAtIndex:(NSUInteger)index to:(MRTimeInterval)duration;
- (void)pianoRollView:(MRPianoRollView *)view changedPitchOfNoteAtIndex:(NSUInteger)index to:(MRNotePitch)pitch;

- (void)pianoRollView:(MRPianoRollView *)view insertedNoteAtIndex:(NSUInteger)index withTimestamp:(MRTimeInterval)timestamp duration:(MRTimeInterval)duration pitch:(MRNotePitch)pitch;
- (void)pianoRollView:(MRPianoRollView *)view deletedNotesAtIndices:(NSIndexSet *)indices;

@end
