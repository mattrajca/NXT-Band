//
//  NSUndoManager+Blocks.h
//  NXT Band
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

@interface NSUndoManager (Blocks)

- (void)groupUndoWithActionName:(NSString *)name block:(void(^)(NSUndoManager *))block;

@end
