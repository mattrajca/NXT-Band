//
//  RMDFile+Playback.h
//  NXT Band
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

#import "RMDFile.h"

@interface RMDFile (Playback)

- (BOOL)isPlaying; // KVO-compliant

- (void)play;
- (void)stop;

@end
