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
- (void)pr_changedNoteViewX:(MRNoteView *)noteView;
- (void)pr_changedNoteViewY:(MRNoteView *)noteView;

- (CGFloat)gridAlignedYPosition:(CGFloat)y;

@end
