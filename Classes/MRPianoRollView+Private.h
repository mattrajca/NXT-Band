//
//  MRPianoRollView+Private.h
//  NoteKit
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "MRPianoRollView.h"

@class MRNoteView;

@interface MRPianoRollView (Private)

- (void)pr_selectedNoteView:(MRNoteView *)noteView;
- (void)pr_changedNoteViewWidth:(MRNoteView *)noteView;

@end
