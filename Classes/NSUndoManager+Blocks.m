//
//  NSUndoManager+Blocks.m
//  NXT Band
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

#import "NSUndoManager+Blocks.h"

@implementation NSUndoManager (Blocks)

- (void)groupUndoWithActionName:(NSString *)name block:(void(^)(NSUndoManager *))block {
	[self beginUndoGrouping];
	
	block(self);
	
	[self endUndoGrouping];
	[self setActionName:name];
}

@end
